'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage) {
  'ngInject';

  var tb = require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  $scope.resource = EcotoxTemplate;

//  createButton(document.getElementById("edit_table"), function() {alert(this.parentNode.childNodes[1])});

//  let obj = {firstName:"John", lastName:"Doe", age:50, eyeColor:"blue"};
//  $scope.testMsg = tb.testMsg(obj);

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

let fieldwork = [{
  "id":"4568140a7f01462edc029e42ab040f01",
  "matrix":"feather",
  "project": "Kongsfjorden northern fulmar",
  "species": "fulmarus glacialis",
  "species_identification": "77",
  "label_name": "6745232",
  "my_own_field": "test",
  "my_own_field2": "test2",
  "event_date":"2019-02-01",
  "comment": "dead"
},
{
  "id":"4568140a7f01462edc029e42ab056e41",
  "matrix":"feather",
  "project": "Kongsfjorden northern fulmar",
  "species": "fulmarus glacialis",
  "species_identification": "78",
  "label_name": "6745211",
  "my_own_field": "test0",
  "my_own_field2": "test2",
  "event_date":"2019-09-01",
  "comment": "Juvenile"
},
{
  "id":"4568140a7f01462edc029e42ab056e41",
  "matrix":"egg",
  "project": "Kongsfjorden northern fulmar",
  "species": "fulmarus glacialis",
  "species_identification": "79",
  "label_name": "4566432",
  "my_own_field": "test1",
  "my_own_field2": "test2",
  "event_date":"2019-01-01",
  "comment": ""
}];


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
let obj = { "fieldwork":fieldwork,
            "template":template,
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
