'use strict';

var router = function($routeProvider, $locationProvider) {
  'ngInject';

  $locationProvider.html5Mode(true).hashPrefix('!');


  $routeProvider.when('/', {
    redirectTo: '/dbtemplate'
  }).when('/template/:id', {
      templateUrl: 'template/show/show-ecotox-template.html',
      controller: 'EcotoxTemplateShowController'
  }).when('/template/:id/edit', {
      template: '<npdc:formula></npdc:formula>',
      controller: 'EcotoxTemplateEditController'
  }).when('/fieldwork/:id', {
        templateUrl: 'fieldwork/show/show-ecotox-fieldwork.html',
        controller: 'EcotoxFieldworkShowController'
  }).when('/fieldwork/:id/edit', {
        template: '<npdc:formula></npdc:formula>',
        controller: 'EcotoxFieldworkEditController'
  }).when('/dbtemplate', {
    templateUrl: 'template/search/search.html',
    controller: 'EcotoxTemplateSearchController',
    reloadOnSearch: false
  }).when('/dbfieldwork', {
    templateUrl: 'fieldwork/search/search.html',
    controller: 'EcotoxFieldworkSearchController'
  });
};

module.exports = router;
