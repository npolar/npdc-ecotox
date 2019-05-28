'use strict';

var EcotoxFieldworkService = function() {
  'ngInject';

  let excelObj =  { dataRows:[],
             headers:[],
             selectlist: {},
             autocompletes: [],
             dateFields: [],
             saveJson:[],
             id:""
  };
      return {
          excelObj : excelObj
      };

};


module.exports = EcotoxFieldworkService;
