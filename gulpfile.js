var gulp = require('gulp');
var npdcGulp = require('npdc-gulp');
var config = npdcGulp.baseConfig;
config.COMMON_VERSION = '4.11.3';
npdcGulp.loadAppTasks(gulp, {
   'deps':{
     'assets': [
         'node_modules/@srldl/exceldb/style.css'
      ]
}});
;
