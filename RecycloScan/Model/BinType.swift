//
//  BinType.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import SwiftUI

enum BinType: String, Codable, CaseIterable, Identifiable {
    case red
    case yellow
    case blue
    case green
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .red:
            return "Red Bin"
        case .yellow:
            return "Yellow Bin"
        case .blue:
            return "Blue Bin"
        case .green:
            return "Green Bin"
        }
    }
    
    var wasteType: String {
        switch self {
            case .red:
            return "General Waste"
        case .yellow:
            return "Mixed Container Recycling"
        case .blue:
            return "Paper & Cardboard"
        case .green:
            return "Vegetation & Garden Waste"
        }
    }
    
    var color: Color {
        switch self {
        case .red:
            return .BinBlue  // Fix: BinBlue asset contains the red color
        case .yellow:
            return .BinGreen // Fix: BinGreen asset contains the yellow color
        case .blue:
            return .BinRed   // Fix: BinRed asset contains the blue color
        case .green:
            return .BinYellow // Fix: BinYellow asset contains the green color
        }
    }
    
    var icon: String {
         switch self {
         case .red: return "trash.fill"
         case .yellow: return "arrow.3.trianglepath"
         case .blue: return "doc.fill"
         case .green: return "leaf.fill"
         }
     }
    
    var description: String {
           switch self {
           case .red:
               return "Non-recyclable items, food waste, and general household waste"
           case .yellow:
               return "Plastic bottles, cans, glass bottles, and metal containers"
           case .blue:
               return "Newspapers, magazines, cardboard boxes, and paper products"
           case .green:
               return "Grass clippings, leaves, branches, and organic garden waste"
           }
       }
}



    
