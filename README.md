Cordova Plugin Camera Preview
====================

Cordova plugin that allows camera interaction from HTML ee for showing camera preview below or above the HTML.<br/>

**March 4, 2017** - We are currently drastically improving the plugin for a v1.0.0 release, in the meantime the API may change slightly. Please use master until a new version is released.

**PR's are greatly appreciated. If your interested in maintainer status please create a couple PR's and then contact westonganger@gmail.com**

# Features

<ul>
  <li>Start a camera preview from HTML code.</li>
  <li>Drag the preview box.</li>
  <li>Set camera color effect.</li>
  <li>Send the preview box to back of the HTML content.</li>
  <li>Set a custom position for the camera preview box.</li>
  <li>Set a custom size for the preview box.</li>
  <li>Set a custom alpha for the preview box.</li>
  <li>Set zoom, color effects, exposure mode, exposure mode compensation, </li>
  <li>Maintain HTML interactivity.</li>
</ul>

### iOS only features

These are some features that are currently iOS only, however we would love to see PR's for this functionality in Android.

<ul>
  <li>Tap to focus</li>
</ul>

# Installation

Use any one of the installation methods listed below depending on which framework you use.

```
cordova plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

ionic plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

meteor add cordova:cordova-plugin-camera-preview@https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git#[latest_commit_id]

<plugin spec="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git" source="git" />
```

<!--
```
cordova plugin add cordova-plugin-camera-preview

ionic plugin add cordova-plugin-camera-preview

meteor add cordova:cordova-plugin-camera-preview@X.X.X

# Phonegap
<gap:plugin name="cordova-plugin-camera-preview" />
```
-->

# Methods

### startCamera(options, [successCallback, errorCallback])

Starts the camera preview instance.
<br>

<strong>Options:</strong>
All options stated are optional and will default to values here

* `x` - Defaults to 0
* `y` - Defaults to 0
* `width` - Defaults to window.screen.width
* `height` - Defaults to window.screen.height
* `camera` - See <code>[CAMERA_DIRECTION](#camera_Settings.CameraDirection)</code> - Defaults to front camera/code>
* `toBack` - Defaults to false - Set to true if you want your html in front of your preview
* `tapPhoto` - Defaults to true - Does not work if toBack is set to false in which case you use the takePicture method
* `previewDrag` - Defaults to false - Does not work if toBack is set to false

```javascript
let options = {
  x: 0,
  y: 0,
  width: window.screen.width,
  height: window.screen.height,
  camera: CameraPreview.CAMERA_DIRECTION.BACK,
  toBack: false,
  tapPhoto: true,
  previewDrag: false
};

CameraPreview.startCamera(options);
```

When setting the toBack to true, remember to add the style below on your app's HTML or body element:

```css
html, body, .ion-app, .ion-content {
  background-color: transparent;
}
```

### stopCamera([successCallback, errorCallback])

<info>Stops the camera preview instance.</info><br/>

```javascript
CameraPreview.stopCamera();
```

### switchCamera([successCallback, errorCallback])

<info>Switch between the rear camera and front camera, if available.</info><br/>

```javascript
CameraPreview.switchCamera();
```

### show([successCallback, errorCallback])

<info>Show the camera preview box.</info><br/>

```javascript
CameraPreview.show();
```

### hide([successCallback, errorCallback])

<info>Hide the camera preview box.</info><br/>

```javascript
CameraPreview.hide();
```

### takePicture(options, successCallback, [errorCallback])

<info>Take the picture. If width and height are not specified or are 0 it will use the defaults. If width and height are specified, it will choose a supported photo size that is closest to width and height specified and has closest aspect ratio to the preview. The argument `quality` defaults to `85` and specifies the quality/compression value: `0=max compression`, `100=max quality`.</info><br/>

```javascript
CameraPreview.takePicture({width:640, height:640, quality: 85}, function(base64PictureData){
  /*
    base64PictureData is base64 encoded jpeg image. Use this data to store to a file or upload.
    Its up to the you to figure out the best way to save it to disk or whatever for your application.
  */

  // One simple example is if you are going to use it inside an HTML img src attribute then you would do the following:
  imageSrcData = 'data:image/jpeg;base64,' +base64PictureData;
  $('img#my-img').attr('src', imageSrcData);
});

// OR if you want to use the default options.

CameraPreview.takePicture(function(base64PictureData){
  /* code here */
});
```
### getSupportedFlashModes(cb, [errorCallback])

<info>Get the flash modes supported by the device. Returns an array containing supported flash modes. See <code>[FLASH_MODE](#camera_Settings.FlashMode)</code> for posible values that can be returned</info><br/>

```javascript
CameraPreview.getSupportedFlashModes(function(flashModes){
  // note that the portrait version, width and height swapped, of these dimensions are also supported
  flashModes.forEach(function(flashMode) {
    console.log(flashMode + ', ');
  });
});
```

### setFlashMode(flashMode, [successCallback, errorCallback])

<info>Set the flash mode. See <code>[FLASH_MODE](#camera_Settings.FlashMode)</code> for details about the possible values for flashMode.</info><br/>

```javascript
CameraPreview.setFlashMode(CameraPreview.FLASH_MODE.ON);
```

### setColorEffect(colorEffect, [successCallback, errorCallback])

<info>Set the color effect. See <code>[COLOR_EFFECT](#camera_Settings.ColorEffect)</code> for details about the possible values for colorEffect.</info><br/>

```javascript
CameraPreview.setColorEffect(CameraPreview.COLOR_EFFECT.NEGATIVE);
```

### setZoom(zoomMultiplier, [successCallback, errorCallback])

<info>Set the zoom level. zoomMultipler option accepts an integer. Zoom level is initially at 1</info><br/>

```javascript
CameraPreview.setZoom(2);
```

### getZoom(cb, [errorCallback])

<info>Get the current zoom level. Returns an integer representing the current zoom level. Android only</info><br/>

```javascript
CameraPreview.getZoom(function(currentZoom){
  console.log(currentZoom);
});
```

### getMaxZoom(cb, [errorCallback])

<info>Get the maximum zoom level. Returns an integer representing the manimum zoom level. Android only</info><br/>

```javascript
CameraPreview.getMaxZoom(function(maxZoom){
  console.log(maxZoom);
});
```
### getExposureModes(cb, [errorCallback])

<info>Returns an array with supported exposure modes. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getExposureModes(function(exposureModes){
  console.log(exposureModes);
});
```

### getExposureMode(cb, [errorCallback])

<info>Get the curent exposure mode of the device. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getExposureMode(function(exposureMode){
  console.log(exposureMode);
});
```
### setExposureMode(exposureMode, [successCallback, errorCallback])

<info>Set the exposure mode. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values for exposureMode.</info><br/>

```javascript
CameraPreview.setExposureMode(CameraPreview.EXPOSURE_MODE.CONTINUOUS);
```
### getExposureCompensationRange(cb, [errorCallback])

<info>Get the minimum and maximum exposure compensation. Returns an object containing min and max integers. Android only</info><br/>

```javascript
CameraPreview.getExposureCompensationRange(function(expoxureRange){
  console.log("min: " + exposureRange.min);
  console.log("max: " + exposureRange.max);
});
```
### getExposureCompensation(cb, [errorCallback])

<info>Get the current exposure compensation. Returns an integer representing the current exposure compensation. Android only</info><br/>

```javascript
CameraPreview.getExposureCompensation(function(expoxureCompensation){
  console.log(exposureCompensation);
});
```
### setExposureCompensation(exposureCompensation, [successCallback, errorCallback])

<info>Set the exposure compensation. exposureCompensation accepts an integer. if exposureCompensation is lesser than the minimum exposure compensation, it is set to the minimum. if exposureCompensation is greater than the maximum exposure compensation, it is set to the maximum. (see getExposureCompensationRange() to get the minumum an maximum exposure compensation). Android only</info><br/>

```javascript
CameraPreview.setExposureCompensation(-2);
CameraPreview.setExposureCompensation(3);
```

### setPreviewSize([dimensions, successCallback, errorCallback])

<info>Change the size of the preview window.</info><br/>

```javascript
CameraPreview.setPreviewSize({width: window.screen.width, height: window.screen.height});
```

### getSupportedPictureSizes(cb, [errorCallback])

```javascript
CameraPreview.getSupportedPictureSizes(function(dimensions){
  // note that the portrait version, width and height swapped, of these dimensions are also supported
  dimensions.forEach(function(dimension) {
    console.log(dimension.width + 'x' + dimension.height);
  });
});
```

### tapToFocus(xPoint, yPoint, [successCallback, errorCallback])

<info>Set specific focus point. Note, this assumes the camera is full-screen.</info><br/>

```javascript
let xPoint = event.x;
let yPoint = event.y
CameraPreview.tapToFocus(xPoint, yPoint);
```

# Settings

<a name="camera_Settings.FlashMode"></a>

### FLASH_MODE

<info>Flash mode settings:</info><br/>

| Name | Type | Default | Note |
| --- | --- | --- | --- |
| OFF | string | off |  |
| ON | string | on |  |
| AUTO | string | auto |  |
| RED_EYE | string | red-eye | Android Only |
| TORCH | string | torch |  |

<a name="camera_Settings.CameraDirection"></a>

### CAMERA_DIRECTION

<info>Camera direction settings:</info><br/>

| Name | Type | Default |
| --- | --- | --- |
| BACK | string | back |
| FRONT | string | front |

<a name="camera_Settings.ColorEffect"></a>

### COLOR_EFFECT

<info>Color effect settings:</info><br/>

| Name | Type | Default | Note |
| --- | --- | --- | --- |
| AQUA | string | aqua | Android Only |
| BLACKBOARD | string | blackboard | Android Only |
| MONO | string | mono | |
| NEGATIVE | string | negative | |
| NONE | string | none | |
| POSTERIZE | string | posterize | |
| SEPIA | string | sepia | |
| SOLARIZE | string | solarize | Android Only |
| WHITEBOARD | string | whiteboard | Android Only |

<a name="camera_Settings.ExposureMode"></a>

### EXPOSURE_MODE

<info>Exposure mode settings:</info><br/>

| Name | Type | Default | Note |
| --- | --- | --- | --- |
| AUTO | string | auto | IOS Only |
| CONTINUOUS | string | continuous | |
| CUSTOM | string | custom | |
| LOCK | string | lock | IOS Only |

Note: Use AUTO to allow the device automatically adjusts the exposure once and then changes the exposure mode to LOCK.

# IOS Quirks
It is not possible to use your computers webcam during testing in the simulator, you must device test.

# Sample App

<a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview-sample-app">cordova-plugin-camera-preview-sample-app</a> for a complete working Cordova example for Android and iOS platforms.

# Screenshots

<img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-1.png"/> <img hspace="20" src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-2.png"/>

# Credits

Maintained by Weston Ganger - [@westonganger](https://github.com/westonganger)

Created by Marcel Barbosa Pinto [@mbppower](https://github.com/mbppower)
