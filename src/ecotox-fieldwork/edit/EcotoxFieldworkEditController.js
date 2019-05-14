'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch) {
  'ngInject';

  var tb = require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  $scope.resource = EcotoxFieldwork;
  //console.log($scope.resource);

  //Convert object to array
  function obj_to_arr(obj){
      let arr = [];
      let result = Object.keys(obj).map(function(key) {
         if (obj[key] === true){
             arr.push(key);
         }
      });
  return arr;
  }


        $scope.show().$promise.then((ecotoxFieldwork) => {

           //Data rows
           let fieldwork = ecotoxFieldwork.entry;


            //Extract the header texts
            var full = DBSearch.get({search:$scope.document.id, link:'ecotox',link2:'template'}, function(){
               //Traverse object full to get all the parameters_ subobjects
               let header = [];
               let result = Object.keys(full).map(function(key) {
                  //Check for empty object
                  if ((full[key].constructor === Object)&&(key.startsWith('parameters_'))){
                     //Header for database view
                     header.push.apply(header, (obj_to_arr(full[key])));
                  }
                  });
                  header.push('id');

                  //Internal autocomplete of additional fields
                  let autocompletesInternal = [];
                  for (var val of full.additional) {
                       //Replace space with underscore
                       let temp = (val.parameter_name);
                       //Strip parameter_name for all chars except English letters, numbers, space and underscore
                       autocompletesInternal.push(temp.replace(/[^a-zA-Z0-9_]+/,'_'));
                  }


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
                                       } else if ((header).includes(key)&&($scope.jsonSchema.properties.entry.items[key].format == "date-time")) {
                                            dateFields.push(key);
                                       }
                              }
                        }




                 //Input object
                 let obj = { "dataRows":fieldwork,
                            "headers":header,
                            "selectlist": selectlist, //{"project_group":["MOSJ","thesis"]},
                            "autocompletes": autocompletesInternal,
                            "dateFields":dateFields,
                            "saveJson":[]
                 };

                  //console.log(obj);


                  //  tb.testComponent();
                    tb.insertTable(obj);
                  //  $scope.$watch('obj.saveJson', function(save_obj) {
                       console.log(obj);
                  //     console.log("save");
                  //  });

                  });  //Fetch selects

            });
});



/*  var full = DBSearch.get({search:res, link:'ecotox',link2:'template'}, function(){
       console.log(full);
       console.log("full");
  }); */

/*  var full = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){
       console.log(full);
  });*/


};

/*function createButton(context, func) {
   var button = document.createElement("input");
   button.type = "button";
   button.value = "im a button";
   button.onclick = func;
   context.appendChild(button);
}*/



module.exports = EcotoxFieldworkEditController;
