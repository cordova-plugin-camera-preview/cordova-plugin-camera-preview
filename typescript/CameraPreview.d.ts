interface CameraPreview {
  startCamera(options?:any, onSuccess?:any, onError?:any):any;
  stopCamera(onSuccess?:any, onError?:any):any;
  switchCamera(onSuccess?:any, onError?:any):any;
  hide(onSuccess?:any, onError?:any):any;
  show(onSuccess?:any, onError?:any):any;
  takePicture(options?:any, onSuccess?:any, onError?:any):any;
  setColorEffect(effect:string, onSuccess?:any, onError?:any):any;
  setZoom(zoom?:any, onSuccess?:any, onError?:any):any;
  setPreviewSize(dimensions?:any, onSuccess?:any, onError?:any):any;
  getSupportedPictureSizes(onSuccess?:any, onError?:any):any;
  setFlashMode(flashMode:string, onSuccess?:any, onError?:any):any;
}
