'use strict';

var EcotoxFieldworkEditController = function($http, $scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, $filter, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpdcSearchService, NpolarMessage) {
  'ngInject';


  var tb = require( '@srldl/edit-tabletest/js/edit-table.js');

  $controller('NpolarEditController', { $scope: $scope });

  $scope.resource = EcotoxTemplate;
  $scope.ecotoxTab = tb.tabRow;
  tb.printMsg();
  $scope.testMsg = tb.testMsg();
};


module.exports = EcotoxFieldworkEditController;
