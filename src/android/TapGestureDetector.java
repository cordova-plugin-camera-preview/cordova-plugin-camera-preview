package com.cordovaplugincamerapreview;

import android.view.GestureDetector;
import android.view.MotionEvent;

class TapGestureDetector extends GestureDetector.SimpleOnGestureListener{
  private final String TAG = "TapGestureDetector";

  @Override
  public boolean onDown(MotionEvent e) {
    return false;
  }

  @Override
  public boolean onSingleTapUp(MotionEvent e) {
    return true;
  }

  @Override
  public boolean onSingleTapConfirmed(MotionEvent e) {
    return true;
  }
}
