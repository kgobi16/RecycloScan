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

class PickupSchedulerVM: ObservableObject {
    @Published var pickupSchedule: PickupSchedule
    @Published var isLoading: Bool = false
    
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
    }
    
    //Schedule Management
    
    // Update pickup days for a specific bin type
    func updatePickupDays(for binType: BinType, days: [WeekDay], isEnabled: Bool = true) {
        pickupSchedule.updateSchedule(for: binType, pickupDays: days, isEnabled: isEnabled)
        saveSchedule()
        
        // Reschedule notifications when schedule changes
        scheduleNotifications()
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
    
    //Integration with RecyclingManager Will update when Yu finshes her section
    
    //Confirm that bins were put out (for gamification)
    func confirmBinsPutOut(for binTypes: [BinType], on date: Date) {
        // This could award points or track completion
        print("✅ Bins put out: \(binTypes.map { $0.displayName }.joined(separator: ", "))")
        
        // Future integration with RecyclingManager for points
        // recyclingManager?.recordBinCompletion(binTypes: binTypes, date: date)
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
        pickupSchedule = PickupSchedule()
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
        
        return scheduler
    }
    
    static var empty: PickupSchedulerVM {
        return PickupSchedulerVM()
    }
}
