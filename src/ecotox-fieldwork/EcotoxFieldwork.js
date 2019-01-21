'use strict';

function EcotoxTemplate( $q, EcotoxTemplateResource) {
  'ngInject';


  EcotoxTemplateResource.create = function() {
      let lang = 'en';
      let collection = "ecotox";
      let matrix = { "needed": true};
      let event_date = {"needed": true};
      let latitude = {"needed": true};
      let longitude = {"needed": true};
      let location = {"needed": true};
      let people_responsible = {"needed": true};
      let ecotox_lab = {"needed": true};
      let rightsholder = {"needed": true};
      let species = {"needed": true};
      let schema = 'http://api.npolar.no/schema/ecotox-template';
      let e = {lang, collection, schema,matrix,event_date,latitude,longitude,location,people_responsible,ecotox_lab,rightsholder,species};
      console.debug(e);
      return e;

    };

     // The hashi (v0) file object should be object with keys filename, url...
  EcotoxTemplateResource.hashiObject = function(file) {
       console.debug('hashiObject', file);
      return {
        url: file.uri,
        filename: file.filename,
        // icon
        length: file.file_size,
        md5sum: (file.hash||'md5:').split('md5:')[1],
        content_type: file.type
      };
    };


    EcotoxTemplateResource.fileObject = function(hashi) {
      console.debug('fileObject', hashi);
      return {
        uri: hashi.url,
        filename: hashi.filename,
        length: hashi.file_size,
        hash: 'md5:'+hashi.md5sum,
        type: hashi.content_type
     };
   };

  return EcotoxTemplateResource;



}
module.exports = EcotoxTemplate;
