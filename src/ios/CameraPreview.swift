import AVFoundation
import CoreMotion

@objc(CameraPreview)
class CameraPreview: CDVPlugin, TakePictureDelegate, FocusDelegate {
    var sessionManager: CameraSessionManager!
    var cameraRenderController: CameraRenderController!
    var onPictureTakenHandlerId = ""
    var motionManager: CMMotionManager!
    var accelerometerOrientation: AVCaptureVideoOrientation?
    
    override func pluginInitialize() {
        // start as transparent
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
    }

    // 0 [options.x,
    // 1 options.y,
    // 2 options.width,
    // 3 options.height,
    // 4 options.camera,
    // 5 options.tapPhoto,
    // 6 options.previewDrag,
    // 7 options.toBack,
    // 8 options.alpha,
    // 9 options.tapFocus,
    // 10 options.disableExifHeaderStripping]
    func startCamera(_ command: CDVInvokedUrlCommand) {
        if sessionManager != nil {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera already started!")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        self.startAccelerometerOrientation()
        
        guard command.arguments.count > 3 else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let x = (command.arguments[0] as? CGFloat ?? 0.0) + webView.frame.origin.x
        let y = (command.arguments[1] as? CGFloat ?? 0.0) + webView.frame.origin.y
        let width = CGFloat((command.arguments[2] as? Int)!)
        let height = CGFloat((command.arguments[3] as? Int)!)
        let defaultCamera = command.arguments[4]
        let tapToTakePicture: Bool = (command.arguments[5] as? Int)! != 0
        let dragEnabled: Bool = (command.arguments[6] as? Int)! != 0
        let toBack: Bool = (command.arguments[7] as? Int)! != 0
        let alpha = CGFloat((command.arguments[8] as? Int)!)
        let tapToFocus: Bool = (command.arguments[9] as? Int)! != 0
        let disableExifHeaderStripping: Bool = (command.arguments[10] as? Int)! != 0
        
        // Create the session manager
        sessionManager = CameraSessionManager()
        
        // Render controller setup
        cameraRenderController = CameraRenderController()
        cameraRenderController.dragEnabled = dragEnabled
        cameraRenderController.tapToTakePicture = tapToTakePicture
        cameraRenderController.tapToFocus = tapToFocus
        cameraRenderController.disableExifHeaderStripping = disableExifHeaderStripping
        cameraRenderController.sessionManager = sessionManager
        cameraRenderController.view.frame = CGRect(x: x, y: y, width: width, height: height)
        cameraRenderController.delegate = self
        viewController.addChildViewController(cameraRenderController)
        
        // Add video preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: sessionManager?.session!)
        previewLayer?.frame = cameraRenderController.view.frame
        print(cameraRenderController.view.bounds)
        cameraRenderController.view.layer.addSublayer(previewLayer!)
        
        if toBack {
            // display the camera below the webview
            // make transparent
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.superview?.addSubview(cameraRenderController.view)
            webView.superview?.bringSubview(toFront: webView)
        } else {
            cameraRenderController.view.alpha = alpha
            webView.superview?.insertSubview(cameraRenderController.view, aboveSubview: webView)
        }
        
        // Setup session
        sessionManager.delegate = cameraRenderController
        sessionManager.setupSession(defaultCamera as? String, completion: {(_ started: Bool) -> Void in
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        })
    }
    
    func startAccelerometerOrientation() {
        print("--> startAccelerometerOrientation")
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue() ) { p, _ in
            if p != nil {
                if abs(p!.acceleration.y) < abs(p!.acceleration.x) {
                    if p!.acceleration.x > 0 {
                        self.accelerometerOrientation = .landscapeLeft
                    } else {
                        self.accelerometerOrientation = .landscapeRight
                    }
                } else {
                    if p!.acceleration.y > 0 {
                        self.accelerometerOrientation = .portraitUpsideDown
                    } else {
                        self.accelerometerOrientation = .portrait
                    }
                }
            }
        }
    }

    func stopCamera(_ command: CDVInvokedUrlCommand) {
        print("--> stopCamera")
        if cameraRenderController != nil {
            cameraRenderController.view.removeFromSuperview()
            cameraRenderController.removeFromParentViewController()
            cameraRenderController = nil
        }
        
        if motionManager != nil {
            motionManager.stopAccelerometerUpdates()
            motionManager = nil
        }

        commandDelegate.run(inBackground: {() -> Void in
            guard self.sessionManager != nil else {
                print("--> Camera not started")
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            if let inputs = self.sessionManager.session?.inputs as? [AVCaptureInput] {
                for input in inputs {
                    self.sessionManager.session?.removeInput(input)
                }
            }
            

            if let outputs = self.sessionManager.session?.outputs as? [AVCaptureOutput] {
                for output in outputs {
                    self.sessionManager.session?.removeOutput(output)
                }
            }

            self.sessionManager.session?.stopRunning()
            self.sessionManager = nil

            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        })
    }

    func hideCamera(_ command: CDVInvokedUrlCommand) {
        print("hideCamera")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        cameraRenderController.view.isHidden = true
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
    
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func showCamera(_ command: CDVInvokedUrlCommand) {
        print("showCamera")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        cameraRenderController.view.isHidden = false
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func switchCamera(_ command: CDVInvokedUrlCommand) {
        print("switchCamera")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        sessionManager.switchCamera({(_ switched: Bool) -> Void in
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        })
    }

    func getSupportedFocusModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let focusModes = sessionManager.getFocusModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusModes)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getFocusMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
    
        let focusMode = sessionManager.getFocusMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusMode)
    
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    func setFocusMode(_ command: CDVInvokedUrlCommand) {
        var focusMode = command.arguments[0] as? String
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        focusMode = sessionManager.setFocusmode(focusMode)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusMode)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedFlashModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
    
        let flashModes = sessionManager.getFlashModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: flashModes)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getFlashMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let flashMode: Int = sessionManager.getFlashMode()
        var sFlashMode: String
        if flashMode == 0 {
            sFlashMode = "off"
        } else if flashMode == 1 {
            sFlashMode = "on"
        } else if flashMode == 2 {
            sFlashMode = "auto"
        } else {
            sFlashMode = "unsupported"
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: sFlashMode)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setFlashMode(_ command: CDVInvokedUrlCommand) {
        print("Flash Mode")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        var errMsg = ""
        let flashMode = command.arguments[0] as? String
        
        if let flashMode = flashMode {
            if flashMode == "off" {
                sessionManager.setFlashMode(.off)
            } else if flashMode == "on" {
                sessionManager.setFlashMode(.on)
            } else if flashMode == "auto" {
                sessionManager.setFlashMode(.auto)
            } else if flashMode == "torch" {
                sessionManager.setTorchMode()
            } else {
                errMsg = "Flash Mode not supported"
            }
        }
        
        if errMsg != "" {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errMsg)
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setZoom(_ command: CDVInvokedUrlCommand) {
        print("Zoom")
        let desiredZoomFactor = command.arguments[0] as? CGFloat ?? 0.0
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        sessionManager.setZoom(desiredZoomFactor)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getZoom(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let zoom: CGFloat = sessionManager.getZoom()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(zoom))
    
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getHorizontalFOV(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let fov: Float = sessionManager.getHorizontalFOV()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(fov))
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getMaxZoom(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let maxZoom: CGFloat = sessionManager.getMaxZoom()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(maxZoom))
    
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureModes = sessionManager.getExposureModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureModes)
   
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureMode = sessionManager.getExposureMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setExposureMode(_ command: CDVInvokedUrlCommand) {
        var exposureMode = command.arguments[0] as? String
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        exposureMode = sessionManager.setExposureMode(exposureMode)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedWhiteBalanceModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let whiteBalanceModes = sessionManager.getSupportedWhiteBalanceModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceModes)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getWhiteBalanceMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let whiteBalanceMode = sessionManager.getWhiteBalanceMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setWhiteBalanceMode(_ command: CDVInvokedUrlCommand) {
        let whiteBalanceMode = command.arguments[0] as? String
        
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let wbMode = sessionManager.setWhiteBalanceMode(whiteBalanceMode)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: wbMode)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureCompensationRange(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureRange = sessionManager.getExposureCompensationRange()
        var dimensions = [AnyHashable: Any]()
        dimensions["min"] = exposureRange?[0]
        dimensions["max"] = exposureRange?[1]
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dimensions)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureCompensation(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureCompensation: CGFloat = sessionManager.getExposureCompensation()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(exposureCompensation))

        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setExposureCompensation(_ command: CDVInvokedUrlCommand) {
        print("Zoom")
        let exposureCompensation = command.arguments[0] as? Float ?? 0.0
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        sessionManager.setExposureCompensation(exposureCompensation)
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(exposureCompensation))

        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func takePicture(_ command: CDVInvokedUrlCommand) {
        print("takePicture")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        onPictureTakenHandlerId = command.callbackId
        let width = command.arguments[0] as? CGFloat ?? 0.0
        let height = command.arguments[1]  as? CGFloat ?? 0.0
        let quality = (command.arguments[2]  as? CGFloat  ?? 0.0) / 100.0
        invokeTakePicture(width, withHeight: height, withQuality: quality)
    }
    
    func setColorEffect(_ command: CDVInvokedUrlCommand) {
        print("setColorEffect")
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        let filterName = command.arguments[0] as? String
        
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        if filterName == "none" {
            sessionManager.sessionQueue?.async(execute: {() -> Void in
                self.sessionManager.ciFilter = nil
            })
        } else if filterName == "mono" {
            sessionManager.sessionQueue?.async(execute: {() -> Void in
                let filter = CIFilter(name: "CIColorMonochrome")
                filter?.setDefaults()
                self.sessionManager.ciFilter = filter
            })
        } else if filterName == "negative" {
            sessionManager.sessionQueue?.async(execute: {() -> Void in
                let filter = CIFilter(name: "CIColorInvert")
                filter?.setDefaults()
                self.sessionManager.ciFilter = filter
            })
        } else if filterName == "posterize" {
            sessionManager.sessionQueue?.async(execute: {() -> Void in
                let filter = CIFilter(name: "CIColorPosterize")
                filter?.setDefaults()
                self.sessionManager.ciFilter = filter
            })
        } else if filterName == "sepia" {
            sessionManager.sessionQueue?.async(execute: {() -> Void in
                let filter = CIFilter(name: "CISepiaTone")
                filter?.setDefaults()
                self.sessionManager.ciFilter = filter
            })
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Filter not found")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    //    0 [dimensions.width,
    //    1 dimensions.height]
    func setPreviewSizeOld(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        guard command.arguments.count > 1  else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let width = command.arguments[0] as? CGFloat ?? 0.0
        let height = command.arguments[1] as? CGFloat ?? 0.0
        
        cameraRenderController.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    func setPreviewSize(_ command: CDVInvokedUrlCommand) {
        print("--> setPreviewSize")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        guard command.arguments.count > 1  else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let width = command.arguments[0] as? CGFloat ?? 0.0
        let height = command.arguments[1] as? CGFloat ?? 0.0
        
        setPreviewSizeOld(command)
        
        // Set device format matching given width and height
        setDeviceFormat(width, height: height)
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedPictureSizes(_ command: CDVInvokedUrlCommand) {
        print("-->getSupportedPictureSizes")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let formats = sessionManager.getDeviceFormats() as? [AVCaptureDevice.Format];
        var jsonFormats = [Any]()
        var lastWidth: Int = 0
        var lastHeight: Int = 0
        
        for format: AVCaptureDevice.Format in formats! {
            let dim: CMVideoDimensions = format.highResolutionStillImageDimensions
            if Int(dim.width) != lastWidth && Int(dim.height) != lastHeight {
                var dimensions = [String: Int32]()
                let width = dim.width
                let height = dim.height
                dimensions["width"] = width
                dimensions["height"] = height
                jsonFormats.append(dimensions)
                
                lastWidth = Int(dim.width)
                lastHeight = Int(dim.height)
            }
        }
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonFormats)

        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getBase64Image(_ image: UIImage, withQuality quality: CGFloat) -> String? {
        var base64Image: String? = nil
        do {
            let imageData = UIImageJPEGRepresentation(image, quality)
            base64Image = imageData?.base64EncodedString(options: [])
        } catch let exception {
            print("error while get base64Image: \(exception)")
        }
        return base64Image
    }

    func tapToFocus(_ command: CDVInvokedUrlCommand) {
        print("tapToFocus")
        let xPoint = command.arguments[0] as? CGFloat ?? 0.0
        let yPoint = command.arguments[1] as? CGFloat ?? 0.0
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }

        var completion = {() -> Void in
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
        sessionManager.tapToFocus(toFocus: xPoint, yPoint: yPoint, completion: &completion)
        
    }
    
    func radiansFromUIImageOrientation(_ orientation: UIImageOrientation) -> Double {
        var radians: Double
        switch self.accelerometerOrientation! {
            case .portrait:
                radians = .pi / 2
            case .landscapeLeft:
                radians = .pi
            case .landscapeRight:
                radians = 0.0
            case .portraitUpsideDown:
                radians = -.pi / 2
        }
        return radians
    }

    func cgImageRotated(_ originalCGImage: CGImage, withRadians radians: Double) -> CGImage? {
        let imageSize = CGSize(width: originalCGImage.width, height: originalCGImage.height)
        var rotatedSize: CGSize
        if radians == .pi / 2 || radians == -.pi / 2 {
            rotatedSize = CGSize(width: imageSize.height, height: imageSize.width)
        } else {
            rotatedSize = imageSize
        }
        let rotatedCenterX = CGFloat(rotatedSize.width / 2.0)
        let rotatedCenterY = CGFloat(rotatedSize.height / 2.0)
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, 1.0)
        let rotatedContext = UIGraphicsGetCurrentContext()
        if radians == 0.0 || radians == .pi {
            // 0 or 180 degrees
            rotatedContext?.translateBy(x: CGFloat(rotatedCenterX), y: rotatedCenterY)
            if radians == 0.0 {
                rotatedContext?.scaleBy(x: 1.0, y: -1.0)
            } else {
                rotatedContext?.scaleBy(x: -1.0, y: 1.0)
            }
            rotatedContext?.translateBy(x: -rotatedCenterX, y: -rotatedCenterY)
        } else if radians == .pi / 2 || radians == -.pi / 2 {
            // +/- 90 degrees
            rotatedContext?.translateBy(x: CGFloat(rotatedCenterX), y: rotatedCenterY)
            rotatedContext?.rotate(by: CGFloat(radians))
            rotatedContext?.scaleBy(x: 1.0, y: -1.0)
            rotatedContext?.translateBy(x: -rotatedCenterY, y: -rotatedCenterX)
        }
        let drawingRect = CGRect(x: 0.0, y: 0.0, width: imageSize.width, height: imageSize.height)
        rotatedContext?.draw(originalCGImage, in: drawingRect)
        let rotatedCGImage = rotatedContext?.makeImage()
    
        UIGraphicsEndImageContext()
    
        return rotatedCGImage
    }
    
    func invokeTap(toFocus point: CGPoint) {
        var completion = {() -> Void in
            print("Focus ended")
        }
        sessionManager.tapToFocus(toFocus: point.x, yPoint: point.y, completion: &completion)
    }

    func invokeTakePicture() {
        invokeTakePicture(0.0, withHeight: 0.0, withQuality: 0.85)
    }

    func invokeTakePictureOnFocus() {
        // The sessionManager will call onFocus, as soon as the camera is done with focusing.
        sessionManager.takePictureOnFocus()
    }

    func setDeviceFormat(_ width: CGFloat, height: CGFloat) {
        print("--> setDeviceFormat")

        let allFormats = sessionManager.getDeviceFormats();
        
        // Keep only formats with given dimensions
        var dimensionsFormats = [AVCaptureDevice.Format]()
        for format: AVCaptureDevice.Format in allFormats {
            let dimensions: CMVideoDimensions = format.highResolutionStillImageDimensions
            if dimensions.width == Int32(width) && dimensions.height == Int32(height) {
                dimensionsFormats.append(format)
            }
        }

        // Take the last format with given dimensions, the one with biggest video dimensions
        if let format = dimensionsFormats.last {
            sessionManager.setPictureSize(format)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Format not supported for this device, call getSupportedPictureSizes() to get all supported formats.")
            commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
        }
        
    }

    
    func invokeTakePicture(_ width: CGFloat, withHeight height: CGFloat, withQuality quality: CGFloat) {
    
        let connection = sessionManager.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)

        if let aConnection = connection {

            // Set orientation
            if self.cameraRenderController.disableExifHeaderStripping {
                sessionManager.updateOrientation(self.accelerometerOrientation!)
            }
        
            // Fix front mirroring
            connection?.isVideoMirrored = sessionManager.device?.position == AVCaptureDevicePosition.front
            
            // Capture image
            sessionManager.stillImageOutput?.captureStillImageAsynchronously(from: aConnection, completionHandler: {(_ sampleBuffer: CMSampleBuffer!, _ error: Error?) -> Void in
                
                print("Done creating still image")
                if error != nil {
                    print("\(error)")
                } else {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)

                    let capturedImage = UIImage(data: imageData!)
                    var finalImage: UIImage? = nil
                    
                    // Apply filters if needed
                    let filter: CIFilter? = self.sessionManager.ciFilter
                    var finalCGImage: CGImage? = nil
                    if filter != nil {
                        let imageToFilter = CIImage(cgImage: (capturedImage?.cgImage)!)
                        self.sessionManager.filterLock?.lock()
                        filter?.setValue(imageToFilter, forKey: kCIInputImageKey)
                        let filteredCImage = filter?.outputImage
                        self.sessionManager.filterLock?.unlock()
                        finalCGImage = self.cameraRenderController.ciContext?.createCGImage(filteredCImage!, from: filteredCImage?.extent ?? CGRect.zero)
                        finalImage = UIImage(cgImage: finalCGImage!)
                    } else {
                        finalImage = capturedImage
                    }
                    
                    // Rotate image if EXIF stripping not disabled
                    if !self.cameraRenderController.disableExifHeaderStripping {
                        let ciImage = CIImage(image: finalImage!)
                        finalCGImage = self.cameraRenderController.ciContext?.createCGImage(ciImage!, from: ciImage?.extent ?? CGRect.zero)
                        let radians = self.radiansFromUIImageOrientation((finalImage?.imageOrientation)!)
                        let imageRotated = self.cgImageRotated(finalCGImage!, withRadians: radians)
                        finalImage = UIImage(cgImage: imageRotated!)
                    }
                    
                    // Export to Base64
                    var params = [AnyHashable]()
                    let base64Image = self.getBase64Image(finalImage!, withQuality: quality)
                    params.append(base64Image!)
                    
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: params)
                    pluginResult?.setKeepCallbackAs(true)
                    self.commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
                }
            })
        }
    }
}
