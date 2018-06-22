package com.cordovaplugincamerapreview;

import android.app.Fragment;
import android.graphics.Bitmap;
import android.util.Base64;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.hardware.Camera;
import android.hardware.Camera.Area;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.ShutterCallback;
import android.hardware.Camera.Size;
import android.os.Bundle;
import android.util.Log;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.support.media.ExifInterface;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.lang.Exception;
import java.lang.Integer;
import java.util.List;
import java.util.Arrays;

import static android.hardware.Camera.Parameters.FOCUS_MODE_AUTO;
import static android.hardware.Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE;
import static android.hardware.Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO;
import static android.hardware.Camera.Parameters.FOCUS_MODE_EDOF;
import static android.hardware.Camera.Parameters.FOCUS_MODE_FIXED;
import static android.hardware.Camera.Parameters.FOCUS_MODE_MACRO;

public class CameraActivity extends Fragment {

  public interface CameraPreviewListener {
    void onPictureTaken(String originalPicture);

    void onPictureTakenError(String message);

    void onFocusSet(int pointX, int pointY);

    void onFocusSetError(String message);

    void onBackButton();

    void onCameraStarted();
  }

  private CameraPreviewListener eventListener;
  private static final String TAG = "PP/CameraActivity";

  private Preview mPreview;
  private boolean canTakePicture = true;

  public ViewGroup containerView;
  private Parameters currentCameraParameters;
  private Camera mCamera;
  private int numberOfCameras;
  public int cameraCurrentlyLocked;
  private int currentQuality;

  // The first rear facing camera
  private int defaultCameraId;
  public String defaultCamera;
  public boolean tapToTakePicture;
  public boolean dragEnabled;
  public boolean tapToFocus;
  public boolean disableExifHeaderStripping;
  public boolean toBack;

  public void setEventListener(CameraPreviewListener listener) {
    eventListener = listener;
  }

  @Override
  public void onCreate(Bundle savedInstanceState) {

    super.onCreate(savedInstanceState);
    setDefaultCameraId();

  }

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    containerView = container;
    // video view
    mPreview = new Preview(getActivity());
    Log.d(TAG, "add PreviewView to containerView");
    containerView.setEnabled(false);

    if (toBack == false) {
      this.setupTouchAndBackButton();
    }

    return mPreview;
  }

  @Override
  public void onSaveInstanceState(Bundle outState) {
    // No call for super(). Bug on API Level > 11.
  }

  private void initCamera(int cameraId, Parameters cameraParameters) {

    if (mCamera != null) {
      if (cameraId == cameraCurrentlyLocked) {
        Log.d(TAG, "initCamera: requested camera is already init");
        return;
      }
      Log.d(TAG, "initCamera: a Camera is already init stop it before continue");
      stopCurrentCamera();
    }

    Log.d(TAG, "initCamera: Open camera " + cameraId);

    mCamera = Camera.open(cameraId);
    if (cameraParameters != null) {
      setCameraParameters(cameraParameters);
    }

    cameraCurrentlyLocked = cameraId;
    setBestFocusMode();
    setPreviewSizeFromCameraPictureSize();
    mPreview.setCamera(mCamera);

  }

  private void stopCurrentCamera() {
    if (mCamera == null) {
      return;
    }

    mCamera.stopPreview();
    mPreview.setCamera(null);
    mCamera.release();
    mCamera = null;
  }

  private void setupTouchAndBackButton() {

    final GestureDetector gestureDetector = new GestureDetector(getActivity().getApplicationContext(),
        new TapGestureDetector());

    getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        containerView.setClickable(true);
        containerView.setOnTouchListener(new View.OnTouchListener() {

          private int mLastTouchX;
          private int mLastTouchY;
          private int mPosX = 0;
          private int mPosY = 0;

          @Override
          public boolean onTouch(View v, MotionEvent event) {
            Log.d(TAG, "onTouch" + event);
            FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) containerView.getLayoutParams();

            boolean isSingleTapTouch = gestureDetector.onTouchEvent(event);
            if (event.getAction() != MotionEvent.ACTION_MOVE && isSingleTapTouch) {
              if (tapToTakePicture && tapToFocus) {
                setFocusArea((int) event.getX(0), (int) event.getY(0), new AutoFocusCallback() {
                  public void onAutoFocus(boolean success, Camera camera) {
                    if (success) {
                      takePicture(85);
                    } else {
                      Log.d(TAG, "onTouch:" + " setFocusArea() did not suceed");
                    }
                  }
                });

              } else if (tapToTakePicture) {
                takePicture(85);

              } else if (tapToFocus) {
                setFocusArea((int) event.getX(0), (int) event.getY(0), new AutoFocusCallback() {
                  public void onAutoFocus(boolean success, Camera camera) {
                    if (success) {
                      // A callback to JS might make sense here.
                    } else {
                      Log.d(TAG, "onTouch:" + " setFocusArea() did not suceed");
                    }
                  }
                });
              }
              return true;
            } else {
              if (dragEnabled) {
                int x;
                int y;

                switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                  if (mLastTouchX == 0 || mLastTouchY == 0) {
                    mLastTouchX = (int) event.getRawX() - layoutParams.leftMargin;
                    mLastTouchY = (int) event.getRawY() - layoutParams.topMargin;
                  } else {
                    mLastTouchX = (int) event.getRawX();
                    mLastTouchY = (int) event.getRawY();
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

                  containerView.setLayoutParams(layoutParams);

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
        containerView.setFocusableInTouchMode(true);
        containerView.requestFocus();
        containerView.setOnKeyListener(new android.view.View.OnKeyListener() {
          @Override
          public boolean onKey(android.view.View v, int keyCode, android.view.KeyEvent event) {

            if (keyCode == android.view.KeyEvent.KEYCODE_BACK) {
              eventListener.onBackButton();
              return true;
            }
            return false;
          }
        });
      }
    });

  }

  private void setDefaultCameraId() {
    // Find the total number of cameras available
    numberOfCameras = Camera.getNumberOfCameras();

    int facing = defaultCamera.equals("front") ? Camera.CameraInfo.CAMERA_FACING_FRONT
        : Camera.CameraInfo.CAMERA_FACING_BACK;

    // Find the ID of the default camera
    Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
    for (int i = 0; i < numberOfCameras; i++) {
      Camera.getCameraInfo(i, cameraInfo);
      if (cameraInfo.facing == facing) {
        defaultCameraId = i;
        break;
      }
    }
  }

  @Override
  public void onResume() {
    super.onResume();

    Log.d(TAG, "on Resume");

    if (mCamera == null) {
      initCamera(defaultCameraId, currentCameraParameters);
      eventListener.onCameraStarted();

    }

    Log.d(TAG, "cameraCurrentlyLocked:" + cameraCurrentlyLocked);

  }

  @Override
  public void onPause() {
    super.onPause();

    // Because the Camera object is a shared resource, it's very important to
    // release it when the activity is paused.
    if (mCamera != null) {
      stopCurrentCamera();
    }

  }

  public Camera getCamera() {
    return mCamera;
  }

  public void switchCamera() {
    // check for availability of multiple cameras
    if (numberOfCameras == 1) {
      // There is only one camera available
    } else {
      int newCamera = cameraCurrentlyLocked;
      Log.d(TAG, "numberOfCameras: " + numberOfCameras);

      Log.d(TAG, "cameraCurrentlyLocked := " + Integer.toString(cameraCurrentlyLocked));
      try {
        newCamera = (cameraCurrentlyLocked + 1) % numberOfCameras;
        Log.d(TAG, "cameraCurrentlyLocked new: " + cameraCurrentlyLocked);
      } catch (Exception exception) {
        Log.d(TAG, exception.getMessage());
      }

      if (newCamera != cameraCurrentlyLocked) {
        currentCameraParameters = null;
        initCamera(newCamera, null);
      }

    }
  }

  public void setCameraParameters(Parameters params) {
    currentCameraParameters = params;

    if (mCamera != null && currentCameraParameters != null) {
      mCamera.setParameters(currentCameraParameters);
    }
  }

  public static Bitmap applyMatrix(Bitmap source, Matrix matrix) {
    return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
  }

  ShutterCallback shutterCallback = new ShutterCallback() {
    public void onShutter() {
      // do nothing, availability of this callback causes default system shutter sound
      // to work
    }
  };

  private static int exifToDegrees(int exifOrientation) {
    if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) {
      return 90;
    } else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) {
      return 180;
    } else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) {
      return 270;
    }
    return 0;
  }

  PictureCallback jpegPictureCallback = new PictureCallback() {

    public void onPictureTaken(byte[] data, Camera arg1) {
      new RotateImageIfNecessary().execute(data);
      mCamera.startPreview();
    }
  };

  class RotateImageIfNecessary extends AsyncTask<byte[], String, String> {
    @Override
    protected String doInBackground(byte[][] params) {

      byte[] data = params[0];

      try {

        if (!disableExifHeaderStripping) {
          Matrix matrix = new Matrix();
          if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            Log.d(TAG, "CameraPreview cameraCurrentlyLocked");
            matrix.preScale(1.0f, -1.0f);
          }

          ExifInterface exifInterface = new ExifInterface(new ByteArrayInputStream(data));
          int rotation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
          int rotationInDegrees = exifToDegrees(rotation);

          if (rotation != 0f) {
            Log.d(TAG, "CameraPreview rotation");
            matrix.preRotate(rotationInDegrees);
          }

          // Check if matrix has changed. In that case, apply matrix and override data
          if (!matrix.isIdentity()) {
            Log.d(TAG, "CameraPreview MatrixIsIdentity");
            Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
            bitmap = applyMatrix(bitmap, matrix);

            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.JPEG, currentQuality, outputStream);
            data = outputStream.toByteArray();
          }
        }

        String encodedImage = Base64.encodeToString(data, Base64.NO_WRAP);

        eventListener.onPictureTaken(encodedImage);
        Log.d(TAG, "CameraPreview pictureTakenHandler called back");

      } catch (OutOfMemoryError e)

      {
        // most likely failed to allocate memory for rotateBitmap
        Log.d(TAG, "CameraPreview OutOfMemoryError");
        // failed to allocate memory
        eventListener.onPictureTakenError("Picture too large (memory)");
      } catch (IOException e)

      {
        Log.d(TAG, "CameraPreview IOException");
        eventListener.onPictureTakenError("IO Error when extracting exif");
      } catch (Exception e)

      {
        Log.d(TAG, "CameraPreview onPictureTaken general exception");
      } finally

      {
        canTakePicture = true;
        return null;
      }
    }
  }

  public void setPictureSize(final int width, final int height) {

    Parameters params = mCamera.getParameters();
    params.setPictureSize(width, height);
    setCameraParameters(params);
    Log.d(TAG, "setPictureSize " + width + ", " + height);
    setPreviewSizeFromCameraPictureSize();

  }

  public void takePicture(final int quality) {
    Log.d(TAG, "CameraPreview takePicture quality: " + quality);

    if (mPreview != null) {
      if (!canTakePicture) {
        return;
      }

      canTakePicture = false;

      new Thread() {
        public void run() {
          Parameters params = mCamera.getParameters();

          /*
           * Camera.Size size = getOptimalPictureSize(width, height,
           * params.getPreviewSize(), params.getSupportedPictureSizes());
           * params.setPictureSize(size.width, size.height);
           */
          currentQuality = quality;

          if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            // The image will be recompressed in the callback
            params.setJpegQuality(99);
          } else {
            params.setJpegQuality(quality);
          }

          setCameraParameters(params);
          mCamera.takePicture(shutterCallback, null, jpegPictureCallback);
        }
      }.start();
    } else {
      canTakePicture = true;
    }
  }

  public void setFocusArea(final int pointX, final int pointY, final AutoFocusCallback callback) {
    if (mCamera != null) {

      Parameters params = mCamera.getParameters();

      if (params.getMaxNumFocusAreas() > 0) {
        Rect tapArea = calculateTapArea(pointX, pointY, 1f);
        Area area = new Area(tapArea, 1000);
        params.setFocusAreas(Arrays.asList(area));
      }

      if (params.getMaxNumMeteringAreas() > 0) {
        Rect meteringRect = calculateTapArea(pointX, pointY, 1.5f);
        Area area = new Area(meteringRect, 1000);
        params.setMeteringAreas(Arrays.asList(area));
      }

      String focusMode = getBestFocusModeForTouchFocus();
      if (focusMode != null) {
        params.setFocusMode(focusMode);
      }

      try {
        setCameraParameters(params);
        mCamera.autoFocus(callback);
      } catch (Exception e) {
        Log.d(TAG, e.getMessage());
        callback.onAutoFocus(false, this.mCamera);
      }
    }
  }

  private Rect calculateTapArea(float x, float y, float coefficient) {
    if (x < 100) {
      x = 100;
    }
    if (x > mPreview.viewWidth - 100) {
      x = mPreview.viewWidth - 100;
    }
    if (y < 100) {
      y = 100;
    }
    if (y > mPreview.viewHeight - 100) {
      y = mPreview.viewHeight - 100;
    }
    return new Rect(Math.round((x - 100) * 2000 / mPreview.viewWidth - 1000),
        Math.round((y - 100) * 2000 / mPreview.viewHeight - 1000),
        Math.round((x + 100) * 2000 / mPreview.viewWidth - 1000),
        Math.round((y + 100) * 2000 / mPreview.viewHeight - 1000));
  }

  public void setPreviewSizeFromCameraPictureSize() {

    Parameters params = mCamera.getParameters();

    Size pictureSize = params.getPictureSize();

    // Get pictureSize Ratio
    mPreview.previewRatio = (double) pictureSize.width / pictureSize.height;
    Log.d(TAG, "previewRatio " + mPreview.previewRatio);
    getActivity().runOnUiThread(new Runnable() {
      @Override
      public void run() {
        mPreview.requestLayout();
      }
    });

    // Get best preview size of the same ratio
    List<Size> supportedPreviewSizes = params.getSupportedPreviewSizes();

    Size optimalPreviewSize = findBestPreviewSize(pictureSize, supportedPreviewSizes);

    if (optimalPreviewSize != null) {
      params.setPreviewSize(optimalPreviewSize.width, optimalPreviewSize.height);
      setCameraParameters(params);
      // Restart camera, otherwise it seems that new previewSize is not applied
      mCamera.stopPreview();
      mCamera.startPreview();
    }
  }

  private Size findBestPreviewSize(Size pictureSize, List<Size> supportedPreviewSizes) {
    Size optimalPreviewSize = null;

    for (Size size : supportedPreviewSizes) {
      double ratio = (double) size.width / size.height;
      if (ratio == mPreview.previewRatio) {
        if (optimalPreviewSize == null) {
          optimalPreviewSize = size;
        } else if ((double) size.height * size.width > (double) optimalPreviewSize.height * optimalPreviewSize.width) {
          optimalPreviewSize = size;
        }
      }
    }
    return optimalPreviewSize;
  }

  private void setBestFocusMode() {
    Parameters params = mCamera.getParameters();
    List<String> focusModes = params.getSupportedFocusModes();
    if (focusModes.contains(FOCUS_MODE_CONTINUOUS_PICTURE)) {
      params.setFocusMode(FOCUS_MODE_CONTINUOUS_PICTURE);
    } else if (focusModes.contains(FOCUS_MODE_CONTINUOUS_VIDEO)) {
      params.setFocusMode(FOCUS_MODE_CONTINUOUS_VIDEO);
    } else if (focusModes.contains(FOCUS_MODE_EDOF)) {
      params.setFocusMode(FOCUS_MODE_EDOF);
    } else if (focusModes.contains(FOCUS_MODE_MACRO)) {
      params.setFocusMode(FOCUS_MODE_MACRO);
    } else if (focusModes.contains(FOCUS_MODE_AUTO)) {
      params.setFocusMode(FOCUS_MODE_AUTO);
    } else if (focusModes.contains(FOCUS_MODE_FIXED)) {
      params.setFocusMode(FOCUS_MODE_FIXED);
    }

    setCameraParameters(params);
  }

  private String getBestFocusModeForTouchFocus() {
    Parameters params = mCamera.getParameters();
    List<String> focusModes = params.getSupportedFocusModes();
    if (focusModes.contains(FOCUS_MODE_AUTO)) {
      return FOCUS_MODE_AUTO;
    } else if (focusModes.contains(FOCUS_MODE_MACRO)) {
      return FOCUS_MODE_MACRO;
    } else if (focusModes.contains(FOCUS_MODE_FIXED)) {
      return FOCUS_MODE_FIXED;
    }
    return null;
  }

}
