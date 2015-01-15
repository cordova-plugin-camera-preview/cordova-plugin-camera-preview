cordova.define("com.mbppower.camerapreview.CameraPreview", function(require, exports, module) { 
var argscheck = require('cordova/argscheck'),
	utils = require('cordova/utils'),
	exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {
};

CameraPreview.setOnPictureTakenHandler = function(onPictureTaken) {
	exec(onPictureTaken, onPictureTaken, PLUGIN_NAME, "setOnPictureTakenHandler", []);
};

//@param rect {x: 0, y: 0, width: 100, height:100}
//@param defaultCamera "front" | "back"
CameraPreview.startCamera = function(rect, defaultCamera, tapEnabled, dragEnabled) {
	exec(null, null, PLUGIN_NAME, "startCamera", [rect.x, rect.y, rect.width, rect.height, defaultCamera, !!tapEnabled, !!dragEnabled]);
};
CameraPreview.stopCamera = function() {
	exec(null, null, PLUGIN_NAME, "stopCamera", []);
};
CameraPreview.takePicture = function() {
	exec(null, null, PLUGIN_NAME, "takePicture", []);
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
});
