//
//  PickupSchedulerVM.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

//
//  PickupSchedulerVM.swift
//  RecycloScan
//
//  Created by Kgobi on 10/15/25.
//

import Foundation
import SwiftUI
#if canImport(WidgetKit)
import WidgetKit
#endif

// Statistics tracking for individual bin types
struct BinStats: Codable {
    var completedPickups: Int = 0
    var missedPickups: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalPointsEarned: Int = 0
    var lastPickupDate: Date?
    
    var completionRate: Double {
        let total = completedPickups + missedPickups
        return total > 0 ? Double(completedPickups) / Double(total) : 0.0
    }
    
    mutating func recordCompletion(points: Int = 10) {
        completedPickups += 1
        currentStreak += 1
        totalPointsEarned += points
        lastPickupDate = Date()
        
        if currentStreak > bestStreak {
            bestStreak = currentStreak
        }
    }
    
    mutating func recordMissed() {
        missedPickups += 1
        currentStreak = 0
    }
}

class PickupSchedulerVM: ObservableObject {
    @Published var pickupSchedule: PickupSchedule
    @Published var isLoading: Bool = false
    
    // Statistics tracking
    @Published var binCompletionStats: [BinType: BinStats] = [:]
    
    // Reference to Yu's: RecyclingManager for gamification integration
    private var recyclingManager: RecyclingManager?
    
    // Reference to NotificationManager for scheduling notifications
    private var notificationManager: NotificationManagerVM?
    
    init(recyclingManager: RecyclingManager? = nil, notificationManager: NotificationManagerVM? = nil) {
        self.recyclingManager = recyclingManager
        self.notificationManager = notificationManager
        
        // Load saved schedule or create new one
        if let savedSchedule = PickupSchedulerVM.loadScheduleFromUserDefaults() {
            self.pickupSchedule = savedSchedule
        } else {
            self.pickupSchedule = PickupSchedule()
        }
        
        // Load statistics
        loadBinStats()
        
        // Initialize stats for all bin types if not present
        for binType in BinType.allCases {
            if binCompletionStats[binType] == nil {
                binCompletionStats[binType] = BinStats()
            }
        }
    }
    
    //Schedule Management
    
    // Update pickup days for a specific bin type
    func updatePickupDays(for binType: BinType, days: [WeekDay], isEnabled: Bool = true) {
        pickupSchedule.updateSchedule(for: binType, pickupDays: days, isEnabled: isEnabled)
        saveSchedule()
        
        // Reschedule notifications when schedule changes
        scheduleNotifications()
        
        // Update widget with new schedule
        updateWidget()
    }
    
    // Toggle bin schedule on/off
    func toggleBinSchedule(for binType: BinType) {
        guard let schedule = pickupSchedule.schedule(for: binType) else { return }
        
        updatePickupDays(for: binType, days: schedule.pickupDays, isEnabled: !schedule.isEnabled)
    }
    
    // Enable or disable all notifications
    func toggleNotifications(_ enabled: Bool) {
        pickupSchedule.notificationsEnabled = enabled
        saveSchedule()
        
        if enabled {
            scheduleNotifications()
        } else {
            cancelAllNotifications()
        }
    }
    
    // Update reminder time (how many hours before pickup to remind)
    func updateReminderTime(hours: Double) {
        pickupSchedule.reminderTimeBeforePickup = hours * 3600 // Convert to seconds
        saveSchedule()
        
        // Reschedule with new reminder time
        scheduleNotifications()
    }
    
    //Pickup Information
    
    //Get the next pickup for any bin
    func getNextPickup() -> (binType: BinType, date: Date)? {
        return pickupSchedule.nextPickup()
    }
    
    //Get all upcoming pickups for the next week
    func getUpcomingPickups(days: Int = 7) -> [(binType: BinType, date: Date)] {
        return pickupSchedule.upcomingPickups(days: days)
    }
    
    //Check if there's a pickup today
    func hasPickupToday() -> Bool {
        return pickupSchedule.hasPickupToday()
    }
    
    //Get which bins need to go out today
    func getTodayPickups() -> [BinType] {
        return pickupSchedule.todayPickups()
    }
    
    //Get formatted string for next pickup of specific bin
    func nextPickupString(for binType: BinType) -> String {
        guard let schedule = pickupSchedule.schedule(for: binType) else {
            return "Not scheduled"
        }
        return schedule.nextPickupString()
    }
    
    //Notification Scheduling
    
    //Schedule all upcoming bin reminder notifications
    private func scheduleNotifications() {
        guard pickupSchedule.notificationsEnabled else { return }
        
        // Use NotificationManager if available
        notificationManager?.scheduleAllBinReminders()
        
        print("📅 Scheduled bin reminder notifications")
    }
    
    //Cancel all scheduled notifications
    private func cancelAllNotifications() {
        notificationManager?.cancelAllIOSNotifications()
        print("🔕 Cancelled all bin reminder notifications")
    }
    
    //MARK: - Statistics Management
    
    // Record that bins were successfully put out
    func recordBinCompletion(for binTypes: [BinType], points: Int = 10) {
        for binType in binTypes {
            binCompletionStats[binType]?.recordCompletion(points: points)
        }
        saveBinStats()
    }
    
    // Record that bins were missed
    func recordBinMissed(for binTypes: [BinType]) {
        for binType in binTypes {
            binCompletionStats[binType]?.recordMissed()
        }
        saveBinStats()
    }
    
    // Get statistics for a specific bin type
    func getStats(for binType: BinType) -> BinStats {
        return binCompletionStats[binType] ?? BinStats()
    }
    
    // Get total points earned across all bins
    func getTotalPointsEarned() -> Int {
        return binCompletionStats.values.reduce(0) { $0 + $1.totalPointsEarned }
    }
    
    // Get total completed pickups across all bins
    func getTotalCompletedPickups() -> Int {
        return binCompletionStats.values.reduce(0) { $0 + $1.completedPickups }
    }
    
    // Get total missed pickups across all bins
    func getTotalMissedPickups() -> Int {
        return binCompletionStats.values.reduce(0) { $0 + $1.missedPickups }
    }
    
    // Get overall completion rate
    func getOverallCompletionRate() -> Double {
        let totalCompleted = getTotalCompletedPickups()
        let totalMissed = getTotalMissedPickups()
        let total = totalCompleted + totalMissed
        return total > 0 ? Double(totalCompleted) / Double(total) : 0.0
    }
    
    // Get best streak across all bins
    func getBestStreak() -> Int {
        return binCompletionStats.values.map { $0.bestStreak }.max() ?? 0
    }
    
    // Get current active streaks
    func getCurrentStreaks() -> [BinType: Int] {
        return binCompletionStats.mapValues { $0.currentStreak }
    }
    
    //Integration with RecyclingManager Will update when Yu finshes her section
    
    //Confirm that bins were put out (for gamification)
    func confirmBinsPutOut(for binTypes: [BinType], on date: Date) {
        // Record completion in statistics
        recordBinCompletion(for: binTypes, points: 10)
        
        print("✅ Bins put out: \(binTypes.map { $0.displayName }.joined(separator: ", "))")
        
        // integration with RecyclingManager for points
        recyclingManager?.recordBinCompletion(binTypes: binTypes, date: date)
    }
    
    //Set the RecyclingManager reference for gamification
    public func setRecyclingManager(_ manager: RecyclingManager) {
        self.recyclingManager = manager
    }
    
    //Set the NotificationManager reference
    public func setNotificationManager(_ manager: NotificationManagerVM) {
        self.notificationManager = manager
    }
    
    //Persistence
    
    private func saveSchedule() {
        if let encoded = try? JSONEncoder().encode(pickupSchedule) {
            UserDefaults.standard.set(encoded, forKey: "pickupSchedule")
            print("💾 Pickup schedule saved")
        }
    }
    
    private func saveBinStats() {
        if let encoded = try? JSONEncoder().encode(binCompletionStats) {
            UserDefaults.standard.set(encoded, forKey: "binCompletionStats")
            print("📊 Bin statistics saved")
        }
    }
    
    private func loadBinStats() {
        guard let data = UserDefaults.standard.data(forKey: "binCompletionStats"),
              let stats = try? JSONDecoder().decode([BinType: BinStats].self, from: data) else {
            print("📊 No saved bin statistics found")
            return
        }
        binCompletionStats = stats
        print("📊 Bin statistics loaded")
    }
    
    private static func loadScheduleFromUserDefaults() -> PickupSchedule? {
        guard let data = UserDefaults.standard.data(forKey: "pickupSchedule"),
              let schedule = try? JSONDecoder().decode(PickupSchedule.self, from: data) else {
            return nil
        }
        print("📂 Pickup schedule loaded")
        return schedule
    }
    
    //Clear all saved data (useful for testing)
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "pickupSchedule")
        UserDefaults.standard.removeObject(forKey: "binCompletionStats")
        pickupSchedule = PickupSchedule()
        binCompletionStats = [:]
        
        // Initialize fresh stats
        for binType in BinType.allCases {
            binCompletionStats[binType] = BinStats()
        }
        
        cancelAllNotifications()
        print("🗑️ All pickup data cleared")
    }
    
    //Statistics
    
    //Get count of enabled bins
    func enabledBinCount() -> Int {
        return pickupSchedule.enabledSchedules.count
    }
    
    // Check if a specific bin is scheduled
    func isBinScheduled(_ binType: BinType) -> Bool {
        guard let schedule = pickupSchedule.schedule(for: binType) else { return false }
        return schedule.isEnabled && !schedule.pickupDays.isEmpty
    }
    
    //Get all scheduled bins
    func getScheduledBins() -> [BinType] {
        return pickupSchedule.enabledSchedules.map { $0.binType }
    }
}

//Sample Data for Testing
extension PickupSchedulerVM {
    static var sample: PickupSchedulerVM {
        let scheduler = PickupSchedulerVM()
        
        // Setup sample schedules
        scheduler.updatePickupDays(for: .red, days: [.monday, .thursday])
        scheduler.updatePickupDays(for: .yellow, days: [.wednesday])
        scheduler.updatePickupDays(for: .blue, days: [.tuesday, .friday])
        scheduler.updatePickupDays(for: .green, days: [.friday])
        
        // Add sample statistics
        scheduler.binCompletionStats[.red] = BinStats(
            completedPickups: 8,
            missedPickups: 2,
            currentStreak: 3,
            bestStreak: 5,
            totalPointsEarned: 80,
            lastPickupDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )
        
        scheduler.binCompletionStats[.yellow] = BinStats(
            completedPickups: 12,
            missedPickups: 1,
            currentStreak: 7,
            bestStreak: 7,
            totalPointsEarned: 120,
            lastPickupDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )
        
        scheduler.binCompletionStats[.blue] = BinStats(
            completedPickups: 6,
            missedPickups: 4,
            currentStreak: 0,
            bestStreak: 4,
            totalPointsEarned: 60,
            lastPickupDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())
        )
        
        scheduler.binCompletionStats[.green] = BinStats(
            completedPickups: 5,
            missedPickups: 1,
            currentStreak: 2,
            bestStreak: 4,
            totalPointsEarned: 50,
            lastPickupDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
        )
        
        return scheduler
    }
    
    static var empty: PickupSchedulerVM {
        return PickupSchedulerVM()
    }
    
    // MARK: - Widget Updates
    
    private func updateWidget() {
        let nextPickup = getNextPickup()
        let widgetData = WidgetData(
            pointsThisWeek: 0, // Will be updated by RecyclingManager
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
}
