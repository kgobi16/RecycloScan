//
//  ColorTheme.swift
//  RecycloScan
//
//  Eco-Natural color palette for RecycloScan app
//
//  Created by Tlaitirang Rathete on 9/10/2025.
//
//

import SwiftUI

// MARK: ColorTheme provides a centralized way to access all brand colors

extension Color {
    
    // These are the main colors that define our app's personality
    // Each color references a Color Set in Assets
    
    static let ForestGreen = Color("ForestGreen")
    static let GrassGreen = Color("GrassGreen")
    static let WarmOrange = Color("WarmOrange")
    static let BackgroundBeige = Color("BackgroundBeige")
    
    // These provide structure and hierarchy to our interface
    
    static let SurfaceWhite = Color.white
    static let TextPrimary = Color("TextPrimary")
    static let TextSecondary = Color("TextSecondary")    // Gray for secondary text
    
    // Specific colors for different waste categories
    // These help users quickly identify waste types
    
    static let PaperBrown = Color("PaperBrown")          // For paper/cardboard
    static let PlasticBlue = Color("PlasticBlue")        // For plastic items
    static let GlassGreen = Color("GlassGreen")          // For glass
    static let MetalGray = Color("MetalGray")            // For metal/aluminum
    static let EWasteRed = Color("EWasteRed")            // For electronic waste
    static let OrganicOrange = Color("OrganicOrange")    // For organic/compost
    static let GeneralGray = Color("GeneralGray")       // For general/landfill items
    
    // Bin Collection Colors
    // Colors matching actual municipal bin colors for pickup scheduling
   
    static let BinRed = Color("BinRed")                  // General waste/garbage
    static let BinYellow = Color("BinYellow")            // Mixed container recycling
    static let BinBlue = Color("BinBlue")                // Paper & cardboard
    static let BinGreen = Color("BinGreen")              // Vegetation/garden waste
   
    
    // Gradient Sets
    
    /// Main hero gradient for headers and featured content
    static let heroGradient = LinearGradient(
        colors: [GrassGreen, ForestGreen.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Scan button gradient
    static let scanGradient = LinearGradient(
        colors: [ForestGreen, GrassGreen.opacity(0.9)],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Background gradient for cards
    static let cardGradient = LinearGradient(
        colors: [SurfaceWhite, BackgroundBeige],
        startPoint: .top,
        endPoint: .bottom
    )
}

// Preview Provider
// This allows us to see all our colors in Xcode's preview pane
struct ColorTheme_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Eco-Natural Color Palette")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top)
                
                // Primary colors
                Group {
                    Text("Primary Colors")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ColorSwatch(color: .ForestGreen, name: "Forest Green", hex: "#2D5016")
                    ColorSwatch(color: .GrassGreen, name: "Grass Green", hex: "#7CB342")
                    ColorSwatch(color: .WarmOrange, name: "Warm Orange", hex: "#FFA726")
                    ColorSwatch(color: .BackgroundBeige, name: "Background Beige", hex: "#F5F5DC")
                }
                
                Divider()
                    .padding(.vertical)
                
                // Category colors
                Group {
                    Text("Waste Category Colors")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ColorSwatch(color: .PaperBrown, name: "Paper Brown", hex: "For Paper/Cardboard")
                    ColorSwatch(color: .PlasticBlue, name: "Plastic Blue", hex: "For Plastic")
                    ColorSwatch(color: .GlassGreen, name: "Glass Green", hex: "For Glass")
                    ColorSwatch(color: .MetalGray, name: "Metal Gray", hex: "For Metal")
                    ColorSwatch(color: .EWasteRed, name: "E-Waste Red", hex: "For Electronics")
                    ColorSwatch(color: .OrganicOrange, name: "Organic Orange", hex: "For Organic/Compost")
                    ColorSwatch(color: .GeneralGray, name: "General Gray", hex: "For General/Landfill")
                }
                
                Divider()
                    .padding(.vertical)
                
                // Bin Collection Colors
                Group {
                    Text("Bin Collection Colors")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ColorSwatch(color: .BinRed, name: "Red Bin", hex: "General Waste")
                    ColorSwatch(color: .BinYellow, name: "Yellow Bin", hex: "Mixed Containers")
                    ColorSwatch(color: .BinBlue, name: "Blue Bin", hex: "Paper & Cardboard")
                    ColorSwatch(color: .BinGreen, name: "Green Bin", hex: "Garden Waste")
                }
                
                Divider()
                    .padding(.vertical)
                
                // Show gradient examples
                Group {
                    Text("Gradients")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.heroGradient)
                        .frame(height: 100)
                        .overlay(
                            Text("Hero Gradient")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                        .padding(.horizontal)
                    
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.scanGradient)
                        .frame(height: 100)
                        .overlay(
                            Text("Scan Gradient")
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
        .background(Color.BackgroundBeige)
    }
}

struct ColorSwatch: View {
    let color: Color
    let name: String
    let hex: String
    
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(width: 70, height: 70)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                
                Text(hex)
                    .font(.system(size: 13))
                    .foregroundColor(.TextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}
