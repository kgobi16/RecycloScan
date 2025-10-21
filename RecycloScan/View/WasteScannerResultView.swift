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
    @ObservedObject var recyclingManager: RecyclingManager //manager to track scanned items
    @State private var showSuccess = false //show success message
    @State private var showShareSheet = false //show share sheet

    // Derive card color from the detected waste type's display name (computed property)
    private var typeColor: Color {
        let name = classifierViewModel.wasteTypeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        switch name {
        case "plastic": return .PlasticBlue
        case "paper": return .PaperBrown
        case "metal": return .MetalGray
        case "glass": return .GlassGreen
        case "organic": return .OrganicOrange
        case "e-waste", "electronic", "electronics": return .EWasteRed
        case "general": return .GeneralGray
        default: return .PlasticBlue
        }
    }

    // Derive SF Symbol icon name from the detected waste type (computed property)
    private var iconName: String {
        let name = classifierViewModel.wasteTypeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        switch name {
        case "plastic": return "waterbottle.fill"
        case "paper": return "doc.fill"
        case "metal": return "wrench.and.screwdriver.fill"
        case "glass": return "wineglass.fill"
        case "organic": return "leaf.fill"
        case "e-waste", "electronic", "electronics": return "laptopcomputer"
        case "general": return "trash.fill"
        default: return "leaf.fill"
        }
    }
    
    // Detect if current classification is e-waste (special handling)
    private var isEWaste: Bool {
        let name = classifierViewModel.wasteTypeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        return ["e-waste", "electronic", "electronics", "battery", "batteries"].contains(name)
    }
 
    // Map detected waste type to one of 4 bins (color, name, description)
    private var binInfo: (color: Color, name: String, description: String) {
        let name = classifierViewModel.wasteTypeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        switch name {
        case "paper":
            return (.BinBlue, "Blue Bin", "Paper & Cardboard")
        case "organic":
            return (.BinGreen, "Green Bin", "Garden or organic Waste")
        case "plastic":
            return (.BinRed, "Red Bin", "General Waste")
        default:
            // glass & metal
            return (.BinYellow, "Yellow Bin", "Mixed Containers")
        }
    }

    var body: some View {
        ZStack {
            Color.backgroundBeige
                .ignoresSafeArea()

            ScrollView {
                Color.clear.frame(height: 0)
                VStack(spacing: 20) {
                    
                    // MARK: - Page title
                    Text("Scan Result")
                        .font(.displayLarge)

                    // Smaller captured image at the top
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 200, height: 200)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.grassGreen, lineWidth: 5)
                            )
                        
                        // Share button in bottom right
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.callout)
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.GrassGreen.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8)
                    }

                    // MARK: - Classification Results
                    if !classifierViewModel.wasteTypeText.isEmpty {
                        Text("The camera has identified this item as:")
                            .font(.headingSmall)
                            .multilineTextAlignment(.center)
                            .padding(.top)

                        // Classification Type Card
                        HStack {
                            Image(systemName: iconName)
                                .font(.headingLarge)
                                .foregroundColor(.white)

                            Text("\(classifierViewModel.wasteTypeText)")
                                .font(.headingLarge)
                                .foregroundColor(.white)

                            Spacer()

                            VStack {
                                Text("Confidence:")
                                    .font(.captionSmall)
                                    .foregroundStyle(typeColor)
                                    .fontWeight(.bold)
                                Text("\(classifierViewModel.confidenceText)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(typeColor)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(
                                color: Color.black.opacity(0.08),
                                radius: 5,
                                x: 0,
                                y: 1
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(typeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(
                            color: typeColor.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )

                        //MARK: - Bin Color Information
                        if isEWaste {
                            // Special guidance for e-waste and batteries
                            HStack(spacing: 15) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.eWasteRed)
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "battery.100.bolt")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    )

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("E‑Waste Handling Required")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.textPrimary)

                                    Text("Do not place electronics or batteries in household bins. Take to an e‑waste drop‑off or hazardous waste center.")
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
                            .shadow(
                                color: Color.black.opacity(0.1),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        } else {
                            VStack(spacing: 12) {
                                Text("Disposal Information:")
                                    .font(.headingSmall)
                                    .padding(.top)

                                HStack(spacing: 15) {
                                    // Bin Color Indicator
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(binInfo.color)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Image(systemName: "trash.fill")
                                                .font(.title2)
                                                .foregroundColor(.white)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(binInfo.name)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.textPrimary)

                                        Text(binInfo.description)
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
                                .shadow(
                                    color: Color.black.opacity(0.1),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                            }
                        }
                    } else {
                        //MARK: - If no analysis found.
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.headline)
                            Text(
                                "An error occrued, please try again one more time!"
                            )
                            .font(.body)
                            .multilineTextAlignment(.center)
                        }
                        .padding(20)
                    }

                    
                    
                    // action buttons
                    if !classifierViewModel.wasteTypeText.isEmpty {
                        if showSuccess {
                            // Success message
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.GrassGreen)
                                Text("Recycled! +\(getPointValue()) points")
                                    .font(.bodyMedium)
                                    .foregroundColor(.GrassGreen)
                            }
                            .padding()
                            .background(Color.GrassGreen.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        } else {
                            // Action buttons
                            HStack(spacing: 12) {
                                // Try Again button
                                Button("Try Again") {
                                    isPresented = false
                                }
                                .foregroundColor(.grassGreen)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.BackgroundBeige)
                                .cornerRadius(12)
                                
                                // Add to Collection button
                                Button("Recycle it!") {
                                    addToCollection()
                                }
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.GrassGreen)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Retry button for errors
                        Button("Retry") {
                            isPresented = false
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.GrassGreen)
                        .clipShape(Capsule())
                    }
                    
                }
                .padding()
            }
        }
        .persistentSystemOverlays(.hidden)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [capturedImage])
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Helper Functions
    // Adds the scanned item to RecyclingManager and shows success feedback
    private func addToCollection() {
        // Convert classification result to RecyclableType enum
        let type = mapToRecyclableType()
        
        // Add to Yu's RecyclingManager
        recyclingManager.addScannedItem(type: type)
        
        // Show success message with animation
        withAnimation {
            showSuccess = true
        }
        
        // Auto-close after 1.5 seconds to return to camera
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPresented = false
        }
    }
    
    // Maps Ariel's classification text to Yu's RecyclableType enum
    private func mapToRecyclableType() -> RecyclableType {
        let name = classifierViewModel.wasteTypeText.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).lowercased()
        
        switch name {
        case "plastic": return .plastic
        case "paper": return .paper
        case "metal": return .metal
        case "glass": return .glass
        case "organic": return .organic
        case "e-waste", "electronic", "electronics": return .electronic
        case "general": return .general
        default: return .general  // Fallback to general if unknown type
        }
    }
    
    // Gets point value for detected item type
    private func getPointValue() -> Int {
        return mapToRecyclableType().pointValue
    }
}

// MARK: - ShareSheet UIViewControllerRepresentable
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No update needed
    }
}
    

#Preview {
    WasteScannerResultView(
        capturedImage: UIImage(systemName: "photo")!,
        isPresented: .constant(true),
        classifierViewModel: ScannerClassifierViewModel(),
        recyclingManager: RecyclingManager.sample
    )
}
