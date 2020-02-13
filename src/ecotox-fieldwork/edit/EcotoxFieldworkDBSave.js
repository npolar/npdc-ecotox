'use strict';

// @ngInject
//Save to database

var EcotoxFieldworkDBSave = function($resource, npolarApiConfig){


return $resource(npolarApiConfig.base + '/ecotox/fieldwork/:id', null,
{
    'update': { method:'PUT' }
});
};

module.exports = EcotoxFieldworkDBSave;
