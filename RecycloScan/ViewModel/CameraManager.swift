//
//  CameraManager.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import AVFoundation
import Foundation
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

    //MARK: - Orientation Helpers

    func currentInterfaceOrientation() -> UIInterfaceOrientation {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .interfaceOrientation ?? .portrait
    }

    func captureRotationAngle(for io: UIInterfaceOrientation) -> CGFloat {
        switch io {
        case .portrait: return 90
        case .portraitUpsideDown: return 90  // treat as portrait (no flip)
        case .landscapeLeft: return 180
        case .landscapeRight: return 0
        default: return 90
        }
    }

    //MARK: - Camera Utilities

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

            guard
                let videoDevice = AVCaptureDevice.default(
                    .builtInWideAngleCamera,
                    for: .video,
                    position: .back
                )
            else {
                print("No camera available")
                self.captureSession.commitConfiguration()
                return
            }

            do {
                let videoDeviceInput = try AVCaptureDeviceInput(
                    device: videoDevice
                )

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

            // Set initial video orientation (iOS 17 compatible)
            if let connection = self.captureSession.connections.first {
                if #available(iOS 17.0, *) {
                    // Use new rotation-angle API
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90  // Portrait orientation
                    }
                } else {
                    // Fallback for older iOS versions
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
            }

            self.captureSession.commitConfiguration()
            
            // Ensure configuration is fully committed before starting
            DispatchQueue.main.async {
                // Add a small delay to ensure commitConfiguration is fully processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.startSession()
                }
            }
        }
    }

    func startSession() {
        guard permissionGranted && !isSessionRunning else {
            print(
                "Cannot start session - permission: \(permissionGranted), running: \(isSessionRunning)"
            )
            return
        }

        sessionQueue.async { [weak self] in
            guard let self = self else { return }

            // Double-check that session is not running
            guard !self.captureSession.isRunning else {
                print("Session is already running")
                DispatchQueue.main.async {
                    self.isSessionRunning = true
                }
                return
            }
            
            // Start the session
            self.captureSession.startRunning()
            print("Camera session started")

            DispatchQueue.main.async {
                self.isSessionRunning = self.captureSession.isRunning
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

        // Align photo orientation with the current UI orientation (matches preview)
        if let conn = photoOutput.connection(with: .video) {
            if #available(iOS 17.0, *) {
                let angle = captureRotationAngle(
                    for: currentInterfaceOrientation()
                )
                if conn.isVideoRotationAngleSupported(angle) {
                    conn.videoRotationAngle = angle
                }
            }

            // Avoid exceptions and unwanted flips (mirror only for front camera)
            if conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = false  // back camera → no mirror
            }
        }

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

}

// Photo capture delegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("Error capturing photo: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
            let image = UIImage(data: imageData)
        else {
            print("Failed to create image from photo data")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
            print("Photo captured successfully")
        }
    }
}
