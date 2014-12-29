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

<p><b>Methods:</b></p>

<p>
  <b>StartCamera</b><br/>
  <info>Starts the camera preview instance.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.startCamera({x: 400, y: 500, width: 300, height:300});</code>
</p>
<p>
  <b>StopCamera</b><br/>
  <info>Stops the camera preview instance.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.stopCamera();</code>
</p>
<p>
  <b>TakePicture</b><br/>
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
  <b>SwitchCamera</b><br/>
  <info>Switch from the rear camera and front camera, if available.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.switchCamera();</code>
</p>
<p>
  <b>Show</b><br/>
  <info>Show the camera preview box.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.show();</code>
</p>
<p>
  <b>Hide</b><br/>
  <info>Hide the camera preview box.</info><br/>
  <i>Usage:</i><br/>
  <code>cordova.plugins.camerapreview.hide();</code>
</p>

<p><b>Sample:</b></p>
<p>Please see the <i>sample</i> folder for a complete working example for Android and iOS platforms.</p>





