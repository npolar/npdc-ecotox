'use strict';
var npdcCommon = require('npdc-common');
var AutoConfig = npdcCommon.AutoConfig;

var angular = require('angular');
require('npdc-common/src/wrappers/leaflet');
//require('jquery');
//require('jqGrid');


var npdcEcotoxApp = angular.module('npdcEcotoxApp', ['npdcCommon']);


npdcEcotoxApp.controller('EcotoxTemplateShowController', require('./ecotox-template/show/EcotoxTemplateShowController'));
npdcEcotoxApp.controller('EcotoxTemplateSearchController', require('./ecotox-template/search/EcotoxTemplateSearchController'));
npdcEcotoxApp.controller('EcotoxTemplateEditController', require('./ecotox-template/edit/EcotoxTemplateEditController'));
npdcEcotoxApp.factory('EcotoxTemplate', require('./ecotox-template/EcotoxTemplate.js'));
npdcEcotoxApp.controller('EcotoxFieldworkSearchController', require('./ecotox-fieldwork/search/EcotoxFieldworkSearchController'));
npdcEcotoxApp.controller('EcotoxFieldworkEditController', require('./ecotox-fieldwork/edit/EcotoxFieldworkEditController'));
npdcEcotoxApp.controller('EcotoxFieldworkCSVController', require('./ecotox-fieldwork/EcotoxFieldworkCSVController'));
npdcEcotoxApp.controller('GetdataSearchController', require('./getdata/GetdataSearchController.js'));
npdcEcotoxApp.service('GetdataDBSearch', require('./getdata/GetdataDBSearch.js'));
npdcEcotoxApp.factory('EcotoxFieldworkService', require('./ecotox-fieldwork/edit/EcotoxFieldworkService.js'));
npdcEcotoxApp.factory('EcotoxFieldworkDBSave', require('./ecotox-fieldwork/edit/EcotoxFieldworkDBSave.js'));
npdcEcotoxApp.service('DBSearch', require('./DBSearch.js'));
npdcEcotoxApp.service('DBSearchQuery', require('./DBSearchQuery.js'));
npdcEcotoxApp.service('CSVService', require('./ecotox-fieldwork/edit/CSVService.js'));

// Bootstrap ngResource models using NpolarApiResource
var resources = [
  {'path': '/', 'resource': 'NpolarApi'},
  {'path': '/user', 'resource': 'User'},
  {'path': '/dataset', 'resource': 'Dataset'},
  {'path': '/project', 'resource': 'Project'},
  {'path': '/expedition', 'resource': 'Expedition'},
  {'path': '/publication', 'resource': 'Publication'},
  {'path': '/geology/sample', 'resource': 'GeologySample'},
  {'path': '/ecotox/template', 'resource': 'EcotoxTemplateResource'},
  //{'path': '/ecotox/template', 'resource': 'EcotoxTemplate'},
  {'path': '/ecotox/fieldwork', 'resource': 'EcotoxFieldwork'}


];


resources.forEach(service => {
  // Expressive DI syntax is needed here
  npdcEcotoxApp.factory(service.resource, ['NpolarApiResource', function (NpolarApiResource) {
  return NpolarApiResource.resource(service);
  }]);
});

// Routing
npdcEcotoxApp.config(require('./router'));

npdcEcotoxApp.config(($httpProvider) => {


  $httpProvider.interceptors.push('npolarApiInterceptor');
});

npdcEcotoxApp.run(($http, npolarApiConfig,  npdcAppConfig, NpolarTranslate) => {
  //var environment = "development";

  //var autoconfig = new AutoConfig(environment);
  //autoconfig.environment = "development";
  var autoconfig = new AutoConfig("production");
//  autoconfig.base = '//api-test.data.npolar.no';
  autoconfig.base = '//api.npolar.no';

   Object.assign(npolarApiConfig, autoconfig, { resources, formula : { template : 'default' } });

  npdcAppConfig.help = { uri: 'https://github.com/npolar/npdc-ecotox/wiki' };
  //NpolarTranslate.loadBundles('npdc-ecotox');
  npdcAppConfig.toolbarTitle = NpolarTranslate.translate("Norwegian Polar Institute's ecotox archive");
});
