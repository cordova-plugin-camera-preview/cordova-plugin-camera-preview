cordova.define("com.mbppower.camerapreview.CameraPreview", function(require, exports, module) { 
var argscheck = require('cordova/argscheck'),
	utils = require('cordova/utils'),
	exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {
};

CameraPreview.bindListener = function(listener) {
	exec(listener, listener, PLUGIN_NAME, "bindListener", []);
};
	
CameraPreview.startCamera = function(pos, bounds) {
	exec(null, null, PLUGIN_NAME, "startCamera", [pos, bounds]);
};

CameraPreview.takePicture = function() {
	exec(null, null, PLUGIN_NAME, "takePicture", []);
};

CameraPreview.hide = function(hide) {
	exec(null, null, PLUGIN_NAME, "hide", [hide]);
};

CameraPreview.close = function() {
	exec(null, null, PLUGIN_NAME, "close", []);
};

CameraPreview.show = function() {
	exec(null, null, PLUGIN_NAME, "show", []);
};

CameraPreview.disable = function(disable) {
	exec(null, null, PLUGIN_NAME, "disable", [disable]);
};

CameraPreview.isVisible = false;
module.exports = CameraPreview;




});
