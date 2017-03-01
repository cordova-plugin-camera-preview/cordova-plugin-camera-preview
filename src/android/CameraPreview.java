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
  private final String setOnPictureTakenHandlerAction = "setOnPictureTakenHandler";
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

  private final String getSupportedPreviewSizesAction = "getSupportedPreviewSizes";
  private final String getSupportedPictureSizesAction = "getSupportedPictureSizes";    


  private final String [] permissions = {
    Manifest.permission.CAMERA,
    Manifest.permission.READ_EXTERNAL_STORAGE,
    Manifest.permission.WRITE_EXTERNAL_STORAGE
  };

  private final int permissionsReqId = 0;

  private CameraActivity fragment;
  private CallbackContext takePictureCallbackContext;
  private CallbackContext wLogCallbackContext;

  private CallbackContext execCallback;
  private JSONArray execArgs;

  private int containerViewId = 1;
  public CameraPreview(){
    super();
    Log.d(TAG, "Constructing");
  }

  @Override
  public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

    if (setOnPictureTakenHandlerAction.equals(action)){
      return setOnPictureTakenHandler(args, callbackContext);
    } else if (startCameraAction.equals(action)) {
      if (cordova.hasPermission(permissions[0])) {
        return startCamera(args, callbackContext);
      }
      else {
        execCallback = callbackContext;
        execArgs = args;
        cordova.requestPermissions(this, 0, permissions);
      }
    } else if (takePictureAction.equals(action)) {
      return takePicture(args, callbackContext);
    } else if (setColorEffectAction.equals(action)) {
      return setColorEffect(args, callbackContext);
    } else if (setZoomAction.equals(action)) {
      return setZoom(args, callbackContext);
    } else if (previewSizeAction.equals(action)) {
      return setPreviewSize(args, callbackContext);
    } else if (setFlashModeAction.equals(action)) {
      return setFlashMode(args, callbackContext);
    } else if (stopCameraAction.equals(action)){
      return stopCamera(args, callbackContext);
    } else if (hideCameraAction.equals(action)) {
      return hideCamera(args, callbackContext);
    } else if (showCameraAction.equals(action)) {
      return showCamera(args, callbackContext);
    } else if (switchCameraAction.equals(action)) {
      return switchCamera(args, callbackContext);
    } else if (getSupportedPreviewSizesAction.equals(action)) {
      return getSupportedResolutions("previews", callbackContext);
    } else if (getSupportedPictureSizesAction.equals(action)) {
      return getSupportedResolutions("pictures", callbackContext);
    }        

    return false;
  }

  @Override
  public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults) throws JSONException {
    for(int r:grantResults)
    {
      if(r == PackageManager.PERMISSION_DENIED)
      {
        execCallback.sendPluginResult(new PluginResult(PluginResult.Status.ILLEGAL_ACCESS_EXCEPTION));
        return;
      }
    }
    if (requestCode == permissionsReqId) {
      startCamera(execArgs, execCallback);
    }
  }

  private boolean getSupportedResolutions(final String type, CallbackContext callbackContext) {

    List<Camera.Size> supportedSizes;
    Camera camera = fragment.getCamera();

    if (camera != null) {
      supportedSizes = (type.equals("previews")) ? camera.getParameters().getSupportedPreviewSizes() : camera.getParameters().getSupportedPictureSizes();
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

  private boolean startCamera(final JSONArray args, CallbackContext callbackContext) {
    Log.d(TAG, "start camera action");
    if (fragment != null) {
      callbackContext.error("Camera already started");
      return false;
    }
    fragment = new CameraActivity();
    fragment.setEventListener(this);
    final CallbackContext cb = callbackContext;

    cordova.getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {

        try {
          DisplayMetrics metrics = cordova.getActivity().getResources().getDisplayMetrics();
          // offset
          int x = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(0), metrics);
          int y = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(1), metrics);

          // size
          int width = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(2), metrics);
          int height = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(3), metrics);

          String defaultCamera = args.getString(4);
          Boolean tapToTakePicture = args.getBoolean(5);
          Boolean dragEnabled = args.getBoolean(6);
          Boolean toBack = args.getBoolean(7);

          fragment.defaultCamera = defaultCamera;
          fragment.tapToTakePicture = tapToTakePicture;
          fragment.dragEnabled = dragEnabled;
          fragment.setRect(x, y, width, height);

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
            containerView.setAlpha(Float.parseFloat(args.getString(8)));
            containerView.bringToFront();
          }

          //add the fragment to the container
          FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
          FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
          fragmentTransaction.add(containerView.getId(), fragment);
          fragmentTransaction.commit();

          cb.success("Camera started");
        } catch (Exception e) {
          e.printStackTrace();
          cb.error("Camera start error");                    
        }
      }
    });
    return true;
  }

  private String invertCamera(String originalCamera){
    return originalCamera == "front" ? "back" : "front";
  }

  private boolean takePicture(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null){
      return false;
    }
    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
    pluginResult.setKeepCallback(true);
    callbackContext.sendPluginResult(pluginResult);
    try {
      double maxWidth = 0;
      double maxHeight = 0;
      fragment.takePicture(maxWidth, maxHeight);
    } catch (Exception e) {
      e.printStackTrace();
      return false;
    }
    return true;
  }

  public void onPictureTaken(String originalPicture) {
    JSONArray data = new JSONArray();
    data.put(originalPicture);
    PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, data);
    pluginResult.setKeepCallback(true);
    takePictureCallbackContext.sendPluginResult(pluginResult);
  }

  private boolean setColorEffect(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null){
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null){
      return true;
    }

    Camera.Parameters params = camera.getParameters();

    try {
      String effect = args.getString(0);

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
      return true;
    } catch(Exception e) {
      e.printStackTrace();
      return false;
    }
  }

  private boolean setZoom(final JSONArray args, CallbackContext callbackContext) {

    if (fragment == null) {
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      return false;
    }

    Camera.Parameters params = camera.getParameters();

    try {
      int zoom = (int) args.getInt(0);
      if (camera.getParameters().isZoomSupported()) {
        params.setZoom(zoom);
        fragment.setCameraParameters(params);
      }

      return true;
    } catch (Exception e) {
      e.printStackTrace();
      return false;
    }
  }

  private boolean setPreviewSize(final JSONArray args, CallbackContext callbackContext) {
    if (fragment == null) {
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      return false;
    }

    Camera.Parameters params = camera.getParameters();
    try {
      int width = (int) args.getInt(0);
      int height = (int) args.getInt(1);

      params.setPreviewSize(width, height);
      fragment.setCameraParameters(params);
      camera.startPreview();

      return true;
    } catch (Exception e) {
      e.printStackTrace();

      return false;
    }
  }

  private boolean setFlashMode(final JSONArray args, CallbackContext callbackContext) {
    if (fragment == null) {
      return false;
    }

    Camera camera = fragment.getCamera();
    if (camera == null) {
      return false;
    }

    Camera.Parameters params = camera.getParameters();

    try {
      int mode = (int) args.getInt(0);

      switch(mode) {
        case 0:
          params.setFlashMode(params.FLASH_MODE_OFF);
          break;

        case 1:
          params.setFlashMode(params.FLASH_MODE_ON);
          break;

        case 2:
          params.setFlashMode(params.FLASH_MODE_TORCH);
          break;

        case 3:
          params.setFlashMode(params.FLASH_MODE_AUTO);
          break;
      }

      fragment.setCameraParameters(params);

      return true;
    } catch (Exception e) {
      e.printStackTrace();

      return false;
    }
  }

  private boolean stopCamera(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null){
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.remove(fragment);
    fragmentTransaction.commit();
    fragment = null;

    return true;
  }

  private boolean showCamera(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null){
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.show(fragment);
    fragmentTransaction.commit();

    return true;
  }
  private boolean hideCamera(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null) {
      return false;
    }

    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
    fragmentTransaction.hide(fragment);
    fragmentTransaction.commit();

    return true;
  }
  private boolean switchCamera(final JSONArray args, CallbackContext callbackContext) {
    if(fragment == null){
      return false;
    }
    fragment.switchCamera();
    return true;
  }

  private boolean setOnPictureTakenHandler(JSONArray args, CallbackContext callbackContext) {
    Log.d(TAG, "setOnPictureTakenHandler");
    takePictureCallbackContext = callbackContext;
    return true;
  }
}
