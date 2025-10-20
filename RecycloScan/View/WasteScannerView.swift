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
    @StateObject private var classifierViewModel = ScannerClassifierViewModel()
    @State private var isScanning = false
    @State private var showWasteTypeView = false
    
    var body: some View {
        ZStack {
            Color.backgroundBeige
                .ignoresSafeArea()
            
            ScrollView {
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
                                    .stroke(Color.forestGreen, lineWidth: 5)
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
                    }
                    .padding(.horizontal)
                    
                    // Capture button
                    Button(action: {
                        // Capture photo and process with ML
                        cameraManager.capturePhoto()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // Process captured image with ML model
                            if let capturedImage = cameraManager.capturedImage {
                                classifierViewModel.selectedImage = capturedImage
                                classifierViewModel.classifyImage()
                            }
                            showWasteTypeView = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                            Text("Capture")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.forestGreen)
                        .clipShape(Capsule())
                    }
                    .padding(.bottom)
                }
                .padding()
            }
        }
        .onAppear {
            // Restart camera when returning to the scan tab
            if cameraManager.permissionGranted && !cameraManager.isSessionRunning {
                cameraManager.startSession()
            }
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .fullScreenCover(isPresented: $showWasteTypeView) {
            if let capturedImage = cameraManager.capturedImage {
                WasteScannerResultView(
                    capturedImage: capturedImage,
                    isPresented: $showWasteTypeView,
                    classifierViewModel: classifierViewModel
                )
            }
        }
    }
}


#Preview {
    WasteScannerView()
}
