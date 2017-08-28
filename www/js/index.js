window.rcCamera = {
  
    getPicture:function(callback,error){
      var _this = this;
      _this.callback = callback;
      _this.error = error;
      _this.init();
  
      CameraPreview.startCamera({
          x: 0,
          y: 0,
          width: _this.container.width(),
          height: _this.container.height(),
          camera: 'back',
          toBack: true,
          previewDrag: false,
          tapPhoto: false
        },function(){
          setTimeout(function(){
            $('ion-app').css({
              opacity:0
            });
            _this.container.show();
          },300);
        },function(err){
          _this.error && _this.error(err);
          _this.callback = _this.error = null;
        });
    },
    stopCamera: function () {
      CameraPreview.stopCamera();
    },
  
    switchCamera: function () {
      CameraPreview.switchCamera();
    },
  
    show: function () {
      CameraPreview.show();
    },
  
    hide: function () {
      CameraPreview.hide();
    },
  
    changeColorEffect: function () {
      var effect = document.getElementById('selectColorEffect').value;
      CameraPreview.setColorEffect(effect);
    },
  
    changeFlashMode: function () {
      var mode = document.getElementById('selectFlashMode').value;
      CameraPreview.setFlashMode(mode);
    },
  
    changeZoom: function () {
      var zoom = document.getElementById('zoomSlider').value;
      document.getElementById('zoomValue').innerHTML = zoom;
      CameraPreview.setZoom(zoom);
    },
  
    changePreviewSize: function () {
      window.smallPreview = !window.smallPreview;
      if (window.smallPreview) {
        CameraPreview.setPreviewSize({
          width: 100,
          height: 100
        });
      } else {
        CameraPreview.setPreviewSize({
          width: window.screen.width,
          height: window.screen.height
        });
      }
    },
  
    showSupportedPictureSizes: function () {
      CameraPreview.getSupportedPictureSizes(function (dimensions) {
        dimensions.forEach(function (dimension) {
          console.log(dimension.width + 'x' + dimension.height);
        });
      });
    },
  
    init: function () {
      var _this = this;
      if (!_this.container) {
        // $(window).on('orientationchange', function (event) {
        //   if (isNaN(window.orientation)) {
        //     return 'landscape';
        //   } else {
        //     if (window.orientation % 180 === 0) {
        //       return 'portrait';
        //     } else {
        //       return 'landscape';
        //     }
        //   }
        // });
        var container;
      //   '    <div class="ricent-control-container">\
      //   <div class="ricent-top ricent-right">\
      //     <div class="ricent-draw ricent-control">\
      //       <div class="ricent-draw-section">\
      //         <div class="ricent-draw-toolbar ricent-bar ricent-draw-toolbar-top">\
      //           <a class="rc-edit pan_red" ></a>\
      //           <a class="rc-edit pan_blue" ></a>\
      //           <a class="rc-edit pan_green" ></a>\
      //         </div>\
      //         <div class="ricent-draw-actions"></div>\
      //       </div>\
      //     </div>\
      //   </div>\
      //   <div class="ricent-bottom ricent-left"></div>\
      //   <div class="ricent-bottom ricent-right"></div>\
      // </div>\'
        _this.container = container = $('<div class="ricent-camera ricent-container ricent-touch ricent-retina">\
      <canvas class="ricent-pane ricent-map-pane"></canvas>\
      <div class="controls">\
        <a class="cancelTack"><i class="rc-back2"></i></a>\
        <a class="tackPhoto"><i class="rc-camera"></i></a>\
        <a class="saveTack"><i class="rc-save"></i></a>\
      </div>\
    </div>').appendTo($('body'));
        _this.takePhoto = $('.tackPhoto', container);
        _this.canvas = $('canvas', container);
        _this.cancel = $('.cancelTack', container);
        _this.cancel.on('click', function () {
          if(_this.isPad){
            _this.isPad =false;
          _this.canvas.hide();
          _this.show();
          }
          else{
            CameraPreview.stopCamera(function(){
              _this.container.hide();
              $('ion-app').css({
                opacity:1
              });
              var canvas = _this.canvas[0];
              canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
              canvas.width=0;
              canvas.height=0;
              _this.error && _this.error('canceled');
              _this.callback = _this.error = null;
            });
          }
        });
        _this.save = $('.saveTack',container);
        _this.save.on('click',function(){
          CameraPreview.stopCamera(function(){
            _this.container.hide();
            $('ion-app').css({
              opacity:1
            });
            var canvas = _this.canvas[0];
            var data = canvas.toDataURL().split(',')[1];
            canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
            canvas.width=0;
            canvas.height=0;
            _this.callback && _this.callback(data);
            _this.callback = _this.error = null;
          });
          
        });
        _this.takePhoto.on('click', function () {
          var w = _this.container.width(),
            h = _this.container.height();
          // if (!_this.sketchpad) {
          //   _this.sketchpad = new Sketchpad({
          //     element: _this.canvas,
          //     width: w,
          //     height: h,
          //   });
          //   _this.sketchpad.color = '#DE3031';
          //   _this.sketchpad.penSize = 3;
          // }
          CameraPreview.takePicture({
            width: w,
            height: h
          }, function (data) {
            _this.isPad = true;
            var img = new Image();
            _this.canvas[0].width = w;
            _this.canvas[0].height = h;
            
            img.onload = function () {
              //var cvs = document.createElement('canvas');
              //cvs.width = w;
              //cvs.height = h;
              var ctx = _this.canvas[0].getContext('2d');
              ctx.clearRect(0, 0, w, h);
              var sx = 0,
                sy = 0,
                sWidth = parseFloat(img.width),
                sHeight = parseFloat(img.height),
                dx = 0,
                dy = 0,
                dWidth = parseFloat(w),
                dHeight = parseFloat(h),
                hRatio = dWidth / sHeight,
                vRatio = dHeight / sWidth,
                ratio = Math.max(hRatio, vRatio) //,
              //dx = (dWidth - sWidth * ratio) / 2,
              //dy = (dHeight - sHeight * ratio) / 2,
              dWidth = sWidth * ratio,
                dHeight = sHeight * ratio;
                //前
              // ctx.translate(0, sHeight);
              // ctx.rotate((-90 - window.orientation) * Math.PI / 180);
              // ctx.drawImage(img, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight);
       
              //后
              ctx.translate(dHeight, 0);
              ctx.rotate((90 - window.orientation) * Math.PI / 180);
              ctx.drawImage(img, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight);
  //-----
             // var ctx1 = _this.canvas[0].getContext('2d');
             // ctx1.drawImage(cvs,0,0,w,h);
              // if (window.orientation == 90
              //    || window.orientation == -90)
              // {
              //     ctx.save();
              //     // rotate 90
              //     ctx.translate(w/2, h/2);
              //     ctx.rotate((90 - window.orientation) *Math.PI/180);
              //     ctx.drawImage(img, 0, 0, img.width, img.height, -w/2, -h/2,w, h);
              //     //
              //     ctx.restore();
              // }
              // else
              // {
              //     ctx.save();
              //     // rotate 90
              //     ctx.translate(w/2, h/2);
              //     ctx.rotate((90 - window.orientation)*Math.PI/180);
              //     ctx.drawImage(img, 0, 0, img.width, img.height, -h/2, -w/2, h, w);
              //     //
              //     ctx.restore();
              // }
              _this.canvas.show();
              _this.hide();
            };
            img.src = 'data:image/jpeg;base64,' + data;
          });
        });
      };
  
      // CameraPreview.startCamera({
      //   x: 0,
      //   y: 0,
      //   width: _this.container.width(),
      //   height: _this.container.height(),
      //   camera: 'front',
      //   toBack: true,
      //   previewDrag: false,
      //   tapPhoto: false
      // });
    }
  };

document.addEventListener('deviceready', function () {
  rcCamera.getPicture();
}, false);
$(function(){
  rcCamera.getPicture();
})