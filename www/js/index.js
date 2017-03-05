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
    CameraPreview.takePicture({width: window.device.width, height: window.device.height, quality: 90});
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

  changeColorEffect: function(){
    var effect = document.getElementById('selectColorEffect').value;
    CameraPreview.setColorEffect(effect);
  },

  changeFlashMode: function(){
    var mode = document.getElementById('selectFlashMode').value;
    CameraPreview.setFlashMode(mode);
  },

  changeZoom: function(){
    var zoom = document.getElementById('zoomSlider').value;
    document.getElementById('zoomValue').text = zoom;
    CameraPreview.setZoom(zoom);
  },

  changePreviewSize: function(){
    window.smallPreview = !window.smallPreview;
    if(window.smallPreview){
      CameraPreview.setPreviewSize({width: 100, height: 100});
    }else{
      CameraPreview.setPreviewSize({width: window.device.width, height: window.device.height});
    }
  },

  showSupportedSize: function(type){
    if(type === 'picture'){
      CameraPreview.getSupportedPictureSize(function(dimensions){
        alert("Supported Picture Size\n\nWidth: " + dimensions.width + "\nHeight: " + 'dimensions.height');
      });
    }else{
      CameraPreview.getSupportedPreviewSize(function(dimensions){
        alert("Supported Preview Size\n\nWidth: " + dimensions.width + "\nHeight: " + 'dimensions.height');
      });
    }
  }


  init: function(){
    document.getElementById('startCameraButton').addEventListener('click', this.startCamera, false);
    document.getElementById('startCameraAnotherPosButton').addEventListener('click', this.startCameraAnotherPos, false);

    document.getElementById('stopCameraButton').addEventListener('click', this.stopCamera, false);
    document.getElementById('switchCameraButton').addEventListener('click', this.switchCamera, false);
    document.getElementById('showButton').addEventListener('click', this.show, false);
    document.getElementById('hideButton').addEventListener('click', this.hide, false);
    
    CameraPreview.setOnPictureTakenHandler(function(imgData){
      document.getElementById('originalPicture').src = 'data:image/jpeg;base64,' + imgData;
    });

    document.getElementById('takePictureButton').addEventListener('click', this.takePicture, false);

    document.getElementById('selectColorEffect').addEventListener('change', this.changeColorEffect, false);

    if(device.platform === 'Android'){
      document.getElementById('selectFlashMode').addEventListener('change', this.changeFlashMode, false);
      document.getElementById('zoomSlider').addEventListener('change', this.changeZoom, false);
    }else{
      document.getElementById('androidOnly').style.display = 'none';
    }

    window.smallPreview = false;
    document.getElementById('togglePreviewSize').addEventListener('click', this.changePreviewSize, false);

    document.getElementById('showSupportedPreviewSize').addEventListener('click', this.showSupportedSize('preview'), false);
    document.getElementById('showSupportedPictureSize').addEventListener('click', this.showSupportedSize('picture'), false);

    // legacy - not sure if this was supposed to fix anything
    //window.addEventListener('orientationchange', this.onStopCamera, false);
  }
};

document.addEventListener('deviceready', function(){	
  app.init();
}, false);
