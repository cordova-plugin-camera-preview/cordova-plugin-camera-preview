var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function(){};

CameraPreview.setOnPictureTakenHandler = function(onPictureTaken) {
  exec(onPictureTaken, onPictureTaken, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

CameraPreview.setFlashMode = function(flashMode) {
  exec(null, null, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

CameraPreview.setOnLogHandler = function(onLog) {
  exec(onLog, onLog, PLUGIN_NAME, "wLog", []);
};

CameraPreview.startCamera = function(options){
  if(typeof(options.options) === 'undefined'){
    var options = {};
  }
  if(typeof(options.x) === 'undefined'){
    options.x = 0;
  }
  if(typeof(options.y) === 'undefined'){
    options.y = 0;
  }
  if(typeof(options.width) === 'undefined'){
    options.width = window.screen.width;
  }
  if(typeof(options.height) === 'undefined'){
    options.height = window.screen.height;
  }
  if(typeof(options.camera) === 'undefined'){
    options.x = 'front';
  }
  if(typeof(options.tapPhoto) === 'undefined'){
    options.tapPhoto = true;
  }
  if(typeof(options.previewDrag) === 'undefined'){
    options.previewDrag = false;
  }
  if(typeof(options.toBack) === 'undefined'){
    options.toBack = false;
  }
  if(typeof(options.alpha) === 'undefined'){
    options.alpha = 1;
  }

  exec(null, null, PLUGIN_NAME, "startCamera", [options.x, options.y, options.width, options.height, options.camera, options.tapPhoto, options.previewDrag, options.toBack, options.alpha]);
};

CameraPreview.stopCamera = function(){
  exec(null, null, PLUGIN_NAME, "stopCamera", []);
};

CameraPreview.takePicture = function(size){
  var params = [window.device.width, window.device.height];
  if(typeof(options.options) === 'undefined'){
    var options = {};
  }
  if(typeof(options.maxWidth) === 'undefined'){
    options.maxWidth = window.device.width;
  }
  if(typeof(options.maxHeight) === 'undefined'){
    options.maxHeight = window.device.height;
  }
  exec(null, null, PLUGIN_NAME, "takePicture", [options.maxWidth, options.maxHeight]);
};

CameraPreview.setColorEffect = function(effect){
  exec(null, null, PLUGIN_NAME, "setColorEffect", [effect]);
};

CameraPreview.switchCamera = function(){
  exec(null, null, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function(){
  exec(null, null, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function(){
  exec(null, null, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.disable = function(disable){
  exec(null, null, PLUGIN_NAME, "disable", [disable]);
};

CameraPreview.FlashMode = {OFF: 0, ON: 1, AUTO: 2};

module.exports = CameraPreview;
