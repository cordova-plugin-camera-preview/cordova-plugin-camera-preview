package com.mbppower;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.widget.FrameLayout;
import android.widget.LinearLayout;

public class CameraPreview extends CordovaPlugin implements CameraActivity.CameraPreviewListener {

	private final String TAG = "CameraPreview";
	private final String bindListenerAction = "bindListener";
	private final String startCameraAction = "startCamera";
	private final String stopCameraAction = "stopCamera";
	private final String switchCameraAction = "switchCamera";
	private final String takePictureAction = "takePicture";
	private final String showCameraAction = "showCamera";
	private final String hideCameraAction = "hideCamera";

	private CameraActivity fragment;
	private CallbackContext takePictureCallbackContext;
	private CallbackContext listenerCallbackContext;

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

	            FrameLayout containerView = new FrameLayout(cordova.getActivity().getApplicationContext());
				try {

					FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(args.getInt(2), args.getInt(3));
					layoutParams.setMargins(args.getInt(0), args.getInt(1), 0, 0);

					cordova.getActivity().addContentView(containerView, layoutParams);
					containerView.setId(666);

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
