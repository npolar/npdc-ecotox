'use strict';

function EcotoxTemplate( $q, EcotoxTemplateResource) {
  'ngInject';


  EcotoxTemplateResource.create = function() {
      let lang = 'en';
      let collection = "ecotox";
      let schema = 'http://api-test.data.npolar.no/schema/geology-sample';
      let e = {  lang, collection, schema };
      console.debug(e);
      return e;

    };

  return EcotoxTemplateResource;



}
module.exports = EcotoxTemplate;
