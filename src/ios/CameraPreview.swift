//import Cordova
import AVFoundation

class CameraPreview: CDVPlugin, TakePictureDelegate, FocusDelegate {
    var sessionManager: CameraSessionManager!
    var cameraRenderController: CameraRenderController!
    var onPictureTakenHandlerId = ""
    
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
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera already started!")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        if command.arguments.count > 3 {
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
            // let disableExifHeaderStripping: Bool = (command.arguments[10] as? Int)! != 0 // ignore, Android only
            
            // Create the session manager
            sessionManager = CameraSessionManager()
            
            // Render controller setup
            cameraRenderController = CameraRenderController()
            cameraRenderController.dragEnabled = dragEnabled
            cameraRenderController.tapToTakePicture = tapToTakePicture
            cameraRenderController.tapToFocus = tapToFocus
            cameraRenderController.sessionManager = sessionManager
            cameraRenderController.view.frame = CGRect(x: x, y: y, width: width, height: height)
            cameraRenderController.delegate = self
            viewController.addChildViewController(cameraRenderController)
            
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
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    func stopCamera(command: CDVInvokedUrlCommand) {
        print("stopCamera")
        cameraRenderController.view.removeFromSuperview()
        cameraRenderController.removeFromParentViewController()
        cameraRenderController = nil
        
        commandDelegate.run(inBackground: {() -> Void in
        
            var pluginResult: CDVPluginResult?
            if self.sessionManager != nil {
            
                for input: AVCaptureInput? in (self.sessionManager.session?.inputs as? [AVCaptureInput])! {
                    if let anInput = input {
                        self.sessionManager?.session?.removeInput(anInput)
                    }
                }
                
                for output: AVCaptureOutput? in (self.sessionManager.session?.outputs as? [AVCaptureOutput])! {
                    if let anOutput = output {
                        self.sessionManager?.session?.removeOutput(anOutput)
                    }
                }
                
                self.sessionManager.session?.stopRunning()
                self.sessionManager = nil
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            } else {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            }
            self.commandDelegate.send(pluginResult, callbackId: command.callbackId)
        })
    }

    func hideCamera(command: CDVInvokedUrlCommand) {
        print("hideCamera")
        var pluginResult: CDVPluginResult?
        if cameraRenderController != nil {
            cameraRenderController.view.isHidden = true
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func showCamera(command: CDVInvokedUrlCommand) {
        print("showCamera")
        var pluginResult: CDVPluginResult?
        if cameraRenderController != nil {
            cameraRenderController.view.isHidden = false
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func switchCamera(command: CDVInvokedUrlCommand) {
        print("switchCamera")
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            sessionManager.switchCamera({(_ switched: Bool) -> Void in
                self.commandDelegate.send(CDVPluginResult(status: CDVCommandStatus_OK), callbackId: command.callbackId)
            })
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }

    func getSupportedFocusModes(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let focusModes = sessionManager.getFocusModes()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusModes)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getFocusMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let focusMode = sessionManager.getFocusMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    func setFocusMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        let focusMode = command.arguments[0] as? String
        if sessionManager != nil {
            sessionManager.setFocusmode(focusMode)
            let focusMode = sessionManager.getFocusMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: focusMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedFlashModes(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let flashModes = sessionManager.getFlashModes()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: flashModes)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getFlashMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
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
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: sFlashMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setFlashMode(command: CDVInvokedUrlCommand) {
        print("Flash Mode")
        var errMsg = ""
        var pluginResult: CDVPluginResult?
        let flashMode = command.arguments[0] as? String
        if sessionManager != nil {
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
        } else {
            errMsg = "Session not started"
        }
        if errMsg != "" {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: errMsg)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setZoom(command: CDVInvokedUrlCommand) {
        print("Zoom")
        var pluginResult: CDVPluginResult?
        let desiredZoomFactor = command.arguments[0] as? CGFloat ?? 0.0
        if sessionManager != nil {
            sessionManager.setZoom(desiredZoomFactor)
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getZoom(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let zoom: CGFloat = sessionManager.getZoom()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(zoom))
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    func getHorizontalFOV(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let fov: Float = sessionManager.getHorizontalFOV()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(fov))
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getMaxZoom(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let maxZoom: CGFloat = sessionManager.getMaxZoom()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(maxZoom))
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureModes(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let exposureModes = sessionManager.getExposureModes()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureModes)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let exposureMode = sessionManager.getExposureMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setExposureMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        let exposureMode = command.arguments[0] as? String
        if sessionManager != nil {
            sessionManager.setExposureMode(exposureMode)
            let exposureMode = sessionManager.getExposureMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: exposureMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedWhiteBalanceModes(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let whiteBalanceModes = sessionManager.getSupportedWhiteBalanceModes()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceModes)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getWhiteBalanceMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let whiteBalanceMode = sessionManager.getWhiteBalanceMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: whiteBalanceMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setWhiteBalanceMode(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        let whiteBalanceMode = command.arguments[0] as? String
        if sessionManager != nil {
            sessionManager.setWhiteBalanceMode(whiteBalanceMode)
            let wbMode = sessionManager.getWhiteBalanceMode()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: wbMode)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureCompensationRange(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let exposureRange = sessionManager.getExposureCompensationRange()
            var dimensions = [AnyHashable: Any]()
            dimensions["min"] = exposureRange?[0]
            dimensions["max"] = exposureRange?[1]
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: dimensions)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getExposureCompensation(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let exposureCompensation: CGFloat = sessionManager.getExposureCompensation()
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(exposureCompensation))
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func setExposureCompensation(command: CDVInvokedUrlCommand) {
        print("Zoom")
        var pluginResult: CDVPluginResult?
        let exposureCompensation = command.arguments[0] as? Float ?? 0.0
        if sessionManager != nil {
            sessionManager.setExposureCompensation(exposureCompensation)
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: Double(exposureCompensation))
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func takePicture(command: CDVInvokedUrlCommand) {
        print("takePicture")
        var pluginResult: CDVPluginResult?
        if cameraRenderController != nil {
            onPictureTakenHandlerId = command.callbackId
            let width = command.arguments[0] as? CGFloat ?? 0.0
            let height = command.arguments[1]  as? CGFloat ?? 0.0
            let quality = (command.arguments[2]  as? CGFloat  ?? 0.0) / 100.0
            invokeTakePicture(width, withHeight: height, withQuality: quality)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Camera not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
        }
    }
    
    func setColorEffect(command: CDVInvokedUrlCommand) {
        print("setColorEffect")
        var pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        let filterName = command.arguments[0] as? String
        if sessionManager != nil {
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
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }
    
    //    0 [dimensions.width,
    //    1 dimensions.height]
    func setPreviewSize(command: CDVInvokedUrlCommand) {
        var pluginResult: CDVPluginResult?
        if sessionManager == nil {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
            commandDelegate.send(pluginResult, callbackId: command.callbackId)
            return
        }
        if command.arguments.count ?? 0 > 1 {
            let width = command.arguments[0] as? CGFloat ?? 0.0
            let height = command.arguments[1] as? CGFloat ?? 0.0
            
            cameraRenderController.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
            
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Invalid number of parameters")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getSupportedPictureSizes(command: CDVInvokedUrlCommand) {
        print("getSupportedPictureSizes")
        var pluginResult: CDVPluginResult?
        if sessionManager != nil {
            let formats  = sessionManager.getDeviceFormats() as? [AVCaptureDevice.Format];
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
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: jsonFormats)
            
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func getBase64Image(_ imageRef: CGImage, withQuality quality: CGFloat) -> String? {
        var base64Image: String? = nil
        
        do {
            let image = UIImage(cgImage: imageRef)
            let imageData = UIImageJPEGRepresentation(image, quality)
            base64Image = imageData?.base64EncodedString(options: [])
        } catch let exception {
            print("error while get base64Image: \(exception)")
        }
        return base64Image
    }

    func tapToFocus(command: CDVInvokedUrlCommand) {
        print("tapToFocus")
        var pluginResult: CDVPluginResult?
        let xPoint = command.arguments[0] as? CGFloat ?? 0.0
        let yPoint = command.arguments[1] as? CGFloat ?? 0.0
        if sessionManager != nil {
            sessionManager.tapToFocus(toFocus: xPoint, yPoint: yPoint)
            pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        } else {
            pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: "Session not started")
        }
        commandDelegate.send(pluginResult, callbackId: command.callbackId)
    }

    func radiansFromUIImageOrientation(_ orientation: UIImageOrientation) -> Double {
        var radians: Double
        switch UIApplication.shared.statusBarOrientation {
            case .portrait:
                radians = .pi / 2
            case .landscapeLeft:
                radians = 0.0
            case .landscapeRight:
                radians = .pi
            case .portraitUpsideDown:
                radians = -.pi / 2
            case .unknown:
                radians = .pi / 2
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
        sessionManager.tapToFocus(toFocus: point.x, yPoint: point.y)
    }

    func invokeTakePicture() {
        invokeTakePicture(0.0, withHeight: 0.0, withQuality: 0.85)
    }

    func invokeTakePictureOnFocus() {
        // The sessionManager will call onFocus, as soon as the camera is done with focusing.
        sessionManager.takePictureOnFocus()
    }

    func invokeTakePicture(_ width: CGFloat, withHeight height: CGFloat, withQuality quality: CGFloat) {
        let connection: AVCaptureConnection? = sessionManager.stillImageOutput?.connection(withMediaType: AVMediaTypeVideo)
        if let aConnection = connection {
            sessionManager.stillImageOutput?.captureStillImageAsynchronously(from: aConnection, completionHandler: {(_ sampleBuffer: CMSampleBuffer?, _ error: Error?) -> Void in
                print("Done creating still image")
                if error != nil {
                    if let anError = error {
                        print("\(anError)")
                    }
                } else {
                    var imageData: Data? = nil
                    if let aBuffer = sampleBuffer {
                        imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(aBuffer)
                    }
                    var capturedImage: UIImage? = nil
                    if let aData = imageData {
                        capturedImage = UIImage(data: aData)
                    }
                    var capturedCImage: CIImage?
                    //image resize
                    if width > 0 && height > 0 {
                        let scaleHeight: CGFloat = width / (capturedImage?.size.height ?? 0.0)
                        let scaleWidth: CGFloat = height / (capturedImage?.size.width ?? 0.0)
                        let scale: CGFloat = scaleHeight > scaleWidth ? scaleWidth : scaleHeight
                        var resizeFilter = CIFilter(name: "CILanczosScaleTransform")
                        if let anImage = capturedImage?.cgImage {
                            resizeFilter?.setValue(CIImage(cgImage: anImage), forKey: kCIInputImageKey)
                        }
                        resizeFilter?.setValue(1.0, forKey: "inputAspectRatio")
                        resizeFilter?.setValue(scale, forKey: "inputScale")
                        capturedCImage = resizeFilter?.outputImage
                    } else {
                        if let anImage = capturedImage?.cgImage {
                            capturedCImage = CIImage(cgImage: anImage)
                        }
                    }
                    var imageToFilter: CIImage?
                    var finalCImage: CIImage?
                    
                    //fix front mirroring
                    if self.sessionManager.defaultCamera == .front {
                        let matrix = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: (capturedCImage?.extent.size.height)!)
                        imageToFilter = capturedCImage?.applying(matrix)
                    } else {
                        imageToFilter = capturedCImage
                    }
                    
                    var filter: CIFilter? = self.sessionManager.ciFilter
                    if filter != nil {
                        self.sessionManager.filterLock?.lock()
                        filter?.setValue(imageToFilter, forKey: kCIInputImageKey)
                        finalCImage = filter?.outputImage
                        self.sessionManager.filterLock?.unlock()
                    } else {
                        finalCImage = imageToFilter
                    }
                    
                    var params = [AnyHashable]()
                    
                    var finalImage: CGImage? = nil
                    if let anImage = finalCImage {
                        finalImage = self.cameraRenderController.ciContext?.createCGImage(anImage, from: finalCImage?.extent ?? CGRect.zero)
                    }
                    
                    var resultImage: UIImage? = nil
                    if let anImage = finalImage {
                        resultImage = UIImage(cgImage: anImage)
                    }
                    
                    let radians: Double = self.radiansFromUIImageOrientation((resultImage?.imageOrientation)!)
                    
                    let resultFinalImage = self.cgImageRotated(finalImage!, withRadians: radians)
                    
                    // CGImageRelease(finalImage)  // release CGImage to remove memory leaks
                    
                    let base64Image = self.getBase64Image(resultFinalImage!, withQuality: quality)
                    
                    // CGImageRelease(resultFinalImage) // release CGImage to remove memory leaks
                    
                    params.append(base64Image!)
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: params)
                    pluginResult?.setKeepCallbackAs(true)
                    self.commandDelegate.send(pluginResult, callbackId: self.onPictureTakenHandlerId)
                }
            })
        }
    }
}
