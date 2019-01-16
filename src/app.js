'use strict';
var npdcCommon = require('npdc-common');
var AutoConfig = npdcCommon.AutoConfig;

var angular = require('angular');
require('npdc-common/src/wrappers/leaflet');

var npdcEcotoxApp = angular.module('npdcEcotoxApp', ['npdcCommon','leaflet']);

npdcEcotoxApp.controller('EcotoxTemplateShowController', require('./ecotox-template/show/EcotoxTemplateShowController'));
npdcEcotoxApp.controller('EcotoxTemplateSearchController', require('./ecotox-template/search/EcotoxTemplateSearchController'));
npdcEcotoxApp.controller('EcotoxTemplateEditController', require('./ecotox-template/edit/EcotoxTemplateEditController'));
npdcEcotoxApp.directive('ecotoxTemplateCoverage', require('./ecotox-template/edit/coverage/coverageDirective'));
npdcEcotoxApp.factory('EcotoxTemplate', require('./ecotox-template/EcotoxTemplate.js'));
npdcEcotoxApp.controller('EcotoxFieldworkShowController', require('./ecotox-fieldwork/show/EcotoxFieldworkShowController'));
npdcEcotoxApp.controller('EcotoxFieldworkSearchController', require('./ecotox-fieldwork/search/EcotoxFieldworkSearchController'));
npdcEcotoxApp.controller('EcotoxFieldworkEditController', require('./ecotox-fieldwork/edit/EcotoxFieldworkEditController'));
npdcEcotoxApp.directive('ecotoxFieldworkCoverage', require('./ecotox-fieldwork/edit/coverage/coverageDirective'));
npdcEcotoxApp.factory('EcotoxFieldwork', require('./ecotox-fieldwork/EcotoxFieldwork.js'));

// Bootstrap ngResource models using NpolarApiResource
var resources = [
  {'path': '/', 'resource': 'NpolarApi'},
  {'path': '/user', 'resource': 'User'},
  {'path': '/dataset', 'resource': 'Dataset'},
  {'path': '/project', 'resource': 'Project'},
  {'path': '/expedition', 'resource': 'Expedition'},
  {'path': '/publication', 'resource': 'Publication'},
  {'path': '/ecotox/template', 'resource': 'EcotoxTemplate'},
    {'path': '/geology/sample', 'resource': 'GeologySample'}

];


resources.forEach(service => {
  // Expressive DI syntax is needed here
  npdcEcotoxApp.factory(service.resource, ['NpolarApiResource', function (NpolarApiResource) {
  return NpolarApiResource.resource(service);
  }]);
});

// Routing
npdcEcotoxApp.config(require('./router'));

npdcEcotoxApp.config(($httpProvider, npolarApiConfig) => {
  var autoconfig = new AutoConfig("development");
  autoconfig.base = '//api-test.data.npolar.no';

  angular.extend(npolarApiConfig, autoconfig, { resources });
  console.debug("npolarApiConfig", npolarApiConfig);

  $httpProvider.interceptors.push('npolarApiInterceptor');
});

npdcEcotoxApp.run(( npdcAppConfig, NpolarTranslate) => {
  npdcAppConfig.help = { uri: 'https://github.com/npolar/npdc-ecotox/wiki' };
  NpolarTranslate.loadBundles('npdc-ecotox');
});
