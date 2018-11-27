//
//  CardFinderController.swift
//  CardGrabber
//
//  Created by venkata on 2018-11-27.
//  Copyright © 2018 NVM. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class CardFinderController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var dataOutput: AVCaptureVideoDataOutput?
    var requests = [VNDetectRectanglesRequest]()
    
    @IBOutlet var previewView : UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let captureDevice = AVCaptureDevice.default(for: .video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            
            captureSession?.startRunning()
            
            dataOutput = AVCaptureVideoDataOutput()
            if captureSession!.canAddOutput(dataOutput!){
                captureSession!.addOutput(dataOutput!)
            }
            let queue: DispatchQueue = DispatchQueue.global(qos: .default)
            self.dataOutput!.setSampleBufferDelegate(self, queue: queue)
            
            startRectDetection()
        } catch {
            print(error)
        }
        
    }
    
    func startRectDetection() {
        
        let rectRequest = VNDetectRectanglesRequest(completionHandler:self.detectRectHandler)
        rectRequest.minimumConfidence = 0.7
        rectRequest.minimumSize = 0.3
//        rectRequest.minimumAspectRatio = 0.6
//        rectRequest.maximumAspectRatio = 1.0
        
        self.requests = [rectRequest]
    }
    
    func detectRectHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRectangleObservation] else {
            print("no result")
            return
        }
        
        DispatchQueue.main.async() {
            
            self.previewView.subviews.forEach({ (s) in
                s.removeFromSuperview()
            })
            
            for box in observations {
                self.highlightBox(box: box)
            }
        }
        
    }
    
    func transformRect(fromRect: CGRect , toViewRect :UIView) -> CGRect {
        
        var toRect = CGRect()
        toRect.size.width = fromRect.size.width * toViewRect.frame.size.width
        toRect.size.height = fromRect.size.height * toViewRect.frame.size.height
        toRect.origin.y =  (toViewRect.frame.height) - (toViewRect.frame.height * fromRect.origin.y )
        toRect.origin.y  = toRect.origin.y -  toRect.size.height
        toRect.origin.x =  fromRect.origin.x * toViewRect.frame.size.width
        
        return toRect
    }
    
    func CreateBoxView(withColor : UIColor) -> UIView {
        let view = UIView()
        view.layer.borderColor = withColor.cgColor
        view.layer.borderWidth = 2
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func highlightBox(box: VNRectangleObservation) {
       
        print(box.boundingBox)
        
        var transformedRect = box.boundingBox
        //transformedRect.origin.y = 1 - transformedRect.origin.y
        let convertedRect = self.videoPreviewLayer?.layerRectConverted(fromMetadataOutputRect: transformedRect)
        
        
        let view = CreateBoxView(withColor: UIColor.red)
        view.frame = convertedRect!
        
        
        
        
        previewView.addSubview(view)
        
       
//        let xCord = box.topLeft.x
//        let yCord = (1 - minY) * imageView.frame.size.height
//        let width = (minX - maxX) * imageView.frame.size.width
//        let height = (minY - maxY) * imageView.frame.size.height
//
//        let outline = CALayer()
//        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
//        outline.borderWidth = 2.0
//        outline.borderColor = UIColor.red.cgColor
//
//        imageView.layer.addSublayer(outline)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("nothing here")
            return
        }
        
        var requestOptions : [VNImageOption : Any] = [:]
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,attachmentModeOut: nil){
           requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation:CGImagePropertyOrientation.up, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
        
    }
    
//    func prepareRectangleDetector() -> CIDetector {
//        let options: [String: AnyObject] = [CIDetectorAccuracy: CIDetectorAccuracyHigh as AnyObject, CIDetectorAspectRatio: 1.0 as AnyObject]
//        return CIDetector(ofType: CIDetectorTypeRectangle, context: nil, options: options)!
//    }
//
//    func performRectangleDetection(image: CIImage) -> CIImage? {
//        var resultImage: CIImage?
//        if let detector = detector {
//            // Get the detections
//            let features = detector.featuresInImage(image)
//            for feature in features as! [CIRectangleFeature] {
//                resultImage = drawHighlightOverlayForPoints(image, topLeft: feature.topLeft, topRight: feature.topRight,
//                                                            bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight)
//            }
//        }
//        return resultImage
//    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
