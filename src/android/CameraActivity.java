package com.cordovaplugincamerapreview;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.app.Fragment;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.util.Base64;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.ShutterCallback;
import android.os.Bundle;
import android.util.Log;
import android.util.DisplayMetrics;
import android.view.GestureDetector;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import org.apache.cordova.LOG;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.Exception;
import java.lang.Integer;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

public class CameraActivity extends Fragment {

  public interface CameraPreviewListener {
    void onPictureTaken(String originalPicture);
  }

  private CameraPreviewListener eventListener;
  private static final String TAG = "CameraActivity";
  public FrameLayout mainLayout;
  public FrameLayout frameContainerLayout;

  private Preview mPreview;
  private boolean canTakePicture = true;

  private View view;
  private Camera.Parameters cameraParameters;
  private Camera mCamera;
  private int numberOfCameras;
  private int cameraCurrentlyLocked;

  // The first rear facing camera
  private int defaultCameraId;
  public String defaultCamera;
  public boolean tapToTakePicture;
  public boolean dragEnabled;

  public int width;
  public int height;
  public int x;
  public int y;

  public void setEventListener(CameraPreviewListener listener){
    eventListener = listener;
  }

  private String appResourcesPackage;

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    appResourcesPackage = getActivity().getPackageName();

    // Inflate the layout for this fragment
    view = inflater.inflate(getResources().getIdentifier("camera_activity", "layout", appResourcesPackage), container, false);
    createCameraPreview();
    return view;
  }

  public void setRect(int x, int y, int width, int height){
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  private void createCameraPreview(){
    if(mPreview == null) {
      setDefaultCameraId();

      //set box position and size
      FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(width, height);
      layoutParams.setMargins(x, y, 0, 0);
      frameContainerLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("frame_container", "id", appResourcesPackage));
      frameContainerLayout.setLayoutParams(layoutParams);

      //video view
      mPreview = new Preview(getActivity());
      mainLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("video_view", "id", appResourcesPackage));
      mainLayout.setLayoutParams(new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT));
      mainLayout.addView(mPreview);
      mainLayout.setEnabled(false);

      final GestureDetector gestureDetector = new GestureDetector(getActivity().getApplicationContext(), new TapGestureDetector());

      getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          frameContainerLayout.setClickable(true);
          frameContainerLayout.setOnTouchListener(new View.OnTouchListener() {

            private int mLastTouchX;
            private int mLastTouchY;
            private int mPosX = 0;
            private int mPosY = 0;

            @Override
            public boolean onTouch(View v, MotionEvent event) {
              FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) frameContainerLayout.getLayoutParams();


              boolean isSingleTapTouch = gestureDetector.onTouchEvent(event);
              if (event.getAction() != MotionEvent.ACTION_MOVE && isSingleTapTouch) {
                if (tapToTakePicture) {
                  takePicture(0, 0, 85);
                }
                return true;
              } else {
                if (dragEnabled) {
                  int x;
                  int y;

                  switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                      if(mLastTouchX == 0 || mLastTouchY == 0) {
                        mLastTouchX = (int)event.getRawX() - layoutParams.leftMargin;
                        mLastTouchY = (int)event.getRawY() - layoutParams.topMargin;
                      }
                      else{
                        mLastTouchX = (int)event.getRawX();
                        mLastTouchY = (int)event.getRawY();
                      }
                      break;
                    case MotionEvent.ACTION_MOVE:

                      x = (int) event.getRawX();
                      y = (int) event.getRawY();

                      final float dx = x - mLastTouchX;
                      final float dy = y - mLastTouchY;

                      mPosX += dx;
                      mPosY += dy;

                      layoutParams.leftMargin = mPosX;
                      layoutParams.topMargin = mPosY;

                      frameContainerLayout.setLayoutParams(layoutParams);

                      // Remember this touch position for the next move event
                      mLastTouchX = x;
                      mLastTouchY = y;

                      break;
                    default:
                      break;
                  }
                }
              }
              return true;
            }
          });
        }
      });
    }
  }

  private void setDefaultCameraId(){

    // Find the total number of cameras available
    numberOfCameras = Camera.getNumberOfCameras();

    int camId = defaultCamera.equals("front") ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK;

    // Find the ID of the default camera
    Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
    for (int i = 0; i < numberOfCameras; i++) {
      Camera.getCameraInfo(i, cameraInfo);
      if (cameraInfo.facing == camId) {
        defaultCameraId = camId;
        break;
      }
    }
  }

  @Override
  public void onResume() {
    super.onResume();

    mCamera = Camera.open(defaultCameraId);

    if (cameraParameters != null) {
      mCamera.setParameters(cameraParameters);
    }

    cameraCurrentlyLocked = defaultCameraId;

    if(mPreview.mPreviewSize == null){
      mPreview.setCamera(mCamera, cameraCurrentlyLocked);
    } else {
      mPreview.switchCamera(mCamera, cameraCurrentlyLocked);
      mCamera.startPreview();
    }

    Log.d(TAG, "cameraCurrentlyLocked:" + cameraCurrentlyLocked);

    final FrameLayout frameContainerLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("frame_container", "id", appResourcesPackage));
    ViewTreeObserver viewTreeObserver = frameContainerLayout.getViewTreeObserver();
    if (viewTreeObserver.isAlive()) {
      viewTreeObserver.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
        @Override
        public void onGlobalLayout() {
          frameContainerLayout.getViewTreeObserver().removeGlobalOnLayoutListener(this);
          frameContainerLayout.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
          final RelativeLayout frameCamContainerLayout = (RelativeLayout) view.findViewById(getResources().getIdentifier("frame_camera_cont", "id", appResourcesPackage));

          FrameLayout.LayoutParams camViewLayout = new FrameLayout.LayoutParams(frameContainerLayout.getWidth(), frameContainerLayout.getHeight());
          camViewLayout.gravity = Gravity.CENTER_HORIZONTAL | Gravity.CENTER_VERTICAL;
          frameCamContainerLayout.setLayoutParams(camViewLayout);
        }
      });
    }
  }

  @Override
  public void onPause() {
    super.onPause();

    // Because the Camera object is a shared resource, it's very important to release it when the activity is paused.
    if (mCamera != null) {
      setDefaultCameraId();
      mPreview.setCamera(null, -1);
      mCamera.setPreviewCallback(null);
      mCamera.release();
      mCamera = null;
    }
  }

  public Camera getCamera() {
    return mCamera;
  }

  public void switchCamera() {
    // check for availability of multiple cameras
    if (numberOfCameras == 1) {
      //There is only one camera available
    }else{
      Log.d(TAG, "numberOfCameras: " + numberOfCameras);

      // OK, we have multiple cameras. Release this camera -> cameraCurrentlyLocked
      if (mCamera != null) {
        mCamera.stopPreview();
        mPreview.setCamera(null, -1);
        mCamera.release();
        mCamera = null;
      }

      // Acquire the next camera and request Preview to reconfigure parameters.
      mCamera = Camera.open((cameraCurrentlyLocked + 1) % numberOfCameras);

      if (cameraParameters != null) {
        mCamera.setParameters(cameraParameters);
      }

      Log.d(TAG, "cameraCurrentlyLocked := " + Integer.toString(cameraCurrentlyLocked));
      try {
        cameraCurrentlyLocked = (cameraCurrentlyLocked + 1) % numberOfCameras;
        Log.d(TAG, "cameraCurrentlyLocked new: " + cameraCurrentlyLocked);
      } catch (Exception exception) {
        Log.d(TAG, exception.getMessage());
      }

      mCamera = Camera.open(cameraCurrentlyLocked);

      if (cameraParameters != null) {
        Log.d(TAG, "camera parameter not null");
        mCamera.setParameters(cameraParameters);
      } else {
        Log.d(TAG, "camera parameter NULL");
      }

      mPreview.switchCamera(mCamera, cameraCurrentlyLocked);

      mCamera.startPreview();
    }
  }

  public void setCameraParameters(Camera.Parameters params) {
    cameraParameters = params;

    if (mCamera != null && cameraParameters != null) {
      mCamera.setParameters(cameraParameters);
    }
  }

  public boolean hasFrontCamera(){
    return getActivity().getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT);
  }

  public Bitmap cropBitmap(Bitmap bitmap, Rect rect){
    int w = rect.right - rect.left;
    int h = rect.bottom - rect.top;
    Bitmap ret = Bitmap.createBitmap(w, h, bitmap.getConfig());
    Canvas canvas= new Canvas(ret);
    canvas.drawBitmap(bitmap, -rect.left, -rect.top, null);
    return ret;
  }

  public static Bitmap rotateBitmap(Bitmap source, float angle)
  {
      Matrix matrix = new Matrix();
      matrix.postRotate(angle);
      return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
  }

  ShutterCallback shutterCallback = new ShutterCallback()
	{
		 public void onShutter()
		 {
			 // Just do nothing.
		 }
	};

	PictureCallback rawPictureCallback = new PictureCallback()
	{
		 public void onPictureTaken(byte[] arg0, Camera arg1)
		 {
			 // Just do nothing.
		 }
	};

	PictureCallback jpegPictureCallback = new PictureCallback()
	{
    public void onPictureTaken(byte[] data, Camera arg1)
		{
			// Save the picture.
      Log.d(TAG, "CameraPreview onPictureTaken");
      Camera.Parameters params = mCamera.getParameters();
			try {
				Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0,data.length);
        bitmap = rotateBitmap(bitmap, mPreview.getDisplayOrientation());
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
				bitmap.compress(Bitmap.CompressFormat.JPEG, params.getJpegQuality(), outputStream);
        byte[] byteArray = outputStream.toByteArray();
        String encodedImage = Base64.encodeToString(byteArray, Base64.NO_WRAP);
        Log.d(TAG, "CameraPreview callbck javascript onPictureTaken");
        eventListener.onPictureTaken(encodedImage);
        Log.d(TAG, "CameraPreview done");
        // result = outputStream.toByteArray();
			}
			catch (Exception e)
			{
        Log.d(TAG, "CameraPreview exception");
				e.printStackTrace();
			}
		}
	};

  private Camera.Size getOptimalPictureSize(final int width, final int height, final Camera.Size previewSize, final List<Camera.Size> supportedSizes)
  {
    Camera.Size size = mCamera.new Size(width, height);
    // convert to landscape if necessary
    if (size.width < size.height) {
      int temp = size.width;
      size.width = size.height;
      size.height = temp;
    }
    Log.d(TAG, "CameraPreview preview size " + previewSize.width + 'x' + previewSize.height);
    // get the supportedPictureSize that:
    // - has the closest aspect ratio to the preview aspectratio
    // - has picture.width / picture.height closest to width and height
    // - has the highest supporte pictured width / height if width == 0 || height == 0
    double previewAspectRatio  = (double)previewSize.width / (double)previewSize.height;
    if (previewAspectRatio < 1.0) {
      // reset ratio to landscape
      previewAspectRatio = 1.0 / previewAspectRatio;
    }
    Log.d(TAG, "CameraPreview previewAspectRatio " + previewAspectRatio);
    double aspectTolerance = 0.1;
    double bestDifference = Double.MAX_VALUE;
    //for (int i = supportedSizes.size() - 1; i >= 0; i--) {
    for (int i = 0; i < supportedSizes.size(); i++) {
      Camera.Size supportedSize = supportedSizes.get(i);
      Log.d(TAG, "CameraPreview supportedSize " + supportedSize.width + "x" + supportedSize.height);
      double difference = Math.abs(previewAspectRatio - ((double)supportedSize.width / (double)supportedSize.height));
      if (difference < bestDifference - aspectTolerance) {
        // better aspectRatio found
        size.width = supportedSize.width;
        size.height = supportedSize.height;
        bestDifference = difference;
        Log.d(TAG, "CameraPreview better aspectRatio " + (double)supportedSize.width / (double)supportedSize.height);
      } else if (difference < bestDifference + aspectTolerance) {
        // same aspectRatio found (within tolerance), get highest supported resolution
        if (width == 0 || height == 0) {
          if (size.width < supportedSize.width) {
            size.width = supportedSize.width;
            size.height = supportedSize.height;
          }
        } else {
          // check if this pictureSize closer to width/height
          Log.d(TAG, "CameraPreview width x height " + width + "x" + height + ", supported width x height: "+ supportedSize.width + 'x' + supportedSize.height);
          Log.d(TAG, "CameraPreview current size width x height " + size.width + 'x' + size.height);
          Log.d(TAG, "CameraPreview opp new " + Math.abs(width - supportedSize.width) * Math.abs(height - supportedSize.height) + ", opp old:" + Math.abs(width - size.width) * Math.abs(width - size.height));
          if (Math.abs(width - supportedSize.width) * Math.abs(height - supportedSize.height) <
            Math.abs(width - size.width) * Math.abs(height - size.height)) {
              size.width = supportedSize.width;
              size.height = supportedSize.height;
              Log.d(TAG, "CameraPreview better width/height " + size.width + 'x' + size.height);
          }
        }
      }
    }
    Log.d(TAG, "CameraPreview optimalPictureSize " + size.width + 'x' + size.height);
    return size;
  }

  public void takePicture(final int width, final int height, final int quality){
    Log.d(TAG, "CameraPreview takePicture width: " + width + ", height: " + height + ", quality: " + quality);

    if(mPreview != null) {

      if(!canTakePicture){
        return;
      }

      canTakePicture = false;

      new Thread() {
        public void run() {
          // this approach based on http://ibuzzlog.blogspot.nl/2012/08/how-to-use-camera-in-android.html
          Camera.Parameters params = mCamera.getParameters();
          Camera.Size size = getOptimalPictureSize(width, height, params.getPreviewSize(), params.getSupportedPictureSizes());
          //params.setPictureSize(424, 240); // always defined in landscape, rotate later if necessary
          params.setPictureSize(size.width, size.height);
          params.setJpegQuality(quality);
          mCamera.setParameters(params);
          mCamera.takePicture(shutterCallback, rawPictureCallback, jpegPictureCallback);
        }
      }.start();

/*
      mPreview.setOneShotPreviewCallback(new Camera.PreviewCallback() {

        @Override
        public void onPreviewFrame(final byte[] data, final Camera camera) {

          new Thread() {
            public void run() {
              int w = width;
              int h = height;

              Camera.Parameters params = camera.getParameters();
              w = params.getPreviewSize().width;
              h = params.getPreviewSize().height;
              //raw picture
              byte[] bytes = mPreview.getFramePicture(data, camera, w, h, quality); // raw bytes from preview
              final Bitmap pic = BitmapFactory.decodeByteArray(bytes, 0, bytes.length); // Bitmap from preview


              //scale down
              //float scale = (float) pictureView.getWidth() / (float) pic.getWidth();
              //Bitmap scaledBitmap = Bitmap.createScaledBitmap(pic, (int) (pic.getWidth() * scale), (int) (pic.getHeight() * scale), false);


              final Matrix matrix = new Matrix();
              if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                Log.d(TAG, "mirror y axis");
                matrix.preScale(-1.0f, 1.0f);
              }
              Log.d(TAG, "preRotate " + mPreview.getDisplayOrientation() + "deg");
              matrix.postRotate(mPreview.getDisplayOrientation());


              // final Bitmap fixedPic = Bitmap.createBitmap(scaledBitmap, 0, 0, scaledBitmap.getWidth(), scaledBitmap.getHeight(), matrix, false);
              // final Rect rect = new Rect(mPreview.mSurfaceView.getLeft(), mPreview.mSurfaceView.getTop(), mPreview.mSurfaceView.getRight(), mPreview.mSurfaceView.getBottom());


              Log.d(TAG, mPreview.mSurfaceView.getLeft() + " " + mPreview.mSurfaceView.getTop() + " " + mPreview.mSurfaceView.getRight() + " " + mPreview.mSurfaceView.getBottom());

              getActivity().runOnUiThread(new Runnable() {
                @Override
                public void run() {

                  //pictureView.setImageBitmap(fixedPic);
                  //pictureView.layout(rect.left, rect.top, rect.right, rect.bottom);

                  //Bitmap finalPic = pic;
                  //Bitmap originalPicture = Bitmap.createBitmap(finalPic, 0, 0, (int) (finalPic.getWidth()), (int) (finalPic.getHeight()), matrix, false);


                  Bitmap originalPicture = Bitmap.createBitmap(pic, 0, 0, (int) (pic.getWidth()), (int) (pic.getHeight()), matrix, false);

                  generatePictureFromView(originalPicture, quality);
                  canTakePicture = true;
                  camera.startPreview();
                }
              });
            }
          }.start();
        }
      }); */
    } else {
      canTakePicture = true;
    }
  }

  private void generatePictureFromView(final Bitmap originalPicture, final int quality){
    final FrameLayout cameraLoader = (FrameLayout) view.findViewById(getResources().getIdentifier("camera_loader", "id", appResourcesPackage));
    cameraLoader.setVisibility(View.VISIBLE);
    final ImageView pictureView = (ImageView) view.findViewById(getResources().getIdentifier("picture_view", "id", appResourcesPackage));
    new Thread() {
      public void run() {

        try {
          ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
          originalPicture.compress(Bitmap.CompressFormat.JPEG, quality, byteArrayOutputStream);
          byte[] byteArray = byteArrayOutputStream.toByteArray();
          String encodedImage = Base64.encodeToString(byteArray, Base64.NO_WRAP);

          eventListener.onPictureTaken(encodedImage);

          getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
              cameraLoader.setVisibility(View.INVISIBLE);
              pictureView.setImageBitmap(null);
            }
          });
        } catch (Exception e) {
          //An unexpected error occurred while saving the picture.
          getActivity().runOnUiThread(new Runnable() {
            @Override
            public void run() {
              cameraLoader.setVisibility(View.INVISIBLE);
              pictureView.setImageBitmap(null);
            }
          });
        }
      }
    }.start();
  }

  @Override
  public void onDestroy() {
    super.onDestroy();
  }
}
