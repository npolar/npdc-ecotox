'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch, EcotoxFieldworkService, $resource,
  EcotoxFieldworkDBSave) {
  'ngInject';

  //let tb = require( '@srldl/edit-tabletest/js/edit-table.js');
  let tb = require('@srldl/exceldb/index.js');

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters, security and auth
  $scope.resource = EcotoxFieldwork;
  $scope.security = NpolarApiSecurity;
  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);


    //Save to database
    function saveDb(jsonObj){
      let id = $routeParams.id;
      let user = NpolarApiSecurity.getUser();
      let dateobj = new Date();
      // Update object with all entry infomation
      let arrObj = [];
      let obj;
      for (let i=0;i<jsonObj.dataRows.length;i++){
        obj = {};
        for (let j=0;j<jsonObj.headers.length;j++){
           obj[jsonObj.headers[j].toString()] = jsonObj.dataRows[i][j];
        }
        arrObj.push(obj);
      }
      //Fetch last rev
      var ecotoxFieldwork = DBSearch.get({search:id, link:'ecotox',link2:'fieldwork'}, function(){

                ecotoxFieldwork.entry = arrObj;
                ecotoxFieldwork.updated_by = user.name;
                ecotoxFieldwork.updated = dateobj.toISOString();
                EcotoxFieldworkDBSave.update({ id: id }, ecotoxFieldwork);

      }, function() {  //get an error because it is a new entry
         console.log("got an error");
         //create a new object
         let ecotoxFieldworkEntry  = {
            "_id": id,
            "id": id,
            "schema": "http://api.npolar.no/schema/ecotox-fieldwork",
            "lang": "en",
            "ecotox_template": id,
            entry: arrObj,
            "collection": "ecotox-fieldwork",
            "created": dateobj.toISOString(),
            "updated": dateobj.toISOString(),
            "created_by": user.name,
            "updated_by": user.name
         };
        // ecotoxFieldworkEntry.entry = jsonObj;
         EcotoxFieldworkDBSave.update({ id: id }, ecotoxFieldworkEntry);
      });

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
         //Traverse object full to get all the parameters_ subobject
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
            let autocomplete = {};
            for (var val of full.additional) {
                 //Replace space with underscore
                 let temp = (val.parameter_name);
                 //Strip parameter_name for all chars except English letters, numbers, space and underscore
                 //autocomplete - add new property to object
                 autocomplete[temp.replace(/[^a-zA-Z0-9_]+/,'_')] = "internal";
                 header.push(temp.replace(/[^a-zA-Z0-9_]+/,'_'));
            }

            //Finally add id
            header.push('id');

          //Get select and date list
          let selectlist = {};  //Array to hold select elements
          let dateFields = [];  //Array to hold date fields
          let header_tooltip = [];  //Array to hold tooltip
          $scope.jsonSchema = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){

              //Set headet_tooltip
              for (let s=0;s<header.length;s++){
                    if  ($scope.jsonSchema.properties.entry.items.hasOwnProperty(header[s])) {
                      header_tooltip.push($scope.jsonSchema.properties.entry.items[header[s]].description === undefined ? "" :  $scope.jsonSchema.properties.entry.items[header[s]].description);
                    }
              }

              //header_tooltip might not be filled if there are additionalwon defined fields
              //additional.parameter_description
              for (let k=header_tooltip.length;k<header.length;k++) {
                    for (let g=0;g<full.additional.length;g++) {
                      if (header[k] === full.additional[g].parameter_name){
                            header_tooltip.push(full.additional[g].parameter_description === undefined ? "" : full.additional[g].parameter_description);
                      }
                    }
              }



                  //Iterate through all schema keys containing enum and date-time
                  //If key are in headers list, add key and options (enums) to select list
                  //If key element contains format =  date-time, add it to the datelist
                  for (var key in $scope.jsonSchema.properties.entry.items) {
                        if  (($scope.jsonSchema.properties.entry.items.hasOwnProperty(key))) {
                                //Insert select and date elements
                                 if ((header).includes(key)&&($scope.jsonSchema.properties.entry.items[key].enum)) {
                                     selectlist[key] =  $scope.jsonSchema.properties.entry.items[key].enum;
                                 } else if ((header).includes(key)&&($scope.jsonSchema.properties.entry.items[key].format === "date-time")) {
                                      dateFields.push(key);
                                 }
                        }
                  }

              //Create input object for library
              EcotoxFieldworkService.excelObj =
                          { "dataRows": fieldwork,
                            "headers": header,
                            "selectlist": selectlist, //{"project_group":["MOSJ","thesis"]},
                            "headers_tooltip": header_tooltip,
                            "autocompletes": autocomplete,
                            "dateFields":dateFields,
                            "saveJson":[],
                            "id": id,
                            "sanitize": true
                          };

               $scope.excelObj = EcotoxFieldworkService.excelObj;
               tb.insertTable(EcotoxFieldworkService.excelObj,saveDb);

            });  //Fetch selects

      });

    } //end function



         //Search database, fetch old entries or start a new, empty sheet
         $scope.show().$promise.then((ecotoxFieldwork) => {
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
