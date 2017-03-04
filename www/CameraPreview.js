var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function(){};

CameraPreview.startCamera = function(options, onSuccess, onError){
  options = options || {};
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
    options.camera = 'front';
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

  exec(onSuccess, onError, PLUGIN_NAME, "startCamera", [options.x, options.y, options.width, options.height, options.camera, options.tapPhoto, options.previewDrag, options.toBack, options.alpha]);
};

CameraPreview.stopCamera = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "stopCamera", []);
};

CameraPreview.switchCamera = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.takePicture = function(opts, onSuccess, onError){
  opts = opts || {};
  opts.width = opts.width || 0;
  opts.height = opts.height || 0;

  if(!opts.quality || !(opts.quality <= 100 && opts.quality >= 0)){
    opts.quality = 85;
  }

  exec(onSuccess, onError, PLUGIN_NAME, "takePicture", [opts.width, opts.height, opts.quality]);
};

CameraPreview.setOnPictureTakenHandler = function(onSuccess, onError) {
  exec(onSuccess, onError, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

CameraPreview.setColorEffect = function(effect, onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "setColorEffect", [effect]);
};

CameraPreview.setZoom = function(zoom, onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "setZoom", [zoom]);
}

CameraPreview.setPreviewSize = function(width, height, onSuccess, onError){
  if(!width){
    width = 0;
  }

  if(!height){
    height = 0;
  }

  return exec(onSuccess, onError, PLUGIN_NAME, "setPreviewSize", [width, height]);
}

CameraPreview.getSupportedPreviewSize = function(dimensions){
  return exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPreviewSize", []);
};

CameraPreview.getSupportedPictureSize = function(dimensions){
  exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPictureSize", []);
};

CameraPreview.setOnLogHandler = function(onSuccess, onError) {
  exec(onSuccess, onError, PLUGIN_NAME, "wLog", []);
};

CameraPreview.setFlashMode = function(flashMode, onSuccess, onError) {
  exec(onSuccess, onError, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

CameraPreview.FlashMode = {OFF: 0, ON: 1, TORCH: 2, AUTO: 3};

module.exports = CameraPreview;
