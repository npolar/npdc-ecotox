'use strict';

var EcotoxTemplateEditController = function($scope, $controller, $routeParams, GeologySample, EcotoxTemplate, formula,
  formulaAutoCompleteService, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang, npolarApiConfig,
  NpolarApiSecurity, npolarCountryService, NpolarMessage) {
  'ngInject';

   function init() {

  // EditController -> NpolarEditController
  $controller('NpolarEditController', {
    $scope: $scope
  });

  // GeologySample -> npolarApiResource -> ngResource
  $scope.resource = EcotoxTemplate;

  let templates = [];

  let i18n = [
  //{
  //    map: require('./en.json'),
  //    code: 'en'
  //  },
    {
      map: require('./no.json'),
      code: 'nb_NO',
    }];

  $scope.formula = formula.getInstance({
    schema: '//api-test.data.npolar.no/schema/ecotox-template',
    form: 'edit/formula.json',
    language: NpolarLang.getLang(),
    templates: npdcAppConfig.formula.templates.concat(templates),
    languages: npdcAppConfig.formula.languages.concat(i18n)
   });
}


  try {
    init();

     // edit (or new) action
     $scope.edit();

  } catch (e) {
    NpolarMessage.error(e);
  }


};

module.exports = EcotoxTemplateEditController;
