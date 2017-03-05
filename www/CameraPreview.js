var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function(){};

CameraPreview.startCamera = function(options, onSuccess, onError){
  options = options || {};
  options.x = options.x || 0;
  options.y = options.y || 0;
  options.width = options.width || window.screen.width;
  options.height = options.height || window.screen.height;
  options.camera = options.camera || 'front';
  if(typeof(options.tapPhoto) === 'undefined'){
    options.tapPhoto = true;
  }
  options.previewDrag = options.previewDrag || false;
  options.toBack = options.toBack || false;
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

CameraPreview.takePicture = function(opts, onError){
  opts = opts || {};
  opts.width = opts.width || 0;
  opts.height = opts.height || 0;

  if(!opts.quality || !(opts.quality <= 100 && opts.quality >= 0)){
    opts.quality = 85;
  }

  exec(null, onError, PLUGIN_NAME, "takePicture", [opts.width, opts.height, opts.quality]);
};

CameraPreview.setOnPictureTakenHandler = function(cb) {
  exec(cb, null, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

CameraPreview.setColorEffect = function(effect, onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "setColorEffect", [effect]);
};

CameraPreview.setZoom = function(zoom, onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "setZoom", [zoom]);
}

CameraPreview.setPreviewSize = function(dimensions, onSuccess, onError){
  dimensions = dimensions || {};
  dimensions.width = dimensions.width || window.screen.width;
  dimensions.height = dimensions.height || window.screen.height;

  return exec(onSuccess, onError, PLUGIN_NAME, "setPreviewSize", [dimensions.width, dimensions.height]);
}

CameraPreview.getSupportedPreviewSize = function(onSuccess, onError){
  return exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPreviewSize", []);
};

CameraPreview.getSupportedPictureSize = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPictureSize", []);
};

CameraPreview.setFlashMode = function(flashMode, onSuccess, onError) {
  exec(onSuccess, onError, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

CameraPreview.FlashMode = {OFF: 0, ON: 1, TORCH: 2, AUTO: 3};

module.exports = CameraPreview;
