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
#if canImport(WidgetKit)
import WidgetKit
#endif

class RecyclingManager: ObservableObject {
    @Published var totalPoints: Int = 0
    @Published var pendingItems: [RecyclableItem] = []
    @Published var pickupHistory: [PickupEvent] = []
    
    init() {
        loadFromUserDefaults()
    }
    
    
    // MARK: - Scanning (Add item + award scan points)
    func addScannedItem(type: RecyclableType) {
        // 1️⃣ Create a new recyclable item
        let item = RecyclableItem(type: type)
        pendingItems.append(item)
        
        // 2️⃣ Award immediate points for successful scan
        totalPoints += type.pointValue
        
        // 3️⃣ Save updated data
        saveToUserDefaults()

    }
        
        
    // MARK: - Pickup Completion (Award Points)
    
    // Complete pickup and award points
    // Called by Kobi's PickupSchedulerVM when garbage is collected
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
        
        // Update widget with latest data
        updateWidgetDataFromPickupScheduler()
    }
    
    
    // MARK: - Bin Completion (User confirmed put out)
    func recordBinCompletion(binTypes: [BinType], date: Date) {
        if !pendingItems.isEmpty {
            completePickup(pickupDate: date)
        } else {
            print("⚠️ No recyclables pending for pickup.")
        }
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
    
    func getPointsThisWeek() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        return pickupHistory
            .filter { $0.timestamp >= weekAgo }
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
    
    
    func updateWidgetData(nextPickup: (binType: BinType, date: Date)?) {
        let widgetData = WidgetData(
            pointsThisWeek: getPointsThisWeek(),
            nextPickupDate: nextPickup?.date,
            nextPickupBinType: nextPickup?.binType.displayName,
            lastUpdated: Date()
        )
        WidgetData.save(widgetData)
        
        // Tell widget to refresh
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
    
    // Internal method to update widget data by finding the pickup scheduler
    private func updateWidgetDataFromPickupScheduler() {
        // Try to get next pickup from pickup scheduler
        // Since this is called from within RecyclingManager, we need to access it differently
        // For now, just update with current points and let the app update pickup info
        let widgetData = WidgetData(
            pointsThisWeek: getPointsThisWeek(),
            nextPickupDate: nil, // Will be updated by PickupSchedulerVM
            nextPickupBinType: nil,
            lastUpdated: Date()
        )
        WidgetData.save(widgetData)
        
        // Tell widget to refresh
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
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

// MARK: - Sample Data

extension RecyclingManager {
    static var sample: RecyclingManager {
        let manager = RecyclingManager()
        
        // Add some sample scanned items
        manager.addScannedItem(type: .plastic)
        manager.addScannedItem(type: .paper)
        manager.addScannedItem(type: .metal)
        manager.addScannedItem(type: .glass)
        
        // Simulate a completed pickup
        manager.completePickup(pickupDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!)
        
        // Add more pending items
        manager.addScannedItem(type: .electronic)
        manager.addScannedItem(type: .plastic)
        
        return manager
    }
}

// MARK: Integration

/*
 
 INTEGRATE WITH TEAMMATES:
 
 1. ARIEL'S SCANNER (after image classification completes):
 
    // In WasteScannerView
    func handleClassificationResult(_ result: RecyclableType) {
        recyclingManager.addScannedItem(type: result)
    }
 
 2. KOBI'S PICKUP SCHEDULER (in PickupSchedulerVM.swift):
 
    // Already integrated! Kobi's confirmBinsPutOut calls:
    func confirmBinsPutOut(for binTypes: [BinType], on date: Date) {
        recyclingManager?.recordBinCompletion(binTypes: binTypes, date: date)
    }
 
 */
