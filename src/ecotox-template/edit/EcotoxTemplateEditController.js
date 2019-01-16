'use strict';


// @ngInject

var EcotoxTemplateEditController = function($scope, $controller, $routeParams, $http, $sce, EcotoxTemplate, GeologySample, formula,
  formulaAutoCompleteService, npdcAppConfig, chronopicService, fileFunnelService, NpolarLang,
npolarApiConfig, NpolarApiSecurity, NpolarMessage, npolarCountryService) {



  function init() {

 // EditController -> NpolarEditController
 $controller('NpolarEditController', {
   $scope: $scope
 });

 // GeologySample -> npolarApiResource -> ngResource
 $scope.resource = EcotoxTemplate;

 let templates = [];

 let i18n = [
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

 initFileUpload($scope.formula);

 formulaAutoCompleteService.autocomplete({
   match: "@placename",
   querySource: 'https://api.npolar.no/placename?q-name.@value=&format=json&filter-status=official',
   //api.npolar.no/placename/?q=&filter-status=official&format=json&fields=type.id,name
   label: 'name.@value',   // ["name['@value']"],
   value: 'name.@value'
 }, $scope.formula);

 formulaAutoCompleteService.autocompleteFacets(['lithology', 'expedition','geologist'], $scope.resource, $scope.formula);


 let autocompleteFacets = ["geologist"];
 formulaAutoCompleteService.autocompleteFacets(autocompleteFacets, GeologySample, $scope.formula);


//Set chronopic view format (this does not change the internal value, i.e. ISO string date)
chronopicService.defineOptions({ match(field) {
   return field.path.match(/_date$/);
}, format: '{date}'});

}


function initFileUpload(formula) {

   let server = `${NpolarApiSecurity.canonicalUri($scope.resource.path)}/:id/_file`;

   fileFunnelService.fileUploader({
     match(field) {
       return field.id === "files";
     },
     server,
     multiple: true,
     //progress: false,
      restricted: function () {
       return formula.getModel().restricted;
     },
     fileToValueMapper: GeologySample.fileObject,
     valueToFileMapper: GeologySample.hashiObject,
     fields: ['filename'] // 'type', 'hash'
   }, formula);
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
