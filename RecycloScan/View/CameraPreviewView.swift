//
//  CameraPreviewView.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import SwiftUI
import AVFoundation

// MARK: - Orientation helpers
fileprivate func currentInterfaceOrientation() -> UIInterfaceOrientation {
    (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
        .interfaceOrientation ?? .portrait
}

// Rotation angles (degrees) used by AVCaptureVideoPreviewLayer on iOS 17+
fileprivate func rotationAngle(for io: UIInterfaceOrientation) -> CGFloat {
    switch io {
    case .portrait: return 90
    case .landscapeLeft: return 0
    case .landscapeRight: return 180
    default: return 90
    }
}

// MARK: - Backed by AVCaptureVideoPreviewLayer
final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
        applyCurrentOrientation()
    }
    
    func applyCurrentOrientation() {
        guard let conn = videoPreviewLayer.connection else { return }

        // --- Orientation (iOS 17+ uses rotation angles) ---
        if #available(iOS 17.0, *) {
            let angle: CGFloat
            switch currentInterfaceOrientation() {
            case .portrait: angle = 90
            case .landscapeLeft: angle = 180
            case .landscapeRight: angle = 0
            default: angle = 90
            }
            if conn.isVideoRotationAngleSupported(angle) {
                conn.videoRotationAngle = angle
            }
        } else {
            switch currentInterfaceOrientation() {
            case .portrait: conn.videoOrientation = .portrait
            case .landscapeLeft: conn.videoOrientation = .landscapeLeft
            case .landscapeRight: conn.videoOrientation = .landscapeRight
            default: conn.videoOrientation = .portrait
            }
        }

        // --- Mirroring (prevent crash) ---
        if conn.isVideoMirroringSupported {
            // Disable auto first, then set explicit mirroring state.
            if #available(iOS 17.0, *) {
                conn.automaticallyAdjustsVideoMirroring = false
            } else {
                conn.automaticallyAdjustsVideoMirroring = false
            }

            // For back camera we generally want NO mirroring.
            conn.isVideoMirrored = false
            // If you ever switch to the front camera, set this to true instead.
            // conn.isVideoMirrored = (frontCamera ? true : false)
        }
    }
}

// MARK: - SwiftUI wrapper
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.backgroundColor = .black

        let layer = view.videoPreviewLayer
        layer.session = session
        layer.videoGravity = .resizeAspectFill

        view.applyCurrentOrientation()

        // Reapply when device orientation changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.orientationChanged),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        context.coordinator.targetView = view
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
        uiView.applyCurrentOrientation()
    }

    class Coordinator {
        weak var targetView: PreviewView?
        @objc func orientationChanged() {
            targetView?.applyCurrentOrientation()
        }
    }
}

#Preview {
    let mockSession = AVCaptureSession()
    return ZStack {
        Color.backgroundBeige.ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Camera Preview Mock Up Frame")
                .font(.title).fontWeight(.bold)

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
