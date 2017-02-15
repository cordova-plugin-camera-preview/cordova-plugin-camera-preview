Cordova Plugin Camera Preview
====================

Cordova plugin that allows camera interaction from HTML code for showing camera preview below or above the HTML.<br/>

**Feb 11, 2017** - We are finally getting all the fixes and enhancements from other branches merged here. Please use master until a new version is released.

**PR's are greatly appreciated. If your interested in maintainer status please create a couple PR's and then contact westonganger@gmail.com**

<p><b>Features:</b></p>
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

<p><b>Android only features:</b></p>
<ul>
  <li>Zoom.</li>
  <li>Auto focus.</li>
  <li>Different modes of flash.</li>
</ul>

<p><b>Installation:</b></p>

```
cordova plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

ionic plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

meteor add cordova:cordova-plugin-camera-preview@https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git#[latest_commit_id]

# Phonegap
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

<p><b>Methods:</b></p>

* Note: The successCallback and errorCallback options are optional *

<b>startCamera(options, successCallback, errorCallback)</b><br/>
<info>
Starts the camera preview instance.
<br/>
<br/>
When setting the toBack to true, remember to add the style below on your app's HTML or body element:
```css
html, body {
  background-color: transparent;
}
```
</info>

```javascript
/* All options stated are optional and will default to values here */
CameraPreview.startCamera({x: 0, y: 0, width: window.device.width, height: window.device.height, camera: "front", tapPhoto: true, previewDrag: false, toBack: false});
```

<b>stopCamera(successCallback, errorCallback)</b><br/>
<info>Stops the camera preview instance.</info><br/>

```javascript
CameraPreview.stopCamera();
```

<b>takePicture(size, successCallback, errorCallback)</b><br/>
<info>Take the picture, the parameter size is optional</info><br/>

```javascript
CameraPreview.takePicture({maxWidth:640, maxHeight:640});
```

<b>setOnPictureTakenHandler(successCallback, errorCallback)</b><br/>
<info>Register a callback function that receives the image captured from the preview box.</info><br/>

```javascript
CameraPreview.setOnPictureTakenHandler(function(picture) {
  document.getElementById('picture').src = picture; // base64 picture;
});
```

<b>switchCamera(successCallback, errorCallback)</b><br/>
<info>Switch from the rear camera and front camera, if available.</info><br/>

```javascript
CameraPreview.switchCamera();
```

<b>show(successCallback, errorCallback)</b><br/>
<info>Show the camera preview box.</info><br/>

```javascript
CameraPreview.show();
```

<b>hide(successCallback, errorCallback)</b><br/>
<info>Hide the camera preview box.</info><br/>

```javascript
CameraPreview.hide();
```

<b>setFlashMode(flashMode, successCallback, errorCallback)</b><br/>
<info>Set the flash mode. Options are `OFF`, `ON`, `AUTO`, `TORCH`</info><br/>

```javascript
CameraPreview.setFlashMode('ON');
```

<b>setColorEffect(colorEffect, successCallback, errorCallback)</b><br/>
<info>Set the color effect.<br>iOS Effects: `none`, `mono`, `negative`, `posterize`, `sepia`.<br>Android Effects: `none`, `mono`, `negative`, `posterize`, `sepia`, `aqua`, `blackboard`, `solarize`, `whiteboard`</info><br/>

```javascript
CameraPreview.setColorEffect('sepia');
```

<b>setOnLogHandler(successCallback, errorCallback)</b><br/>
<info></info><br/>

```javascript
CameraPreview.setOnLogHandler(function(){
  console.log('log handler set!');
});
```

<b>setZoom(zoomMultiplier, successCallback, errorCallback)</b><br/>
<info>Set the zoom level. zoomMultipler option accepts an integer.</info><br/>

```javascript
CameraPreview.setZoom(2);
```

<b>setPreviewSize(width, height, successCallback, errorCallback)</b><br/>
<info>Change the size of the preview window.</info><br/>

```javascript
CameraPreview.setPreviewSize(window.screen.width, window.screen.height);
```

<b>getSupportedPreviewSizes(successCallback, errorCallback)</b><br/>
<info></info><br/>

```javascript
CameraPreview.getSupportedPreviewSizes(function(sizes){
  console.log('Width: ' + sizes.width); 
  console.log('Height: ' + sizes.height); 
});
```

<b>getSupportedPictureSizes(successCallback, errorCallback)</b><br/>
<info></info><br/>

```javascript
CameraPreview.getSupportedPictureSizes(function(sizes){
  console.log('Width: ' + sizes.width); 
  console.log('Height: ' + sizes.height); 
});
```


<b>IOS Quirks:</b><br/>
It is not possible to use your computers webcam during testing in the simulator, you must device test.


<b>Sample App:</b><br/>
<a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview-sample-app">cordova-plugin-camera-preview-sample-app</a> for a complete working Cordova example for Android and iOS platforms.

<p><b>Android Screenshots:</b></p>
<p><img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-1.png"/></p>
<p><img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-2.png"/></p>
