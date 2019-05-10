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


  let species_list = ["ursus maritimus", "vulpes lagopus",
        "boreogadus saida","salvelinus alpinus","mallotus villosus",
        "strongylocentrotus droebachiensis","hyas araneus","buccinum undatum",
        "buccinum glaciale", "mya truncata",
        "gymnacanthus tricuspis","myoxocephalus scorpius",
        "phoca vitulina","pagophilus groenlandicus",
        "cystophora cristata","pusa hispida",
        "odobenus rosmarus","leptonychotes weddellii",
        "orcinus orca","delphinapterus leucas", "monodon monoceros",
        "bubo scandiacus","larus hyperboreus","uria lomvia","uria aalge","rissa tridactyla",
        "somateria mollissima","fratercula arctica","phalacrocorax aristotelis",
        "larus argentatus", "morus bassanus", "fulmarus glacialis", "alle alle"];

  let matrix_list = ["egg","milk","whole blood","blood cell",
        "plasma","serum","abdominal fat","subcutaneous fat",
        "blubber","hair","feather","muscle","liver","brain",
        "adrenal","whole animal","gonad",
        "whole animal except lower part of foot",
        "whole animal except closing muscle and siphon",
        "digestive gland"];


        $scope.show().$promise.then((ecotoxFieldwork) => {

           console.log(ecotoxFieldwork);
           let fieldwork = ecotoxFieldwork.entry;


            //Get the header texts
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


                  //Input object
                  let obj = { "dataRows":fieldwork,
                              "headers":header,
                              "selectlist": {"species":species_list, "matrix":matrix_list},
                              "autocompletes":["my_own_field","my_own_field2"],
                              "datefields":["event_date"],
                              "returnJson":[]
                            };

                  //console.log(obj);


                  //  tb.testComponent();
                    tb.insertTable(obj);
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
