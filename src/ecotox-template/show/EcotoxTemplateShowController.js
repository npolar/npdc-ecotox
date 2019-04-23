'use strict';

var EcotoxTemplateShowController = function($controller, $routeParams,
  $scope, $q, EcotoxTemplate, npdcAppConfig, Dataset, Publication, Project) {
    'ngInject';


  $controller('NpolarBaseController', {
    $scope: $scope
  });
  $scope.resource = EcotoxTemplate;


  //Show map in Antarctica
  $scope.mapOptions = {};
  $scope.mapOptions.color = "#FF0000";


  let show = function() {

    $scope.show().$promise.then((EcotoxTemplate) => {

      //Overlay the map with lat,lng
      console.log($scope.document);
      $scope.mapOptions.coverage = [[[EcotoxTemplate.latitude,EcotoxTemplate.longitude],[EcotoxTemplate.latitude,EcotoxTemplate.longitude]]];
      $scope.mapOptions.geojson = "geojson";
    });

  };

  show();

};

module.exports = EcotoxTemplateShowController;
