'use strict';

var GetdataSearchController = function ($http, $scope, $location, $controller, $filter, GetdataDBSearch,NpolarApiSecurity, EcotoxFieldwork, npdcAppConfig,  NpdcSearchService, NpolarTranslate) {
  'ngInject';


    var res = '';
    var sok = 'id=22b23dd5-b60f-43b9-9645-474e13c4e503';
  //  var full = 
    GetdataDBSearch.get({search:res, search2:sok}, function(){
        //var len = full;
    });


};

module.exports = GetdataSearchController;
