'use strict';

var EcotoxFieldworkEditController = function($scope, $controller, $routeParams, EcotoxTemplate,
  npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpolarMessage) {
  'ngInject';

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


  function init() {
  // EditController -> NpolarEditController
  $controller('NpolarEditController', {
    $scope: $scope
  });

  // EcotoxTemplate -> npolarApiResource -> ngResource
  $scope.resource = EcotoxTemplate;
  console.log($scope);
  console.log("XXXXXXXXXX");
  }



  try {
    init();

     // edit (or new) action
    // $scope.edit();

  } catch (e) {
    NpolarMessage.error(e);
  }


};



module.exports = EcotoxFieldworkEditController;
