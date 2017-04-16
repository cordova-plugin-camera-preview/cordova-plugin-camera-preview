interface CameraPreview {
  startCamera(options?:any, onSuccess?:any, onError?:any):any;
  stopCamera(onSuccess?:any, onError?:any):any;
  switchCamera(onSuccess?:any, onError?:any):any;
  hide(onSuccess?:any, onError?:any):any;
  show(onSuccess?:any, onError?:any):any;
  takePicture(options?:any, onSuccess?:any, onError?:any):any;
  setColorEffect(effect:string, onSuccess?:any, onError?:any):any;
  setZoom(zoom?:any, onSuccess?:any, onError?:any):any;
  getMaxZoom(onSuccess?:any, onError?:any):any;
  getZoom(onSuccess?:any, onError?:any):any;
  setPreviewSize(dimensions?:any, onSuccess?:any, onError?:any):any;
  getSupportedPictureSizes(onSuccess?:any, onError?:any):any;
  getExposureModes(onSuccess?:any, onError?:any):any;
  getExposureMode(onSuccess?:any, onError?:any):any;
  setExposureMode(exposureMode?:any, onSuccess?:any, onError?:any):any;
  getExposureCompensation(onSuccess?:any, onError?:any):any;
  setExposureCompensation(exposureCompensation?:any, onSuccess?:any, onError?:any):any;
  getExposureCompensationRange(onSuccess?:any, onError?:any):any;
  setFlashMode(flashMode:string, onSuccess?:any, onError?:any):any;
}
