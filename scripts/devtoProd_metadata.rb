#!/usr/bin/env ruby
# Read FILES from development to production server
#
# Author: srldl
#
# Requirements:
#
########################################

require '../config'
require '../server'
require 'net/http'
require 'net/ssh'
require 'net/scp'
require 'time'
require 'date'
require 'json'
require 'digest/md5'
require 'fileutils'

module Couch

  class DevtoProd

    #Set from (dev) server
    host = Couch::Config::HOST4
    port = Couch::Config::PORT4
    user = Couch::Config::USER4
    password = Couch::Config::PASSWORD4
    auth = Couch::Config::AUTH4

    database = 'ecotox-fieldwork'
    database2 = 'ecotox/fieldwork'


    #Set server database here
    server = Couch::Server.new(host, port)

    #Fetch a list of all entries locally
    #Fetch a UUID from couchdb
    link = 'http://db-test.data.npolar.no:5984/'+ database +'/_all_docs?include_docs=false'

    res = server.gets(URI(link))
    #Extract the UUID from reply
    @uuids = JSON.parse(res.body)
    #puts @uuids['rows'][1]['id']

    #Fetch each file id
    @uuids['rows'].each do |entry|
        #Fetch metadata
        id2 = "#{entry['id']}"

        #Fetch the single metadata file
        link2 = 'http://db-test.data.npolar.no:5984/'+ database +'/' + id2
        res2 = server.gets(URI(link2))
        #Extract the UUID from reply
        @metadata = JSON.parse(res2.body)
        #@entry = (res2.body).inspect
        #Need to remove _rev
        @metadata.tap { |hs| hs.delete('_rev') }

        url = 'https://api.npolar.no/'+ database2 +'/'+id2.to_s
        @uri = URI.parse(url)
        http = Net::HTTP.new(@uri.host, @uri.port);
        http.use_ssl = true;
        req = Net::HTTP::Post.new(@uri.path,{'Authorization' => auth, 'Content-Type' => 'application/json' })
        req.body = @metadata.to_json
        req.basic_auth(user, password)
        res2 = http.request(req)
        unless ((res2.header).inspect) == "#<Net::HTTPOK 200 OK readbody=true>"
            puts (res2.header).inspect
            puts (res2.body).inspect
        end

    end


end
end
