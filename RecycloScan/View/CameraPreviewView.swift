//
//  CameraPreviewView.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import SwiftUI
import AVFoundation

// Custom Preview View
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = UIColor.black
        
        if let previewLayer = view.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
            previewLayer.videoGravity = .resizeAspectFill
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Update the preview layer if needed
        if let previewLayer = uiView.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
        }
    }
}

#Preview {
    // Create a mock session for preview
    let mockSession = AVCaptureSession()
    
    return ZStack {
        Color.backgroundBeige
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            Text("Camera Preview Mock Up Frame")
                .font(.title)
                .fontWeight(.bold)
            
            CameraPreviewView(session: mockSession)
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.forestGreen, lineWidth: 5)
                )
            
            Text("Mock camera frame preview")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding()
    }
}
