'use strict';
//service

// @ngInject

var GetdataDBSearch = function($resource,  npolarApiConfig){
     console.log("mil");
    return $resource( 'https:' + npolarApiConfig.base + '/ecotox/fieldwork/?q=:search2&limit=all&locales=utf-8:search' , { search:'@search', search2:'@search2'}, {
    query: {method: 'GET'}
    });
};

module.exports = GetdataDBSearch;
