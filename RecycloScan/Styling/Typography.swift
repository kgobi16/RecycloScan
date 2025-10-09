//
//  Typography.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 9/10/2025.
//
//  Typography system following Eco-Natural design principles
// test

import SwiftUICore
import SwiftUI

extension Font {
    
    // Display Styles
    // Large, bold text for major headings
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Heading Styles
    // For content hierarchy and subsection titles
    static let headingLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let headingSmall = Font.system(size: 16, weight: .semibold, design: .rounded)
    
    // Body Styles
    // Standard readable text for main content
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Caption Styles
    // Small text for metadata and supporting information
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
    
    // Button Styles
    // Text styles specifically for buttons and CTAs
    static let buttonLarge = Font.system(size: 16, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 14, weight: .medium, design: .default)
    static let buttonSmall = Font.system(size: 12, weight: .medium, design: .default)
}

extension View {
    
    //Display Modifiers
    
    func displayLargeStyle() -> some View {
        self
            .font(.displayLarge)
            .foregroundColor(.TextPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }
    
    func displayMediumStyle() -> some View {
        self
            .font(.displayMedium)
            .foregroundColor(.TextPrimary)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
    }
    
    //Heading Modifiers
    
    func headingLargeStyle() -> some View {
        self
            .font(.headingLarge)
            .foregroundColor(.TextPrimary)
            .lineLimit(3)
    }
    
    func headingMediumStyle() -> some View {
        self
            .font(.headingMedium)
            .foregroundColor(.TextPrimary)
            .lineLimit(2)
    }
    
    func headingSmallStyle() -> some View {
        self
            .font(.headingSmall)
            .foregroundColor(.TextPrimary)
            .lineLimit(1)
    }
    
    //Body Modifiers
    
    func bodyLargeStyle() -> some View {
        self
            .font(.bodyLarge)
            .foregroundColor(.TextPrimary)
            .lineSpacing(4)
    }
    
    func bodyMediumStyle() -> some View {
        self
            .font(.bodyMedium)
            .foregroundColor(.TextSecondary)
            .lineSpacing(2)
    }
    
    func bodySmallStyle() -> some View {
        self
            .font(.bodySmall)
            .foregroundColor(.TextSecondary)
    }
    
    //Caption Modifiers
    
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.TextSecondary)
            .lineLimit(1)
    }
    
    func captionSmallStyle() -> some View {
        self
            .font(.captionSmall)
            .foregroundColor(.TextSecondary)
            .lineLimit(1)
    }
}

//Typography Preview
struct Typography_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                Text("RecycloScan Typography")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top)
                
                // Display styles
                Group {
                    Text("Display Styles")
                        .font(.headline)
                    
                    Text("Scan Your Waste")
                        .displayLargeStyle()
                    
                    Text("Sort Smarter")
                        .displayMediumStyle()
                }
                
                Divider()
                
                // Heading styles
                Group {
                    Text("Heading Styles")
                        .font(.headline)
                    
                    Text("Recent Scans")
                        .headingLargeStyle()
                    
                    Text("Coffee Cup")
                        .headingMediumStyle()
                    
                    Text("Plastic • Recycling")
                        .headingSmallStyle()
                }
                
                Divider()
                
                // Body styles
                Group {
                    Text("Body Styles")
                        .font(.headline)
                    
                    Text("This item can be recycled. Remove the lid and rinse before placing in your recycling bin.")
                        .bodyLargeStyle()
                    
                    Text("Make sure to check for recycling symbols")
                        .bodyMediumStyle()
                    
                    Text("Last scanned 2 hours ago")
                        .bodySmallStyle()
                }
                
                Divider()
                
                // Button examples
                Group {
                    Text("Button Text Examples")
                        .font(.headline)
                    
                    Text("Start Scanning")
                        .font(.buttonLarge)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(Color.ForestGreen)
                        .cornerRadius(16)
                    
                    Text("View Details")
                        .font(.buttonMedium)
                        .foregroundColor(.GrassGreen)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.GrassGreen.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.BackgroundBeige)
    }
}
