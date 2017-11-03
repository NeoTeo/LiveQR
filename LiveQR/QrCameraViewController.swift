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

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    private let metadataOutput = AVCaptureMetadataOutput()
    private let scannerQueue = DispatchQueue(label: "QR code scanner queue")
    
    private enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    private var sessionStatus: SessionSetupResult = .success
    
    private var qrCamLayer: AVCaptureVideoPreviewLayer?
    
    private let visionSequenceHandler = VNSequenceRequestHandler()
    
    // Holds the last observation as returned by the vision system.
    private var lastObservation: VNDetectedObjectObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Here we should check for access.
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access.
            break
            
        case .notDetermined:
            // Suspend execution of the configuration until the user has responded.
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted == false { self.sessionStatus = .notAuthorized }
                self.sessionQueue.resume()
            }
        default:
            // The user had previously denied access.
            // Since we have no access so we need to return to manual id entry.
            sessionStatus = .notAuthorized
        }
        
        // Session config can take a while so we run it async and pass it a completion handler.
        sessionQueue.async {
            self.configureSession { result in
                switch result {
                case .success:
                    self.captureSession.startRunning()
                default:
                    print("Failed to configure the session.")
                    self.sessionStatus = .notAuthorized
                }
            }
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            if self.sessionStatus == .success {
                self.captureSession.stopRunning()
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        qrCamLayer?.frame = qrCamView?.bounds ?? .zero
    }
    
    private func configureSession(with resultHandler: (SessionSetupResult)->Void) {
        
        guard sessionStatus == .success else { return }
        
        captureSession.sessionPreset = .photo
        
        guard
            let backCam = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: backCam)
        else {
            resultHandler(.configurationFailed)
            return
        }

        captureSession.addInput(input)
        
        // MARK: May have do this on the main thread...not sure.
        qrCamLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        DispatchQueue.main.async {
            self.qrCamView.layer.addSublayer(self.qrCamLayer!)
            self.view.setNeedsLayout()
        }
        
        // Register for camera buffers.
//        let videoOutput = AVCaptureVideoDataOutput()
//        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "qrVideoQueue"))
//        captureSession.addOutput(videoOutput)

        guard captureSession.canAddOutput(metadataOutput) == true else {
            resultHandler(.configurationFailed)
            return
        }
        
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: scannerQueue)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        resultHandler(.success)
    }
}

extension QrCameraViewController : AVCaptureMetadataOutputObjectsDelegate {
    
    // Called when the camera recognizes a barcode.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        //var sensorId: String?
        let supportedBarcodeTypes = [AVMetadataObject.ObjectType.qr]
        for codeMetadata in metadataObjects {
            if supportedBarcodeTypes.contains(codeMetadata.type) {
                
                guard let qrCodeObject = qrCamLayer?.transformedMetadataObject(for: codeMetadata) as? AVMetadataMachineReadableCodeObject else { continue }
                let qrCode = qrCodeObject.stringValue
                print("The QR code is \(String(describing: qrCode))")
            }
        }
    }
}
/*
extension QrCameraViewController : AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // To continue we need the pixel buffer from the sample buffer and a valid last observation.
        guard
            let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let lastObservation = self.lastObservation
        else { return }
        
        // Make a request object.
//        let request = VNTrackObjectRequest(detectedObjectObservation: lastObservation)
        let request = VNDetectBarcodesRequest() { request, error in
            print("aaaarse")
        }
        
        do {
            try visionSequenceHandler.perform([request], on: pixelBuffer)
            
        } catch { print("Error performing vision request. \(error)") }
    }
}
*/

