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
require 'net/http/post/multipart'
require 'net/ssh'
require 'net/scp'
require 'time'
require 'date'
require 'json'
require 'digest/md5'
require 'fileutils'

module Couch

  class DevtoProdFilearchive

    #Set from (dev) server
    host = Couch::Config::HOST4
    port = Couch::Config::PORT4
    user = Couch::Config::USER4
    password = Couch::Config::PASSWORD4
    auth = Couch::Config::AUTH4


    #Set server database here
    server = Couch::Server.new(host, port)

    #Fetch a list of all entries locally
    #Fetch a UUID from couchdb
    link = 'http://db-test.data.npolar.no:5984/ecotox-excel/_all_docs?include_docs=true'

    res = server.gets(URI(link))
    #Extract the UUID from reply
    @uuids = JSON.parse(res.body)
    #puts @uuids['rows'][1]['id']


    #Fetch each file id
    @uuids['rows'].each do |entry|
        #Fetch metadata
        id2 = "#{entry['id']}"
        doc_temp = "#{entry['doc']}"
        doc =  eval(doc_temp)
        md5 = doc['hash']
        filename = doc['filename']
        filetype = doc['type']
      #  puts doc.to_json
      puts id2, filename, filetype, md5

        send_file = 0

        #Fetching the file
        uri =  URI('https://api-test.data.npolar.no/ecotox-excel/'+ id2 +'/_file/' + md5)
        request = Net::HTTP::Get.new uri.request_uri
        request.basic_auth user, password

        Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
          response = http.request request
          if ((response.header).inspect) == "#<Net::HTTPOK 200 OK readbody=true>"
            # @entry = (response.body).inspect
            @entry = response.body
            File.open(filename, 'a') { |file| file.puts (@entry) }
            send_file = 1
          else
            send_file = 0
          end
      end


    #Send file
    if (send_file == 1)
        url2 = URI.parse('http://api.npolar.no/ecotox/excel/'+id2.to_s+'/_file/')
        http2 = Net::HTTP.new(url2.host, url2.port)
        http2.use_ssl = true if url2.scheme == 'https'

        http2.start do |http22|

        File.open(filename) do |xls|
          req2 = Net::HTTP::Post::Multipart.new url2.path,'file' => UploadIO.new(xls, filetype, filename),'Authorization' => auth
          req2.basic_auth(user, password)
          res3 = http22.request(req2)
          if ((res3.header).inspect) == "#<Net::HTTPOK 200 OK readbody=true>"
             "Uploaded server"

          else
             puts (res3.header).inspect
             puts (res3.body).inspect
            puts "---------------"
          end

       end # file open
     end #http2

    end #send_file



    end

end
end
