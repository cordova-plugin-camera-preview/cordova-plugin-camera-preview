//  The converted code is limited to 4 KB.
//  Upgrade your plan to remove this limitation.
//
//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
class CameraSessionManager {
    init() {
        super.init()

        // Create the AVCaptureSession
        session = AVCaptureSession()
        sessionQueue = DispatchQueue(label: "session queue")
        if session.canSetSessionPreset(.photo) {
            session.sessionPreset = .photo
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
        colorTemperatures = [AnyHashable: Any](objects: [wbIncandescent, wbCloudyDaylight, wbDaylight, wbFluorescent, wbShade, wbWarmFluorescent, wbTwilight], forKeys: ["incandescent", "cloudy-daylight", "daylight", "fluorescent", "shade", "warm-fluorescent", "twilight"])
    
    }

    func getDeviceFormats() -> [Any]? {
        let videoDevice: AVCaptureDevice? = camera(with: defaultCamera)
        return videoDevice?.formats
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
            case default, .portrait:
                orientation = .portrait
        }
        return orientation
    }
//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
func setupSession(_ defaultCamera: String?, completion: @escaping (_ started: Bool) -> Void) {
    // If this fails, video input will just stream blank frames and the user will be notified. User only has to accept once.
    checkDeviceAuthorizationStatus()
    sessionQueue.async(execute: {() -> Void in
        var error: Error? = nil
        var success = true
        print("defaultCamera: \(defaultCamera ?? "")")
        if defaultCamera == "front" {
            self.defaultCamera = .front
        } else {
            self.defaultCamera = .back
        }
        let videoDevice: AVCaptureDevice? = self.camera(withPosition: self.defaultCamera)
        if videoDevice?.hasFlash ?? false && videoDevice?.isFlashModeSupported(.auto) ?? false {
            if try? videoDevice?.lockForConfiguration() != nil {
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
            if let anError = error {
                print("\(anError)")
            }
            success = false
        }
        if let anInput = videoDeviceInput {
            if self.session.canAdd(anInput) {
                if let anInput = videoDeviceInput {
                    self.session.add(anInput)
                }
                self.videoDeviceInput = videoDeviceInput
            }
        }
        let stillImageOutput = AVCaptureStillImageOutput()
        if self.session.canAdd(stillImageOutput) {
            self.session.add(stillImageOutput)
            stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            self.stillImageOutput = stillImageOutput
        }
        let dataOutput = AVCaptureVideoDataOutput()
        if self.session.canAdd(dataOutput) {
            self.dataOutput = dataOutput
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : kCVPixelFormatType_32BGRA]
            dataOutput.setSampleBufferDelegate(self.delegate, queue: self.sessionQueue)
            self.session.add(dataOutput)
        }
        self.update(self.getCurrentOrientation())
        self.device = videoDevice
        completion(success)
    })
}

func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
    var captureConnection: AVCaptureConnection?
    if stillImageOutput != nil {
        captureConnection = stillImageOutput.connection(with: .video)
        if captureConnection?.isVideoOrientationSupported() != nil {
            captureConnection?.videoOrientation = orientation
        }
    }
    if dataOutput != nil {
        captureConnection = dataOutput.connection(with: .video)
        if captureConnection?.isVideoOrientationSupported() != nil {
            captureConnection?.videoOrientation = orientation
        }
    }
}

//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
func switchCamera(_ completion: @escaping (_ switched: Bool) -> Void) {
    if defaultCamera == .front {
        defaultCamera = .back
    } else {
        defaultCamera = .front
    }
    sessionQueue.async(execute: {() -> Void in
        var error: Error? = nil
        var success = true
        self.session.beginConfiguration()
        if self.videoDeviceInput != nil {
            self.session.removeInput(self.videoDeviceInput())
            self.videoDeviceInput = nil
        }
        var videoDevice: AVCaptureDevice? = nil
        videoDevice = self.camera(withPosition: self.defaultCamera)
        if videoDevice?.hasFlash ?? false && videoDevice?.isFlashModeSupported(self.defaultFlashMode) ?? false {
            if try? videoDevice?.lockForConfiguration() != nil {
                videoDevice?.flashMode = self.defaultFlashMode
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
        if let anInput = videoDeviceInput {
            if self.session.canAdd(anInput) {
                if let anInput = videoDeviceInput {
                    self.session.add(anInput)
                }
                self.videoDeviceInput = videoDeviceInput
            }
        }
        self.updateOrientation(self.getCurrentOrientation())
        self.session.commitConfiguration()
        self.device = videoDevice
        completion(success)
    })
}

func getFocusModes() -> [Any]? {
    var focusModes = [AnyHashable]()
    if device.isFocusModeSupported([]) {
        focusModes.append("fixed")
    }
    if device.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 1)!) {
        focusModes.append("auto")
    }
    if device.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 2)!) {
        focusModes.append("continuous")
    }
    return focusModes as? [Any]
}

func getFocusMode() -> String? {
    var focusMode: String
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    switch videoDevice?.focusMode {
        case 0:
            focusMode = "fixed"
        case 1:
            focusMode = "auto"
        case 2:
            focusMode = "continuous"
        default:
            focusMode = "unsupported"
            print("Mode not supported")
    }
    return focusMode
}

//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
var focusMode: AVCaptureDevice.FocusMode {
    var errMsg: String
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    try? device.lockForConfiguration()
    if focusMode == "fixed" {
        if videoDevice?.isFocusModeSupported([]) ?? false {
            videoDevice?.focusMode = []
        } else {
            errMsg = "Focus mode not supported"
        }
    } else if focusMode == "auto" {
        if videoDevice?.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 1)!) ?? false {
            videoDevice?.focusMode = AVCaptureDevice.FocusMode(rawValue: 1)!
        } else {
            errMsg = "Focus mode not supported"
        }
    } else if focusMode == "continuous" {
        if videoDevice?.isFocusModeSupported(AVCaptureDevice.FocusMode(rawValue: 2)!) ?? false {
            videoDevice?.focusMode = AVCaptureDevice.FocusMode(rawValue: 2)!
        } else {
            errMsg = "Focus mode not supported"
        }
    } else {
        errMsg = "Exposure mode not supported"
    }
    device.unlockForConfiguration()
    if errMsg != "" {
        print("\(errMsg)")
        return "ERR01"
    }
    return focusMode
}

func getFlashModes() -> [Any]? {
    var flashModes = [AnyHashable]()
    if device.hasFlash {
        if device.isFlashModeSupported([]) {
            flashModes.append("off")
        }
        if device.isFlashModeSupported(AVCaptureDevice.FlashMode(rawValue: 1)!) {
            flashModes.append("on")
        }
        if device.isFlashModeSupported(AVCaptureDevice.FlashMode(rawValue: 2)!) {
            flashModes.append("auto")
        }
        if device.hasTorch {
            flashModes.append("torch")
        }
    }
    return flashModes as? [Any]
}

func getFlashMode() -> Int {
    if device.hasFlash && device.isFlashModeSupported(defaultFlashMode) {
        return device.flashMode
    }
    return -1
}

var flashMode: AVCaptureDevice.FlashMode {
    var error: Error? = nil
    // Let's save the setting even if we can't set it up on this camera.
    defaultFlashMode = flashMode
    if device.hasFlash && device.isFlashModeSupported(defaultFlashMode) {
        if try? device.lockForConfiguration() != nil {
            if device.hasTorch && device.isTorchAvailable() {
                device.torchMode = []
            }
            device.flashMode = defaultFlashMode
            device.unlockForConfiguration()
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
    if device.hasTorch && device.isTorchAvailable() {
        if try? device.lockForConfiguration() != nil {
            if device.isTorchModeSupported(AVCaptureDevice.TorchMode(rawValue: 1)!) {
                device.torchMode = AVCaptureDevice.TorchMode(rawValue: 1)!
            } else if device.isTorchModeSupported(AVCaptureDevice.TorchMode(rawValue: 2)!) {
                device.torchMode = AVCaptureDevice.TorchMode(rawValue: 2)!
            } else {
                device.torchMode = []
            }
            device.unlockForConfiguration()
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
    try? device.lockForConfiguration()
    videoZoomFactor = max(1.0, min(desiredZoomFactor, device.activeFormat.videoMaxZoomFactor))
    device.videoZoomFactor = videoZoomFactor
    device.unlockForConfiguration()
    print("\(videoZoomFactor) zoom factor set")
}

func getZoom() -> CGFloat {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    return videoDevice?.videoZoomFactor ?? 0.0
}

func getHorizontalFOV() -> Float {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    return videoDevice?.activeFormat.videoFieldOfView ?? 0.0
}

func getMaxZoom() -> CGFloat {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    return videoDevice?.activeFormat.videoMaxZoomFactor ?? 0.0
}

//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
func getExposureModes() -> [Any]? {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    var exposureModes = [AnyHashable]()
    if videoDevice?.isExposureModeSupported([]) ?? false {
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
    return exposureModes as? [Any]
}

func getExposureMode() -> String? {
    var exposureMode: String
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    switch videoDevice?.exposureMode {
        case 0:
            exposureMode = "lock"
        case 1:
            exposureMode = "auto"
        case 2:
            exposureMode = "continuous"
        case 3:
            exposureMode = "custom"
        default:
            exposureMode = "unsupported"
            print("Mode not supported")
    }
    return exposureMode
}

var exposureMode: AVCaptureDevice.ExposureMode {
    var errMsg: String
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    try? device.lockForConfiguration()
    if exposureMode == "lock" {
        if videoDevice?.isExposureModeSupported([]) ?? false {
            videoDevice?.exposureMode = []
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
    device.unlockForConfiguration()
    if errMsg != "" {
        print("\(errMsg)")
        return "ERR01"
    }
    return exposureMode
}

func getExposureCompensationRange() -> [Any]? {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    let maxExposureCompensation = CGFloat(videoDevice?.maxExposureTargetBias ?? 0.0)
    let minExposureCompensation = CGFloat(videoDevice?.minExposureTargetBias ?? 0.0)
    let exposureCompensationRange = [minExposureCompensation, maxExposureCompensation]
    return exposureCompensationRange
}

func getExposureCompensation() -> CGFloat {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    print("getExposureCompensation: \(videoDevice?.exposureTargetBias ?? 0.0)")
    return CGFloat(videoDevice?.exposureTargetBias ?? 0.0)
}

func setExposureCompensation(_ exposureCompensation: CGFloat) {
    var error: Error? = nil
    if try? device.lockForConfiguration() != nil {
        let exposureTargetBias: CGFloat = max(device.minExposureTargetBias, min(exposureCompensation, device.maxExposureTargetBias))
        device.setExposureTargetBias(Float(exposureTargetBias), completionHandler: nil)
        device.unlockForConfiguration()
    } else {
        if let anError = error {
            print("\(anError)")
        }
    }
}

//  The converted code is limited to 4 KB.
//  Upgrade your plan to remove this limitation.
//
//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
func getSupportedWhiteBalanceModes() -> [Any]? {
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    print("maxWhiteBalanceGain: \(videoDevice?.maxWhiteBalanceGain ?? 0.0)")
    var whiteBalanceModes = [AnyHashable]()
    if videoDevice?.isWhiteBalanceModeSupported([]) ?? false {
        whiteBalanceModes.append("lock")
    }
    if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 1)!) ?? false {
        whiteBalanceModes.append("auto")
    }
    if videoDevice?.isWhiteBalanceModeSupported(AVCaptureDevice.WhiteBalanceMode(rawValue: 2)!) ?? false {
        whiteBalanceModes.append("continuous")
    }
    let enumerator: NSEnumerator? = colorTemperatures.objectEnumerator()
    var wbTemperature: TemperatureAndTint?
    while wbTemperature = enumerator?.nextObject() as? TemperatureAndTint {
        let temperatureAndTintValues: AVCaptureWhiteBalanceTemperatureAndTintValues
        temperatureAndTintValues.temperature = (wbTemperature?.minTemperature + wbTemperature?.maxTemperature) / 2
        temperatureAndTintValues.tint = wbTemperature?.tint ?? 0.0
        let rgbGains: AVCaptureWhiteBalanceGains? = videoDevice?.deviceWhiteBalanceGains(for: temperatureAndTintValues) as? AVCaptureWhiteBalanceGains
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
    return whiteBalanceModes as? [Any]
}

func getWhiteBalanceMode() -> String? {
    var whiteBalanceMode: String
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    switch videoDevice?.whiteBalanceMode {
        case 0:
            whiteBalanceMode = "lock"
            if currentWhiteBalanceMode != nil {
                whiteBalanceMode = currentWhiteBalanceMode
            }
        case 1:
            whiteBalanceMode = "auto"
        case 2:
            whiteBalanceMode = "continuous"
        default:
            whiteBalanceMode = "unsupported"
            print("White balance mode not supported")
    }
    return whiteBalanceMode
}
//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
var whiteBalanceMode: AVCaptureDevice.WhiteBalanceMode {
    var errMsg: String
    print("plugin White balance mode: \(whiteBalanceMode ?? "")")
    let videoDevice: AVCaptureDevice? = camera(withPosition: defaultCamera)
    try? device.lockForConfiguration()
    if whiteBalanceMode == "lock" {
        if videoDevice?.isWhiteBalanceModeSupported([]) ?? false {
            videoDevice?.whiteBalanceMode = []
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
        let temperatureForWhiteBalanceSetting = colorTemperatures[whiteBalanceMode] as? TemperatureAndTint
        if temperatureForWhiteBalanceSetting != nil {
            let temperatureAndTintValues: AVCaptureWhiteBalanceTemperatureAndTintValues
            temperatureAndTintValues.temperature = (temperatureForWhiteBalanceSetting?.minTemperature + temperatureForWhiteBalanceSetting?.maxTemperature) / 2
            temperatureAndTintValues.tint = temperatureForWhiteBalanceSetting?.tint ?? 0.0
            let rgbGains: AVCaptureWhiteBalanceGains? = videoDevice?.deviceWhiteBalanceGains(for: temperatureAndTintValues) as? AVCaptureWhiteBalanceGains
            if ((rgbGains?.blueGain ?? 0.0) >= 1) && ((rgbGains?.blueGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.redGain ?? 0.0) >= 1) && ((rgbGains?.redGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) && ((rgbGains?.greenGain ?? 0.0) >= 1) && ((rgbGains?.greenGain ?? 0.0) <= (videoDevice?.maxWhiteBalanceGain ?? 0.0)) {
                if let aGains = rgbGains {
                    videoDevice?.setWhiteBalanceModeLocked(with: aGains, completionHandler: nil)
                }
                currentWhiteBalanceMode = whiteBalanceMode
            } else {
                errMsg = "White balance mode not supported"
            }
        } else {
            errMsg = "White balance mode not supported"
        }
    }
    device.unlockForConfiguration()
    if errMsg != "" {
        print("\(errMsg)")
        return "ERR01"
    }
    return whiteBalanceMode
}

func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [String : Any]?, context: UnsafeMutableRawPointer?) {
    // removes the observer, when the camera is done focussing.
    if (keyPath == "adjustingFocus") {
        let adjustingFocus: Bool = change?[.newKey] == 1
        if !adjustingFocus {
            device.removeObserver(self, forKeyPath: "adjustingFocus")
            delegate.onFocus()
        }
    }
}

//  Converted to Swift 4 by Swiftify v4.1.6691 - https://objectivec2swift.com/
func takePictureOnFocus() {
        // add an observer, when takePictureOnFocus is requested.
    let flag: NSKeyValueObservingOptions = .new
    device.addObserver(self, forKeyPath: "adjustingFocus", options: flag, context: nil)
}

func tapToFocus(toFocus xPoint: CGFloat, yPoint: CGFloat) {
    try? device.lockForConfiguration()
    let screenRect: CGRect = UIScreen.main.bounds
    let screenWidth: CGFloat = screenRect.size.width
    let screenHeight: CGFloat = screenRect.size.height
    let focus_x: CGFloat = xPoint / screenWidth
    let focus_y: CGFloat = yPoint / screenHeight
    if device.isFocusModeSupported(.autoFocus) {
        device.focusPointOfInterest = CGPoint(x: focus_x, y: focus_y)
        device.focusMode = .autoFocus
    }
    if device.isExposureModeSupported(.autoExpose) {
        device.exposurePointOfInterest = CGPoint(x: focus_x, y: focus_y)
        device.exposureMode = .autoExpose
    }
    device.unlockForConfiguration()
}

func checkDeviceAuthorizationStatus() {
    let mediaType = .video
    AVCaptureDevice.requestAccess(for: AVMediaType(mediaType), completionHandler: {(_ granted: Bool) -> Void in
        if !granted {
            //Not granted access to mediaType
            DispatchQueue.main.async(execute: {() -> Void in
                UIAlertView(title: "Error", message: "Camera permission not found. Please, check your privacy settings.", delegate: self, cancelButtonTitle: "OK", otherButtonTitles: "").show()
            })
        }
    })
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
    let devices = AVCaptureDevice.devices(for: .video)
    for device: AVCaptureDevice in devices {
        if device.position == position {
            return device
        }
    }
    return nil
}

