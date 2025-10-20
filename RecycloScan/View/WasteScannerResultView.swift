//
//  WasteScannerTypeView.swift
//  RecycloScan
//
//  Created by Ariel Waraney on 09/10/25.
//

import SwiftUI

struct WasteScannerResultView: View {
    let capturedImage: UIImage
    @Binding var isPresented: Bool
    @ObservedObject var classifierViewModel: ScannerClassifierViewModel
    
    var body: some View {
        ZStack {
            Color.backgroundBeige
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                Text("Scan Analysis")
                    .font(.displayLarge)
                
                // Smaller captured image at the top
                Image(uiImage: capturedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 200, height: 200)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Classification Results (if available)
                if !classifierViewModel.resultText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Classification Results:")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                        
                        Text(classifierViewModel.resultText)
                            .font(.body)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.leading)
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
                
                Text("The camera has identified this item as:")
                    .font(.headingSmall)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Classification Type Card
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.headingLarge)
                        .foregroundColor(.white)
                    
                    Text("Plastic")
                        .font(.headingLarge)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.plasticBlue)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.plasticBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Bin Color Information
                VStack(spacing: 12) {
                    Text("Disposal Information:")
                        .font(.headingSmall)
                        .padding(.top)
                    
                    HStack(spacing: 15) {
                        // Bin Color Indicator
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.plasticBlue)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "trash.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blue Bin")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.textPrimary)
                            
                            Text("Place in the blue recycling bin for plastic items")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                
                Button("Back") {
                    isPresented = false
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .background(Color.forestGreen)
                .clipShape(Capsule())
                }
                .padding()
            }
        }
    }
}

#Preview {
    WasteScannerResultView(
        capturedImage: UIImage(systemName: "photo")!,
        isPresented: .constant(true),
        classifierViewModel: ScannerClassifierViewModel()
    )
}
