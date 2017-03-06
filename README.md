cordova-plugin-camera-preview Sample Cordova App
=======================

This is a sample cordova application for <a href="https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview">cordova-plugin-camera-preview</a>

## Install
```
cordova platform add android
cordova build android

cordova platform add ios
cordova build ios
```

## Reset / Update Plugin to Latest

If you last installed an older version of the plugin and want to ensure the sample app is up to date again just do the following to reset.

```
rm -rf platforms/ plugins/

cordova platform add android
cordova build android

cordova platform add ios
cordova build ios
```

## IOS Quirks

It is not possible to use your computers webcam during testing in the simulator, you must device test
