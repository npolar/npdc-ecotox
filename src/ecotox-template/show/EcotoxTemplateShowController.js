'use strict';

var EcotoxTemplateShowController = function($controller, $routeParams,
  $scope, $q, EcotoxTemplate, npdcAppConfig, Dataset, Publication, Project, DBSearch, DBSearchQuery) {
    'ngInject';


  $controller('NpolarBaseController', {
    $scope: $scope
  });
  $scope.resource = EcotoxTemplate;


  //Show map in Antarctica
  $scope.mapOptions = {};
  $scope.mapOptions.color = "#FF0000";

  //Get enum fields to view select options
  $scope.jsonSchema = DBSearch.get({search:'ecotox-fieldwork.json', link:'schema',link2:''}, function(){
         console.log($scope.jsonSchema);
  });

  //Get all additional fields to reuse parameters
  $scope.additional = DBSearchQuery.get({search:'q=&fields=additional', link:'ecotox',link2:'template'}, function(){
         console.log($scope.additional.feed.entries);
  });


//  let show =  $scope.show().$promise.then((EcotoxTemplate) => {
  $scope.show().$promise.then((EcotoxTemplate) => {
      //Overlay the map with lat,lng
      console.log($scope.document);
      $scope.mapOptions.coverage = [[[EcotoxTemplate.latitude,EcotoxTemplate.longitude],[EcotoxTemplate.latitude,EcotoxTemplate.longitude]]];
      $scope.mapOptions.geojson = "geojson";
    });

};

module.exports = EcotoxTemplateShowController;
