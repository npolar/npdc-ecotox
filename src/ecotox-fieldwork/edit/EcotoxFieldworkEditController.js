'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch, EcotoxFieldworkService, $resource) {
  'ngInject';

  require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters
  $scope.resource = EcotoxFieldwork;
  $scope.security = NpolarApiSecurity;
 //Auth
  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);

         //Fetch or save new
         $scope.show().$promise.then((ecotoxFieldwork) => {
              console.log(ecotoxFieldwork.entry);
              console.log("exists already");
          })
          .catch((err) => {
               if (err.body.error === "not_found") {
                  console.log("establish");

            let user = NpolarApiSecurity.getUser();
            let id = $routeParams.id;
            let dateobj = new Date();
            let base  = {
              	"_id": id,
              	"id": id,
              	"schema": "http://api.npolar.no/schema/ecotox-fieldwork",
              	"lang": "en",
                "ecotox_template": id,
              	"collection": "ecotox-fieldwork",
              	"created": dateobj.toISOString(),
              	"updated": dateobj.toISOString(),
              	"created_by": user.name,
              	"updated_by": user.name
              };

                 let push_new = $resource('http://api-test.data.npolar.no/ecotox/fieldwork/'+id);
                 push_new.save(base);


                /* $scope.save().$promise.then((entry) => {
                      console.log("saved");
                  })
                  .catch((err) => {
                     console.log("could not save new");
                  }); */
              }
          });




};


module.exports = EcotoxFieldworkEditController;
