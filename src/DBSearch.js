'use strict';
//service

// @ngInject

var DBSearch = function($resource,  npolarApiConfig){

    return $resource( 'https:' + npolarApiConfig.base + '/:link/:link2/:search' ,
    { search:'@search',link:'@link',link2:'@link2'},
    {query: {method: 'GET'}}
  );
};

module.exports = DBSearch;
