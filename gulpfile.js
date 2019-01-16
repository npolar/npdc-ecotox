var gulp = require('gulp');
var npdcGulp = require('npdc-gulp');
var config = npdcGulp.baseConfig;
config.COMMON_VERSION = '4.10.16';
npdcGulp.loadAppTasks(gulp, config);
