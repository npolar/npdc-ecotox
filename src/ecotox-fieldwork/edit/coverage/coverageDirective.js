"use strict";

let coverageDirective = function () {
  "ngInject";

  return {
    template: require('./coverage.html'),
    controller($scope, $timeout) {
      "ngInject";

      let rectLayer;
      let changesDueToMapSelect = 0;

      let initField = function (field) {
        field.step = 0.01;
        $scope.$watch(field.id+'.value', n => {
          if (!changesDueToMapSelect && rectLayer) {
            let newBounds = [
              [$scope.south.value, $scope.west.value],
              [$scope.north.value, $scope.east.value]
            ];
            rectLayer.setBounds(newBounds);
          }
          if (changesDueToMapSelect > 0) {
            changesDueToMapSelect--;
          }
        });
        $scope[field.id] = field;
      };

      $scope.field.fields.forEach(initField);

      let coverage;
      if ($scope.field.value && $scope.field.value.north) {
        coverage = [[[$scope.south.value, $scope.west.value],
          [$scope.north.value, $scope.east.value]]];
      }

      //mapOptions object is initiating the wrapper
      $scope.mapOptions = {
        draw: {
          rectangle: true
        },
        edit: {
          edit: true,
          remove: true
        },
        coverage: coverage,
        initcoord: [-72.011389, 2.535]
      };

      $scope.$on('mapSelect', (e, layer) => {
        changesDueToMapSelect = 4;
        $scope.north.value = Math.round(layer._latlngs[2].lat * 100) / 100;
        $scope.east.value = Math.round(layer._latlngs[2].lng * 100) / 100;
        $scope.south.value = Math.round(layer._latlngs[0].lat * 100) / 100;
        $scope.west.value = Math.round(layer._latlngs[0].lng * 100) / 100;
        rectLayer = layer;
        $timeout();
      });
    }
  };
};

module.exports = coverageDirective;