'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage) {
  'ngInject';

   $controller('NpolarEditController', { $scope: $scope });
   $scope.resource = EcotoxTemplate;


    let query = function() {

        let defaults;

        defaults = {
            limit: "50",
            sort:  "title",
          //  filter:"-id=4568140a7f01462edc029e42ab078155"
            //fields: 'title,created,updated,updated_by,id',
            facets: 'title'
          };

      let invariants = $scope.security.isAuthenticated() ? {} : {} ;
      return Object.assign({}, defaults, invariants);
      };


    var res = $scope.search(query());


  console.log(res);


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



//  try {
//    init();
     // edit (or new) action
    // $scope.edit();
//  } catch (e) {
//    NpolarMessage.error(e);
//  }
};


module.exports = EcotoxFieldworkEditController;
