'use strict';

function EcotoxTemplate(EcotoxTemplateResource) {
  'ngInject';

  let schema = 'http://api.npolar.no/schema/ecotox-template';

  return Object.assign(EcotoxTemplateResource, {

    schema,

  create: function() {
      let lang = 'en';
      let collection = "ecotox-template";
      let parameters_metadata = {
	         "rightsholder": true,
	         "people_responsible": true
      };
      let parameters_time_and_place = {
	         "event_date": true,
	         "placename": true,
	         "latitude": true,
	         "longitude": true
      };
      let parameters_base = {
	       "species": true
      };

      let p = {lang,collection,schema,parameters_metadata,parameters_time_and_place,parameters_base};
      console.debug(p);
      return p;
    },


     // The hashi (v0) file object should be object with keys filename, url...
    hashiObject: function(file) {
       console.debug('hashiObject', file);
      return {
        url: file.uri,
        filename: file.filename,
        // icon
        length: file.file_size,
        md5sum: (file.hash||'md5:').split('md5:')[1],
        content_type: file.type
      };
    },

    fileObject: function(hashi) {
      console.debug('fileObject', hashi);
      return {
        uri: hashi.url,
        filename: hashi.filename,
        length: hashi.file_size,
        hash: 'md5:'+hashi.md5sum,
        type: hashi.content_type
     };
   }

 });

}
module.exports = EcotoxTemplate;
