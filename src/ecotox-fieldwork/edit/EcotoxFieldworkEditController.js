'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch, EcotoxFieldworkService, $resource) {
  'ngInject';

  let tb = require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters, security and auth
  $scope.resource = EcotoxFieldwork;
  $scope.security = NpolarApiSecurity;
  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);
  //A global object to hold the full JSON schema from database
  let ecotoxFieldworkEntry = {};

  //Save to database
  function saveDb(jsonObj){
    console.log(jsonObj);
    let id = $routeParams.id;
    let user = NpolarApiSecurity.getUser();
    let dateobj = new Date();
    //Save - use either dev or prod
    let resource_str = 'http:' + npolarApiConfig.base + '/ecotox/fieldwork/'+id;
    let push_new = $resource(resource_str);

    //If base information does not exist, create an initial object
    if (ecotoxFieldworkEntry === {}) {
      ecotoxFieldworkEntry  = {
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
      ecotoxFieldworkEntry.entry = jsonObj;


    } else {
      ecotoxFieldworkEntry.entry = jsonObj;
      ecotoxFieldworkEntry.updated_by = user.name;
      ecotoxFieldworkEntry.updated = dateobj.toISOString();
      //Define save to be update/PUT
      let push_new = $resource(resource_str, null,{'update': { method:'PUT' }});
    }
    //Save the entry to database
    push_new.save(ecotoxFieldworkEntry);
    console.log(ecotoxFieldworkEntry);
    console.log("start saving");
  }


    //Convert object to array
    function obj_to_arr(obj){
        let arr = [];
        Object.keys(obj).map(function(key) {
           if (obj[key] === true){
               arr.push(key);
           }
        });
    return arr;
    }

    //Convert object to array
    function view_fieldwork(id,fieldwork=[]){
      //Extract the header texts
     var full = DBSearch.get({search:id, link:'ecotox',link2:'template'}, function(){
         //Traverse object full to get all the parameters_ subobjects
         let header = [];
           Object.keys(full).map(function(key) {
            //Check for empty object
            if ((full[key].constructor === Object)&&(key.startsWith('parameters_'))){
               //Header for database view
               header.push.apply(header, (obj_to_arr(full[key])));
            }
            });


            //If there is additional fields, add these also
            //Internal autocomplete of additional fields
            let autocompletesInternal = [];
            for (var val of full.additional) {
                 //Replace space with underscore
                 let temp = (val.parameter_name);
                 //Strip parameter_name for all chars except English letters, numbers, space and underscore
                 autocompletesInternal.push(temp.replace(/[^a-zA-Z0-9_]+/,'_'));
                 header.push(temp.replace(/[^a-zA-Z0-9_]+/,'_'));
            }

            //Finally add id
            header.push('id');

          //Get select and date list
          let selectlist = {};
          let dateFields = [];
          $scope.jsonSchema = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){

                  //Iterate through all schema keys containing enum and date-time
                  //If key are in headers list, add key and options (enums) to select list
                  //If key element contains format =  date-time, add it to the datelist
                  for (var key in $scope.jsonSchema.properties.entry.items) {
                        if  (($scope.jsonSchema.properties.entry.items.hasOwnProperty(key))) {
                                 if ((header).includes(key)&&($scope.jsonSchema.properties.entry.items[key].enum)) {
                                     selectlist[key] =  $scope.jsonSchema.properties.entry.items[key].enum;
                                 } else if ((header).includes(key)&&($scope.jsonSchema.properties.entry.items[key].format === "date-time")) {
                                      dateFields.push(key);
                                 }
                        }
                  }

              //Create input object for library
              EcotoxFieldworkService.excelObj =
                          { "dataRows":fieldwork,
                            "headers":header,
                            "selectlist": selectlist, //{"project_group":["MOSJ","thesis"]},
                            "autocompletes": autocompletesInternal,
                            "dateFields":dateFields,
                            "saveJson":[],
                            "id": id
                          };

               $scope.excelObj = EcotoxFieldworkService.excelObj;

              tb.insertTable(EcotoxFieldworkService.excelObj,saveDb);


            });  //Fetch selects

      });

    } //end function



         //Search database, fetch old entries or start a new, empty sheet
         $scope.show().$promise.then((ecotoxFieldwork) => {
              // Update global object with all entry infomation
              ecotoxFieldworkEntry = ecotoxFieldwork;
              console.log(ecotoxFieldworkEntry);
              console.log("exists");
              //Get data rows, call template for header
              view_fieldwork($scope.document.id, ecotoxFieldwork.entry);

          })  //If fieldwork is a new database, call returns error
          .catch((err) => {
               if (err.body.error === "not_found") {
                  //Create empty object, call template for header
                   view_fieldwork($routeParams.id, []);
              }
          });

};


module.exports = EcotoxFieldworkEditController;
