import AVFoundation
import CoreImage

protocol OnFocusDelegate: class {
    func onFocus()
}

class CameraSessionManager: NSObject {

    var ciFilter: CIFilter?
    var filterLock: NSLock?
    var session: AVCaptureSession?
    var sessionQueue: DispatchQueue?
    var defaultCamera: AVCaptureDevice.Position?
    var defaultFlashMode: AVCaptureDevice.FlashMode = .off
    var videoZoomFactor: CGFloat = 0.0
    var device: AVCaptureDevice?
    var videoDeviceInput: AVCaptureDeviceInput?
    var stillImageOutput: AVCaptureStillImageOutput?
    var dataOutput: AVCaptureVideoDataOutput?
    var delegate: CameraRenderController?
    var currentWhiteBalanceMode = ""
    var colorTemperatures = [String: TemperatureAndTint]()

    override init() {
        super.init()

        // Create the AVCaptureSession
        session = AVCaptureSession()
        sessionQueue = DispatchQueue(label: "session queue")
        if (session?.canSetSessionPreset(AVCaptureSessionPresetPhoto))! {
            session?.sessionPreset = AVCaptureSessionPresetPhoto
        }
        filterLock = NSLock()
        let wbIncandescent = TemperatureAndTint()
        wbIncandescent.mode = "incandescent"
        wbIncandescent.minTemperature = 2200
        wbIncandescent.maxTemperature = 3200
        wbIncandescent.tint = 0
        let wbCloudyDaylight = TemperatureAndTint()
        wbCloudyDaylight.mode = "cloudy-daylight"
        wbCloudyDaylight.minTemperature = 6000
        wbCloudyDaylight.maxTemperature = 7000
        wbCloudyDaylight.tint = 0
        let wbDaylight = TemperatureAndTint()
        wbDaylight.mode = "daylight"
        wbDaylight.minTemperature = 5500
        wbDaylight.maxTemperature = 5800
        wbDaylight.tint = 0
        let wbFluorescent = TemperatureAndTint()
        wbFluorescent.mode = "fluorescent"
        wbFluorescent.minTemperature = 3300
        wbFluorescent.maxTemperature = 3800
        wbFluorescent.tint = 0
        let wbShade = TemperatureAndTint()
        wbShade.mode = "shade"
        wbShade.minTemperature = 7000
        wbShade.maxTemperature = 8000
        wbShade.tint = 0
        let wbWarmFluorescent = TemperatureAndTint()
        wbWarmFluorescent.mode = "warm-fluorescent"
        wbWarmFluorescent.minTemperature = 3000
        wbWarmFluorescent.maxTemperature = 3000
        wbWarmFluorescent.tint = 0
        let wbTwilight = TemperatureAndTint()
        wbTwilight.mode = "twilight"
        wbTwilight.minTemperature = 4000
        wbTwilight.maxTemperature = 4400
        wbTwilight.tint = 0
        
        colorTemperatures["incandescent"] = wbIncandescent
        colorTemperatures["cloudy-daylight"] = wbCloudyDaylight
        colorTemperatures["daylight"] = wbDaylight
        colorTemperatures["fluorescent"] = wbFluorescent
        colorTemperatures["shade"] = wbShade
        colorTemperatures["warm-fluorescent"] = wbWarmFluorescent
        colorTemperatures["twilight"] = wbTwilight
    }

    func getDeviceFormats() -> [Any] {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        return (videoDevice?.formats)!
    }

    func getCurrentOrientation() -> AVCaptureVideoOrientation {
        return getCurrentOrientation(UIApplication.shared.statusBarOrientation)
    }

    func getCurrentOrientation(_ toInterfaceOrientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        
        
        switch toInterfaceOrientation {
            case .portraitUpsideDown:
                orientation = .portraitUpsideDown
            case .landscapeRight:
                orientation = .landscapeRight
            case .landscapeLeft:
                orientation = .landscapeLeft
            case .portrait:
                orientation = .portrait
            default:
                orientation = .portrait
        }
        return orientation
    }
    
    func setupSession(_ defaultCamera: String?, completion: @escaping (_ started: Bool) -> Void) {
        // If this fails, video input will just stream blank frames and the user will be notified. User only has to accept once.
        checkDeviceAuthorizationStatus()
        sessionQueue?.async(execute: {() -> Void in
            let error: Error? = nil
            var success = true
            print("defaultCamera: \(defaultCamera ?? "")")
            if defaultCamera == "front" {
                self.defaultCamera = .front
            } else {
                self.defaultCamera = .back
            }
            let videoDevice: AVCaptureDevice? = self.cameraWithPosition(position: self.defaultCamera!)
            if videoDevice?.hasFlash ?? false && videoDevice?.isFlashModeSupported(.auto) ?? false {
                if try! videoDevice?.lockForConfiguration() != nil {
                    videoDevice?.flashMode = .auto
                    videoDevice?.unlockForConfiguration()
                } else {
                    if let anError = error {
                        print("\(anError)")
                    }
                    success = false
                }
            }
            var videoDeviceInput: AVCaptureDeviceInput? = nil
            
            if let aDevice = videoDevice {
                videoDeviceInput = try? AVCaptureDeviceInput(device: aDevice)
            }
            
            if error != nil {
                print("\(error)")
                success = false
            }
            
            if (self.session?.canAddInput(videoDeviceInput))! {
                self.session?.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }

            let stillImageOutput = AVCaptureStillImageOutput()
            if (self.session?.canAddOutput(stillImageOutput))! {
                self.session?.addOutput(stillImageOutput)
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                self.stillImageOutput = stillImageOutput
            }
            let dataOutput = AVCaptureVideoDataOutput()
            if (self.session?.canAddOutput(dataOutput))! {
                self.dataOutput = dataOutput
                dataOutput.alwaysDiscardsLateVideoFrames = true
                dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA]
                dataOutput.setSampleBufferDelegate(self.delegate as! AVCaptureVideoDataOutputSampleBufferDelegate, queue: self.sessionQueue)
                self.session?.addOutput(dataOutput)
            }
            self.updateOrientation(self.getCurrentOrientation())
            self.device = videoDevice
            completion(success)
        })
    }

    func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
        var captureConnection: AVCaptureConnection?
        if stillImageOutput != nil {
            captureConnection = stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
            if captureConnection?.isVideoOrientationSupported != nil {
                captureConnection?.videoOrientation = orientation
            }
        }
        if dataOutput != nil {
            captureConnection = dataOutput?.connection(withMediaType: AVMediaTypeVideo)
            if captureConnection?.isVideoOrientationSupported != nil {
                captureConnection?.videoOrientation = orientation
            }
        }
    }

    func switchCamera(_ completion: @escaping (_ switched: Bool) -> Void) {
        if defaultCamera == .front {
            defaultCamera = .back
        } else {
            defaultCamera = .front
        }
        sessionQueue?.async(execute: {() -> Void in
            var error: Error? = nil
            var success = true
            self.session?.beginConfiguration()
            if self.videoDeviceInput != nil {
                self.session?.removeInput(self.videoDeviceInput)
                self.videoDeviceInput = nil
            }
            var videoDevice: AVCaptureDevice? = nil
            videoDevice = self.cameraWithPosition(position: self.defaultCamera!)
            if videoDevice?.hasFlash ?? false && videoDevice?.isFlashModeSupported(AVCaptureFlashMode(rawValue: self.defaultFlashMode.rawValue)!) ?? false {
                if try! videoDevice?.lockForConfiguration() != nil {
                    videoDevice?.flashMode = AVCaptureFlashMode(rawValue: self.defaultFlashMode.rawValue)!
                    videoDevice?.unlockForConfiguration()
                } else {
                    if let anError = error {
                        print("\(anError)")
                    }
                    success = false
                }
            }
            var videoDeviceInput: AVCaptureDeviceInput? = nil
            if let aDevice = videoDevice {
                videoDeviceInput = try? AVCaptureDeviceInput(device: aDevice)
            }
            if error != nil {
                if let anError = error {
                    print("\(anError)")
                }
                success = false
            }
            
            if (self.session?.canAddInput(videoDeviceInput))! {
                self.session?.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }

            self.updateOrientation(self.getCurrentOrientation())
            self.session?.commitConfiguration()
            self.device = videoDevice
            completion(success)
        })
    }

    func getFocusModes() -> [Any]? {
        var focusModes = [AnyHashable]()
        if (device?.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 0)!))! {
            focusModes.append("fixed")
        }
        if (device?.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 1)!))! {
            focusModes.append("auto")
        }
        if (device?.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 2)!))! {
            focusModes.append("continuous")
        }
        return focusModes as? [Any]
    }

    func getFocusMode() -> String? {
        var focusMode: String
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        switch videoDevice!.focusMode {
            case .locked:
                focusMode = "fixed"
            case .autoFocus:
                focusMode = "auto"
            case .continuousAutoFocus:
                focusMode = "continuous"
            default:
                focusMode = "unsupported"
                print("Mode not supported")
        }
        return focusMode
    }

    func setFocusmode(_ focusMode: String?) -> String? {
        var errMsg = ""
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        try? device?.lockForConfiguration()
        if focusMode == "fixed" {
            if videoDevice?.isFocusModeSupported(.locked) ?? false {
                videoDevice?.focusMode = .locked
            } else {
                errMsg = "Focus mode not supported"
            }
        } else if focusMode == "auto" {
            if videoDevice?.isFocusModeSupported(.autoFocus) ?? false {
                videoDevice?.focusMode = .autoFocus
            } else {
                errMsg = "Focus mode not supported"
            }
        } else if focusMode == "continuous" {
            if videoDevice?.isFocusModeSupported(.continuousAutoFocus) ?? false {
                videoDevice?.focusMode = .continuousAutoFocus
            } else {
                errMsg = "Focus mode not supported"
            }
        } else {
            errMsg = "Exposure mode not supported"
        }
        device?.unlockForConfiguration()
        if errMsg != "" {
            print("\(errMsg)")
            return "ERR01"
        }
        return focusMode
    }


    func getFlashModes() -> [Any]? {
        var flashModes = [AnyHashable]()
        if (device?.hasFlash)! {
            if (device?.isFlashModeSupported(.off))! {
                flashModes.append("off")
            }
            if (device?.isFlashModeSupported(.on))! {
                flashModes.append("on")
            }
            if (device?.isFlashModeSupported(.off))! {
                flashModes.append("auto")
            }
            if (device?.hasTorch)! {
                flashModes.append("torch")
            }
        }
        return flashModes as? [Any]
    }

    func getFlashMode() -> Int {
        if device!.hasFlash && device!.isFlashModeSupported(AVCaptureFlashMode(rawValue: defaultFlashMode.rawValue)!) {
            return device!.flashMode.rawValue
        }
        return -1
    }

    func setFlashMode(_ flashMode: AVCaptureDevice.FlashMode) {
        var error: Error? = nil
        // Let's save the setting even if we can't set it up on this camera.
        defaultFlashMode = flashMode
        if device!.hasFlash && device!.isFlashModeSupported(AVCaptureFlashMode(rawValue: defaultFlashMode.rawValue)!) {
            if try! device?.lockForConfiguration() != nil {
                if device!.hasTorch && device!.isTorchAvailable {
                    device?.torchMode = .off
                }
                device?.flashMode = AVCaptureFlashMode(rawValue: defaultFlashMode.rawValue)!
                device?.unlockForConfiguration()
            } else {
                if let anError = error {
                    print("\(anError)")
                }
            }
        } else {
            print("Camera has no flash or flash mode not supported")
        }
    }

    func setTorchMode() {
        var error: Error? = nil
        // Let's save the setting even if we can't set it up on this camera.
        //self.defaultFlashMode = flashMode;
        if device!.hasTorch && device!.isTorchAvailable {
            if try! device?.lockForConfiguration() != nil {
                if (device?.isTorchModeSupported(.on))! {
                    device?.torchMode = .on
                } else if (device?.isTorchModeSupported(.auto))! {
                    device?.torchMode = .auto
                } else {
                    device?.torchMode = .off
                }
                device?.unlockForConfiguration()
            } else {
                if let anError = error {
                    print("\(anError)")
                }
            }
        } else {
            print("Camera has no flash or flash mode not supported")
        }
    }

    func setZoom(_ desiredZoomFactor: CGFloat) {
        try? device?.lockForConfiguration()
        videoZoomFactor = max(1.0, min(desiredZoomFactor, (device?.activeFormat.videoMaxZoomFactor)!))
        device?.videoZoomFactor = videoZoomFactor
        device?.unlockForConfiguration()
        print("\(videoZoomFactor) zoom factor set")
    }

    func getZoom() -> CGFloat {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        return videoDevice?.videoZoomFactor ?? 0.0
    }

    func getHorizontalFOV() -> Float {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        return videoDevice?.activeFormat.videoFieldOfView ?? 0.0
    }

    func getMaxZoom() -> CGFloat {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        return videoDevice?.activeFormat.videoMaxZoomFactor ?? 0.0
    }

    func getExposureModes() -> [Any]? {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        var exposureModes = [AnyHashable]()
        if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 0)!) ?? false {
            exposureModes.append("lock")
        }
        if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 1)!) ?? false {
            exposureModes.append("auto")
        }
        if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 2)!) ?? false {
            exposureModes.append("cotinuous")
        }
        if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 3)!) ?? false {
            exposureModes.append("custom")
        }
        print("\(exposureModes)")
        return exposureModes as [Any]
    }

    func getExposureMode() -> String? {
        var exposureMode: String
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        switch videoDevice?.exposureMode {
            case AVCaptureDevice.ExposureMode(rawValue: 0):
                exposureMode = "lock"
            case AVCaptureDevice.ExposureMode(rawValue: 1):
                exposureMode = "auto"
            case AVCaptureDevice.ExposureMode(rawValue: 2):
                exposureMode = "continuous"
            case AVCaptureDevice.ExposureMode(rawValue: 3):
                exposureMode = "custom"
            default:
                exposureMode = "unsupported"
                print("Mode not supported")
        }
        return exposureMode
    }

    func setExposureMode(_ exposureMode: String?) -> String? {
        var errMsg = ""
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        try? device?.lockForConfiguration()
        if exposureMode == "lock" {
            if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 0)!) ?? false {
                videoDevice?.exposureMode = AVCaptureDevice.ExposureMode(rawValue: 0)!
            } else {
                errMsg = "Exposure mode not supported"
            }
        } else if exposureMode == "auto" {
            if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 1)!) ?? false {
                videoDevice?.exposureMode = AVCaptureDevice.ExposureMode(rawValue: 1)!
            } else {
                errMsg = "Exposure mode not supported"
            }
        } else if exposureMode == "continuous" {
            if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 2)!) ?? false {
                videoDevice?.exposureMode = AVCaptureDevice.ExposureMode(rawValue: 2)!
            } else {
                errMsg = "Exposure mode not supported"
            }
        } else if exposureMode == "custom" {
            if videoDevice?.isExposureModeSupported(AVCaptureDevice.ExposureMode(rawValue: 3)!) ?? false {
                videoDevice?.exposureMode = AVCaptureDevice.ExposureMode(rawValue: 3)!
            } else {
                errMsg = "Exposure mode not supported"
            }
        } else {
            errMsg = "Exposure mode not supported"
        }
        device?.unlockForConfiguration()
        if errMsg != "" {
            print("\(errMsg)")
            return "ERR01"
        }
        return exposureMode
    }

    func getExposureCompensationRange() -> [Any]? {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        let maxExposureCompensation = CGFloat(videoDevice?.maxExposureTargetBias ?? 0.0)
        let minExposureCompensation = CGFloat(videoDevice?.minExposureTargetBias ?? 0.0)
        let exposureCompensationRange = [minExposureCompensation, maxExposureCompensation]
        return exposureCompensationRange
    }

    func getExposureCompensation() -> CGFloat {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        print("getExposureCompensation: \(videoDevice?.exposureTargetBias ?? 0.0)")
        return CGFloat(videoDevice?.exposureTargetBias ?? 0.0)
    }

    func setExposureCompensation(_ exposureCompensation: Float) {
        var error: Error? = nil
        if try! device?.lockForConfiguration() != nil {
            let exposureTargetBias: Float = max(device!.minExposureTargetBias, min(exposureCompensation, (device?.maxExposureTargetBias)!))
            device?.setExposureTargetBias(Float(exposureTargetBias), completionHandler: nil)
            device?.unlockForConfiguration()
        } else {
            if let anError = error {
                print("\(anError)")
            }
        }
    }

    func getSupportedWhiteBalanceModes() -> [Any]? {
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        print("maxWhiteBalanceGain: \(videoDevice?.maxWhiteBalanceGain ?? 0.0)")
        var whiteBalanceModes = [AnyHashable]()
        if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 0)!) ?? false {
            whiteBalanceModes.append("lock")
        }
        if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 1)!) ?? false {
            whiteBalanceModes.append("auto")
        }
        if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 2)!) ?? false {
            whiteBalanceModes.append("continuous")
        }
        
        var enumerator = colorTemperatures.values.makeIterator()
        let wbTemperature: TemperatureAndTint! = TemperatureAndTint()
        
        while wbTemperature == enumerator.next() {
            var temperatureAndTintValues: AVCaptureWhiteBalanceTemperatureAndTintValues! = AVCaptureWhiteBalanceTemperatureAndTintValues()
            temperatureAndTintValues.temperature = ((wbTemperature?.minTemperature)! + (wbTemperature?.maxTemperature)!) / 2
            temperatureAndTintValues.tint = wbTemperature?.tint ?? 0.0
            
            let rgbGains: AVCaptureWhiteBalanceGains? = videoDevice?.deviceWhiteBalanceGains(for: temperatureAndTintValues)
            if let aMode = wbTemperature?.mode {
                print("mode: \(aMode)")
            }
            if let aTemperature = wbTemperature?.minTemperature {
                print("minTemperature: \(aTemperature)")
            }
            if let aTemperature = wbTemperature?.maxTemperature {
                print("maxTemperature: \(aTemperature)")
            }
            print("blueGain: \(rgbGains?.blueGain ?? 0.0)")
            print("redGain: \(rgbGains?.redGain ?? 0.0)")
            print("greenGain: \(rgbGains?.greenGain ?? 0.0)")
            if ((rgbGains?.blueGain ?? 0.0) >= 1) && ((rgbGains?.blueGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.redGain ?? 0.0) >= 1) && ((rgbGains?.redGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.greenGain ?? 0.0) >= 1) && ((rgbGains?.greenGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) {
                if let aMode = wbTemperature?.mode {
                    whiteBalanceModes.append(aMode)
                }
            }
        }
        print("\(whiteBalanceModes)")
        return whiteBalanceModes
    }

    func getWhiteBalanceMode() -> String? {
        var whiteBalanceMode: String
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        switch videoDevice?.whiteBalanceMode {
            case AVCaptureDevice.WhiteBalanceMode (rawValue: 0):
                whiteBalanceMode = "lock"
                if currentWhiteBalanceMode != nil {
                    whiteBalanceMode = currentWhiteBalanceMode
                }
            case AVCaptureDevice.WhiteBalanceMode (rawValue: 1):
                whiteBalanceMode = "auto"
            case AVCaptureDevice.WhiteBalanceMode (rawValue: 2):
                whiteBalanceMode = "continuous"
            default:
                whiteBalanceMode = "unsupported"
                print("White balance mode not supported")
        }
        return whiteBalanceMode
    }
    
    func setWhiteBalanceMode(_ whiteBalanceMode: String?) -> String? {
        var errMsg = "";
        print("plugin White balance mode: \(whiteBalanceMode ?? "")")
        let videoDevice: AVCaptureDevice? = cameraWithPosition(position: defaultCamera!)
        try? device?.lockForConfiguration()
        if whiteBalanceMode == "lock" {
            if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 0)!) ?? false {
                videoDevice?.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode(rawValue: 0)!
            } else {
                errMsg = "White balance mode not supported"
            }
        } else if whiteBalanceMode == "auto" {
            if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 1)!) ?? false {
                videoDevice?.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode(rawValue: 1)!
            } else {
                errMsg = "White balance mode not supported"
            }
        } else if whiteBalanceMode == "continuous" {
            if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 2)!) ?? false {
                videoDevice?.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode(rawValue: 2)!
            } else {
                errMsg = "White balance mode not supported"
            }
        } else {
            print("Additional modes for \(whiteBalanceMode ?? "")")
            let temperatureForWhiteBalanceSetting = colorTemperatures[whiteBalanceMode!]
            if temperatureForWhiteBalanceSetting != nil {
                var temperatureAndTintValues: AVCaptureWhiteBalanceTemperatureAndTintValues! = AVCaptureWhiteBalanceTemperatureAndTintValues()
                temperatureAndTintValues.temperature = ((temperatureForWhiteBalanceSetting?.minTemperature)! + (temperatureForWhiteBalanceSetting?.maxTemperature)!) / 2
                temperatureAndTintValues.tint = temperatureForWhiteBalanceSetting?.tint ?? 0.0
                let rgbGains: AVCaptureWhiteBalanceGains? = videoDevice?.deviceWhiteBalanceGains(for: temperatureAndTintValues)
                if ((rgbGains?.blueGain ?? 0.0) >= 1) && ((rgbGains?.blueGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.redGain ?? 0.0) >= 1) && ((rgbGains?.redGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.greenGain ?? 0.0) >= 1) && ((rgbGains?.greenGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) {
                    if let aGains = rgbGains {
                        videoDevice?.setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains(aGains, completionHandler: nil)
                    }
                    currentWhiteBalanceMode = whiteBalanceMode!
                } else {
                    errMsg = "White balance mode not supported"
                }
            } else {
                errMsg = "White balance mode not supported"
            }
        }
        device?.unlockForConfiguration()
        
        if errMsg != "" {
            print("\(errMsg)")
            return "ERR01"
        }
        
        return whiteBalanceMode
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // removes the observer, when the camera is done focusing.
        if (keyPath == "adjustingFocus") {
            let adjustingFocus: Bool = change?[.newKey] as? Int == 1
            if !adjustingFocus {
                device?.removeObserver(self, forKeyPath: "adjustingFocus")
                delegate?.onFocus()
            }
        }
    }

    func takePictureOnFocus() {
        // add an observer, when takePictureOnFocus is requested
        let flag: NSKeyValueObservingOptions = .new
        device?.addObserver(self, forKeyPath: "adjustingFocus", options: flag, context: nil)
    }

    func tapToFocus(toFocus xPoint: CGFloat, yPoint: CGFloat) {
        try! device?.lockForConfiguration()
        let screenRect: CGRect = UIScreen.main.bounds
        let screenWidth: CGFloat = screenRect.size.width
        let screenHeight: CGFloat = screenRect.size.height
        let focus_x: CGFloat = xPoint / screenWidth
        let focus_y: CGFloat = yPoint / screenHeight
        if (device?.isFocusModeSupported(.autoFocus))! {
            device?.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
            device?.focusMode = .autoFocus
        }
        if (device?.isExposureModeSupported(.autoExpose))! {
            device?.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y)
            device?.exposureMode = .autoExpose
        }
        device?.unlockForConfiguration()
    }

    func checkDeviceAuthorizationStatus() {
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: {(_ granted: Bool) -> Void in
            if !granted {
                // Not granted access to mediaType
                DispatchQueue.main.async(execute: {() -> Void in
                    let alert = UIAlertController(title: "Error", message: "Camera permission not found. Please, check your privacy settings.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`))
                    self.delegate?.present(alert, animated: true, completion: nil)
                })
            }
        })
    }

    // Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) as! [AVCaptureDevice]
        
        for device: AVCaptureDevice in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
}

