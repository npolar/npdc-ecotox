'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage, DBSearch) {
  'ngInject';

  var tb = require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  $scope.resource = EcotoxTemplate;
  console.log($scope.resource);


  console.log(npolarApiConfig.base);
  let res = '4568140a7f01462edc029e42ab078155';
  let link = '';


/*  var full = DBSearch.get({search:res, link:'ecotox',link2:'template'}, function(){
       console.log(full);
       console.log("full");
  }); */



/*  var full = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){
       console.log(full);
  });*/

  //Testdata  template and fieldwork
  let template =  [
      "matrix",
      "project",
      "species",
      "species_identification",
      "label_name",
      "comment",
      "my_own_field",
      "my_own_field2",
      "event_date",
      "id"
  ];

  let fieldwork = [[
    "4568140a7f01462edc029e42ab040f01",
    "feather",
    "Kongsfjorden northern fulmar",
    "fulmarus glacialis",
    "77",
    "6745232",
    "test",
    "test2",
    "2019-02-01",
    "dead"
  ],
  [
    "4568140a7f01462edc029e42ab056e41",
    "feather",
    "Kongsfjorden northern fulmar",
    "fulmarus glacialis",
    "78",
    "6745211",
    "test0",
    "test2",
    "2019-09-01",
    "Juvenile"
  ],
  [
    "4568140a7f01462edc029e42ab056e41",
    "egg",
    "Kongsfjorden northern fulmar",
    "fulmarus glacialis",
    "79",
    "4566432",
    "test1",
    "test2",
    "2019-01-01",
    ""
  ]];

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

//Input object
let obj = { "data_rows":fieldwork,
            "headings":template,
            "selectlist": {"species":species_list, "matrix":matrix_list},
            "autocompletes":["my_own_field","my_own_field2"],
            "datefields":["event_date"]};


//  tb.testComponent();
  tb.insertTable(obj);
};

/*function createButton(context, func) {
   var button = document.createElement("input");
   button.type = "button";
   button.value = "im a button";
   button.onclick = func;
   context.appendChild(button);
}*/



module.exports = EcotoxFieldworkEditController;
