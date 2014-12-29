CordovaCameraPreview
====================

Cordova plugin that allows camera interaction from HTML code.<br/>
Show camera preview popup on top of the HTML.<br/>

<p><b>Features:</b></p>
<ul>
  <li>Start a camera preview from HTML code.</li>
  <li>Set a custom position for the camera preview box.</li>
  <li>Set a custom size for the preview box.</li>
  <li>Maintain HTML interactivity.</li>
</ul>

<p><b>Installation:</b></p>

<code>cordova plugin add https://github.com/mbppower/CordovaCameraPreview.git</code>

<p><b>Methods:</b></p>

<p>
  <b>startCamera(object)</b><br/>
  <info>Starts the camera preview instance.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.startCamera({x: 400, y: 500, width: 300, height:300});</code>
</p>
<p>
  <b>stopCamera()</b><br/>
  <info>Stops the camera preview instance.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.stopCamera();</code>
</p>
<p>
  <b>takePicture(callback)</b><br/>
  <info>Returns the original picture and the image captured from the preview box.</info><br/>
  <i>Usage:</i><br/>
  <pre><code>
  cordova.plugins.camerapreview.takePicture(function onPictureTaken(result){
  	var originalPicturePath = result[0];
  	var previewPicturePath = result[1];
  });</code>
  </pre>
</p>
<p>
  <b>switchCamera()</b><br/>
  <info>Switch from the rear camera and front camera, if available.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.switchCamera();</code>
</p>
<p>
  <b>show()</b><br/>
  <info>Show the camera preview box.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.show();</code>
</p>
<p>
  <b>hide()</b><br/>
  <info>Hide the camera preview box.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.hide();</code>
</p>

<p><b>Sample:</b></p>
<p>Please see the <a href="https://github.com/mbppower/CordovaCameraPreviewApp">CordovaCameraPreviewApp</a> for a complete working example for Android and iOS platforms.</p>

<p><b>Android Screenshots:</b></p>
<p><img src="https://github.com/mbppower/CordovaCameraPreview/blob/master/docs/img/android-1.png"/></p>
<p><img src="https://github.com/mbppower/CordovaCameraPreview/blob/master/docs/img/android-2.png"/></p>





