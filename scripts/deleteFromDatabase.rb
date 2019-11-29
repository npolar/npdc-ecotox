#!/usr/bin/env ruby
#
# This programme deletes all entries from a named couch database
# Handy when you want to clear everything.
#
# Author: srldl
#################################################################

require '../server'
require 'net/http'


module Couchdb

  class DeleteEntries

    host = "db-test.data.npolar.no"
    port  = "5984"
    database = "lab-ecotox"
  #database = "lab-biomarker"
  #  database = "ecotox-fieldwork"

    #Get ready to put into database
    server = Couch::Server.new(host, port)

    #Fetch a UUIDs from couchdb
    res = server.get("/"+ database +"/_all_docs")


    #puts res.body

    #Get the UUIDS
    str = (res.body).tr('"','')
    #puts str


    #Need id
    id = str.split('id:')

    #Need revision
    rev = str.split('rev:')

    #Delete all entries
    (id).each_with_index { |r, i|
        #NB! Sometimes it's 36 chars, sometimes it's 32..
      #  puts r[0,32] + '  ' + (rev[i])[0,34]
        puts r[0,36] + '  ' + (rev[i])[0,34]
    #    puts r.length

        if i > 0
          server.delete(("/" + database + "/" + r[0,36]).to_s + "?rev=" + (rev[i])[0,34])
        end
     }


  end
end
