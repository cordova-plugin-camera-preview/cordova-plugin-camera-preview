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

  private static final String TAG = "CameraPreview";

  private static final String COLOR_EFFECT_ACTION = "setColorEffect";
  private static final String ZOOM_ACTION = "setZoom";
  private static final String FLASH_MODE_ACTION = "setFlashMode";
  private static final String START_CAMERA_ACTION = "startCamera";
  private static final String STOP_CAMERA_ACTION = "stopCamera";
  private static final String PREVIEW_SIZE_ACTION = "setPreviewSize";
  private static final String SWITCH_CAMERA_ACTION = "switchCamera";
  private static final String TAKE_PICTURE_ACTION = "takePicture";
  private static final String SHOW_CAMERA_ACTION = "showCamera";
  private static final String HIDE_CAMERA_ACTION = "hideCamera";
  private static final String SUPPORTED_PICTURE_SIZES_ACTION = "getSupportedPictureSizes";

  private static final int CAM_REQ_CODE = 0;

  private static final String [] permissions = {
    Manifest.permission.CAMERA
  };

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

    if (START_CAMERA_ACTION.equals(action)) {
      if (cordova.hasPermission(permissions[0])) {
        return startCamera(args.getInt(0), args.getInt(1), args.getInt(2), args.getInt(3), args.getString(4), args.getBoolean(5), args.getBoolean(6), args.getBoolean(7), args.getString(8), callbackContext);
      } else {
        this.execCallback = callbackContext;
        this.execArgs = args;
        cordova.requestPermissions(this, CAM_REQ_CODE, permissions);
      }
    } else if (TAKE_PICTURE_ACTION.equals(action)) {
      return takePicture(args.getInt(0), args.getInt(1), args.getInt(2), callbackContext);
    } else if (COLOR_EFFECT_ACTION.equals(action)) {
      return setColorEffect(args.getString(0), callbackContext);
    } else if (ZOOM_ACTION.equals(action)) {
      return setZoom(args.getInt(0), callbackContext);
    } else if (PREVIEW_SIZE_ACTION.equals(action)) {
      return setPreviewSize(args.getInt(0), args.getInt(1), callbackContext);
    } else if (FLASH_MODE_ACTION.equals(action)) {
      return setFlashMode(args.getString(0), callbackContext);
    } else if (STOP_CAMERA_ACTION.equals(action)){
      return stopCamera(callbackContext);
    } else if (HIDE_CAMERA_ACTION.equals(action)) {
      return hideCamera(callbackContext);
    } else if (SHOW_CAMERA_ACTION.equals(action)) {
      return showCamera(callbackContext);
    } else if (SWITCH_CAMERA_ACTION.equals(action)) {
      return switchCamera(callbackContext);
    } else if (SUPPORTED_PICTURE_SIZES_ACTION.equals(action)) {
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
    if (requestCode == CAM_REQ_CODE) {
      startCamera(this.execArgs.getInt(0), this.execArgs.getInt(1), this.execArgs.getInt(2), this.execArgs.getInt(3), this.execArgs.getString(4), this.execArgs.getBoolean(5), this.execArgs.getBoolean(6), this.execArgs.getBoolean(7), this.execArgs.getString(8), this.execCallback);
    }
  }

  private boolean hasView(CallbackContext callbackContext) {
    if(fragment == null) {
      callbackContext.error("No preview");
      return false;
    }

    return true;
  }

  private boolean hasCamera(CallbackContext callbackContext) {
    if(this.hasView(callbackContext) == false){
      return false;
    }

    if(fragment.getCamera() == null) {
      callbackContext.error("No Camera");
      return false;
    }

    return true;
  }

  private boolean getSupportedPictureSizes(CallbackContext callbackContext) {
    if(this.hasCamera(callbackContext) == false){
      return true;
    }

    List<Camera.Size> supportedSizes;
    Camera camera = fragment.getCamera();

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
        catch(JSONException e){
          e.printStackTrace();
        }
        sizes.put(jsonSize);
      }
      callbackContext.success(sizes);
      return true;
    }

    callbackContext.error("Camera Parameters access error");
    return true;
  }

  private boolean startCamera(int x, int y, int width, int height, String defaultCamera, Boolean tapToTakePicture, Boolean dragEnabled, final Boolean toBack, String alpha, CallbackContext callbackContext) {
    Log.d(TAG, "start camera action");
    if (fragment != null) {
      callbackContext.error("Camera already started");
      return true;
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
    if(this.hasView(callbackContext) == false){
      return true;
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
    if(this.hasCamera(callbackContext) == false){
      return true;
    }

    Camera camera = fragment.getCamera();
    Camera.Parameters params = camera.getParameters();

    if (effect.equals(Camera.Parameters.EFFECT_AQUA)) {
      params.setColorEffect(Camera.Parameters.EFFECT_AQUA);
    } else if (effect.equals(Camera.Parameters.EFFECT_BLACKBOARD)) {
      params.setColorEffect(Camera.Parameters.EFFECT_BLACKBOARD);
    } else if (effect.equals(Camera.Parameters.EFFECT_MONO)) {
      params.setColorEffect(Camera.Parameters.EFFECT_MONO);
    } else if (effect.equals(Camera.Parameters.EFFECT_NEGATIVE)) {
      params.setColorEffect(Camera.Parameters.EFFECT_NEGATIVE);
    } else if (effect.equals(Camera.Parameters.EFFECT_NONE)) {
      params.setColorEffect(Camera.Parameters.EFFECT_NONE);
    } else if (effect.equals(Camera.Parameters.EFFECT_POSTERIZE)) {
      params.setColorEffect(Camera.Parameters.EFFECT_POSTERIZE);
    } else if (effect.equals(Camera.Parameters.EFFECT_SEPIA)) {
      params.setColorEffect(Camera.Parameters.EFFECT_SEPIA);
    } else if (effect.equals(Camera.Parameters.EFFECT_SOLARIZE)) {
      params.setColorEffect(Camera.Parameters.EFFECT_SOLARIZE);
    } else if (effect.equals(Camera.Parameters.EFFECT_WHITEBOARD)) {
      params.setColorEffect(Camera.Parameters.EFFECT_WHITEBOARD);
    } else {
      callbackContext.error("Color effect not supported" + effect);
      return true;
    }

    fragment.setCameraParameters(params);

    callbackContext.success(effect);
    return true;
  }

  private boolean setZoom(int zoom, CallbackContext callbackContext) {
    if(this.hasCamera(callbackContext) == false){
      return true;
    }

    Camera camera = fragment.getCamera();
    Camera.Parameters params = camera.getParameters();

    if (camera.getParameters().isZoomSupported()) {
      params.setZoom(zoom);
      fragment.setCameraParameters(params);

      callbackContext.success(zoom);
    } else {
      callbackContext.error("Zoom not supported");
    }

    return true;
  }

  private boolean setPreviewSize(int width, int height, CallbackContext callbackContext) {
    if(this.hasCamera(callbackContext) == false){
      return true;
    }

    Camera camera = fragment.getCamera();
    Camera.Parameters params = camera.getParameters();

    params.setPreviewSize(width, height);
    fragment.setCameraParameters(params);
    camera.startPreview();

    callbackContext.success();
    return true;
  }

  private boolean setFlashMode(String flashMode, CallbackContext callbackContext) {
    if(this.hasCamera(callbackContext) == false){
      return true;
    }

    Camera camera = fragment.getCamera();
    Camera.Parameters params = camera.getParameters();

    if (flashMode.equals(Camera.Parameters.FLASH_MODE_OFF)) {
      params.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
    } else if(flashMode.equals(Camera.Parameters.FLASH_MODE_ON)) {
      params.setFlashMode(Camera.Parameters.FLASH_MODE_ON);
    } else if(flashMode.equals(Camera.Parameters.FLASH_MODE_AUTO)) {
      params.setFlashMode(Camera.Parameters.FLASH_MODE_AUTO);
    } else if(flashMode.equals(Camera.Parameters.FLASH_MODE_TORCH)) {
      params.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);
    } else {
      callbackContext.error("Flash Mode not recognised" + flashMode);
      return true;
    }

    fragment.setCameraParameters(params);

    callbackContext.success(flashMode);
    return true;
  }

  private boolean stopCamera(CallbackContext callbackContext) {
    if(this.hasView(callbackContext) == false){
      return true;
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
    if(this.hasView(callbackContext) == false){
      return true;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.show(fragment);
    fragmentTransaction.commit();

    callbackContext.success();
    return true;
  }

  private boolean hideCamera(CallbackContext callbackContext) {
    if(this.hasView(callbackContext) == false){
      return true;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.hide(fragment);
    fragmentTransaction.commit();

    callbackContext.success();
    return true;
  }

  private boolean switchCamera(CallbackContext callbackContext) {
    if(this.hasView(callbackContext) == false){
      return true;
    }

    fragment.switchCamera();

    callbackContext.success();
    return true;
  }
}
