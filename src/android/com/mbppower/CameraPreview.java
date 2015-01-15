package com.mbppower;

import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.widget.FrameLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class CameraPreview extends CordovaPlugin implements CameraActivity.CameraPreviewListener {

	private final String TAG = "CameraPreview";
	private final String bindListenerAction = "bindListener";
	private final String setColorEffectAction = "setColorEffect";
	private final String startCameraAction = "startCamera";
	private final String stopCameraAction = "stopCamera";
	private final String switchCameraAction = "switchCamera";
	private final String takePictureAction = "takePicture";
	private final String showCameraAction = "showCamera";
	private final String hideCameraAction = "hideCamera";

	private CameraActivity fragment;
	private CallbackContext takePictureCallbackContext;
	private CallbackContext listenerCallbackContext;
	private int containerViewId = 1;
	public CameraPreview(){
		super();
		Log.d(TAG, "Constructing");
	}

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

    	if (bindListenerAction.equals(action)){
    		return bindListener(args, callbackContext);
    	}
        else if (startCameraAction.equals(action)){
    		return startCamera(args, callbackContext);
    	}
	    else if (takePictureAction.equals(action)){
		    return takePicture(args, callbackContext);
	    }
	    else if (setColorEffectAction.equals(action)){
	      return setColorEffect(args, callbackContext);
	    }
	    else if (stopCameraAction.equals(action)){
		    return stopCamera(args, callbackContext);
	    }
	    else if (hideCameraAction.equals(action)){
		    return hideCamera(args, callbackContext);
	    }
	    else if (showCameraAction.equals(action)){
		    return showCamera(args, callbackContext);
	    }
	    else if (switchCameraAction.equals(action)){
		    return switchCamera(args, callbackContext);
	    }
    	
    	return false;
    }

	private boolean startCamera(final JSONArray args, CallbackContext callbackContext) {
        if(fragment != null){
	        return false;
        }
		fragment = new CameraActivity();
		fragment.setEventListener(this);

		cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {

				try {
					DisplayMetrics metrics = cordova.getActivity().getResources().getDisplayMetrics();
					int x = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(0), metrics);
					int y = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(1), metrics);
					int width = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(2), metrics);
					int height = (int) TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, args.getInt(3), metrics);
					String defaultCamera = args.getString(4);
					
					fragment.defaultCamera = defaultCamera;
					
					FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(width, height);
					layoutParams.setMargins(x, y, 0, 0);

					//create or update the layout params for the container view
					FrameLayout containerView = (FrameLayout)cordova.getActivity().findViewById(containerViewId);
					if(containerView == null){
						containerView = new FrameLayout(cordova.getActivity().getApplicationContext());
						containerView.setId(containerViewId);
						cordova.getActivity().addContentView(containerView, layoutParams);
					}
					else{
						containerView.setLayoutParams(layoutParams);
					}

					//add the fragment to the container
					FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
					FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
					fragmentTransaction.add(containerView.getId(), fragment);
					fragmentTransaction.commit();
				}
				catch(Exception e){
					e.printStackTrace();
				}
            }
        });
		return true;
	}
	private boolean takePicture(final JSONArray args, CallbackContext callbackContext) {
		if(fragment == null){
			return false;
		}
		takePictureCallbackContext = callbackContext;
		PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
		pluginResult.setKeepCallback(true);
		callbackContext.sendPluginResult(pluginResult);
		fragment.takePicture();
		return true;
	}
	public void onPictureTaken(String originalPicturePath, String previewPicturePath){
		JSONArray data = new JSONArray();
		data.put(originalPicturePath).put(previewPicturePath);
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

    private boolean bindListener(JSONArray args, CallbackContext callbackContext) {
    	Log.d(TAG, "bindListener");
    	listenerCallbackContext = callbackContext;
    	PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
    	pluginResult.setKeepCallback(true);
    	callbackContext.sendPluginResult(pluginResult);
    	return true;
	}

    public void reportEvent(JSONObject eventData){
    	Log.d(TAG, "reportEvent");
    	PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, eventData);
    	pluginResult.setKeepCallback(true);
    	listenerCallbackContext.sendPluginResult(pluginResult);
    }
}
