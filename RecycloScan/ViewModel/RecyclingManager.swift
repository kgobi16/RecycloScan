//
//  RecyclingManager.swift
//  RecycloScan
//
//  Created by Yu on 10/14/25.
//

//  Kate's part
//  Main manager for counting items and awarding points


import Foundation
import SwiftUI

class RecyclingManager: ObservableObject {
    @Published var totalPoints: Int = 0
    @Published var pendingItems: [RecyclableItem] = []
    @Published var pickupHistory: [PickupEvent] = []
    
    init() {
        loadFromUserDefaults()
    }
    
    // MARK: - Scanning (Count Only, No Points)
    
    // Add scanned item to pending collection
    // Called by Ariel's ScannerViewModel after classification
    func addScannedItem(type: RecyclableType) {
        let item = RecyclableItem(type: type)
        pendingItems.append(item)
        saveToUserDefaults()
        
        print("📦 Added \(type.displayName) to collection (pending: \(pendingItems.count))")
    }
    
    // MARK: - Pickup Completion (Award Points)
    
    // Complete pickup and award points
    // Called by Kgobi's PickupScheduler when garbage is collected
    func completePickup(pickupDate: Date) {
        guard !pendingItems.isEmpty else {
            print("⚠️ No items to collect")
            return
        }
        
        var collectedItems = pendingItems
        for index in collectedItems.indices {
            collectedItems[index].isCollected = true
        }
        
        let pickupEvent = PickupEvent(pickupDate: pickupDate, collectedItems: collectedItems)
        pickupHistory.append(pickupEvent)
        totalPoints += pickupEvent.pointsAwarded
        
        pendingItems.removeAll()
        saveToUserDefaults()
        
        print("🎉 Pickup completed! +\(pickupEvent.pointsAwarded) points for \(collectedItems.count) items")
    }
    
    // Remove item from pending collection
    func removePendingItem(_ item: RecyclableItem) {
        pendingItems.removeAll { $0.id == item.id }
        saveToUserDefaults()
    }
    
    // MARK: - Statistics
    
    func getPendingItemCount() -> Int {
        return pendingItems.count
    }
    
    func getPendingItemsByType() -> [RecyclableType: Int] {
        var counts: [RecyclableType: Int] = [:]
        for item in pendingItems {
            counts[item.type, default: 0] += 1
        }
        return counts
    }
    
    func getPotentialPoints() -> Int {
        return pendingItems.reduce(0) { $0 + $1.type.pointValue }
    }
    
    func getTotalItemsRecycled() -> Int {
        return pickupHistory.reduce(0) { $0 + $1.itemCount }
    }
    
    func getPointsThisMonth() -> Int {
        let calendar = Calendar.current
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        
        return pickupHistory
            .filter { $0.timestamp >= monthAgo }
            .reduce(0) { $0 + $1.pointsAwarded }
    }
    
    func getTotalPickups() -> Int {
        return pickupHistory.count
    }
    
    func getMostRecycledType() -> RecyclableType? {
        var typeCounts: [RecyclableType: Int] = [:]
        
        for pickup in pickupHistory {
            for item in pickup.collectedItems {
                typeCounts[item.type, default: 0] += 1
            }
        }
        
        return typeCounts.max(by: { $0.value < $1.value })?.key
    }
    
    func getAllRecycledItemsByType() -> [RecyclableType: Int] {
        var typeCounts: [RecyclableType: Int] = [:]
        
        for pickup in pickupHistory {
            for item in pickup.collectedItems {
                typeCounts[item.type, default: 0] += 1
            }
        }
        
        return typeCounts
    }
    
    // MARK: - Persistence
    
    private func saveToUserDefaults() {
        if let pendingData = try? JSONEncoder().encode(pendingItems) {
            UserDefaults.standard.set(pendingData, forKey: "pendingItems")
        }
        
        if let pickupData = try? JSONEncoder().encode(pickupHistory) {
            UserDefaults.standard.set(pickupData, forKey: "pickupHistory")
        }
        
        UserDefaults.standard.set(totalPoints, forKey: "totalPoints")
    }
    
    private func loadFromUserDefaults() {
        totalPoints = UserDefaults.standard.integer(forKey: "totalPoints")
        
        if let pendingData = UserDefaults.standard.data(forKey: "pendingItems"),
           let items = try? JSONDecoder().decode([RecyclableItem].self, from: pendingData) {
            pendingItems = items
        }
        
        if let pickupData = UserDefaults.standard.data(forKey: "pickupHistory"),
           let pickups = try? JSONDecoder().decode([PickupEvent].self, from: pickupData) {
            pickupHistory = pickups
        }
    }
}

// MARK: Integration

/*
 
 INTEGRATE WITH TEAMMATES:
 
 1. ARIEL'S SCANNER (after image classification completes):
 
    // In ScannerViewModel.swift
    func handleClassificationResult(_ result: RecyclableType) {
        recyclingManager.addScannedItem(type: result)
    }
 
 2. KGOBI'S PICKUP SCHEDULER (when pickup confirmed):
 
    // In PickupScheduler.swift
    func confirmPickupCompletion(date: Date) {
        recyclingManager.completePickup(pickupDate: date)
    }
 
 */
