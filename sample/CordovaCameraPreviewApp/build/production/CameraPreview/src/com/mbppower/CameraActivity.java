package com.mbppower;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Rect;
import android.graphics.Region;
import android.graphics.YuvImage;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.hardware.Camera;
import android.net.Uri;
import android.os.*;
import android.util.Log;
import android.view.Display;
import android.view.Gravity;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.HorizontalScrollView;
import android.widget.ImageButton;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.ToggleButton;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

import android.media.MediaActionSound;

import com.mbppower.CordovaCameraPreviewApp.R;

public class CameraActivity extends Activity {
    private FrameLayout mainLayout;
    private Preview mPreview;
	private boolean canTakePicture = true;
    Camera mCamera;
    int numberOfCameras;
    int cameraCurrentlyLocked;

    // The first rear facing camera
    int defaultCameraId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Hide the window title.
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);

        setContentView(R.layout.camera_activity);
        createCameraPreview();
    }
    
    private void createCameraPreview(){
        if(mPreview == null) {
            // Find the total number of cameras available
            numberOfCameras = Camera.getNumberOfCameras();

            // Find the ID of the default camera
            Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
            for (int i = 0; i < numberOfCameras; i++) {
                Camera.getCameraInfo(i, cameraInfo);
                if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                    defaultCameraId = i;
                }
            }

            mPreview = new Preview(this);
            mainLayout = (FrameLayout) findViewById(R.id.video_view);
            mainLayout.addView(mPreview);
        }
    }
    
    @Override
    protected void onResume() {
        super.onResume();

        mCamera = Camera.open();
        cameraCurrentlyLocked = defaultCameraId;
        mPreview.setCamera(mCamera);

        final FrameLayout frameContainerLayout = (FrameLayout) findViewById(R.id.frame_container);
        ViewTreeObserver viewTreeObserver = frameContainerLayout.getViewTreeObserver();
        if (viewTreeObserver.isAlive()) {
            viewTreeObserver.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
                    frameContainerLayout.getViewTreeObserver().removeGlobalOnLayoutListener(this);
                    frameContainerLayout.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
                    int size = Math.min(frameContainerLayout.getHeight(), frameContainerLayout.getWidth());
                    final RelativeLayout frameCamContainerLayout = (RelativeLayout) findViewById(R.id.frame_camera_cont);

                    FrameLayout.LayoutParams camViewLayout = new FrameLayout.LayoutParams(size, size);
                    camViewLayout.gravity = Gravity.CENTER_HORIZONTAL;
                    frameCamContainerLayout.setLayoutParams(camViewLayout);
                }
            });
        }
    }

    @Override
    protected void onPause() {
        super.onPause();

        // Because the Camera object is a shared resource, it's very
        // important to release it when the activity is paused.
        if (mCamera != null) {
            mPreview.setCamera(null);
            mCamera.release();
            mCamera = null;
        }
    }

    public void switchCamera() {
        // check for availability of multiple cameras
        if (numberOfCameras == 1) {
            AlertDialog.Builder builder = new AlertDialog.Builder(this);
            builder.setMessage("There is only one camera available.").setNeutralButton("OK", null);
            AlertDialog alert = builder.create();
            alert.show();
        }
		else{
			// OK, we have multiple cameras.
			// Release this camera -> cameraCurrentlyLocked
			if (mCamera != null) {
				mCamera.stopPreview();
				mPreview.setCamera(null);
				mCamera.release();
				mCamera = null;
			}

			// Acquire the next camera and request Preview to reconfigure
			// parameters.
			mCamera = Camera.open((cameraCurrentlyLocked + 1) % numberOfCameras);
			cameraCurrentlyLocked = (cameraCurrentlyLocked + 1) % numberOfCameras;
			mPreview.switchCamera(mCamera);

			// Start the preview
			mCamera.startPreview();
		}
    }

    public boolean hasFrontCamera(){
        return getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT);
    }
	
	//close frames window
	public void close(View v) {   
    	finish();
    }
		
    public Bitmap cropBitmap(Bitmap bitmap, Rect rect){
        int w = rect.right - rect.left;
        int h = rect.bottom - rect.top;
        Bitmap ret = Bitmap.createBitmap(w, h, bitmap.getConfig());
        Canvas canvas= new Canvas(ret);
        canvas.drawBitmap(bitmap, -rect.left, -rect.top, null);
        return ret;
    }
	
	public void takePicture(){
		final ImageView pictureView = (ImageView) findViewById(R.id.picture_view);
		if(mPreview != null) {
			
			if(!canTakePicture)
				return;
			
			canTakePicture = false;

			mPreview.setOneShotPreviewCallback(new Camera.PreviewCallback() {

				@Override
				public void onPreviewFrame(final byte[] data, final Camera camera) {

					MediaActionSound media = new MediaActionSound();
					media.play(MediaActionSound.SHUTTER_CLICK);

					new Thread() {
						public void run() {

							byte[] bytes = mPreview.getFramePicture(data, camera);
							Bitmap pic = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
							float scale = (float)pictureView.getWidth()/(float)pic.getWidth();
							Bitmap scaledBitmap = Bitmap.createScaledBitmap(pic, (int)(pic.getWidth()*scale), (int)(pic.getHeight()*scale), false);

							Matrix matrix = new Matrix();
							if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
								float[] mirrorY = {1, 0, 0, 0, -1, 0, 0, 0, 1};
								Matrix mMirror = new Matrix();
								mMirror.setValues(mirrorY);
								matrix.postConcat(mMirror);
							}
							matrix.preRotate(mPreview.getDisplayOrientation());

							final Bitmap fixedPic = Bitmap.createBitmap(scaledBitmap, 0, 0, scaledBitmap.getWidth(), scaledBitmap.getHeight(), matrix, false);
							final Rect rect = new Rect(mPreview.mSurfaceView.getLeft(), mPreview.mSurfaceView.getTop(), mPreview.mSurfaceView.getRight(), mPreview.mSurfaceView.getBottom());

							runOnUiThread(new Runnable() {
								@Override
								public void run() {
									pictureView.setImageBitmap(fixedPic);
									pictureView.layout(rect.left, rect.top, rect.right, rect.bottom);

									canTakePicture = true;
									showConfirmationScreen();
								}
							});
						}
					}.start();
				}
			});
		}
		else{
			canTakePicture = true;
		}
	}
    private void showConfirmationScreen(){

	    final FrameLayout cameraLoader = (FrameLayout)findViewById(R.id.camera_loader);
	    cameraLoader.setVisibility(View.VISIBLE);

	    new Thread() {
		    public void run() {

			    try {
				    //get bitmap and compress
				    Bitmap picture = loadBitmapFromView(findViewById(R.id.frame_camera_cont));
				    ByteArrayOutputStream stream = new ByteArrayOutputStream();
				    picture.compress(Bitmap.CompressFormat.PNG, 80, stream);
				    final File picFile = storeImage(picture);

					//callback
				    
			    }
			    catch(Exception e){
				    runOnUiThread(new Runnable() {
					    @Override
					    public void run() {
						    cameraLoader.setVisibility(View.INVISIBLE);
						    AlertDialog.Builder alert = new AlertDialog.Builder(CameraActivity.this);
						    alert.setTitle("Error");
						    alert.setMessage("An unexpected error occurred while saving the picture.");
						    alert.show();
					    }
				    });
			    }
		    }
	    }.start();
    }

    private File getOutputMediaFile(){
        // To be safe, you should check that the SDCard is mounted
        // using Environment.getExternalStorageState() before doing this.
        File mediaStorageDir = new File(Environment.getExternalStorageDirectory()
                + "/Android/data/"
                + getApplicationContext().getPackageName()
                + "/Files");

        // This location works best if you want the created images to be shared
        // between applications and persist after your app has been uninstalled.

        // Create the storage directory if it does not exist
        if (! mediaStorageDir.exists()){
            if (! mediaStorageDir.mkdirs()){
                return null;
            }
        }
        // Create a media file name
        String timeStamp = new SimpleDateFormat("dd_MM_yyyy_HHmm").format(new Date());
        File mediaFile;
        String mImageName = "richlo_fashion_frame_" + timeStamp +".jpg";
        mediaFile = new File(mediaStorageDir.getPath() + File.separator + mImageName);
        return mediaFile;
    }

    private File storeImage(Bitmap image) {
        File pictureFile = getOutputMediaFile();
        if (pictureFile != null) {
            try {
                FileOutputStream fos = new FileOutputStream(pictureFile);
                image.compress(Bitmap.CompressFormat.JPEG, 80, fos);
                fos.close();
                return pictureFile;
            }
            catch (Exception ex) {
            }
        }
        return null;
    }

    
	public int calculateInSampleSize(BitmapFactory.Options options, int reqWidth, int reqHeight) {
		// Raw height and width of image
		final int height = options.outHeight;
		final int width = options.outWidth;
		int inSampleSize = 1;

		if (height > reqHeight || width > reqWidth) {

			final int halfHeight = height / 2;
			final int halfWidth = width / 2;

			// Calculate the largest inSampleSize value that is a power of 2 and keeps both
			// height and width larger than the requested height and width.
			while ((halfHeight / inSampleSize) > reqHeight && (halfWidth / inSampleSize) > reqWidth) {
				inSampleSize *= 2;
			}
		}
		return inSampleSize;
	}
	
    private Bitmap loadBitmapFromView(View v) {
        Bitmap b = Bitmap.createBitmap( v.getMeasuredWidth(), v.getMeasuredHeight(), Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(b);
        v.layout(v.getLeft(), v.getTop(), v.getRight(), v.getBottom());
        v.draw(c);
        return b;
    }
    
    @Override
    public void onDestroy() {
        super.onDestroy();
    }
}


class Preview extends RelativeLayout implements SurfaceHolder.Callback {
    private final String TAG = "Preview";

    CustomSurfaceView mSurfaceView;
    SurfaceHolder mHolder;
    Camera.Size mPreviewSize;
    List<Camera.Size> mSupportedPreviewSizes;
    Camera mCamera;

    Preview(Context context) {
        super(context);

        mSurfaceView = new CustomSurfaceView(context);
        addView(mSurfaceView);

        requestLayout();

        // Install a SurfaceHolder.Callback so we get notified when the
        // underlying surface is created and destroyed.
        mHolder = mSurfaceView.getHolder();
        mHolder.addCallback(this);
        mHolder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);
    }

    public void setCamera(Camera camera) {
        mCamera = camera;
        if (mCamera != null) {
            mSupportedPreviewSizes = mCamera.getParameters().getSupportedPreviewSizes();
            mCamera.setDisplayOrientation(getDisplayOrientation());
            //mCamera.getParameters().setRotation(getDisplayOrientation());
            requestLayout();
        }
    }

    public int getDisplayOrientation() {
        int angle;
        Display display = ((Activity)getContext()).getWindowManager().getDefaultDisplay();
        switch (display.getRotation()) {
            case Surface.ROTATION_0: // This is display orientation
                angle = 90; // This is camera orientation
                break;
            case Surface.ROTATION_90:
                angle = 0;
                break;
            case Surface.ROTATION_180:
                angle = 270;
                break;
            case Surface.ROTATION_270:
                angle = 180;
                break;
            default:
                angle = 90;
                break;
        }
        return angle;
    }

    public void switchCamera(Camera camera) {
        setCamera(camera);
        try {
            camera.setPreviewDisplay(mHolder);
        } catch (IOException exception) {
            Log.e(TAG, "IOException caused by setPreviewDisplay()", exception);
        }
        Camera.Parameters parameters = camera.getParameters();
        parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
        requestLayout();

        //camera.setParameters(parameters);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        // We purposely disregard child measurements because act as a
        // wrapper to a SurfaceView that centers the camera preview instead
        // of stretching it.
        final int width = resolveSize(getSuggestedMinimumWidth(), widthMeasureSpec);
        final int height = resolveSize(getSuggestedMinimumHeight(), heightMeasureSpec);
        setMeasuredDimension(width, height);

        if (mSupportedPreviewSizes != null) {
            mPreviewSize = getOptimalPreviewSize(mSupportedPreviewSizes, width, height);
        }
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {

        if (changed && getChildCount() > 0) {
            final View child = getChildAt(0);

            int orientation = getDisplayOrientation();

            int width = r - l;
            int height = b - t;

            if(orientation == 90 || orientation == 270) {
                width = b - t;
                height = r - l;
            }

            int previewWidth = width;
            int previewHeight = height;

            if (mPreviewSize != null) {
                previewWidth = mPreviewSize.width;
                previewHeight = mPreviewSize.height;

                if(orientation == 90 || orientation == 270) {
                    previewWidth = mPreviewSize.height;
                    previewHeight = mPreviewSize.width;
                }
            }

            int nW;
            int nH;
            int top;
            int left;

            float scale = 1.0f;//((float)previewHeight/(float)height);

            // Center the child SurfaceView within the parent.
            if (width * previewHeight < height * previewWidth) {
                int scaledChildWidth = (int)((previewWidth * height / previewHeight) * scale);
                nW = (width + scaledChildWidth) / 2;
                nH = (int)(height * scale);
                top = 0;
                left = (width - scaledChildWidth) / 2;
            }
            else {
                int scaledChildHeight = (int)((previewHeight * width / previewWidth) * scale);
                nW = (int)(width * scale);
                nH = (height + scaledChildHeight) / 2;
                top = (height - scaledChildHeight) / 2;
                left = 0;
            }
            child.layout(left, top, nW, nH);

            Log.d("layout", "left:" + left);
            Log.d("layout", "top:" + top);
            Log.d("layout", "right:" + nW);
            Log.d("layout", "bottom:" + nH);
        }
    }

    public void surfaceCreated(SurfaceHolder holder) {
        // The Surface has been created, acquire the camera and tell it where
        // to draw.
        try {
            if (mCamera != null) {
                mSurfaceView.setWillNotDraw(false);
                mCamera.setPreviewDisplay(holder);
            }
        } catch (IOException exception) {
            Log.e(TAG, "IOException caused by setPreviewDisplay()", exception);
        }
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        // Surface will be destroyed when we return, so stop the preview.
        if (mCamera != null) {
            mCamera.stopPreview();
        }
    }
    private Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
        final double ASPECT_TOLERANCE = 0.1;
        double targetRatio = (double) w / h;
        if (sizes == null) return null;

        Camera.Size optimalSize = null;
        double minDiff = Double.MAX_VALUE;

        int targetHeight = h;

        // Try to find an size match aspect ratio and size
        for (Camera.Size size : sizes) {
            double ratio = (double) size.width / size.height;
            if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
            if (Math.abs(size.height - targetHeight) < minDiff) {
                optimalSize = size;
                minDiff = Math.abs(size.height - targetHeight);
            }
        }

        // Cannot find the one match the aspect ratio, ignore the requirement
        if (optimalSize == null) {
            minDiff = Double.MAX_VALUE;
            for (Camera.Size size : sizes) {
                if (Math.abs(size.height - targetHeight) < minDiff) {
                    optimalSize = size;
                    minDiff = Math.abs(size.height - targetHeight);
                }
            }
        }
        return optimalSize;
    }

    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
	    if(mCamera != null) {
		    // Now that the size is known, set up the camera parameters and begin
		    // the preview.
		    Camera.Parameters parameters = mCamera.getParameters();
		    parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
		    requestLayout();
		    //mCamera.setDisplayOrientation(90);
		    //mCamera.setParameters(parameters);
		    mCamera.startPreview();
	    }
    }

    public byte[] getFramePicture(byte[] data, Camera camera) {
        Camera.Parameters parameters = camera.getParameters();
        int format = parameters.getPreviewFormat();

        //YUV formats require conversion
        if (format == ImageFormat.NV21 || format == ImageFormat.YUY2 || format == ImageFormat.NV16) {
            int w = parameters.getPreviewSize().width;
            int h = parameters.getPreviewSize().height;

            // Get the YuV image
            YuvImage yuvImage = new YuvImage(data, format, w, h, null);
            // Convert YuV to Jpeg
            Rect rect = new Rect(0, 0, w, h);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
            yuvImage.compressToJpeg(rect, 80, outputStream);
            return outputStream.toByteArray();
        }
        return data;
    }
    public void setOneShotPreviewCallback(Camera.PreviewCallback callback) {
        if(mCamera != null) {
            mCamera.setOneShotPreviewCallback(callback);
        }
    }
}

class CustomSurfaceView extends SurfaceView implements SurfaceHolder.Callback{
    private final String TAG = "CustomSurfaceView";

    CustomSurfaceView(Context context){
        super(context);
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
    }
}