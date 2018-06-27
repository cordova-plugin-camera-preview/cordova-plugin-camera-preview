
package com.cordovaplugincamerapreview;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.app.Fragment;
import android.content.Context;
import android.content.pm.PackageManager;
import android.content.res.Configuration;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.graphics.RectF;
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
import android.view.OrientationEventListener;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.view.WindowManager;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.support.media.ExifInterface;

import org.apache.cordova.LOG;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.Exception;
import java.lang.Integer;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Arrays;
import java.util.concurrent.locks.ReentrantLock;

abstract class SimpleOrientationListener extends OrientationEventListener {

    public static final int CONFIGURATION_ORIENTATION_UNDEFINED = Configuration.ORIENTATION_UNDEFINED;
    private volatile int defaultScreenOrientation = CONFIGURATION_ORIENTATION_UNDEFINED;
    public int prevOrientation = OrientationEventListener.ORIENTATION_UNKNOWN;
    private Context ctx;
    private ReentrantLock lock = new ReentrantLock(true);
    public static int ORIENTATION_LANDSCAPE_RIGHT = 403;
    public static int ORIENTATION_LANDSCAPE_LEFT = 402;
    public static int ORIENTATION_PORTRAIT = 400;
    public static int ORIENTATION_PORTRAIT_UPSIDE_DOWN = 4001;

    public SimpleOrientationListener(Context context) {
        super(context);
        ctx = context;
    }

    @Override
    public void onOrientationChanged(final int orientation) {
        int currentOrientation = OrientationEventListener.ORIENTATION_UNKNOWN;
        if (orientation >= 330 || orientation < 30) {
            currentOrientation = Surface.ROTATION_0;
        } else if (orientation >= 60 && orientation < 120) {
            currentOrientation = Surface.ROTATION_90;
        } else if (orientation >= 150 && orientation < 210) {
            currentOrientation = Surface.ROTATION_180;
        } else if (orientation >= 240 && orientation < 300) {
            currentOrientation = Surface.ROTATION_270;
        }

        if (prevOrientation != currentOrientation && orientation != OrientationEventListener.ORIENTATION_UNKNOWN) {
            prevOrientation = currentOrientation;
            if (currentOrientation != OrientationEventListener.ORIENTATION_UNKNOWN)
                reportOrientationChanged(currentOrientation);
        }

    }

    private void reportOrientationChanged(final int currentOrientation) {

        int defaultOrientation = getDeviceDefaultOrientation();
        int orthogonalOrientation = defaultOrientation == Configuration.ORIENTATION_LANDSCAPE ? Configuration.ORIENTATION_PORTRAIT
                : Configuration.ORIENTATION_LANDSCAPE;

        int toReportOrientation;

        if (currentOrientation == Surface.ROTATION_0 || currentOrientation == Surface.ROTATION_180)
            toReportOrientation = defaultOrientation;
        else
            toReportOrientation = orthogonalOrientation;

        int orient = defaultOrientation;
        if (toReportOrientation == Configuration.ORIENTATION_LANDSCAPE) {
            if (currentOrientation == Surface.ROTATION_90) {
                orient = ORIENTATION_LANDSCAPE_RIGHT;
            } else {
                orient = ORIENTATION_LANDSCAPE_LEFT;
            }
            //Log.d("CameraActivity", "ORIENTATION_LANDSCAPE: "+ currentOrientation);
        } else if (toReportOrientation == Configuration.ORIENTATION_PORTRAIT) {
            if (currentOrientation == Surface.ROTATION_180) {
                orient = ORIENTATION_PORTRAIT_UPSIDE_DOWN;
            } else {
                orient = ORIENTATION_PORTRAIT;
            }
            // Log.d("CameraActivity", "ORIENTATION_PORTRAIT: "+ currentOrientation + " orient: "+ orient);
        }

        onSimpleOrientationChanged(orient);
    }

    /**
     * Must determine what is default device orientation (some tablets can have default landscape). Must be initialized when device orientation is defined.
     *
     * @return value of {@link Configuration#ORIENTATION_LANDSCAPE} or {@link Configuration#ORIENTATION_PORTRAIT}
     */
    private int getDeviceDefaultOrientation() {
        if (defaultScreenOrientation == CONFIGURATION_ORIENTATION_UNDEFINED) {
            lock.lock();
            defaultScreenOrientation = initDeviceDefaultOrientation(ctx);
            lock.unlock();
        }
        return defaultScreenOrientation;
    }

    /**
     * Provides device default orientation
     *
     * @return value of {@link Configuration#ORIENTATION_LANDSCAPE} or {@link Configuration#ORIENTATION_PORTRAIT}
     */
    private int initDeviceDefaultOrientation(Context context) {

        WindowManager windowManager = (WindowManager) context.getSystemService(Context.WINDOW_SERVICE);
        Configuration config = context.getResources().getConfiguration();
        int rotation = windowManager.getDefaultDisplay().getRotation();

        boolean isLand = config.orientation == Configuration.ORIENTATION_LANDSCAPE;
        boolean isDefaultAxis = rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180;

        int result = CONFIGURATION_ORIENTATION_UNDEFINED;
        if ((isDefaultAxis && isLand) || (!isDefaultAxis && !isLand)) {
            result = Configuration.ORIENTATION_LANDSCAPE;
        } else {
            result = Configuration.ORIENTATION_PORTRAIT;
        }
        return result;
    }

    /**
     * Fires when orientation changes from landscape to portrait and vice versa.
     *
     * @param orientation value of {@link Configuration#ORIENTATION_LANDSCAPE} or {@link Configuration#ORIENTATION_PORTRAIT}
     */
    public abstract void onSimpleOrientationChanged(int orientation);

}