
var argscheck = require('cordova/argscheck'),
	utils = require('cordova/utils'),
	exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {
};

CameraPreview.bindListener = function(listener) {
	exec(listener, listener, PLUGIN_NAME, "bindListener", []);
};

//@param rect {x: 0, y: 0, width: 100, height:100}
CameraPreview.startCamera = function(rect) {
	exec(null, null, PLUGIN_NAME, "startCamera", [rect.x, rect.y, rect.width, rect.height]);
};
CameraPreview.stopCamera = function() {
	exec(null, null, PLUGIN_NAME, "stopCamera", []);
};
CameraPreview.takePicture = function(onPictureTaken) {
	exec(onPictureTaken, onPictureTaken, PLUGIN_NAME, "takePicture", []);
};

CameraPreview.switchCamera = function() {
	exec(null, null, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function() {
	exec(null, null, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function() {
	exec(null, null, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.disable = function(disable) {
	exec(null, null, PLUGIN_NAME, "disable", [disable]);
};

module.exports = CameraPreview;