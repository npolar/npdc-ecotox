#!/usr/bin/env ruby
#
# This programme deletes all entries from a named couch database
# Handy when you want to clear everything.
#
# Author: srldl
#################################################################

require '../server'
require 'net/http'
require 'json'
require '../config'


module Couchdb

  class DeleteEntries

    #Post to server
    def  self.deleteToServer(url,auth,user,password)
     @uri = URI.parse(url)
     http = Net::HTTP.new(@uri.host, @uri.port);
     http.use_ssl = true;
     req = Net::HTTP::Delete.new(@uri.path,{'Authorization' => auth, 'Content-Type' => 'application/json' })
     req.basic_auth(user, password)
     res2 = http.request(req)
     unless ((res2.header).inspect) == "#<Net::HTTPOK 200 OK readbody=true>"
         puts (res2.header).inspect
         puts (res2.body).inspect
         #FileUtils.mv 'leser/'+ filename, 'feilet/' + filename
     end
     return 0
   end

    #Set server
    host = Couch::Config::HOST3
    port = Couch::Config::PORT3
    user = Couch::Config::USER3
    password = Couch::Config::PASSWORD3
    auth = Couch::Config::AUTH3

    db_fieldwork_ecotox = "fieldwork-ecotox"
    db_lab_ecotox = "lab-ecotox"
    db_lab_biomarker = "lab-biomarker"

    #Delete all entries connected to this sample
    delete_id = '31c304e0-60c0-4ea6-90ec-decfad8d7744'
    #'c544a48b-1d85-4017-ac1a-14aff7f70ead'
    #'a4c630fd-cf82-493f-972e-0bf5896ef28b' #1995-1998
    #'01f8f0ec-07e1-4209-b4ec-5538cfcbdacb' #Ark1
    #'31c304e0-60c0-4ea6-90ec-decfad8d7744' #concent 2007 Copol
    #'c0e104a8-fec8-4091-a33c-2bd89080ad3e' #COPOL
    #'3e5e54ab-3d8c-4f4b-9aab-1909e7de6fcd'  #Kjetils

    #Set server database here
    server = Couch::Server.new(host, port)

    link = 'https://' + host + '/lab/ecotox/?q=&filter-database_sample_id_base=' + delete_id + '&limit=all'
    res_eco = server.gets(URI(link))
    #Extract the UUID from reply
    json_eco = JSON.parse(res_eco.body)
    len2 = json_eco['feed']['opensearch']['totalResults']
    entries_lab_ecotox = json_eco['feed']['entries']
    puts "----------"
    puts len2

    j=0
    while j < len2
        puts j
        link_del = 'https://' + host + '/lab/ecotox/' + entries_lab_ecotox[j]['id']
        deleteToServer(link_del,auth,user,password)
        j=j+1
    end

    link = 'https://' + host + '/lab/biomarker/?q=&filter-database_sample_id=' + delete_id + '&limit=all'
    res_bio = server.gets(URI(link))
    #Extract the UUID from reply
    json_bio = JSON.parse(res_bio.body)
    entries_lab_bio = json_bio['feed']['entries']
    len3 = json_bio['feed']['opensearch']['totalResults']

    m=0
    while m < len3
        link_del = 'https://' + host + '/lab/biomarker/' + entries_lab_bio[m]['id']
        deleteToServer(link_del,auth,user,password)
        m=m+1
    end

    #Get search
    link = 'https://' + host + '/ecotox/fieldwork/?q=&filter-database_sample_id_base=' + delete_id + '&limit=all'
    res = server.gets(URI(link))
    #Extract the UUID from reply
    json_field = JSON.parse(res.body)
    len = json_field['feed']['opensearch']['totalResults']
    entries_ecotox_fieldwork = json_field['feed']['entries']

    s=0
    while s < len
        puts entries_ecotox_fieldwork[s]['id']
        link_del = 'https://' + host + '/ecotox/fieldwork/' + entries_ecotox_fieldwork[s]['id']
        deleteToServer(link_del,auth,user,password)
        s=s+1
    end

  end
end
