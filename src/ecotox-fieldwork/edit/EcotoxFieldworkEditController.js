'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage) {
  'ngInject';

   $controller('NpolarEditController', { $scope: $scope });
   $scope.resource = EcotoxTemplate;

    let query = function(search_id,db_key) {

        let defaults;

        if (db_key==="template"){
          defaults = {
            "filter-id": search_id
          };
          console.log(defaults);
        } else {
          defaults = {
            "filter-ecotox_template": search_id
          };
          console.log(defaults);
        }

      let invariants = $scope.security.isAuthenticated() ? {} : {} ;
      return Object.assign({}, defaults, invariants);
      };


    var res_template = $scope.search(query("a11a7305-45a8-4ad2-80d9-60f4b8980cc3","template"));
      console.log(res_template);

    $scope.resource = EcotoxFieldwork;
    var res_fieldwork = $scope.search(query("a11a7305-45a8-4ad2-80d9-60f4b8980cc3","fieldwork"));
    console.log(res_fieldwork);



  //Jump to another tab
  $scope.ecotoxTab = function(label) {
    var i, tabcontent, tablinks;
    tabcontent = document.getElementsByClassName("tabcontent");
    for (i = 0; i < tabcontent.length; i++) {
        tabcontent[i].style.display = "none";
    }
    tablinks = document.getElementsByClassName("tablinks");
    for (i = 0; i < tablinks.length; i++) {
        tablinks[i].className = tablinks[i].className.replace(" active", "");
    }
    document.getElementById(label).style.display = "block";
    //evt.currentTarget.className += " active";
  };


};


module.exports = EcotoxFieldworkEditController;
