import AVFoundation
import CoreImage
import CoreMedia
import CoreVideo
import GLKit
import ImageIO
import QuartzCore
import UIKit

protocol TakePictureDelegate: class {
    func invokeTakePicture()

    func invokeTakePictureOnFocus()
}

protocol FocusDelegate: class {
    func invokeTap(toFocus point: CGPoint)
}

class CameraRenderController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, OnFocusDelegate {
    var sessionManager: CameraSessionManager?
    var ciContext: CIContext?
    var latestFrame: CIImage?
    var context: EAGLContext?
    var renderLock: NSLock
    var dragEnabled = false
    var tapToTakePicture = false
    var tapToFocus = false
    
    var delegate: CameraPreview?

    var renderBuffer = GLuint()
    var videoTextureCache: CVOpenGLESTextureCache?
    var lumaTexture: CVOpenGLESTexture?


    init(objectId : NSManagedObjectID) {
        super.init(nibName: nil, bundle: nil)


        renderLock = NSLock.init()
    }
//    required init?() {
//        super.init()
//        renderLock = NSLock.init()
//    }
    
    override func loadView() {
        let glkView = GLKView()
        glkView.backgroundColor = UIColor.black
        self.view = glkView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        context = EAGLContext(api: .openGLES2)
        if context == nil {
            print("Failed to create ES context")
        }
        
        let err: CVReturn = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, nil, context!, nil, &videoTextureCache)
        if err != 0 {
            print("Error at CVOpenGLESTextureCacheCreate \(err)")
            return
        }
        
        let view = self.view as? GLKView
        view?.context = context!
        view?.drawableDepthFormat = .format24
        view?.contentMode = .scaleToFill
        
        glGenRenderbuffers(1, &renderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), renderBuffer)
        
        ciContext = CIContext(eaglContext: context!)
        
        if dragEnabled {
            //add drag action listener
            print("Enabling view dragging")
            let drag = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            self.view.addGestureRecognizer(drag)
        }
        
        if tapToFocus && tapToTakePicture {
            //tap to focus and take picture
            let tapToFocusAndTakePicture = UITapGestureRecognizer(target: self, action: #selector(handleFocusAndTakePictureTap))
            self.view.addGestureRecognizer(tapToFocusAndTakePicture)
        } else if tapToFocus {
            // tap to focus
            let tapToFocusGesture = UITapGestureRecognizer(target: self, action: #selector(handleFocusTap))
            self.view.addGestureRecognizer(tapToFocusGesture)
        } else if tapToTakePicture {
            //tap to take picture
            let takePictureTap = UITapGestureRecognizer(target: self, action: #selector(handleTakePictureTap))
            self.view.addGestureRecognizer(takePictureTap)
        }
        
        self.view.isUserInteractionEnabled = dragEnabled || tapToTakePicture || tapToFocus
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(appplicationIsActive), name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationEnteredForeground), name: .UIApplicationWillEnterForeground, object: nil)
        sessionManager?.sessionQueue?.async(execute: {() -> Void in
            print("Starting session")
            self.sessionManager?.session?.startRunning()
        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        sessionManager?.sessionQueue?.async(execute: {() -> Void in
            print("Stopping session")
            self.sessionManager?.session?.stopRunning()
        })
    }

    func handleFocusAndTakePictureTap(_ recognizer: UITapGestureRecognizer?) {
        print("handleFocusAndTakePictureTap")
        // let the delegate take an image, the next time the image is in focus.
        delegate?.invokeTakePictureOnFocus()
        // let the delegate focus on the tapped point.
        handleFocusTap(recognizer)
    }

    func handleTakePictureTap(_ recognizer: UITapGestureRecognizer?) {
        print("handleTakePictureTap")
        delegate?.invokeTakePicture()
    }

    func handleFocusTap(_ recognizer: UITapGestureRecognizer?) {
        print("handleTapFocusTap")
        if recognizer?.state == .ended {
            let point: CGPoint? = recognizer?.location(in: view)
            delegate?.invokeTap(toFocus: point!)
        }
    }

    func onFocus() {
        delegate?.invokeTakePicture()
    }

    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer) {
        let translation: CGPoint = recognizer.translation(in: view)
        recognizer.view?.center = CGPoint(x: (recognizer.view?.center.x ?? 0.0) + translation.x, y: (recognizer.view?.center.y ?? 0.0) + translation.y)
        recognizer.setTranslation(CGPoint(x: 0, y: 0), in: view)
    }

    func appplicationIsActive(_ notification: Notification?) {
        sessionManager?.sessionQueue?.async(execute: {() -> Void in
            print("Starting session")
            self.sessionManager?.session?.startRunning()
        })
    }

    func applicationEnteredForeground(_ notification: Notification?) {
        sessionManager?.sessionQueue?.async(execute: {() -> Void in
            print("Stopping session")
            self.sessionManager?.session?.stopRunning()
        })
    }

    func captureOutput(_ output: AVCaptureOutput, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if renderLock.try() {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) as? CVPixelBuffer?
            var image: CIImage? = nil
            
            if let aBuffer = pixelBuffer {
                image = CIImage(cvPixelBuffer: aBuffer!)
            }
            let scaleHeight: CGFloat = view.frame.size.height / (image?.extent.size.height ?? 0.0)
            let scaleWidth: CGFloat = view.frame.size.width / (image?.extent.size.width ?? 0.0)
            
            var scale, x, y: CGFloat
            if scaleHeight < scaleWidth {
                scale = scaleWidth
                x = 0
                y = ((scale * (image?.extent.size.height ?? 0.0)) - view.frame.size.height) / 2
            } else {
                scale = scaleHeight
                x = ((scale * (image?.extent.size.width ?? 0.0)) - view.frame.size.width) / 2
                y = 0
            }
            
            // scale - translate
            let xscale = CGAffineTransform(scaleX: scale, y: scale)
            let xlate = CGAffineTransform(translationX: -x, y: -y)
            let xform: CGAffineTransform = xscale.concatenating(xlate)

            let centerFilter = CIFilter(name: "CIAffineTransform")!
            centerFilter.setValue(image, forKey: kCIInputImageKey)
            centerFilter.setValue(NSValue(cgAffineTransform: xform), forKey: kCIInputTransformKey)
            
            let transformedImage: CIImage? = centerFilter.outputImage
            
            // crop
            let cropFilter = CIFilter(name: "CICrop")
            let cropRect = CIVector(x: 0, y: 0, z: view.frame.size.width, w: view.frame.size.height)
            cropFilter?.setValue(transformedImage, forKey: kCIInputImageKey)
            cropFilter?.setValue(cropRect, forKey: "inputRectangle")
            var croppedImage: CIImage? = cropFilter?.outputImage
            
            //fix front mirroring
            if sessionManager?.defaultCamera == .front {
                let matrix = CGAffineTransform(scaleX: -1, y: 1).translatedBy(x: 0, y: (croppedImage?.extent.size.height)!)
                croppedImage = croppedImage?.applying(matrix)
            }
            
            latestFrame = croppedImage
            
            var pointScale: CGFloat

            if UIScreen.main.responds(to: #selector(getter: UIScreen.main.nativeScale)) {
                pointScale = UIScreen.main.nativeScale
            } else {
                pointScale = UIScreen.main.scale
            }

            let dest = CGRect(x: 0, y: 0, width: view.frame.size.width * pointScale, height: view.frame.size.height * pointScale)
            if let anImage = croppedImage {
                ciContext?.draw(anImage, in: dest, from: croppedImage?.extent ?? CGRect.zero)
            }
            context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
            (view as? GLKView)?.display()
            renderLock.unlock()
        }
    }

    //    override func viewDidUnload() {
    //        super.viewDidUnload()
    //        if EAGLContext.current() == context {
    //            EAGLContext.setCurrent(nil)
    //        }
    //        context = nil
    //    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc. that aren't in use.
    }
    
    override var shouldAutorotate: Bool {
        return true
    }

    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        sessionManager?.updateOrientation((sessionManager?.getCurrentOrientation(toInterfaceOrientation))!)
    }
}


