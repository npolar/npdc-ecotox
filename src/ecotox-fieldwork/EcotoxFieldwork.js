'use strict';

function EcotoxFieldwork( NpolarApiSecurity, EcotoxFieldworkResource) {
  'ngInject';

   const schema = 'http://api.npolar.no/schema/ecotox-fieldwork';

  return Object.assign(EcotoxFieldworkResource, {

     schema,

     create: function() {

      let user = NpolarApiSecurity.getUser();
      let lang = "en";
      let collection = "ecotox-fieldwork";
      let dateobj = new Date();
      let created= dateobj.toISOString();
      let updated= dateobj.toISOString();
      let created_by= user.name;
      let updated_by= user.name;

      let e = {  schema, lang, collection, created, updated, created_by, updated_by };
      console.debug(e);
      return e;

    }

 });

}
module.exports = EcotoxFieldwork;
