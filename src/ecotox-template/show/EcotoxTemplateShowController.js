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
      $scope.mapOptions.coverage = [[[EcotoxTemplate.latitude,EcotoxTemplate.longitude],[EcotoxTemplate.latitude,EcotoxTemplate.longitude]]];
      $scope.mapOptions.geojson = "geojson";

      $scope.document.lithology =  convert($scope.document.lithology);

    });

  };

  show();

};

/* convert from camelCase to lower case text*/
function convert(str) {
       var  positions = '';

       for(var i=0; i<(str).length; i++){
           if(str[i].match(/[A-Z]/) !== null){
             positions += " ";
             positions += str[i].toLowerCase();
        } else {
            positions += str[i];
        }
      }
        return positions;
}

module.exports = EcotoxTemplateShowController;
