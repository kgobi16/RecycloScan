//
//  ScannerClassifierViewModel.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 20/10/25.
//

import Foundation
import SwiftUI
import Vision

class ScannerClassifierViewModel: ObservableObject {
    @Published var wasteTypeText = ""
    @Published var confidenceText = ""
    @Published var selectedImage: UIImage?
    var classificationRequest: VNCoreMLRequest?
    
    init() {
        //Load and configure ML model
        do {
            let configuration = MLModelConfiguration()
            if let model = try? WasteClassifierOneMLModel(configuration: configuration) {
                let model = try VNCoreMLModel(for: model.model)
                self.classificationRequest = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                    self?.performClassification(for: request, error: error)
                })
                
                //image croping and scaling option
                self.classificationRequest?.imageCropAndScaleOption = .centerCrop
            }
        } catch {
            print("Failed to load the ML vision model: \(error)")
        }
    }
    
    func performClassification(for request: VNRequest, error: Error?){
        DispatchQueue.main.async {
            guard let returnedResult = request.results else {
                self.wasteTypeText = "Error: Unable to classify image.\n\(error?.localizedDescription ?? "Unknown error")"
                self.confidenceText = "N/A"
                return
            }
            
            let classifications = returnedResult as! [VNClassificationObservation]
            
            if classifications.isEmpty {
                self.wasteTypeText = "No waste items detected. Please try again with a clearer image."
                self.confidenceText = "N/A"
            } else {
                // Get the top classification with highest confidence
                let topClassification = classifications.first!
                let confidence = topClassification.confidence
                let wasteType = topClassification.identifier
                
                // Set texts separately
                self.wasteTypeText = wasteType
                self.confidenceText = "\(String(format: "%.1f", confidence * 100))%"
            }
        }
    }
    
    func classifyImage() {
        guard let selectedImage = selectedImage else {
            return
        }
        
        wasteTypeText = "Loading..."
        confidenceText = "Loading..."
        
        let orientation = cgiImageOrientation(from: selectedImage.imageOrientation)
        guard let ciImage = CIImage(image: selectedImage) else {
            print("Unable to create \(CIImage.self) from \(selectedImage)!")
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation)
            do {
                try handler.perform([self.classificationRequest!])
            } catch {
                print("Failed to perform classification.\n\(error.localizedDescription)")
            }
        }
    }
    
    func cgiImageOrientation (from uiImageOrientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch uiImageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: fatalError("Unknown image orientation")
        }
    }
    
}
