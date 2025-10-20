//
//  CameraManager.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import Foundation
import AVFoundation
import UIKit

// Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var permissionGranted = false
    @Published var capturedImage: UIImage?
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput = AVCapturePhotoOutput()
    
    override init() {
        super.init()
        checkPermission()
    }
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionGranted = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            permissionGranted = false
        @unknown default:
            permissionGranted = false
        }
    }
    
    private func setupCamera() {
        guard permissionGranted else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                print("No camera available")
                self.captureSession.commitConfiguration()
                return
            }
            
            do {
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if self.captureSession.canAddInput(videoDeviceInput) {
                    self.captureSession.addInput(videoDeviceInput)
                    self.videoDeviceInput = videoDeviceInput
                    print("Camera input added successfully")
                } else {
                    print("Cannot add video input")
                }
            } catch {
                print("Error setting up camera: \(error)")
            }
            
            // Add photo output for capturing images
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
                print("Photo output added successfully")
            }
            
            // Set video orientation for portrait
            if let connection = self.captureSession.connections.first {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 90 // Portrait orientation
                } else {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.captureSession.commitConfiguration()
            
            // Start the session after a brief delay to ensure configuration is complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.startSession()
            }
        }
    }
    
    func startSession() {
        guard permissionGranted && !isSessionRunning else { 
            print("Cannot start session - permission: \(permissionGranted), running: \(isSessionRunning)")
            return 
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("Camera session started")
            }
            
            DispatchQueue.main.async {
                self.isSessionRunning = true
                print("Session running state: \(self.isSessionRunning)")
            }
        }
    }
    
    func stopSession() {
        guard isSessionRunning else { return }
        
        sessionQueue.async { [weak self] in
            self?.captureSession.stopRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = false
            }
        }
    }
    
    func capturePhoto() {
        guard isSessionRunning else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

// Photo capture delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from photo data")
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            print("Photo captured successfully")
        }
    }
}
