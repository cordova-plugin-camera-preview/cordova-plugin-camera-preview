package br.com.riachuelo.custom;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class CameraPreview extends CordovaPlugin {
	private final String TAG = "CameraPreview";
	private final String ACTION_BIND_LISTENER = "ACTION_BIND_LISTENER";
	private final String ACTION_START_CAMERA_ACTIVITY = "ACTION_START_CAMERA_ACTIVITY";
	
	private CallbackContext listenerCallbackContext;

	public HybridBridge(){
		super();
		Log.d(TAG, "Constructing");
	}
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
    	Log.d(TAG, "execute :: " + this.toString());
    	if (ACTION_BIND_LISTENER.equals(action)){
    		return bindListener(args, callbackContext);
    	}
        else if (ACTION_START_CAMERA_ACTIVITY.equals(action)){
    		return startCameraActivity(args, callbackContext);
    	}
    	
    	return false;
    }
	private boolean startCameraActivity(final JSONArray args, CallbackContext callbackContext) {

        cordova.getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Context context = cordova.getActivity().getApplicationContext();
                Intent intent = new Intent(context, CameraActivity.class);
                try {
                    intent.putExtra("collectionIdx", args.getInt(0));
                }
                catch(Exception ex){
                    ex.printStackTrace();
                }
                cordova.getActivity().startActivity(intent);
            }
        });
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
    /*
    private boolean setNavBarTitle(JSONArray args, CallbackContext callbackContext) throws JSONException {
    	Log.d(TAG, "setNavBarTitle");
    	PluginResult pluginResult;
    	if (args.length()==1){
    		String title = args.getString(0);
    		((Riachuelo)cordova).updateTitle(title);
    		pluginResult = new PluginResult(PluginResult.Status.OK);
    	}
        else {
    		pluginResult = new PluginResult(PluginResult.Status.INVALID_ACTION);
    	}
    	
    	callbackContext.sendPluginResult(pluginResult);
    	return true;
	}
*/
    public void reportEvent(JSONObject eventData){
    	Log.d(TAG, "reportEvent");
    	PluginResult pluginResult = new PluginResult(PluginResult.Status.OK, eventData);
    	pluginResult.setKeepCallback(true);
    	listenerCallbackContext.sendPluginResult(pluginResult);
    }
}
