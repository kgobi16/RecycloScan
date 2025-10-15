//
//  PickupEvent.swift
//  RecycloScan
//
//  Created by Yu on 10/14/25.
//


// Data model for pickup events

import Foundation

struct PickupEvent: Codable, Identifiable {
    let id: UUID
    let pickupDate: Date
    let collectedItems: [RecyclableItem]
    let pointsAwarded: Int
    let timestamp: Date
    
    init(pickupDate: Date, collectedItems: [RecyclableItem]) {
        self.id = UUID()
        self.pickupDate = pickupDate
        self.collectedItems = collectedItems
        self.timestamp = Date()
        
        // Calculate points based on collected items
        self.pointsAwarded = collectedItems.reduce(0) { $0 + $1.type.pointValue }
    }
    
    var itemCount: Int {
        return collectedItems.count
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: pickupDate)
    }
    
    var itemBreakdown: [RecyclableType: Int] {
        var breakdown: [RecyclableType: Int] = [:]
        for item in collectedItems {
            breakdown[item.type, default: 0] += 1
        }
        return breakdown
    }
}
