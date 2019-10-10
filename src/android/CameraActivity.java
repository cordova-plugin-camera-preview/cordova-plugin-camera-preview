package com.cordovaplugincamerapreview;

import android.app.Fragment;
import android.graphics.Bitmap;
import android.hardware.Sensor;
import android.hardware.SensorManager;
import android.util.Base64;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.hardware.Camera;
import android.hardware.Camera.Area;
import android.hardware.Camera.AutoFocusCallback;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.PictureCallback;
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
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.Exception;
import java.lang.Integer;
import java.text.SimpleDateFormat;
import java.util.Collections;
import java.util.Date;
import java.util.List;
import java.util.Locale;
import java.util.TimeZone;
import java.util.UUID;

import static android.hardware.Camera.Parameters.FOCUS_MODE_AUTO;
import static android.hardware.Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE;
import static android.hardware.Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO;
import static android.hardware.Camera.Parameters.FOCUS_MODE_EDOF;
import static android.hardware.Camera.Parameters.FOCUS_MODE_FIXED;
import static android.hardware.Camera.Parameters.FOCUS_MODE_MACRO;

public class CameraActivity extends Fragment {

  public interface CameraPreviewListener {
    void onPictureTaken(String originalPicture, int width, int height, int orientation);
    void onPictureTakenError(String message);
    void onSnapshotTaken(String originalPicture);
    void onSnapshotTakenError(String message);
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
  public boolean storeToFile;
  public String storageDirectory;
  public boolean toBack;

  public Double latitude;
  public Double longitude;
  public Double altitude;
  public Long timestamp;
  public Double trueHeading;
  public Double magneticHeading;
  public String software;
  public boolean withExifInfos;
  public int screenRotation = 0;

  private SensorManager sensorManager;
  private Sensor sensor;

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

    int facing = "front".equals(defaultCamera) ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK;

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
    // Find the total number of cameras available
    numberOfCameras = Camera.getNumberOfCameras();
    
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

  /**
   * Build rotate/scale matrix depending on EXIF orientation
   */
  private static Matrix buildMatrixFromExifOrientation(int orientation) {
    Matrix matrix = new Matrix();
    switch (orientation) {
      case ExifInterface.ORIENTATION_NORMAL:
        break;
      case ExifInterface.ORIENTATION_FLIP_HORIZONTAL:
          matrix.setScale(-1, 1);
          break;
      case ExifInterface.ORIENTATION_ROTATE_180:
          matrix.setRotate(180);
          break;
      case ExifInterface.ORIENTATION_FLIP_VERTICAL:
          matrix.setRotate(180);
          matrix.postScale(-1, 1);
          break;
      case ExifInterface.ORIENTATION_TRANSPOSE:
          matrix.setRotate(90);
          matrix.postScale(-1, 1);
          break;
     case ExifInterface.ORIENTATION_ROTATE_90:
         matrix.setRotate(90);
         break;
     case ExifInterface.ORIENTATION_TRANSVERSE:
         matrix.setRotate(-90);
         matrix.postScale(-1, 1);
         break;
     case ExifInterface.ORIENTATION_ROTATE_270:
         matrix.setRotate(-90);
         break;
     default:
        break;
    }
    return matrix;
  }

  private String getTempDirectoryPath() {
    File dir = null;

    // Use internal storage
    dir = getActivity().getExternalFilesDir(null);

    // Create the cache directory if it doesn't exist
    dir.mkdirs();
    return dir.getAbsolutePath();
  }

  private String getTempFilePath() {
    if (storageDirectory != null) {
      return storageDirectory + UUID.randomUUID().toString().replace("-", "").substring(0, 8) + ".jpg";
    } else {
      return getTempDirectoryPath() + "/cpcp_capture_" + UUID.randomUUID().toString().replace("-", "").substring(0, 8) + ".jpg";
    }
  }


  PictureCallback jpegPictureCallback = new PictureCallback() {

    public void onPictureTaken(byte[] data, Camera arg1) {
      new RotateImageIfNecessary().execute(data);
      mCamera.startPreview();
    }
  };

  /**
   * This will write exif information to image file.
   *
   * @param path
   */
  private void writeExifInfos(String path) {

    Log.d(TAG, "writeExifInfos");

    try {

      ExifInterface exif = new ExifInterface(path);

      double absoluteValueLatitude = Math.abs(latitude);
      double absoluteValueLongitude = Math.abs(longitude);

      // Converts latitude in degrees minutes seconds
      int degreesLatitude = (int) Math.floor(absoluteValueLatitude);
      int minutesLatitude = (int) Math.floor((absoluteValueLatitude - degreesLatitude) * 60);
      double secondsLatitude = (absoluteValueLatitude - (degreesLatitude + ((double) minutesLatitude / 60))) * 3600000;

      // Converts latitude in degrees minutes seconds
      int degreesLongitude = (int) Math.floor(absoluteValueLongitude);
      int minutesLongitude = (int) Math.floor((absoluteValueLongitude - degreesLongitude) * 60);
      double secondsLongitude = (absoluteValueLongitude - (degreesLongitude + ((double) minutesLongitude / 60))) * 3600000;

      String exifLatitude = degreesLatitude + "/1," + minutesLatitude + "/1," + secondsLatitude + "/1000";
      String exifLongitude = degreesLongitude + "/1," + minutesLongitude + "/1," + secondsLongitude + "/1000";

      if (latitude > 0) {
        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, "N");
      } else {
        exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE_REF, "S");
      }

      if (longitude > 0) {
        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, "E");
      } else {
        exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE_REF, "W");
      }

      exif.setAttribute(ExifInterface.TAG_GPS_LATITUDE, exifLatitude);
      exif.setAttribute(ExifInterface.TAG_GPS_LONGITUDE, exifLongitude);

      if (altitude > 0) {
        exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE_REF, "0");
      } else {
        exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE_REF, "1");
      }
      exif.setAttribute(ExifInterface.TAG_GPS_ALTITUDE, String.valueOf(Math.abs(altitude)) + "/1");

      Date gpsDate = new Date(timestamp);
      SimpleDateFormat gpsDateStampFormater = new SimpleDateFormat("yyyy:MM:dd", Locale.getDefault());
      SimpleDateFormat gpsTimeStampFormater = new SimpleDateFormat("kk:mm:ss", Locale.getDefault());

      gpsDateStampFormater.setTimeZone(TimeZone.getTimeZone("UTC"));
      gpsTimeStampFormater.setTimeZone(TimeZone.getTimeZone("UTC"));

      exif.setAttribute(ExifInterface.TAG_GPS_DATESTAMP, gpsDateStampFormater.format(gpsDate));
      exif.setAttribute(ExifInterface.TAG_GPS_TIMESTAMP, gpsTimeStampFormater.format(gpsDate));

      if (trueHeading != Double.NaN || magneticHeading != Double.NaN) {
        if (trueHeading == Double.NaN || trueHeading < 0) {
          exif.setAttribute(ExifInterface.TAG_GPS_IMG_DIRECTION, String.valueOf(magneticHeading) + "/1");
          exif.setAttribute(ExifInterface.TAG_GPS_IMG_DIRECTION_REF, "M");
        } else {
          exif.setAttribute(ExifInterface.TAG_GPS_IMG_DIRECTION, String.valueOf(trueHeading) + "/1");
          exif.setAttribute(ExifInterface.TAG_GPS_IMG_DIRECTION_REF, "T");
        }
      }
      exif.setAttribute(ExifInterface.TAG_SOFTWARE, software);

      exif.saveAttributes();
    }
    catch (IOException e) {
      Log.e(TAG, "Could not wirte exif :\n" + e);
      eventListener.onPictureTakenError("Picture too large (memory)");
    }
  }


  class RotateImageIfNecessary extends AsyncTask<byte[], String, String> {
    @Override
    protected String doInBackground(byte[][] params) {

      byte[] data = params[0];

      try {

        Log.d(TAG, "RotateImageIfNecessary");
        ExifInterface exifInterface = new ExifInterface(new ByteArrayInputStream(data));
        if (!disableExifHeaderStripping) {
          int exifOrientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);

          Log.d(TAG, "CameraPreview exifOrientation: " + exifOrientation);
          Matrix matrix = buildMatrixFromExifOrientation(exifOrientation);

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
        int width = exifInterface.getAttributeInt(ExifInterface.TAG_IMAGE_WIDTH, 500);
        int height = exifInterface.getAttributeInt(ExifInterface.TAG_IMAGE_LENGTH, 500);
        int orientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_UNDEFINED);

        if (!storeToFile) {
          String encodedImage = Base64.encodeToString(data, Base64.NO_WRAP);

          eventListener.onPictureTaken(encodedImage, width, height, orientation);
        } else {
          String path = getTempFilePath();
          FileOutputStream out = new FileOutputStream(path);
          out.write(data);
          out.close();

          if (withExifInfos) {
            writeExifInfos(path);
            withExifInfos = false;
          }

          eventListener.onPictureTaken(path, width, height, orientation);
        }
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
  static byte[] rotateNV21(final byte[] yuv,
                           final int width,
                           final int height,
                           final int rotation)
  {
    if (rotation == 0) return yuv;
    if (rotation % 90 != 0 || rotation < 0 || rotation > 270) {
      throw new IllegalArgumentException("0 <= rotation < 360, rotation % 90 == 0");
    }

    final byte[]  output    = new byte[yuv.length];
    final int     frameSize = width * height;
    final boolean swap      = rotation % 180 != 0;
    final boolean xflip     = rotation % 270 != 0;
    final boolean yflip     = rotation >= 180;

    for (int j = 0; j < height; j++) {
      for (int i = 0; i < width; i++) {
        final int yIn = j * width + i;
        final int uIn = frameSize + (j >> 1) * width + (i & ~1);
        final int vIn = uIn       + 1;

        final int wOut     = swap  ? height              : width;
        final int hOut     = swap  ? width               : height;
        final int iSwapped = swap  ? j                   : i;
        final int jSwapped = swap  ? i                   : j;
        final int iOut     = xflip ? wOut - iSwapped - 1 : iSwapped;
        final int jOut     = yflip ? hOut - jSwapped - 1 : jSwapped;

        final int yOut = jOut * wOut + iOut;
        final int uOut = frameSize + (jOut >> 1) * wOut + (iOut & ~1);
        final int vOut = uOut + 1;

        output[yOut] = (byte)(0xff & yuv[yIn]);
        output[uOut] = (byte)(0xff & yuv[uIn]);
        output[vOut] = (byte)(0xff & yuv[vIn]);
      }
    }
    return output;
  }
  public void takeSnapshot(final int quality) {
    mCamera.setPreviewCallback(new Camera.PreviewCallback() {
      @Override
      public void onPreviewFrame(byte[] bytes, Camera camera) {
        try {
          Camera.Parameters parameters = camera.getParameters();
          Camera.Size size = parameters.getPreviewSize();
          int orientation = mPreview.getDisplayOrientation();
          if (mPreview.getCameraFacing() == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            bytes = rotateNV21(bytes, size.width, size.height, (360 - orientation) % 360);
          } else {
            bytes = rotateNV21(bytes, size.width, size.height, orientation);
          }
          // switch width/height when rotating 90/270 deg
          Rect rect = orientation == 90 || orientation == 270 ?
            new Rect(0, 0, size.height, size.width) :
            new Rect(0, 0, size.width, size.height);
          YuvImage yuvImage = new YuvImage(bytes, parameters.getPreviewFormat(), rect.width(), rect.height(), null);
          ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
          yuvImage.compressToJpeg(rect, quality, byteArrayOutputStream);
          byte[] data = byteArrayOutputStream.toByteArray();
          byteArrayOutputStream.close();
          eventListener.onSnapshotTaken(Base64.encodeToString(data, Base64.NO_WRAP));
        } catch (IOException e) {
          Log.d(TAG, "CameraPreview IOException");
          eventListener.onSnapshotTakenError("IO Error");
        } finally {

          mCamera.setPreviewCallback(null);
        }
      }
    });
  }

  public void takePicture(final int quality){

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

          if(cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT && !storeToFile) {
            // The image will be recompressed in the callback
            params.setJpegQuality(99);
          } else {
            params.setJpegQuality(quality);
          }

          setCameraParameters(params);
          mCamera.takePicture(null, null, jpegPictureCallback);
        }
      }.start();
    } else {
      canTakePicture = true;
    }
  }

  public void setFocusArea(final int pointX, final int pointY, final AutoFocusCallback callback) {
    if (mCamera != null) {

      mCamera.cancelAutoFocus();

      Parameters params = mCamera.getParameters();

      String focusMode = getBestFocusModeForTouchFocus();
      if (focusMode != null) {
        params.setFocusMode(focusMode);
      }

      if (params.getMaxNumFocusAreas() > 0) {
        Rect tapArea = calculateTapArea(pointX, pointY, 1f);
        Area area = new Area(tapArea, 1000);
        params.setFocusAreas(Collections.singletonList(area));
      }

      if (params.getMaxNumMeteringAreas() > 0) {
        Rect meteringRect = calculateTapArea(pointX, pointY, 1.5f);
        Area area = new Area(meteringRect, 1000);
        params.setMeteringAreas(Collections.singletonList(area));
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
