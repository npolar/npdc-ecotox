'use strict';

var EcotoxFieldworkCSVController = function($scope, $location, $controller, $routeParams, EcotoxTemplate,
  EcotoxFieldwork, NpolarApiSecurity, CSVService) {
  'ngInject';

  $controller('NpolarEditController', { $scope: $scope });

  //Input parameters, security and auth
//  $scope.security = NpolarApiSecurity;
//  $scope.authorized = NpolarApiSecurity.isAuthorized('create', 'https:' + $scope.resource.path);
  $scope.entries = CSVService.entryObject;
  console.log("csv controller");
  console.log($scope.entries);


//  console.log($scope.entries);

};


module.exports = EcotoxFieldworkCSVController;
