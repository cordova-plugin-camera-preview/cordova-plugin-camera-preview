package com.cordovaplugincamerapreview;

import android.app.Activity;
import android.graphics.Color;
import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import java.io.IOException;

class Preview extends ViewGroup implements SurfaceHolder.Callback {
  private final String TAG = "PP/Preview";

  CustomSurfaceView mSurfaceView;
  SurfaceHolder mHolder;
  double previewRatio;
  Camera mCamera;
  int cameraId;
  int displayOrientation;
  int facing = Camera.CameraInfo.CAMERA_FACING_BACK;
  int viewWidth;
  int viewHeight;

  Preview(Activity context) {
    super(context);

    mSurfaceView = new CustomSurfaceView(context);
    addView(mSurfaceView);

    requestLayout();

    setBackgroundColor(Color.BLUE);

    // Install a SurfaceHolder.Callback so we get notified when the
    // underlying surface is created and destroyed.
    mHolder = mSurfaceView.getHolder();
    mHolder.addCallback(this);
    mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);

  }

  public void setCamera(Camera camera) {
    if (mCamera == camera) { return; }

    //stopPreviewAndFreeCamera();

    mCamera = camera;

    if (camera != null) {

      try {
        mCamera.setPreviewDisplay(mHolder);
      } catch (IOException e) {
        e.printStackTrace();
      }

      // Important: Call startPreview() to start updating the preview
      // surface. Preview must be started before you can take a picture.
      mCamera.startPreview();
      setCameraDisplayOrientation();

    }
  }

  public int getDisplayOrientation() {
    return displayOrientation;
  }
  
  public int getCameraFacing() {
    return facing;
  }

  private void setCameraDisplayOrientation() {
    Camera.CameraInfo info = new Camera.CameraInfo();
    int rotation = ((Activity) getContext()).getWindowManager().getDefaultDisplay().getRotation();
    int degrees = 0;
    DisplayMetrics dm = new DisplayMetrics();

    Camera.getCameraInfo(cameraId, info);
    ((Activity) getContext()).getWindowManager().getDefaultDisplay().getMetrics(dm);

    switch (rotation) {
      case Surface.ROTATION_0:
        degrees = 0;
        break;
      case Surface.ROTATION_90:
        degrees = 90;
        break;
      case Surface.ROTATION_180:
        degrees = 180;
        break;
      case Surface.ROTATION_270:
        degrees = 270;
        break;
    }
    facing = info.facing;
    if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
      displayOrientation = (info.orientation + degrees) % 360;
      displayOrientation = (360 - displayOrientation) % 360;
    } else {
      displayOrientation = (info.orientation - degrees + 360) % 360;
    }

    Log.d(TAG, "screen is rotated " + degrees + "deg from natural");
    Log.d(TAG, (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT ? "front" : "back") + " camera is oriented -" + info.orientation + "deg from natural");
    Log.d(TAG, "need to rotate preview " + displayOrientation + "deg");
    mCamera.setDisplayOrientation(displayOrientation);
  }

  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {

    // We purposely disregard child measurements because act as a
    // wrapper to a SurfaceView that centers the camera preview instead
    // of stretching it.
    final int width = resolveSize(getSuggestedMinimumWidth(), widthMeasureSpec);
    final int height = resolveSize(getSuggestedMinimumHeight(), heightMeasureSpec);

    Log.d(TAG, "onMeasure width: "+width+" height: "+height);
    FrameLayout parent = (FrameLayout) getParent();

    final int parentWidth = parent.getWidth();
    final int parentHeight = parent.getHeight();

    Log.d(TAG, "onMeasure parentwidth: "+parentWidth+" parentheight: "+parentHeight);

    int nW = 0;
    int nH = 0;

    if(parentHeight > parentWidth) {
      nW = parentWidth;
      nH = (int) Math.round(parentWidth * previewRatio);
    }else{
      nW = (int) Math.round(parentHeight / previewRatio);
      nH = parentHeight;
    }
    viewHeight = nH;
    viewWidth = nW;
    setMeasuredDimension(nW, nH);

  }

  @Override
  protected void onLayout(boolean changed, int l, int t, int r, int b) {
    Log.d(TAG, "onLayout");

    if (changed && getChildCount() > 0) {
      final View child = getChildAt(0);
        child.layout(0, 0, viewWidth, viewHeight);
    }
  }

  public void surfaceCreated(SurfaceHolder holder) {
    Log.d(TAG, "surfaceCreated");

    // The Surface has been created, acquire the camera and tell it where
    // to draw.
    try {
      if (mCamera != null) {
        mSurfaceView.setWillNotDraw(false);
        mCamera.setPreviewDisplay(holder);
      }
    } catch (Exception exception) {
      Log.e(TAG, "Exception caused by setPreviewDisplay()", exception);
    }
  }

  public void surfaceDestroyed(SurfaceHolder holder) {
    Log.d(TAG, "surfaceDestroyed");

    // Surface will be destroyed when we return, so stop the preview.
    if (mCamera != null) {
      // Call stopPreview() to stop updating the preview surface.
      mCamera.stopPreview();
    }
  }

  public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
    Log.d(TAG, "surfaceChanged");

    if(mCamera != null) {
      try {

        requestLayout();
        setCameraDisplayOrientation();

      } catch (Exception exception) {
        Log.e(TAG, "Exception caused by surfaceChanged()", exception);
      }
    }
  }

}
