'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage) {
  'ngInject';

  var tb = require( '@srldl/edit-tabletest/js/edit-table.js');


  $controller('NpolarEditController', { $scope: $scope });

  $scope.resource = EcotoxTemplate;

  tb.printMsg();
  let obj = {firstName:"John", lastName:"Doe", age:50, eyeColor:"blue"};
  $scope.testMsg = tb.testMsg(obj);

  tb.testComponent();
};


module.exports = EcotoxFieldworkEditController;
