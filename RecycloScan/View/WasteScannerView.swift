//
//  WasteScannerView.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import SwiftUI
import AVFoundation

struct WasteScannerView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var isScanning = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with instructions
            VStack(spacing: 12) {
                Text("Scan Your Waste")
                    .font(.displayLarge)
                
                Text("Point your camera at the waste item you want to identify")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)
            
            // Camera view in rounded rectangle
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(height: 400)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.grassGreen.opacity(0.3), lineWidth: 10)
                    )
                
                if cameraManager.permissionGranted {
                    if cameraManager.isSessionRunning {
                        CameraPreviewView(session: cameraManager.captureSession)
                            .frame(height: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.backgroundBeige)
                                .padding(.bottom)
                            Text("Camera Loading...")
                                .foregroundColor(.backgroundBeige)
                                .font(.caption)
                        }
                    }
                } else {
                    VStack {
                        Image(systemName: "camera.badge.exclamationmark")
                            .font(.system(size: 40))
                            .foregroundColor(.backgroundBeige)
                            .padding(.bottom)
                        Text("Camera Permission Required")
                            .foregroundColor(.backgroundBeige)
                            .font(.caption)
                        Text("Please enable camera access in Settings")
                            .foregroundColor(.backgroundBeige)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                // Scanning overlay
                if isScanning {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.forestGreen, lineWidth: 3)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: isScanning)
                }
            }
            .padding(.horizontal)
            
            // Analyze button
            Button(action: {
                // Start/stop analysis
                withAnimation {
                    isScanning.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isScanning ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(isScanning ? "Stop" : "Scan")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 15)
                .background(isScanning ? Color.grassGreen : Color.forestGreen)
                .clipShape(Capsule())
            }
            .padding(.bottom)
        }
        .onAppear {
            // Camera will start automatically after permission is granted and setup is complete
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
}

// Custom Preview View (like ChatGPT's approach)
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

// Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var permissionGranted = false
    
    let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    override init() {
        super.init()
        checkPermission()
    }
    
    private func checkPermission() {
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
            
            // Set video orientation for portrait
            if let connection = self.captureSession.connections.first {
                if #available(iOS 17.0, *) {
                    connection.videoRotationAngle = 90 // Portrait orientation
                } else {
                    connection.videoOrientation = .portrait
                }
            }
            
            self.captureSession.commitConfiguration()
            
            // Start the session immediately after setup
            DispatchQueue.main.async {
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
}

#Preview {
    WasteScannerView()
}
