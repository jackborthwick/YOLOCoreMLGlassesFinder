//
//  ViewController.swift
//  YOLOCoreMLGlassesFinder
//
//  Created by Jack Borthwick on 9/22/17.
//  Copyright © 2017 Jack Borthwick. All rights reserved.
//

import UIKit
import Vision
import AVKit
import CoreML

class ViewController: UIViewController {
    
    @IBOutlet var buttonView   : UIView!
    @IBOutlet var identifyButton   : UIButton!
    var cameraLayer: CALayer!

    //MARK: Set Up Methods
    func viewSetUp() {
        let bgColor = UIColor.init(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8)
        buttonView.backgroundColor = bgColor
    }

    func cameraSetUp() {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!
        let input = try! AVCaptureDeviceInput(device: backCamera)

        captureSession.addInput(input)

        cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraLayer)
        cameraLayer.frame = view.bounds

        view.bringSubview(toFront: buttonView)

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self as? AVCaptureVideoDataOutputSampleBufferDelegate, queue: DispatchQueue(label: "buffer delegate"))
        videoOutput.recommendedVideoSettings(forVideoCodecType: .jpeg, assetWriterOutputFileType: .mp4)

        captureSession.addOutput(videoOutput)
        captureSession.sessionPreset = .high
        captureSession.startRunning()
    }

    //MARK: CoreML Methods
    func predict(image: CGImage) {
        let model = try! VNCoreMLModel(for: TinyYOLO().model)
        let request = VNCoreMLRequest(model: model, completionHandler: results)
        let handler = VNSequenceRequestHandler()
        try! handler.perform([request], on: image)
    }


    func results(request: VNRequest, error: Error?) {
//        print ("\(request.results![0])")
        guard let results = request.results![0] as? VNCoreMLFeatureValueObservation else {
            print("No result found")
            return
        }
        print (results.featureValue)


        let alertController = UIAlertController(title: "Items Identified", message: "\(results)", preferredStyle: UIAlertControllerStyle.alert) //Replace UIAlertControllerStyle.Alert by UIAlertControllerStyle.alert
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            print("OK")
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    


    
    //MARK: Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetUp()
        cameraSetUp()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { fatalError("pixel buffer is nil") }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)

        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { fatalError("cg image") }
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .leftMirrored)

        DispatchQueue.main.sync {
            predict(image: uiImage.cgImage!)
        }
    }
}

