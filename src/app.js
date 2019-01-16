'use strict';
var npdcCommon = require('npdc-common');
var AutoConfig = npdcCommon.AutoConfig;

var angular = require('angular');
require('npdc-common/src/wrappers/leaflet');

var npdcEcotoxApp = angular.module('npdcEcotoxApp', ['npdcCommon','leaflet']);

npdcEcotoxApp.controller('EcotoxTemplateShowController', require('./template/show/EcotoxTemplateShowController'));
npdcEcotoxApp.controller('EcotoxTemplateSearchController', require('./template/search/EcotoxTemplateSearchController'));
npdcEcotoxApp.controller('EcotoxTemplateEditController', require('./template/edit/EcotoxTemplateEditController'));
npdcEcotoxApp.directive('ecotoxTemplateCoverage', require('./template/edit/coverage/coverageDirective'));
npdcEcotoxApp.factory('EcotoxTemplate', require('./template/EcotoxTemplate.js'));
npdcEcotoxApp.controller('EcotoxFieldworkShowController', require('./fieldwork/show/EcotoxFieldworkShowController'));
npdcEcotoxApp.controller('EcotoxFieldworkSearchController', require('./fieldwork/search/EcotoxFieldworkSearchController'));
npdcEcotoxApp.controller('EcotoxFieldworkEditController', require('./fieldwork/edit/EcotoxFieldworkEditController'));
npdcEcotoxApp.directive('ecotoxFieldworkCoverage', require('./fieldwork/edit/coverage/coverageDirective'));
npdcEcotoxApp.factory('EcotoxFieldwork', require('./fieldwork/EcotoxFieldwork.js'));

// Bootstrap ngResource models using NpolarApiResource
var resources = [
  {'path': '/', 'resource': 'NpolarApi'},
  {'path': '/user', 'resource': 'User'},
  {'path': '/dataset', 'resource': 'Dataset'},
  {'path': '/project', 'resource': 'Project'},
  {'path': '/expedition', 'resource': 'Expedition'},
  {'path': '/publication', 'resource': 'Publication'},
  {'path': '/ecotox/template', 'resource': 'EcotoxTemplateResource'}

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

//  NpolarTranslate.loadBundles('npdc-geology');
//  npdcAppConfig.toolbarTitle = NpolarTranslate.translate('Norwegian polar geological sample archive');
//});
