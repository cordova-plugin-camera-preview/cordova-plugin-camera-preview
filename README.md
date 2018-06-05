Cordova Plugin Camera Preview
====================

Cordova plugin that allows camera interaction from Javascript and HTML

**This plugin is under constant development. It is recommended to use master to always have the latest fixes and features.**

**PR's are greatly appreciated. Maintainer(s) wanted.**

# Features

<ul>
  <li>Start a camera preview from HTML code.</li>
  <li>Maintain HTML interactivity.</li>
  <li>Drag the preview box.</li>
  <li>Set camera color effect.</li>
  <li>Send the preview box to back of the HTML content.</li>
  <li>Set a custom position for the camera preview box.</li>
  <li>Set a custom size for the preview box.</li>
  <li>Set a custom alpha for the preview box.</li>
  <li>Set the focus mode, zoom, color effects, exposure mode, white balance mode and exposure compensation</li>
  <li>Tap to focus</li>
</ul>

# Installation

Use any one of the installation methods listed below depending on which framework you use.

To install the master version with latest fixes and features

```
cordova plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

ionic cordova plugin add https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git

meteor add cordova:cordova-plugin-camera-preview@https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git#[latest_commit_id]

<plugin spec="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview.git" source="git" />
```

or if you want to use the last released version on npm

```
cordova plugin add cordova-plugin-camera-preview

ionic cordova plugin add cordova-plugin-camera-preview

meteor add cordova:cordova-plugin-camera-preview@X.X.X

<gap:plugin name="cordova-plugin-camera-preview" />
```

#### iOS Quirks
If you are developing for iOS 10+ you must also add the following to your config.xml

```xml
<config-file platform="ios" target="*-Info.plist" parent="NSCameraUsageDescription" overwrite="true">
  <string>Allow the app to use your camera</string>
</config-file>

<!-- or for Phonegap -->

<gap:config-file platform="ios" target="*-Info.plist" parent="NSCameraUsageDescription" overwrite="true">
  <string>Allow the app to use your camera</string>
</gap:config-file>
```

### Android Quirks (older devices)
When using the plugin for older devices, the camera preview will take the focus inside the app once initialized.
In order to prevent the app from closing when a user presses the back button, the event for the camera view is disabled.
If you still want the user to navigate, you can add a listener for the back event for the preview
(see <code>[onBackButton](#onBackButton)</code>)



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
* `camera` - See <code>[CAMERA_DIRECTION](#camera_Settings.CameraDirection)</code> - Defaults to front camera
* `toBack` - Defaults to false - Set to true if you want your html in front of your preview
* `tapPhoto` - Defaults to true - Does not work if toBack is set to false in which case you use the takePicture method
* `tapFocus` - Defaults to false - Allows the user to tap to focus, when the view is in the foreground
* `previewDrag` - Defaults to false - Does not work if toBack is set to false
* `disableExifHeaderStripping` - Defaults to false - On Android disable automatic rotation of the image, and let the browser deal with it (keep reading on how to achieve it)

```javascript
let options = {
  x: 0,
  y: 0,
  width: window.screen.width,
  height: window.screen.height,
  camera: CameraPreview.CAMERA_DIRECTION.BACK,
  toBack: false,
  tapPhoto: true,
  tapFocus: false,
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

When both tapFocus and tapPhoto are true, the camera will focus, and take a picture as soon as the camera is done focusing.

#### Using disableExifHeaderStripping

If you want to capture large images you will notice in Android that performace is very bad, in those cases you can set
this flag, and add some extra Javascript/HTML to get a proper display of your captured images without risking your application speed.

Example:

```html
<script src="https://raw.githubusercontent.com/blueimp/JavaScript-Load-Image/master/js/load-image.all.min.js"></script>

<p><div id="originalPicture" style="width: 100%"></div></p>
```

```javascript
let options = {
  x: 0,
  y: 0,
  width: window.screen.width,
  height: window.screen.height,
  camera: CameraPreview.CAMERA_DIRECTION.BACK,
  toBack: false,
  tapPhoto: true,
  tapFocus: false,
  previewDrag: false,
  disableExifHeaderStripping: true
};
....

function gotRotatedCanvas(canvasimg) {
  var displayCanvas = $('canvas#display-canvas');
  loadImage.scale(canvasimg, function(img){
    displayCanvas.drawImage(img)
  }, {
    maxWidth: displayCanvas.width,
    maxHeight: displayCanvas.height
  });
}

CameraPreview.getSupportedPictureSizes(function(dimensions){
  dimensions.sort(function(a, b){
    return (b.width * b.height - a.width * a.height);
  });
  var dimension = dimensions[0];
  CameraPreview.takePicture({width:dimension.width, height:dimension.height, quality: 85}, function(base64PictureData){
    /*
      base64PictureData is base64 encoded jpeg image. Use this data to store to a file or upload.
      Its up to the you to figure out the best way to save it to disk or whatever for your application.
    */

    var image = 'data:image/jpeg;base64,' + imgData;
    let holder = document.getElementById('originalPicture');
    let width = holder.offsetWidth;
    loadImage(
      image,
      function(canvas) {
        holder.innerHTML = "";
        if (app.camera === 'front') {
          // front camera requires we flip horizontally
          canvas.style.transform = 'scale(1, -1)';
        }
        holder.appendChild(canvas);
      },
      {
        maxWidth: width,
        orientation: true,
        canvas: true
      }
    );
  });
});
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
### getSupportedFocusModes(cb, [errorCallback])

<info>Get focus modes supported by the camera device currently started. Returns an array containing supported focus modes. See <code>[FOCUS_MODE](#camera_Settings.FocusMode)</code> for possible values that can be returned.</info><br/>

```javascript
CameraPreview.getSupportedFocusModes(function(focusModes){
  focusModes.forEach(function(focusMode) {
    console.log(focusMode + ', ');
  });
});
```

### setFocusMode(focusMode, [successCallback, errorCallback])

<info>Set the focus mode for the camera device currently started.</info><br/>
* `focusMode` - <code>[FOCUS_MODE](#camera_Settings.FocusMode)</code>

```javascript
CameraPreview.setFocusMode(CameraPreview.FOCUS_MODE.CONTINUOUS_PICTURE);
```

### getFocusMode(cb, [errorCallback])

<info>Get the focus mode for the camera device currently started. Returns a string representing the current focus mode.</info>See <code>[FOCUS_MODE](#camera_Settings.FocusMode)</code> for possible values that can be returned.</info><br/>

```javascript
CameraPreview.getFocusMode(function(currentFocusMode){
  console.log(currentFocusMode);
});
```

### getSupportedFlashModes(cb, [errorCallback])

<info>Get the flash modes supported by the camera device currently started. Returns an array containing supported flash modes. See <code>[FLASH_MODE](#camera_Settings.FlashMode)</code> for possible values that can be returned</info><br/>

```javascript
CameraPreview.getSupportedFlashModes(function(flashModes){
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

### getFlashMode(cb, [errorCallback])

<info>Get the flash mode for the camera device currently started. Returns a string representing the current flash mode.</info>See <code>[FLASH_MODE](#camera_Settings.FlashMode)</code> for possible values that can be returned</info><br/>

```javascript
CameraPreview.getFlashMode(function(currentFlashMode){
  console.log(currentFlashMode);
});
```

### getHorizontalFOV(cb, [errorCallback])

<info>Get the Horizontal FOV for the camera device currently started. Returns a string of a float that is the FOV of the camera in Degrees. </info><br/>

```javascript
CameraPreview.getHorizontalFOV(function(getHorizontalFOV){
  console.log(getHorizontalFOV);
});
```

### getSupportedColorEffects(cb, [errorCallback])

*Currently this feature is for Android only. A PR for iOS support would be happily accepted*

<info>Get color modes supported by the camera device currently started. Returns an array containing supported color effects (strings). See <code>[COLOR_EFFECT](#camera_Settings.ColorEffect)</code> for possible values that can be returned.</info><br/>

```javascript
CameraPreview.getSupportedColorEffects(function(colorEffects){
  colorEffects.forEach(function(color) {
    console.log(color + ', ');
  });
});
```


### setColorEffect(colorEffect, [successCallback, errorCallback])

<info>Set the color effect. See <code>[COLOR_EFFECT](#camera_Settings.ColorEffect)</code> for details about the possible values for colorEffect.</info><br/>

```javascript
CameraPreview.setColorEffect(CameraPreview.COLOR_EFFECT.NEGATIVE);
```

### setZoom(zoomMultiplier, [successCallback, errorCallback])

<info>Set the zoom level for the camera device currently started. zoomMultipler option accepts an integer. Zoom level is initially at 1</info><br/>

```javascript
CameraPreview.setZoom(2);
```

### getZoom(cb, [errorCallback])

<info>Get the current zoom level for the camera device currently started. Returns an integer representing the current zoom level.</info><br/>

```javascript
CameraPreview.getZoom(function(currentZoom){
  console.log(currentZoom);
});
```

### getMaxZoom(cb, [errorCallback])

<info>Get the maximum zoom level for the camera device currently started. Returns an integer representing the manimum zoom level.</info><br/>

```javascript
CameraPreview.getMaxZoom(function(maxZoom){
  console.log(maxZoom);
});
```

### getSupportedWhiteBalanceModes(cb, [errorCallback])

<info>Returns an array with supported white balance modes for the camera device currently started. See <code>[WHITE_BALANCE_MODE](#camera_Settings.WhiteBalanceMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getSupportedWhiteBalanceModes(function(whiteBalanceModes){
  console.log(whiteBalanceModes);
});
```

### getWhiteBalanceMode(cb, [errorCallback])

<info>Get the curent white balance mode of the camera device currently started. See <code>[WHITE_BALANCE_MODE](#camera_Settings.WhiteBalanceMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getWhiteBalanceMode(function(whiteBalanceMode){
  console.log(whiteBalanceMode);
});
```
### setWhiteBalanceMode(whiteBalanceMode, [successCallback, errorCallback])

<info>Set the white balance mode for the camera device currently started. See <code>[WHITE_BALANCE_MODE](#camera_Settings.WhiteBalanceMode)</code> for details about the possible values for whiteBalanceMode.</info><br/>

```javascript
CameraPreview.setWhiteBalanceMode(CameraPreview.WHITE_BALANCE_MODE.CLOUDY_DAYLIGHT);
```

### getExposureModes(cb, [errorCallback])

<info>Returns an array with supported exposure modes for the camera device currently started. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getExposureModes(function(exposureModes){
  console.log(exposureModes);
});
```

### getExposureMode(cb, [errorCallback])

<info>Get the curent exposure mode of the camera device currently started. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values returned.</info><br/>

```javascript
CameraPreview.getExposureMode(function(exposureMode){
  console.log(exposureMode);
});
```
### setExposureMode(exposureMode, [successCallback, errorCallback])

<info>Set the exposure mode for the camera device currently started. See <code>[EXPOSURE_MODE](#camera_Settings.ExposureMode)</code> for details about the possible values for exposureMode.</info><br/>

```javascript
CameraPreview.setExposureMode(CameraPreview.EXPOSURE_MODE.CONTINUOUS);
```
### getExposureCompensationRange(cb, [errorCallback])

<info>Get the minimum and maximum exposure compensation for the camera device currently started. Returns an object containing min and max integers.</info><br/>

```javascript
CameraPreview.getExposureCompensationRange(function(expoxureRange){
  console.log("min: " + exposureRange.min);
  console.log("max: " + exposureRange.max);
});
```
### getExposureCompensation(cb, [errorCallback])

<info>Get the current exposure compensation for the camera device currently started. Returns an integer representing the current exposure compensation.</info><br/>

```javascript
CameraPreview.getExposureCompensation(function(expoxureCompensation){
  console.log(exposureCompensation);
});
```
### setExposureCompensation(exposureCompensation, [successCallback, errorCallback])

<info>Set the exposure compensation for the camera device currently started. exposureCompensation accepts an integer. if exposureCompensation is lesser than the minimum exposure compensation, it is set to the minimum. if exposureCompensation is greater than the maximum exposure compensation, it is set to the maximum. (see getExposureCompensationRange() to get the minumum an maximum exposure compensation).</info><br/>

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

### onBackButton(successCallback, [errorCallback])

<info>Callback event for the back button tap</info><br/>

```javascript
CameraPreview.onBackButton(function() {
  console.log('Back button pushed');
});
```

# Settings

<a name="camera_Settings.FocusMode"></a>

### FOCUS_MODE

<info>Focus mode settings:</info><br/>

| Name | Type | Default | Note |
| --- | --- | --- | --- |
| FIXED | string | fixed |  |
| AUTO | string | auto |  |
| CONTINUOUS | string | continuous | IOS Only |
| CONTINUOUS_PICTURE | string | continuous-picture | Android Only |
| CONTINUOUS_VIDEO | string | continuous-video | Android Only |
| EDOF | string | edof | Android Only |
| INFINITY | string | infinity | Android Only |
| MACRO | string | macro | Android Only |

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

<a name="camera_Settings.WhiteBalanceMode"></a>

### WHITE_BALANCE_MODE

<info>White balance mode settings:</info><br/>

| Name | Type | Default | Note |
| --- | --- | --- | --- |
| LOCK | string | lock | |
| AUTO | string | auto | |
| CONTINUOUS | string | continuous | IOS Only |
| INCANDESCENT | string | incandescent | |
| CLOUDY_DAYLIGHT | string | cloudy-daylight | |
| DAYLIGHT | string | daylight | |
| FLUORESCENT | string | fluorescent | |
| SHADE | string | shade | |
| TWILIGHT | string | twilight | |
| WARM_FLUORESCENT | string | warm-fluorescent | |

# IOS Quirks
It is not possible to use your computers webcam during testing in the simulator, you must device test.

# Sample App

<a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview-sample-app">cordova-plugin-camera-preview-sample-app</a> for a complete working Cordova example for Android and iOS platforms.

# Screenshots

<img src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-1.png"/> <img hspace="20" src="https://raw.githubusercontent.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/master/img/android-2.png"/>

# Credits

Maintained by Weston Ganger - [@westonganger](https://github.com/westonganger)

Created by Marcel Barbosa Pinto [@mbppower](https://github.com/mbppower)
