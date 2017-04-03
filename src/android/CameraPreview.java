package com.cordovaplugincamerapreview;

import android.Manifest;
import android.content.pm.PackageManager;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import java.util.List;
import java.util.Arrays;

public class CameraPreview extends CordovaPlugin implements CameraActivity.CameraPreviewListener {

  private final String TAG = "CameraPreview";
  private final String setColorEffectAction = "setColorEffect";
  private final String setZoomAction = "setZoom";
  private final String setFlashModeAction = "setFlashMode";
  private final String startCameraAction = "startCamera";
  private final String stopCameraAction = "stopCamera";
  private final String previewSizeAction = "setPreviewSize";
  private final String switchCameraAction = "switchCamera";
  private final String takePictureAction = "takePicture";
  private final String showCameraAction = "showCamera";
  private final String hideCameraAction = "hideCamera";
  private final String getSupportedPictureSizesAction = "getSupportedPictureSizes";

  private final String [] permissions = {
    Manifest.permission.CAMERA
  };

  private final int permissionsReqId = 0;

  private CameraActivity fragment;
  private CallbackContext takePictureCallbackContext;

  private CallbackContext execCallback;
  private JSONArray execArgs;

  private int containerViewId = 1;
  public CameraPreview(){
    super();
    Log.d(TAG, "Constructing");
  }

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

    if (startCameraAction.equals(action)) {
      if (cordova.hasPermission(permissions[0])) {
        return startCamera(args.getInt(0), args.getInt(1), args.getInt(2), args.getInt(3), args.getString(4), args.getBoolean(5), args.getBoolean(6), args.getBoolean(7), args.getString(8), callbackContext);
      } else {
        this.execCallback = callbackContext;
        this.execArgs = args;
        cordova.requestPermissions(this, 0, permissions);
      }
    } else if (takePictureAction.equals(action)) {
      return takePicture(args.getInt(0), args.getInt(1), args.getInt(2), callbackContext);
    } else if (setColorEffectAction.equals(action)) {
      return setColorEffect(args.getString(0), callbackContext);
    } else if (setZoomAction.equals(action)) {
      return setZoom(args.getInt(0), callbackContext);
    } else if (previewSizeAction.equals(action)) {
      return setPreviewSize(args.getInt(0), args.getInt(1), callbackContext);
    } else if (setFlashModeAction.equals(action)) {
      return setFlashMode(args.getInt(0), callbackContext);
    } else if (stopCameraAction.equals(action)){
      return stopCamera(callbackContext);
    } else if (hideCameraAction.equals(action)) {
      return hideCamera(callbackContext);
    } else if (showCameraAction.equals(action)) {
      return showCamera(callbackContext);
    } else if (switchCameraAction.equals(action)) {
      return switchCamera(callbackContext);
    } else if (getSupportedPictureSizesAction.equals(action)) {
      return getSupportedPictureSizes(callbackContext);
    }

    return false;
  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    for(int r:grantResults){
      if(r == PackageManager.PERMISSION_DENIED){
        execCallback.sendPluginResult(new PluginResult(PluginResult.Status.ILLEGAL_ACCESS_EXCEPTION));
        return;
      }
    }
    if (requestCode == permissionsReqId) {
      startCamera(this.execArgs.getInt(0), this.execArgs.getInt(1), this.execArgs.getInt(2), this.execArgs.getInt(3), this.execArgs.getString(4), this.execArgs.getBoolean(5), this.execArgs.getBoolean(6), this.execArgs.getBoolean(7), this.execArgs.getString(8), this.execCallback);
    }
  }

  private boolean getSupportedPictureSizes(CallbackContext callbackContext) {
    List<Camera.Size> supportedSizes;
    Camera camera = fragment.getCamera();

    if (camera != null) {
      supportedSizes = camera.getParameters().getSupportedPictureSizes();
      if (supportedSizes != null) {
        JSONArray sizes = new JSONArray();
        for (int i=0; i<supportedSizes.size(); i++) {
          Camera.Size size = supportedSizes.get(i);
          int h = size.height;
          int w = size.width;
          JSONObject jsonSize = new JSONObject();
          try {
            jsonSize.put("height", new Integer(h));
            jsonSize.put("width", new Integer(w));
          }
          catch(Exception e){
            e.printStackTrace();
          }
          sizes.put(jsonSize);
        }
        callbackContext.success(sizes);
        return true;
      }
      callbackContext.error("Camera Parameters access error");
      return false;
    }
    callbackContext.error("Camera needs to be started first");
    return false;

  }

  private boolean startCamera(int x, int y, int width, int height, String defaultCamera, Boolean tapToTakePicture, Boolean dragEnabled, final Boolean toBack, String alpha, CallbackContext callbackContext) {
    Log.d(TAG, "start camera action");
    if (fragment != null) {
      callbackContext.error("Camera already started");
      return false;
    }

    final float opacity = Float.parseFloat(alpha);

    fragment = new CameraActivity();
    fragment.setEventListener(this);
    fragment.defaultCamera = defaultCamera;
    fragment.tapToTakePicture = tapToTakePicture;
    fragment.dragEnabled = dragEnabled;

    DisplayMetrics metrics = cordova.getActivity().getResources().getDisplayMetrics();
    // offset
    int computedX = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, x, metrics);
    int computedY = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, y, metrics);

    // size
    int computedWidth = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, width, metrics);
    int computedHeight = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, height, metrics);

    fragment.setRect(computedX, computedY, computedWidth, computedHeight);

    final CallbackContext cb = callbackContext;

    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {


        //create or update the layout params for the container view
        FrameLayout containerView = (FrameLayout)cordova.getActivity().findViewById(containerViewId);
        if(containerView == null){
          containerView = new FrameLayout(cordova.getActivity().getApplicationContext());
          containerView.setId(containerViewId);

          FrameLayout.LayoutParams containerLayoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
          cordova.getActivity().addContentView(containerView, containerLayoutParams);
        }
        //display camera bellow the webview
        if(toBack){
          webView.getView().setBackgroundColor(0x00000000);
          ((ViewGroup)webView.getView()).bringToFront();
        }else{
          //set camera back to front
          containerView.setAlpha(opacity);
          containerView.bringToFront();
        }

        //add the fragment to the container
        FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.add(containerView.getId(), fragment);
        fragmentTransaction.commit();

        cb.success("Camera started");
      }
    });

    return true;
  }

  private boolean takePicture(int width, int height, int quality, CallbackContext callbackContext) {
    if(fragment == null){
      callbackContext.error("No preview");
      return false;
    }

    takePictureCallbackContext = callbackContext;

    fragment.takePicture(width, height, quality);

    return true;
  }

  public void onPictureTaken(String originalPicture) {
    Log.d(TAG, "returning picture");

    JSONArray data = new JSONArray();
    data.put(originalPicture);

    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, data);
    pluginResult.setKeepCallback(true);
    takePictureCallbackContext.sendPluginResult(pluginResult);
  }

  public void onPictureTakenError(String message) {
    Log.d(TAG, "CameraPreview onPictureTakenError");
    takePictureCallbackContext.error(message);
  }

  private boolean setColorEffect(String effect, CallbackContext callbackContext) {
    if(fragment == null){
      callbackContext.error("No preview");
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null){
      callbackContext.error("No camera");
      return true;
    }

    Camera.Parameters params = camera.getParameters();

    if (effect.equals("aqua")) {
      params.setColorEffect(Camera.Parameters.EFFECT_AQUA);
    } else if (effect.equals("blackboard")) {
      params.setColorEffect(Camera.Parameters.EFFECT_BLACKBOARD);
    } else if (effect.equals("mono")) {
      params.setColorEffect(Camera.Parameters.EFFECT_MONO);
    } else if (effect.equals("negative")) {
      params.setColorEffect(Camera.Parameters.EFFECT_NEGATIVE);
    } else if (effect.equals("none")) {
      params.setColorEffect(Camera.Parameters.EFFECT_NONE);
    } else if (effect.equals("posterize")) {
      params.setColorEffect(Camera.Parameters.EFFECT_POSTERIZE);
    } else if (effect.equals("sepia")) {
      params.setColorEffect(Camera.Parameters.EFFECT_SEPIA);
    } else if (effect.equals("solarize")) {
      params.setColorEffect(Camera.Parameters.EFFECT_SOLARIZE);
    } else if (effect.equals("whiteboard")) {
      params.setColorEffect(Camera.Parameters.EFFECT_WHITEBOARD);
    }

    fragment.setCameraParameters(params);
    callbackContext.success(effect);
    return true;
  }

  private boolean setZoom(int zoom, CallbackContext callbackContext) {

    if (fragment == null) {
      callbackContext.error("No preview");
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      callbackContext.error("No camera");
      return false;
    }

    Camera.Parameters params = camera.getParameters();

    if (camera.getParameters().isZoomSupported()) {
      params.setZoom(zoom);
      fragment.setCameraParameters(params);
      callbackContext.success(zoom);
      return true;
    } else {
      callbackContext.error("Zoom not supported");
      return false;
    }
  }

  private boolean setPreviewSize(int width, int height, CallbackContext callbackContext) {
    if (fragment == null) {
      callbackContext.error("No preview");
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      callbackContext.error("No camera");
      return false;
    }

    Camera.Parameters params = camera.getParameters();

    params.setPreviewSize(width, height);
    fragment.setCameraParameters(params);
    camera.startPreview();

    callbackContext.success();
    return true;
  }

  private boolean setFlashMode(int mode, CallbackContext callbackContext) {
    if (fragment == null) {
      callbackContext.error("No preview");
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      callbackContext.error("No camera");
      return false;
    }

    Camera.Parameters params = camera.getParameters();

    switch(mode) {
      case 0:
        params.setFlashMode(params.FLASH_MODE_OFF);
        break;

      case 1:
        params.setFlashMode(params.FLASH_MODE_ON);
        break;

      case 2:
        params.setFlashMode(params.FLASH_MODE_AUTO);
        break;

      case 3:
        params.setFlashMode(params.FLASH_MODE_TORCH);
        break;
    }

    fragment.setCameraParameters(params);

    callbackContext.success(mode);
    return true;
  }

  private boolean stopCamera(CallbackContext callbackContext) {
    if(fragment == null){
      callbackContext.error("No preview");
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.remove(fragment);
    fragmentTransaction.commit();
    fragment = null;

    callbackContext.success();
    return true;
  }

  private boolean showCamera(CallbackContext callbackContext) {
    if(fragment == null){
      callbackContext.error("No preview");
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.show(fragment);
    fragmentTransaction.commit();

    callbackContext.success();
    return true;
  }
  private boolean hideCamera(CallbackContext callbackContext) {
    if(fragment == null) {
      callbackContext.error("No preview");
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.hide(fragment);
    fragmentTransaction.commit();

    callbackContext.success();
    return true;
  }
  private boolean switchCamera(CallbackContext callbackContext) {
    if(fragment == null){
      callbackContext.error("No preview");
      return false;
    }
    fragment.switchCamera();
    callbackContext.success();
    return true;
  }
}
