var app = {
  startCamera: function(){
    CameraPreview.startCamera();
  },

  startCameraAnotherPos: function(){
    CameraPreview.startCamera({x: 50, y: 100, width: 300, height:300, camera: "back", tapPhoto: true, previewDrag: true, toBack: false});
  },

  stopCamera: function(){
    CameraPreview.stopCamera();
  },

  takePicture: function(){
    CameraPreview.takePicture({maxWidth: window.device.width, maxHeight: window.device.height});
  },

  switchCamera: function(){
    CameraPreview.switchCamera();
  },

  show: function(){
    CameraPreview.show();
  },

  hide: function(){
    CameraPreview.hide();
  },

  colorEffectChanged: function(){
    var effect = document.getElementById('colorEffectCombo').value;
    CameraPreview.setColorEffect(effect);
  },

  init: function(){
    document.getElementById('startCameraButton').addEventListener('click', this.startCamera, false);
    document.getElementById('startCameraAnotherPosButton').addEventListener('click', this.startCameraAnotherPos, false);

    document.getElementById('stopCameraButton').addEventListener('click', this.stopCamera, false);
    document.getElementById('takePictureButton').addEventListener('click', this.takePicture, false);
    document.getElementById('switchCameraButton').addEventListener('click', this.switchCamera, false);
    document.getElementById('showButton').addEventListener('click', this.show, false);
    document.getElementById('hideButton').addEventListener('click', this.hide, false);
    document.getElementById('colorEffectCombo').addEventListener('change', this.colorEffectChanged, false);
    //window.addEventListener('orientationchange', this.onStopCamera, false);
    
    CameraPreview.setOnPictureTakenHandler(function(result){
      document.getElementById('originalPicture').src = result[0]; //originalPicturePath;
      document.getElementById('previewPicture').src = result[1]; //previewPicturePath;
    });
  }
};

document.addEventListener('deviceready', function(){	
  app.init();
}, false);
