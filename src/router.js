'use strict';

var router = function($routeProvider, $locationProvider) {
  'ngInject';

  $locationProvider.html5Mode(true).hashPrefix('!');


  $routeProvider.when('/', {
    redirectTo: '/fieldwork'
  }).when('/template/:id', {
      templateUrl: 'ecotox-template/show/show-ecotox-template.html',
      controller: 'EcotoxTemplateShowController'
  }).when('/template/:id/edit', {
      template: '<npdc:formula></npdc:formula>',
      controller: 'EcotoxTemplateEditController'
  }).when('/fieldwork/:id', {
        templateUrl: 'ecotox-fieldwork/show/show-ecotox-fieldwork.html',
        controller: 'EcotoxFieldworkShowController'
  }).when('/fieldwork/:id/edit', {
        template: '<npdc:formula></npdc:formula>',
        controller: 'EcotoxFieldworkEditController'
  }).when('/template', {
    templateUrl: 'ecotox-template/search/search.html',
    controller: 'EcotoxTemplateSearchController'
  }).when('/fieldwork', {
    templateUrl: 'ecotox-fieldwork/search/search.html',
    controller: 'EcotoxFieldworkSearchController',
    reloadOnSearch: false
  });
};

module.exports = router;
