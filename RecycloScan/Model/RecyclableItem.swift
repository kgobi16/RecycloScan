//
//  RecyclableItem.swift
//  RecycloScan
//
//  Created by Yu on 10/14/25.
//

// Data model for scanned items

import SwiftUI

enum RecyclableType: String, Codable, CaseIterable {
    case plastic
    case paper
    case metal
    case glass
    case organic
    case electronic
    case general
    
    var displayName: String {
        switch self {
        case .plastic: return "Plastic"
        case .paper: return "Paper"
        case .metal: return "Metal"
        case .glass: return "Glass"
        case .organic: return "Organic"
        case .electronic: return "E-Waste"
        case .general: return "General"
        }
    }
    
    var pointValue: Int {
        switch self {
        case .plastic: return 10
        case .paper: return 8
        case .metal: return 15
        case .glass: return 12
        case .organic: return 5
        case .electronic: return 20
        case .general: return 3
        }
    }
    
    var color: Color {
        switch self {
        case .plastic: return .PlasticBlue
        case .paper: return .PaperBrown
        case .metal: return .MetalGray
        case .glass: return .GlassGreen
        case .organic: return .OrganicOrange
        case .electronic: return .EWasteRed
        case .general: return .GeneralGray
        }
    }
    
    var icon: String {
        switch self {
        case .plastic: return "🧴"
        case .paper: return "📄"
        case .metal: return "🥫"
        case .glass: return "🍾"
        case .organic: return "🍎"
        case .electronic: return "📱"
        case .general: return "🗑️"
        }
    }
}

struct RecyclableItem: Codable, Identifiable, Hashable {
    let id: UUID
    let type: RecyclableType
    let scannedDate: Date
    var isCollected: Bool
    
    init(type: RecyclableType) {
        self.id = UUID()
        self.type = type
        self.scannedDate = Date()
        self.isCollected = false
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: scannedDate)
    }
    
    var relativeDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(scannedDate) {
            let components = calendar.dateComponents([.hour, .minute], from: scannedDate, to: now)
            if let hours = components.hour, hours > 0 {
                return "\(hours)h ago"
            } else if let minutes = components.minute {
                return "\(minutes)m ago"
            }
            return "Just now"
        } else if calendar.isDateInYesterday(scannedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: scannedDate)
        }
    }
}
