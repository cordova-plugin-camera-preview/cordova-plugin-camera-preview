Cordova Plugin Camera Preview
====================

Cordova plugin that allows camera interaction from HTML code for showing camera preview below or above the HTML.<br/>

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
  <li>Maintain HTML interactivity.</li>
</ul>

### Android only features

These are some features that are currently Android only, however we would love to see PR's for this functionality in iOS.

<ul>
  <li>Zoom</li>
  <li>Auto focus</li>
  <li>Different modes of flash</li>
</ul>

# Installation

Use any one of the installation methods listed below depending on which framework you use.

```
cordova plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

ionic plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

meteor add cordova:cordova-plugin-camera-preview@https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git#[latest_commit_id]

<plugin spec="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-previewn.git" source="git" />
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

**Note: The successCallback and errorCallback options are all optional**

### startCamera(options, [successCallback, errorCallback])

<info>
Starts the camera preview instance.
<br/>
<br/>
When setting the toBack to true, remember to add the style below on your app's HTML or body element:
</info>

```css
html, body {
  background-color: transparent;
}
```

```javascript
/* All options stated are optional and will default to values here */
CameraPreview.startCamera({x: 0, y: 0, width: window.device.width, height: window.device.height, camera: "front", tapPhoto: true, previewDrag: false, toBack: false});
```

### stopCamera([successCallback, errorCallback])

<info>Stops the camera preview instance.</info><br/>

```javascript
CameraPreview.stopCamera();
```

### setOnPictureTakenHandler(onPictureTakenCallback)

<info>Register a callback function that receives the image captured from the preview box.</info><br/>

```javascript
CameraPreview.setOnPictureTakenHandler(function(base64PictureData) {
  /* 
    base64PictureData is base64 encoded jpeg image. Use this data to store to a file or upload.
    Its up to the you to figure out the best way to save it to disk or whatever for your application.
  */

  // One simple example is if you are going to use it inside an HTML img src attribute then you would do the following:
  imageSrcData = 'data:image/jpeg;base64,' +base64PictureData;
  $('img#my-img').attr('src', imageSrcData);
});
```

### takePicture([dimensions, quality=85, successCallback, errorCallback])

<info>Take the picture. The arguments `dimensions` defaults to max supported photo resolution. The argument `quality` defaults to `85` and specifies the quality/compression value: `0=max compression`, `100=max quality`.</info><br/>

```javascript
CameraPreview.takePicture({width:640, height:640});
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

### setFlashMode(flashMode, [successCallback, errorCallback])

<info>Set the flash mode. Options are `OFF`, `ON`, `AUTO`, `TORCH`</info><br/>

```javascript
CameraPreview.setFlashMode('ON');
```

### setColorEffect(colorEffect, [successCallback, errorCallback])

<info>Set the color effect.<br>iOS Effects: `none`, `mono`, `negative`, `posterize`, `sepia`.<br>Android Effects: `none`, `mono`, `negative`, `posterize`, `sepia`, `aqua`, `blackboard`, `solarize`, `whiteboard`</info><br/>

```javascript
CameraPreview.setColorEffect('sepia');
```

### setZoom(zoomMultiplier, [successCallback, errorCallback])

<info>Set the zoom level. zoomMultipler option accepts an integer.</info><br/>

```javascript
CameraPreview.setZoom(2);
```

### setPreviewSize([dimensions, successCallback, errorCallback])

<info>Change the size of the preview window.</info><br/>

```javascript
CameraPreview.setPreviewSize({width: window.screen.width, height: window.screen.height});
```

### getSupportedPreviewSize([successCallback, errorCallback])

<info></info><br/>

```javascript
CameraPreview.getSupportedPreviewSize(function(dimensions){
  console.log('Width: ' + dimensions.width); 
  console.log('Height: ' + dimensions.height); 
});
```

### getSupportedPictureSize([successCallback, errorCallback])

<info></info><br/>

```javascript
CameraPreview.getSupportedPictureSize(function(dimensions){
  console.log('Width: ' + dimensions.width); 
  console.log('Height: ' + dimensions.height); 
});
```


# IOS Quirks
It is not possible to use your computers webcam during testing in the simulator, you must device test.

# Sample App

<a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview-sample-app">cordova-plugin-camera-preview-sample-app</a> for a complete working Cordova example for Android and iOS platforms.

# Screenshots

<img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-1.png"/>

<img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-2.png"/>

# Credits

Maintained by Weston Ganger - [@westonganger](https://github.com/westonganger)

Created by Marcel Barbosa Pinto [@mbppower](https://github.com/mbppower)
