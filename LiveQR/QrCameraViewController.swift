//
//  QrCameraViewController.swift
//  LiveQR
//
//  Created by Teo Sartori on 01/11/2017.
//  Copyright © 2017 ilyb. All rights reserved.
//

import Foundation
import AVFoundation
import Vision
import UIKit

class QrCameraViewController : ViewController {
    @IBOutlet weak var qrCamView: UIView!

    private lazy var captureSession : AVCaptureSession = {
        
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        guard
            let backCam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCam)
        else { return session }
        session.addInput(input)
        return session
    }()
    
    private lazy var qrCamLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        qrCamView.layer.addSublayer(qrCamLayer)
        
        // Register for camera buffers.
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qrVideoQueue"))
        captureSession.addOutput(videoOutput)
        
        captureSession.startRunning()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        qrCamLayer.frame = qrCamView?.bounds ?? .zero
    }
}

extension QrCameraViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        print("Capture this bufffffff")
    }
}
