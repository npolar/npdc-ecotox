'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch, DBSearchQuery, EcotoxFieldworkService, $resource,
  EcotoxFieldworkDBSave, CSVService) {
  'ngInject';


  $scope.id = $routeParams.id;

  //let tb = require( '@srldl/edit-tabletest/js/edit-table.js');
  let tb = require('@srldl/exceldb/index.js');

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters, security and auth
  $scope.resource = EcotoxFieldwork;
  $scope.security = NpolarApiSecurity;
  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);

  //Get current time as ISO8601 string
  function getCurTime(){
     let d = new Date();
     return d.toISOString();
  }

  //Can the string be converted into integer
  function isInteger(value) {
     return /^\d+$/.test(parseInt(value));
  }

  //Can the string be converted into a float
  function isFloat(value) {
     return /[+-]?([0-9]*[.])?[0-9]+/.test(Number(value));
  }


  //Strip away empty rows listed at the end
  //Empty rows in the middle of the array are preserved.
  function checkIfRowEmpty(jsonObj){
      for (let i=jsonObj.dataRows.length-1;i>-1;i--){
        for (let j=0;j<jsonObj.dataRows[i].length-1;j++){
           if  ((jsonObj.dataRows[i][j] === '') || (jsonObj.dataRows[i][j] === 'unknown')){
             //Want the not like version
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

        //Clean the array for empty rows
        let jsonObj_cleaned = checkIfRowEmpty(jsonObj);

        CSVService.entryObject = jsonObj_cleaned.dataRows;

        //Quality control of fields - numbers, integers, arrays
        let err_str = '';  //Inform user of errors
        //Find number and integer fields
        for (let u=0;u<jsonObj_cleaned.typeFields.length;u++){
           let tp = jsonObj_cleaned.typeFields[u];
           //Check if type of field is an integer or number.
           //If yes, convert them to number/integer, if not
           //a proper integer/number write back alert warning
           //instead of saving.
           if ((tp === 'integer') || ((Array.isArray(tp))&&(tp[0] === 'integer'))){
              for (let v=0;v<jsonObj_cleaned.dataRows.length;v++){
                if ((isInteger(jsonObj_cleaned.dataRows[v][u]))&&(jsonObj_cleaned.dataRows[v][u].length>0)){
                     jsonObj_cleaned.dataRows[v][u] = parseInt(jsonObj_cleaned.dataRows[v][u]);
                } else if (isInteger(jsonObj_cleaned.dataRows[v][u] === false)) {
                     err_str = err_str + jsonObj_cleaned.headers[u] + " row " + v.toString() + " is not integer.\n";
                } //if
              }
           //If type of field is a number
           } else if ((tp === 'number') || ((Array.isArray(tp))&&(tp[0] === 'number'))){
             for (let v=0;v<jsonObj_cleaned.dataRows.length;v++){
               if ((isFloat(jsonObj_cleaned.dataRows[v][u]))&&(jsonObj_cleaned.dataRows[v][u].length>0)){
                    jsonObj_cleaned.dataRows[v][u] = Number(jsonObj_cleaned.dataRows[v][u]);
               } else if (isFloat(jsonObj_cleaned.dataRows[v][u]) === false ){
                    err_str = err_str + jsonObj_cleaned.headers[u] + " row " + v.toString() + " is not number(use dot-notation).\n";
               } //if
             }
           }

        }

        if (err_str.length > 0) {
           alert(err_str);
        } else {


          for (let i=0;i<jsonObj_cleaned.dataRows.length;i++){
          //Extending object with base properties
            let obj  = {
              "schema": "http://api.npolar.no/schema/ecotox-fieldwork",
              "lang": "en",
              "collection": "ecotox-fieldwork",
              "created": jsonObj.transferField[0],
              "created_by": jsonObj.transferField[1],
              "updated": getCurTime(),
              "updated_by": NpolarApiSecurity.getUser().email,
              "database_sample_id_base": jsonObj.transferField[2],
              "_rev": jsonObj_cleaned.transferRev[i]
          };
          for (let j=0;j<jsonObj_cleaned.headers.length;j++){

             //If field is a date, convert it into a ISO8601 field
             if (jsonObj_cleaned.dateFields.includes(jsonObj_cleaned.headers[j])){
                obj[jsonObj_cleaned.headers[j].toString()] = jsonObj_cleaned.dataRows[i][j]+"T12:00:00.000Z";
             //if field is empty, it shoul be omitted overall
             //to shorten the json, but also to avoid string to number/int conversion
             //since 0 can be not measured or measured to zero.
             } else if (jsonObj_cleaned.dataRows[i][j] === ''){
                //
             } else {
                obj[jsonObj_cleaned.headers[j].toString()] = jsonObj_cleaned.dataRows[i][j];
             }
             obj.id = obj.database_sample_id;
             obj._id = obj.database_sample_id;
             delete obj.database_sample_id;
          }
          console.log(obj);


          //Saving
           EcotoxFieldworkDBSave.update({ id: obj.id }, obj);

        } //if alert

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
          let typeFields = [];

          $scope.jsonSchema = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){

              //Set header_tooltip
              for (let s=0;s<header.length;s++){
                    if  ($scope.jsonSchema.properties.hasOwnProperty(header[s])) {
                      header_tooltip.push($scope.jsonSchema.properties[header[s]].description === undefined ? "" :  $scope.jsonSchema.properties[header[s]].description);
                      //Push type on to typefields
                      typeFields.push($scope.jsonSchema.properties[header[s]].type);
                    }
              }

              //header_tooltip might not be filled if there are additional own defined fields
              //additional.parameter_description
              for (let k=header_tooltip.length;k<header.length;k++) {
                    for (let g=0;g<full.additional.length;g++) {
                      if (header[k] === full.additional[g].parameter_name){
                            header_tooltip.push(full.additional[g].parameter_description === undefined ? "" : full.additional[g].parameter_description);
                            //Push additional type on to typefields
                            typeFields.push('string');
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

              //Transfer last revision separately
              let rev = [];
              for (let w=0;w<fieldwork.length;w++){
                  rev.push(fieldwork[w]._rev);
              }

              //Create input object for library
              //In fieldwork object change database_sample_id_base => database_sample_id
              //Used in npm packet exceldb as database_sample_id

            // Initiate the created, created_by and database_sample_id_base field
              let base_arr = [];
              if (typeof fieldwork[0] !== "undefined") {
                base_arr = [fieldwork[0].created,fieldwork[0].created_by,id_base];
              } else {
                getCurTime();
                base_arr = [getCurTime(),NpolarApiSecurity.getUser().email,id_base];
              }

              EcotoxFieldworkService.excelObj =
                          { "dataRows": fieldwork,
                            "headers": header,
                            "typeFields": typeFields,
                            "transferField":base_arr,
                            "transferRev":rev,
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
               CSVService.entryObject = EcotoxFieldworkService.excelObj;

               tb.insertTable(EcotoxFieldworkService.excelObj,saveDb);

            });  //Fetch selects


      });

    } //end function


         //Search database, fetch old entries or start a new, empty sheet
         //This code promise is run first, but will only return the first result
         var id_base = ($routeParams.id).substring(0, ($routeParams.id).length-2);
         var ecotoxFieldwork = DBSearchQuery.get({search:'q=&filter-database_sample_id_base='+id_base, link:'ecotox',link2:'fieldwork'}, function(){
                        //Create input object for library
                        let fieldwork = [];

                        for (let i=0;i<ecotoxFieldwork.feed.entries.length;i++){
                          //delete fieldwork.database_sample_id_base;
                          fieldwork.push(ecotoxFieldwork.feed.entries[i]);
                          //In fieldwork object change database_sample_id_base => database_sample_id
                          //Used in npm packet exceldb as database_sample_id
                          fieldwork[i].database_sample_id = ecotoxFieldwork.feed.entries[i].id;
                        }

                        //Request may return ok, but without entries
                        if (ecotoxFieldwork.feed.entries.length > 0){
                              view_fieldwork($routeParams.id, fieldwork);
                        } else {
                              view_fieldwork($routeParams.id, []);
                        }
         }, function() {  //get an error, set up as new entry
                        view_fieldwork($routeParams.id, []);
         });

};


module.exports = EcotoxFieldworkEditController;
