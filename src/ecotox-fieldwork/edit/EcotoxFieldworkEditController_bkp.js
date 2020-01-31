'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch, DBSearchQuery, EcotoxFieldworkService, $resource,
  EcotoxFieldworkDBSave) {
  'ngInject';

  //let tb = require( '@srldl/edit-tabletest/js/edit-table.js');
  let tb = require('@srldl/exceldb/index.js');

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters, security and auth
  $scope.resource = EcotoxFieldwork;
  $scope.security = NpolarApiSecurity;
  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);

  //Strip away empty rows listed at the end
  //Empty rows in the middle of the array are preserved.
  function checkIfRowEmpty(jsonObj){
      for (let i=jsonObj.dataRows.length-1;i>-1;i--){
        for (let j=0;j<jsonObj.dataRows[i].length-1;j++){
           if  ((jsonObj.dataRows[i][j] === '') || (jsonObj.dataRows[i][j] === 'unknown')){
           } else {
               return jsonObj;
           } //if
        } // for
        //Remove empty row
        jsonObj.dataRows.pop();
      }
    return jsonObj;
  }

   //Save to database
   function saveDb(jsonObj){
        console.log("save");
        console.log(jsonObj);

        let jsonObj_cleaned = checkIfRowEmpty(jsonObj);
        console.log(jsonObj_cleaned);

      //let ecotoxFieldworkEntry = new Object();
        let arrObj = [];
        let obj;
        for (let i=0;i<jsonObj_cleaned.dataRows.length;i++){
          let obj  = {
              "schema": "http://api.npolar.no/schema/ecotox-fieldwork",
              "lang": "en",
              "collection": "ecotox-fieldwork"
          };
          for (let j=0;j<jsonObj_cleaned.headers.length;j++){
             obj[jsonObj_cleaned.headers[j].toString()] = jsonObj_cleaned.dataRows[i][j];
             obj.database_sample_id_base = obj.database_sample_id; //Need to break this
             obj.id = obj.database_sample_id;
             //return row here
            // console.log(obj);
            //EcotoxFieldworkDBSave.update({ id: obj.id }, obj);
          }
        //  arrObj.push(obj);
        }
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

     //Extract the header texts - fetch info from ecotox_template
     var  id_base = id.substring(0, id.length-2);
     var full = DBSearch.get({search:id_base, link:'ecotox',link2:'template'}, function(){
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
            header.push('database_sample_id');

          //Get select and date list from ecotox-fieldwork.json schema
          let selectlist = {};  //Array to hold select elements
          let dateFields = [];  //Array to hold date fields
          let header_tooltip = [];  //Array to hold tooltip

          $scope.jsonSchema = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){

              //Set header_tooltip
              for (let s=0;s<header.length;s++){
                    if  ($scope.jsonSchema.properties.hasOwnProperty(header[s])) {
                      header_tooltip.push($scope.jsonSchema.properties[header[s]].description === undefined ? "" :  $scope.jsonSchema.properties[header[s]].description);
                    }
              }

              //header_tooltip might not be filled if there are additional own defined fields
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
                  for (var key in $scope.jsonSchema.properties) {
                        if  (($scope.jsonSchema.properties.hasOwnProperty(key))) {
                                //Insert select and date elements
                                 if ((header).includes(key)&&($scope.jsonSchema.properties[key].enum)) {
                                     selectlist[key] =  $scope.jsonSchema.properties[key].enum;
                                 } else if ((header).includes(key)&&($scope.jsonSchema.properties[key].format === "date-time")) {
                                      dateFields.push(key);
                                 }
                        }
                  }

              //Create input object for library
              //In fieldwork object change database_sample_id_base => database_sample_id
              //Used in npm packet exceldb as database_sample_id
              fieldwork.database_sample_id = id.substring(0, id.length-2);
              delete fieldwork.database_sample_id_base;

              EcotoxFieldworkService.excelObj =
                          { "dataRows": fieldwork,
                            "headers": header,
                            "selectlist": selectlist, //{"project_group":["MOSJ","thesis"]},
                            "headers_tooltip": header_tooltip,
                            "autocompletes": autocomplete,
                            "dateFields":dateFields,
                            "saveJson":[],
                            "id": id_base,
                            //"deleted_entries":[], //Ids of deleted entries
                            "sanitize": true
                          };


               $scope.excelObj = EcotoxFieldworkService.excelObj;
               console.log("excelobj");
               console.log($scope.excelObj);
               tb.insertTable(EcotoxFieldworkService.excelObj,saveDb);

            });  //Fetch selects


      });

    } //end function


         //Search database, fetch old entries or start a new, empty sheet
         //This code promise is run first, but will only return the first result
         var id_base = ($routeParams.id).substring(0, ($routeParams.id).length-2);
         var ecotoxFieldwork = DBSearchQuery.get({search:'q=&filter-database_sample_id_base='+id_base, link:'ecotox',link2:'fieldwork'}, function(){
                        console.log("found");
                        //Create input object for library
                        let fieldwork = [];
                        for (let i=0;i<ecotoxFieldwork.feed.entries.length;i++){
                          //delete fieldwork.database_sample_id_base;
                          fieldwork.push(ecotoxFieldwork.feed.entries[i]);
                          //In fieldwork object change database_sample_id_base => database_sample_id
                          //Used in npm packet exceldb as database_sample_id
                          fieldwork[i].database_sample_id = ecotoxFieldwork.feed.entries[i].id;
                        }

                        view_fieldwork($routeParams.id, fieldwork);
         }, function() {  //get an error because it is a new entry
                        console.log("not found");
                        view_fieldwork($routeParams.id, []);
         });

};


module.exports = EcotoxFieldworkEditController;
