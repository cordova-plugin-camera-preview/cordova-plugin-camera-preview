var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function(){};

function isFunction(obj){
  return !!(obj && obj.constructor && obj.call && obj.apply);
};


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

CameraPreview.takePicture = function(opts, onSuccess, onError){
  if(!opts){
    opts = {};
  }else if(isFunction(opts)){
    onSuccess = opts;
    opts = {};
  }

  if(!isFunction(onSuccess)){
    return false;
  }

  opts.width = opts.width || 0;
  opts.height = opts.height || 0;

  if(!opts.quality || opts.quality > 100 || opts.quality < 0){
    opts.quality = 85;
  }

  exec(onSuccess, onError, PLUGIN_NAME, "takePicture", [opts.width, opts.height, opts.quality]);
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

CameraPreview.getSupportedPictureSizes = function(onSuccess, onError){
  exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPictureSizes", []);
};

CameraPreview.setFlashMode = function(flashMode, onSuccess, onError) {
  flashMode = flashMode.toLowerCase();
  if(flashMode === 'off'){
    flashMode = 0;
  }else if(flashMode === 'on'){
    flashMode = 1;
  }else if(flashMode === 'auto'){
    flashMode = 2;
  }else if(flashMode === 'torch' && navigator.userAgent.match(/Android/i)  == "Android"){
    flashMode = 3;
  }else{
    return false;
  }

  exec(onSuccess, onError, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

module.exports = CameraPreview;
