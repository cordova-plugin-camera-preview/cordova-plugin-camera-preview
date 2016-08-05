Cordova CameraPreview Plugin
====================

Cordova plugin that allows camera interaction from HTML code.<br/>
Show camera preview popup on top of the HTML.<br/>

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

<p><b>Installation:</b></p>

```
cordova plugin add cordova-plugin-camera-preview
```

```
ionic plugin add cordova-plugin-camera-preview
```

<b>Phonegap Build:</b><br/>

```xml
<gap:plugin name="cordova-plugin-camera-preview" />
```

<p><b>Methods:</b></p>

<b>startCamera()</b><br/>
<info>
Starts the camera preview instance.
<br/>
<br/>
When setting the toBack to TRUE, remember to add the style bellow on your app's HTML or body element:
```css
html, body{
  background-color: transparent;
}
```
</info>

Javascript:

```javascript
/* All options stated are optional and will default to values here */
CameraPreview.startCamera({x: 0, y: 0, width: window.device.width, height: window.device.height, camera: "front", tapPhoto: true, previewDrag: false, toBack: false});
```

<b>stopCamera()</b><br/>
<info>Stops the camera preview instance.</info><br/>

```javascript
CameraPreview.stopCamera();
```

<b>takePicture(size)</b><br/>
<info>Take the picture, the parameter size is optional</info><br/>

```javascript
CameraPreview.takePicture({maxWidth:640, maxHeight:640});
```


<b>setOnPictureTakenHandler(callback)</b><br/>
<info>Register a callback function that receives the image captured from the preview box.</info><br/>

```javascript
CameraPreview.setOnPictureTakenHandler(function (picture) {
  document.getElementById('picture').src = picture; // base64 picture;
});
```

<b>switchCamera()</b><br/>
<info>Switch from the rear camera and front camera, if available.</info><br/>

```javascript
CameraPreview.switchCamera();
```

<b>show()</b><br/>
<info>Show the camera preview box.</info><br/>

```javascript
CameraPreview.show();
```

<b>hide()</b><br/>
<info>Hide the camera preview box.</info><br/>

```javasript
CameraPreview.hide();
```

<b>IOS Quirks:</b><br/>
It is not possible to use your computers webcam during testing in the simulator, you must device test.


<b>Sample:</b><br/>
Cordova: <a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview-sample-app">cordova-plugin-camera-preview-sample-app</a> for a complete working Cordova example for Android and iOS platforms.


Ionic: <a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-ionic-preview-sample-app">cordova-plugin-camera-preview-ionic-sample-app</a> for a complete working Ionic example for Android and iOS platforms.

<p><b>Android Screenshots:</b></p>
<p><img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/docs/img/android-1.png"/></p>
<p><img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/docs/img/android-2.png"/></p>
