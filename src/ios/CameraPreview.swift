import AVFoundation
import CoreMotion

let TMP_IMAGE_PREFIX = "cpcp_capture_"

@objc(CameraPreview)
class CameraPreview: CDVPlugin, TakePictureDelegate, FocusDelegate {
    
    var sessionManager: CameraSessionManager!
    var cameraRenderController: CameraRenderController!
    var onPictureTakenHandlerId = ""
    var storeToFile: Bool!
    var storageDirectory = ""
    var exifInfos: Dictionary<String, Any> = Dictionary<String, Any>()
    var withExifInfos = false
    var captureVideoOrientation: AVCaptureVideoOrientation?
    let dateFormatterForPhotoExif: DateFormatter = DateFormatter()
    var startCameraInProgress = false
    
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
    // 10 options.disableExifHeaderStripping
    // 11 options.storeToFile
    // 12 options.storageDirectory]
    @objc func startCamera(_ command: CDVInvokedUrlCommand) {
        print("--> startCamera")
        
        self.startCameraInProgress = true
        
        // Check if camera usage permission is granted in privacy settings. User only has to accept once.
        checkDeviceAuthorizationStatus({(_ granted: Bool) -> Void in
            // If not, return an error code
            if !granted {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs:  "CameraUsageNotGranted")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            if self.sessionManager != nil {
                print("--> Camera already started!")
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "CameraAlreadyStarted")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            guard command.arguments.count > 3 else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            
            let width = CGFloat((command.arguments[2] as? Int)!)
            let height = CGFloat((command.arguments[3] as? Int)!)
            let defaultCamera = command.arguments[4]
            let tapToTakePicture: Bool = (command.arguments[5] as? Int)! != 0
            let dragEnabled: Bool = (command.arguments[6] as? Int)! != 0
            let toBack: Bool = (command.arguments[7] as? Int)! != 0
            let alpha = CGFloat((command.arguments[8] as? Int)!)
            let tapToFocus: Bool = (command.arguments[9] as? Int)! != 0
            let disableExifHeaderStripping: Bool = (command.arguments[10] as? Int)! != 0
            self.storeToFile = (command.arguments[11] as? Int)! != 0
            self.storageDirectory = (command.arguments[12] as? String) ?? ""
            
            DispatchQueue.main.async {
                let x = (command.arguments[0] as? CGFloat ?? 0.0) + self.webView.frame.origin.x
                let y = (command.arguments[1] as? CGFloat ?? 0.0) + self.webView.frame.origin.y
                
                // Create the session manager
                self.sessionManager = CameraSessionManager()
                
                // Render controller setup
                self.cameraRenderController = CameraRenderController()
                self.cameraRenderController.dragEnabled = dragEnabled
                self.cameraRenderController.tapToTakePicture = tapToTakePicture
                self.cameraRenderController.tapToFocus = tapToFocus
                self.cameraRenderController.disableExifHeaderStripping = disableExifHeaderStripping
                self.cameraRenderController.sessionManager = self.sessionManager
                self.cameraRenderController.view.frame = CGRect(x: x, y: y, width: width, height: height) // Relative to full screen
                self.cameraRenderController.delegate = self
                self.viewController.addChildViewController(self.cameraRenderController)
                
                // Add video preview layer
                if let session = self.sessionManager?.session {
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.frame = CGRect(x: 0, y: 0, width: width, height: height) // Relative to cameraRenderController view
                    self.cameraRenderController.view.layer.addSublayer(previewLayer)
                }
                
                if toBack {
                    // display the camera below the webview
                    // make transparent
                    self.webView.isOpaque = false
                    self.webView.backgroundColor = UIColor.clear
                    self.webView.superview?.addSubview(self.cameraRenderController.view)
                    self.webView.superview?.bringSubview(toFront: self.webView)
                } else {
                    self.cameraRenderController.view.alpha = alpha
                    self.webView.superview?.insertSubview(self.cameraRenderController.view, aboveSubview: self.webView)
                }
                
                // Setup session
                self.sessionManager.delegate = self.cameraRenderController
                self.sessionManager.setupSession(defaultCamera as? String, completion: {(_ started: Bool, _ error: String?) -> Void in
                    if started {
                        print("--> camera started")
                        self.startCameraInProgress = false
                        self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
                    }
                })
            }
            
        })
    }
    
    func checkDeviceAuthorizationStatus(_ completion: @escaping (_ granted: Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: completion)
    }
    
    @objc func stopCamera(_ command: CDVInvokedUrlCommand) {
        print("--> stopCamera")
        if cameraRenderController != nil {
            cameraRenderController.view.removeFromSuperview()
            cameraRenderController.removeFromParentViewController()
            cameraRenderController = nil
        }
        
        guard self.startCameraInProgress == false else {
            print("--> startCamera in progress")
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "startCamera in progress")
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        commandDelegate.run(inBackground: {() -> Void in
            guard self.sessionManager != nil else {
                print("--> Camera not started")
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
                self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
                return
            }
            
            guard self.startCameraInProgress == false else {
                print("--> startCamera in progress")
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "startCamera in progress")
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
            
            if self.sessionManager != nil {
                self.sessionManager.delegate = nil;
                self.sessionManager = nil;
            }
            
            print("--> camera stopped")
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        })
    }
    
    @objc func hideCamera(_ command: CDVInvokedUrlCommand) {
        print("--> hideCamera")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        cameraRenderController.view.isHidden = true
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func showCamera(_ command: CDVInvokedUrlCommand) {
        print("--> showCamera")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        cameraRenderController.view.isHidden = false
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func switchCamera(_ command: CDVInvokedUrlCommand) {
        print("--> switchCamera")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        sessionManager.switchCamera({(_ switched: Bool) -> Void in
            self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
        })
    }
    
    @objc func getSupportedFocusModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let focusModes = sessionManager.getFocusModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusModes)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getFocusMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let focusMode = sessionManager.getFocusMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setFocusMode(_ command: CDVInvokedUrlCommand) {
        print("--> setFocusMode");
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
    
    @objc func getSupportedFlashModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let flashModes = sessionManager.getFlashModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: flashModes)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getFlashMode(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func setFlashMode(_ command: CDVInvokedUrlCommand) {
        print("--> Flash Mode")
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        var errMsg = ""
        let flashMode = command.arguments[0] as? String
        
        if let flashMode = flashMode {
            print(flashMode)
            
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
    
    @objc func setZoom(_ command: CDVInvokedUrlCommand) {
        print("--> setZoom")
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
    
    @objc func getZoom(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let zoom: CGFloat = sessionManager.getZoom()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(zoom))
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getHorizontalFOV(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let fov: Float = sessionManager.getHorizontalFOV()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(fov))
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getMaxZoom(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let maxZoom: CGFloat = sessionManager.getMaxZoom()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(maxZoom))
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getExposureModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureModes = sessionManager.getExposureModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureModes)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getExposureMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureMode = sessionManager.getExposureMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setExposureMode(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func getSupportedWhiteBalanceModes(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        let whiteBalanceModes = sessionManager.getSupportedWhiteBalanceModes()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceModes)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getWhiteBalanceMode(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let whiteBalanceMode = sessionManager.getWhiteBalanceMode()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceMode)
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setWhiteBalanceMode(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func getExposureCompensationRange(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func getExposureCompensation(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let exposureCompensation: CGFloat = sessionManager.getExposureCompensation()
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(exposureCompensation))
        
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setExposureCompensation(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func takePicture(_ command: CDVInvokedUrlCommand) {
        print("takePicture")
        guard cameraRenderController != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        onPictureTakenHandlerId = command.callbackId
                
        // Save EXIF infos
        let latitude = command.arguments[1] as? Double
        let longitude = command.arguments[2] as? Double
        let altitude = command.arguments[3] as? Double
        let timestamp = command.arguments[4] as? TimeInterval
        let trueHeading = command.arguments[5] as? Double
        let magneticHeading = command.arguments[6] as? Double
        let software = command.arguments[7] as? String

        self.exifInfos = Dictionary<String, Any>()
        
        if latitude != nil {
            self.exifInfos["latitude"] = latitude
        }
        if longitude != nil {
            self.exifInfos["longitude"] = longitude
        }
        if altitude != nil {
            self.exifInfos["altitude"] = altitude
        }
        if timestamp != nil {
            self.exifInfos["timestamp"] = timestamp
        }
        if trueHeading != nil {
            self.exifInfos["trueHeading"] = trueHeading
        }
        if magneticHeading != nil {
            self.exifInfos["magneticHeading"] = magneticHeading
        }
        if software != nil {
            self.exifInfos["software"] = software
        }
        
        // Take picture
        let quality = (command.arguments[0]  as? CGFloat  ?? 0.0) / 100.0
        invokeTakePicture(withQuality: quality)
    }
    
    @objc func setColorEffect(_ command: CDVInvokedUrlCommand) {
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
    
    @objc func setPictureSize(_ command: CDVInvokedUrlCommand) {
        print("--> setPictureSize")
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
        
        // Set capture device format matching given width and height
        setCaptureDeviceFormat(width, height: height)
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func getSupportedPictureSizes(_ command: CDVInvokedUrlCommand) {
        print("--> getSupportedPictureSizes")
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
            let imageDimensions: CMVideoDimensions = format.highResolutionStillImageDimensions
            
            if Int(imageDimensions.width) != lastWidth && Int(imageDimensions.height) != lastHeight {
                var dimensions = [String: Any]()
                dimensions["width"] = imageDimensions.width
                dimensions["height"] = imageDimensions.height
                jsonFormats.append(dimensions)
                
                lastWidth = Int(imageDimensions.width)
                lastHeight = Int(imageDimensions.height)
            }
        }
        
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonFormats)
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    @objc func setScreenRotation(_ command: CDVInvokedUrlCommand) {
        guard sessionManager != nil else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        
        let rotationAngle = command.arguments[0] as? Int ?? 0
        
        switch rotationAngle {
        case 0:
            self.captureVideoOrientation = .portrait
        case 90:
            self.captureVideoOrientation = .landscapeRight
        case 180:
            self.captureVideoOrientation = .portraitUpsideDown
        case 270:
            self.captureVideoOrientation = .landscapeLeft
        default:
            self.captureVideoOrientation = .portrait
        }
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
    
    @objc func tapToFocus(_ command: CDVInvokedUrlCommand) {
        print("--> tapToFocus")
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
    
    func getRadiansFromCaptureVideoOrientation() -> Double {
        var radians: Double
        switch self.captureVideoOrientation! {
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
    
    func invokeTapToFocus(point: CGPoint) {
        var completion = {() -> Void in
            print("Focus ended")
        }
        sessionManager.tapToFocus(toFocus: point.x, yPoint: point.y, completion: &completion)
    }
    
    func invokeTakePicture() {
        invokeTakePicture(withQuality: 0.85)
    }
    
    func invokeTakePictureOnFocus() {
        // The sessionManager will call onFocus, as soon as the camera is done with focusing.
        sessionManager.takePictureOnFocus()
    }
    
    func setCaptureDeviceFormat(_ width: CGFloat, height: CGFloat) {
        print("--> setCaptureDeviceFormat")
        
        let allFormats = sessionManager.getDeviceFormats();
        
        // Keep only formats with given dimensions
        var dimensionsFormats = [AVCaptureDevice.Format]()
        for format: AVCaptureDevice.Format in allFormats {
            let dimensions: CMVideoDimensions = format.highResolutionStillImageDimensions
            if dimensions.width == Int32(width) && dimensions.height == Int32(height) {
                dimensionsFormats.append(format)
            }
        }
        
        var foundFormat: AVCaptureDevice.Format?
        
        // Find ideal format for this screen, = format with preview width just superior to screen width
        for format: AVCaptureDevice.Format in dimensionsFormats {
            let previewWidth = CGFloat(CMVideoFormatDescriptionGetDimensions(format.formatDescription).width)
            if previewWidth >= UIScreen.main.scale * UIScreen.main.bounds.width {
                foundFormat = format
                break
            }
            
        }
        
        if let format = foundFormat {
            sessionManager.setPictureSize(format)
        } else {
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Format not supported for this device, call getSupportedPictureSizes() to get all supported formats.")
            commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
        }
    }
    
    
    func invokeTakePicture(withQuality quality: CGFloat) {
        
        let connection = sessionManager.stillImageOutput?.connection(with: AVMediaType.video)
        
        if let aConnection = connection {
            
            // Set orientation
            if self.cameraRenderController.disableExifHeaderStripping {
                sessionManager.updateOrientation(self.captureVideoOrientation!)
            }
            
            // Fix front mirroring
            aConnection.isVideoMirrored = sessionManager.device?.position == AVCaptureDevice.Position.front
            
            // Capture image
            sessionManager.stillImageOutput?.captureStillImageAsynchronously(from: aConnection, completionHandler: {(_ sampleBuffer: CMSampleBuffer!, _ error: Error?) -> Void in
                print("Done creating still image")
                
                if error != nil {
                    print("Error taking picture : \(error)")
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "\(error)")
                    self.commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
                    return
                }
                
                if (self.storeToFile) {
                    // Get the image data
                    if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer) {
                        
                        // Get the image source from the data
                        if let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) {
                            
                            let metadata = NSMutableDictionary(dictionary: CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)!)
                            print("exif data 2 = \(metadata[kCGImagePropertyExifDictionary as String] as? [String : AnyObject])")
                            metadata[kCGImageDestinationLossyCompressionQuality as String] = quality
                            
                            self.writeExifInfosToMetadata(to: metadata)
                            
                            let type = "public.jpeg"
                            let data = NSMutableData()
                            let dest: CGImageDestination = CGImageDestinationCreateWithData(data, type as CFString, 1, nil)!
                            
                            var cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
                            CGImageDestinationAddImage(dest, cgImage!, metadata)
                            CGImageDestinationFinalize(dest)
                            
                            // Rotate image if EXIF stripping not disabled
                            if !self.cameraRenderController.disableExifHeaderStripping {
                                cgImage = self.rotateImage(UIImage(cgImage: cgImage!))
                            }
                            
                            do {
                                let fileName = self.getFileName("jpg")!
                                var fileUrl: URL
                                
                                if (self.storageDirectory != "") {
                                    let filePath = String(format: "%@%@", self.storageDirectory, fileName)
                                    fileUrl = URL(string: filePath)!
                                } else {
                                    fileUrl = self.getFileUrl("jpg")!
                                }
                                
                                // Write the file at path
                                try data.write(to: fileUrl, options: [.atomic])
                                
                                
                                
                                var resultMedia = Dictionary<String, Any>()
                                let isPortrait = self.captureVideoOrientation == AVCaptureVideoOrientation.portrait
                                             || self.captureVideoOrientation == AVCaptureVideoOrientation.portraitUpsideDown

                                resultMedia["filePath"] = fileUrl.standardized.absoluteString
                                resultMedia["width"] = isPortrait ? cgImage!.height : cgImage!.width
                                resultMedia["height"] = isPortrait ? cgImage!.width : cgImage!.height
                                resultMedia["orientation"] = metadata[kCGImagePropertyOrientation as String]
                                
                                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: resultMedia)
                                // This means that the callback on JS side is kept for further calls from native side to JS side
                                pluginResult?.setKeepCallbackAs(true)
                                self.commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
                            } catch let error as NSError {
                                print("We have an error to save the picture: \(error)")
                            }
                        }
                    }
                } else {
                    // Get the image data
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    let image: UIImage? = UIImage(data: imageData!)
                    
                    // Export to Base64
                    let base64Image = self.getBase64Image(image!, withQuality: quality)
                    
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: base64Image)
                    // This means that the callback on JS side is kept for further calls from native side to JS side
                    pluginResult?.setKeepCallbackAs(true)
                    self.commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
                }
            })
        }
    }
    
    func applyFilter(_ image: UIImage, filter: CIFilter) -> UIImage {
        let imageToFilter = CIImage(cgImage: (image.cgImage)!)
        self.sessionManager.filterLock?.lock()
        filter.setValue(imageToFilter, forKey: kCIInputImageKey)
        let filteredCImage = filter.outputImage
        self.sessionManager.filterLock?.unlock()
        let finalCGImage = self.cameraRenderController.ciContext?.createCGImage(filteredCImage!, from: filteredCImage?.extent ?? CGRect.zero)
        
        return UIImage(cgImage: finalCGImage!)
    }
    
    func rotateImage(_ image: UIImage) -> CGImage {
        let ciImage = CIImage(image: image)
        let finalCGImage = self.cameraRenderController.ciContext?.createCGImage(ciImage!, from: ciImage?.extent ?? CGRect.zero)
        let radians = self.getRadiansFromCaptureVideoOrientation()
        return self.cgImageRotated(finalCGImage!, withRadians: radians)!
    }
    
    func writeExifInfosToMetadata(to metadata: NSMutableDictionary) {
        let tiff: NSMutableDictionary = metadata[kCGImagePropertyTIFFDictionary as String] as! NSMutableDictionary
        tiff[kCGImagePropertyTIFFSoftware as String] = self.exifInfos["software"]

        let gps = NSMutableDictionary()
        metadata[kCGImagePropertyGPSDictionary as String] = gps

        // Calculate north/south and east/west because we can't set negative latitude and longitude
        var latitudeRef: String
        var longitudeRef: String

        if let latitude = (self.exifInfos["latitude"] as? Double), latitude < 0.0 {
            latitudeRef = "S"
            self.exifInfos["latitude"] = abs(latitude)
        } else {
            latitudeRef = "N"
        }

        if let longitude = (self.exifInfos["longitude"] as? Double), longitude < 0.0 {
            longitudeRef = "W"
            self.exifInfos["longitude"] = abs(longitude)
        } else {
            longitudeRef = "E"
        }
        
        let trueHeading = self.exifInfos["trueHeading"] as? Double
        let magneticHeading = self.exifInfos["magneticHeading"] as? Double
        
        if (trueHeading != nil || magneticHeading != nil) {
            if (trueHeading == nil || trueHeading! < 0.0) {
                gps[kCGImagePropertyGPSImgDirection] = [magneticHeading, 1]
                gps[kCGImagePropertyGPSImgDirectionRef] = "M"
            } else {
                gps[kCGImagePropertyGPSImgDirection] = [trueHeading, 1]
                gps[kCGImagePropertyGPSImgDirectionRef] = "T"
            }
        }

        gps[kCGImagePropertyGPSLatitudeRef as String] = latitudeRef
        gps[kCGImagePropertyGPSLongitudeRef as String] = longitudeRef
        gps[kCGImagePropertyGPSLatitude as String] = self.exifInfos["latitude"]
        gps[kCGImagePropertyGPSLongitude as String] = self.exifInfos["longitude"]

        self.dateFormatterForPhotoExif.dateFormat = "HH:mm:ss"
        gps[kCGImagePropertyGPSTimeStamp as String] = self.dateFormatterForPhotoExif.string(from: Date(timeIntervalSince1970: (self.exifInfos["timestamp"] as! TimeInterval)))
        self.dateFormatterForPhotoExif.dateFormat = "yyyy:MM:dd"
        gps[kCGImagePropertyGPSDateStamp as String] = self.dateFormatterForPhotoExif.string(from: Date(timeIntervalSince1970: (self.exifInfos["timestamp"] as! TimeInterval)))
        
        // Clear EXIF after usage
        self.exifInfos = Dictionary<String, Any>()
    }
    
    func getTempDirectoryUrl() -> URL {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory.appendingPathComponent("NoCloud")
    }
    
    func getFileUrl(_ `extension`: String?) -> URL? {
        let fileName = self.getFileName(`extension`)!
        let fileUrl = self.getTempDirectoryUrl().appendingPathComponent(fileName)
        return fileUrl
    }
    
    func getFileName(_ `extension`: String?) -> String? {
        return String(format: "%@%04d.%@", TMP_IMAGE_PREFIX, Int.random(in: 0 ... 1000000), `extension` ?? "")
    }
}
