# Changelog

## MASTER BRANCH (RECOMMENDED) - UNRELEASED
- [#630](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/630) - For Android, make both camera and autofocus non-required for the library. This is an application level concern.

## v0.12.1 - Oct 21, 2020 - LATEST RELEASED VERSIO
- [#624](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/issues/624) - Remove unused coefficient argument from the `calculateTapArea` method of the Android code
- [#619](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/619) - Fix compiler errors in startRecordVideo by declaring final variables
- [#615](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/615) - Correctly handle torch mode in getFlashMode

## v0.12.0 - May 4, 2020
- [#605](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/605) - Improve memory usage when capturing multiple photos for both Android and iOS
- [#587](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/587) - Add video recording functionality for Android
- [#599](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/599) - Use androidx package instead of legacy android support package
- [#606](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/606) - Remove `android:required` from manifest to avoid conflict with other plugins

## v0.11.2 - February 12, 2020
- [#582](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/582) - Add support for Android devices without Autofocus which can increase the amount of devices for which app installation is allowed by about (~4k at time of)
- [#583](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/583) - Fix typescript error CameraPreview.d.ts is not a module 

## v0.11.1 - November 19, 2019
- [#573](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/573) - Fetch number of cameras immediately before switching cameras in Android
- [#428](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/issues/428) - Fix mispelling of `continuous` within iOS source code for focus modes (was `cotinuous` before)
- [#568](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/568), [PR #570](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/570) - Resolves plugin interaction issues when toBack is set and other plugins like cordova-plugin-googlemaps are changing the layout

## v0.11.0 - May 20, 2019
- [#525](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/525) - Add function `takeSnapshot` for quick image captures
- [#441](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/441) - Add android only option `storeToFile` for storage in temporary file instead of base64
- [#524](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/524) - Add iOS support for `storeToFile`
- [#396](https://github.com/cordova-plugin-camera-preview/cordova-plugin-camera-preview/pull/396) - Add function `getCameraCharacteristics`
- Allow `startCamera` to allow no options object when only callback is provided
- Add Changelog

## v0.10.0 - June 13, 2018
- Merge in features and fixes from various forks

## v0.9.0 - May 9, 2017

## v0.0.8 - March 30, 2015

## v0.0.6 - February 4, 2015

## v0.0.3 - January 12, 2015

## v0.0.2 - January 7, 2015
