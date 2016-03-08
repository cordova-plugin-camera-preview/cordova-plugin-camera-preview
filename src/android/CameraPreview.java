package com.mbppower;

import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;

public class CameraPreview extends CordovaPlugin implements CameraActivity.CameraPreviewListener {


    private final String TAG = "CameraPreview";
    private final String setOnPictureTakenHandlerAction = "setOnPictureTakenHandler";
    private final String setColorEffectAction = "setColorEffect";
    private final String startCameraAction = "startCamera";
    private final String stopCameraAction = "stopCamera";
    private final String switchCameraAction = "switchCamera";
    private final String takePictureAction = "takePicture";
    private final String showCameraAction = "showCamera";
    private final String hideCameraAction = "hideCamera";

    private CameraActivity fragment;
    private CallbackContext takePictureCallbackContext;
    private CallbackContext wLogCallbackContext;
    private int containerViewId = 1;

    public CameraPreview() {
        super();
        Log.d(TAG, "Constructing");
    }

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        if (setOnPictureTakenHandlerAction.equals(action)) {
            return setOnPictureTakenHandler(args, callbackContext);
        } else if (startCameraAction.equals(action)) {
            return startCamera(args, callbackContext);
        } else if (takePictureAction.equals(action)) {
            return takePicture(args, callbackContext);
        } else if (setColorEffectAction.equals(action)) {
            return setColorEffect(args, callbackContext);
        } else if (stopCameraAction.equals(action)) {
            return stopCamera(args, callbackContext);
        } else if (hideCameraAction.equals(action)) {
            return hideCamera(args, callbackContext);
        } else if (showCameraAction.equals(action)) {
            return showCamera(args, callbackContext);
        } else if (switchCameraAction.equals(action)) {
            return switchCamera(args, callbackContext);
        }

        return false;
    }

    private boolean startCamera(final JSONArray args, CallbackContext callbackContext) {
        Log.d(TAG, "start camera action");
        if (fragment != null) {
            return false;
        }
        fragment = new CameraActivity();
        fragment.setEventListener(this);

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
                    //String defaultCamera = invertCamera(args.getString(4));
                    Boolean tapToTakePicture = args.getBoolean(5);
                    Boolean dragEnabled = args.getBoolean(6);
                    Boolean toBack = args.getBoolean(7);

                    fragment.defaultCamera = defaultCamera;
                    fragment.tapToTakePicture = tapToTakePicture;
                    fragment.dragEnabled = dragEnabled;
                    fragment.setRect(x, y, width, height);

                    //create or update the layout params for the container view
                    FrameLayout containerView = (FrameLayout) cordova.getActivity().findViewById(containerViewId);
                    if (containerView == null) {
                        containerView = new FrameLayout(cordova.getActivity().getApplicationContext());
                        containerView.setId(containerViewId);

                        FrameLayout.LayoutParams containerLayoutParams = new FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT);
                        cordova.getActivity().addContentView(containerView, containerLayoutParams);
                    }
                    //display camera bellow the webview
                    if (toBack) {
                        webView.getView().setBackgroundColor(0x00000000);
                        ((ViewGroup)webView.getView()).bringToFront();

                        webView.getView().setOnTouchListener(new View.OnTouchListener() {
                            @Override
                            public boolean onTouch(View view, MotionEvent motionEvent) {
                                if (fragment != null) {
                                    fragment.passMotionEvent(motionEvent);
                                }
                                return false;
                            }
                        });
                    } else {
                        //set camera back to front
                        containerView.bringToFront();
                    }

                    //add the fragment to the container
                    FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
                    FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
                    fragmentTransaction.add(containerView.getId(), fragment);
                    fragmentTransaction.commit();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });

        return true;
    }

    private String invertCamera(String originalCamera){
        return originalCamera == "front" ? "back" : "front";
    }

    private boolean takePicture(final JSONArray args, CallbackContext callbackContext) {
        if (fragment == null) {
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
        if (fragment == null) {
            return false;
        }

        Camera camera = fragment.getCamera();
        if (camera == null) {
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
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private boolean stopCamera(final JSONArray args, CallbackContext callbackContext) {
        if (fragment == null) {
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
        if (fragment == null) {
            return false;
        }

        FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.show(fragment);
        fragmentTransaction.commit();

        return true;
    }

    private boolean hideCamera(final JSONArray args, CallbackContext callbackContext) {
        if (fragment == null) {
            return false;
        }

        FragmentManager fragmentManager = cordova.getActivity().getFragmentManager();
        FragmentTransaction fragmentTransaction = fragmentManager.beginTransaction();
        fragmentTransaction.hide(fragment);
        fragmentTransaction.commit();

        return true;
    }

    private boolean switchCamera(final JSONArray args, CallbackContext callbackContext) {
        if (fragment == null) {
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
