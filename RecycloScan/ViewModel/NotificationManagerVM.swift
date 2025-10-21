//
//  NotificationManagerVM.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationManagerVM: NSObject, ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var notificationPermissionGranted: Bool = false
    @Published var recentTipIDs: [UUID] = [] // Track recent tips to avoid repeats
    
    // Reference to PickupScheduler to get bin schedules
    private var pickupScheduler: PickupSchedulerVM?
    
    // Reference to RecyclingManager for gamification
    private var recyclingManager: RecyclingManager?
    
    init(pickupScheduler: PickupSchedulerVM? = nil, recyclingManager: RecyclingManager? = nil) {
        self.pickupScheduler = pickupScheduler
        self.recyclingManager = recyclingManager
        
        super.init()
        
        loadNotifications()
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from user
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = granted
                
                if granted {
                    print("📱 Notification permission granted")
                    self.setupNotificationCategories()
                    self.scheduleAllNotifications()
                } else {
                    print("❌ Notification permission denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Setup interactive notification categories with actions
    private func setupNotificationCategories() {
        // Actions for bin reminder notifications
        let yesAction = UNNotificationAction(
            identifier: "BIN_YES",
            title: "✅ Put Out",
            options: [.foreground]
        )
        
        let noAction = UNNotificationAction(
            identifier: "BIN_NO", 
            title: "❌ Missed",
            options: []
        )
        
        // Category for bin reminders
        let binReminderCategory = UNNotificationCategory(
            identifier: "BIN_REMINDER",
            actions: [yesAction, noAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Actions for weekly tips
        let dismissAction = UNNotificationAction(
            identifier: "TIP_DISMISS",
            title: "Got it!",
            options: []
        )
        
        // Category for weekly tips
        let weeklyTipCategory = UNNotificationCategory(
            identifier: "WEEKLY_TIP",
            actions: [dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Register categories
        UNUserNotificationCenter.current().setNotificationCategories([
            binReminderCategory,
            weeklyTipCategory
        ])
        
        // Set delegate to handle responses
        UNUserNotificationCenter.current().delegate = self
        
        print("📱 Notification categories set up")
    }
    
    /// Check current notification permission status
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Bin Reminder Notifications
    
    /// Schedule bin reminder notification
    func scheduleBinReminder(for binType: BinType, on date: Date, reminderTimeBefore: TimeInterval = 43200) {
        let notificationDate = date.addingTimeInterval(-reminderTimeBefore)
        
        // Don't schedule past notifications
        guard notificationDate > Date() else { return }
        
        let title = "\(binType.displayName) Collection Tomorrow"
        let message = "Don't forget to put out your \(binType.displayName.lowercased()) (\(binType.wasteType.lowercased())) tonight!"
        
        let notification = NotificationItem(
            type: .binReminder,
            title: title,
            message: message,
            scheduledDate: notificationDate,
            binType: binType
        )
        
        notifications.append(notification)
        saveNotifications()
        
        // Schedule iOS notification
        scheduleIOSNotification(notification)
    }
    
    /// Schedule all bin reminders based on pickup schedule
    func scheduleAllBinReminders() {
        guard let scheduler = pickupScheduler else { return }
        
        // Remove old bin reminders
        notifications.removeAll { $0.type == .binReminder && $0.scheduledDate < Date() }
        
        let upcomingPickups = scheduler.getUpcomingPickups(days: 14)
        
        for pickup in upcomingPickups {
            // Check if notification already exists
            let exists = notifications.contains { notification in
                notification.type == .binReminder &&
                notification.binType == pickup.binType &&
                Calendar.current.isDate(notification.scheduledDate, inSameDayAs: pickup.date)
            }
            
            if !exists {
                scheduleBinReminder(for: pickup.binType, on: pickup.date)
            }
        }
        
        print("🔔 Scheduled bin reminders for \(upcomingPickups.count) pickups")
    }
    
    // MARK: - Weekly Tip Notifications
    
    /// Schedule a weekly recycling tip
    func scheduleWeeklyTip() {
        // Schedule tip for 3 days from now at 10 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 3
        components.hour = 10
        components.minute = 0
        
        guard let tipDate = calendar.date(from: components) else { return }
        
        // Get a random tip that hasn't been shown recently
        let tip = RecyclingTipsDatabase.randomTip(excluding: recentTipIDs)
        
        let notification = NotificationItem(
            type: .weeklyTip,
            title: "Recycling Tip of the Week",
            message: tip.tip,
            scheduledDate: tipDate,
            tipCategory: tip.category
        )
        
        notifications.append(notification)
        recentTipIDs.append(tip.id)
        
        // Keep only last 10 tip IDs
        if recentTipIDs.count > 10 {
            recentTipIDs.removeFirst()
        }
        
        saveNotifications()
        scheduleIOSNotification(notification)
        
        print("💡 Scheduled weekly tip for \(tipDate)")
    }
    
    /// Schedule recurring weekly tips
    func scheduleRecurringWeeklyTips(weeksAhead: Int = 4) {
        for week in 1...weeksAhead {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.day! += (week * 7)
            components.hour = 10
            components.minute = 0
            
            guard let tipDate = calendar.date(from: components) else { continue }
            
            let tip = RecyclingTipsDatabase.randomTip(excluding: recentTipIDs)
            
            let notification = NotificationItem(
                type: .weeklyTip,
                title: "Recycling Tip of the Week",
                message: tip.tip,
                scheduledDate: tipDate,
                tipCategory: tip.category
            )
            
            notifications.append(notification)
            recentTipIDs.append(tip.id)
            scheduleIOSNotification(notification)
        }
        
        saveNotifications()
        print("💡 Scheduled \(weeksAhead) weekly tips")
    }
    
    // MARK: - iOS Native Notifications
    
    /// Schedule notification with iOS system
    private func scheduleIOSNotification(_ notification: NotificationItem) {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.sound = .default
        
        // Enhanced body message with bin status prompt
        if notification.type == .binReminder, let binType = notification.binType {
            content.body = "\(notification.message)\n\nTap to confirm if you put your bin outside."
            content.categoryIdentifier = "BIN_REMINDER"
        } else {
            content.body = notification.message
            content.categoryIdentifier = "WEEKLY_TIP"
        }
        
        // Add custom data for handling response
        content.userInfo = [
            "notificationId": notification.id.uuidString,
            "binType": notification.binType?.rawValue ?? "",
            "type": notification.type.rawValue
        ]
        
        // Create trigger
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notification.scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error.localizedDescription)")
            } else {
                print("📱 iOS notification scheduled for \(notification.formattedScheduledDate)")
            }
        }
    }
    
    /// Cancel all scheduled iOS notifications
    func cancelAllIOSNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("🔕 All iOS notifications cancelled")
    }
    
    /// Schedule all notifications (both bin reminders and tips)
    func scheduleAllNotifications() {
        guard notificationPermissionGranted else {
            requestNotificationPermission()
            return
        }
        
        cancelAllIOSNotifications()
        scheduleAllBinReminders()
        scheduleRecurringWeeklyTips()
    }
    
    // MARK: - Notification Response Handling
    
    /// Mark notification as completed (Yes response)
    func markAsCompleted(_ notification: NotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        notifications[index].markAsCompleted()
        saveNotifications()
        
        // Award points for completing bin reminder
        if notification.type == .binReminder, let binType = notification.binType {
            awardPointsForCompletion(binType: binType)
        }
        
        print("✅ Notification marked as completed: \(notification.title)")
    }
    
    /// Mark notification as missed (No response)
    func markAsMissed(_ notification: NotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        
        notifications[index].markAsMissed()
        saveNotifications()
        
        print("❌ Notification marked as missed: \(notification.title)")
    }
    
    /// Award points when user confirms they put out bins
    private func awardPointsForCompletion(binType: BinType) {
        // Integration point for gamification
        // recyclingManager?.awardBinCompletionPoints(for: binType)
        print("🎉 Would award points for putting out \(binType.displayName)")
    }
    
    // MARK: - Notification Queries
    
    /// Get active (pending) notifications
    var activeNotifications: [NotificationItem] {
        return notifications.filter { $0.isActive }
    }
    
    /// Get completed notifications
    var completedNotifications: [NotificationItem] {
        return notifications.filter { $0.response == .yes }
    }
    
    /// Get missed notifications
    var missedNotifications: [NotificationItem] {
        return notifications.filter { $0.response == .no }
    }
    
    /// Get overdue notifications
    var overdueNotifications: [NotificationItem] {
        return notifications.filter { $0.isOverdue }
    }
    
    /// Get today's notifications
    var todayNotifications: [NotificationItem] {
        return notifications.filter { Calendar.current.isDateInToday($0.scheduledDate) }
    }
    
    // MARK: - Statistics for Gamification
    
    /// Calculate completion rate for bin reminders
    func binReminderCompletionRate() -> Double {
        let binReminders = notifications.filter { $0.type == .binReminder && $0.response != .pending }
        guard !binReminders.isEmpty else { return 0.0 }
        
        let completed = binReminders.filter { $0.response == .yes }.count
        return Double(completed) / Double(binReminders.count)
    }
    
    /// Get total completed bin reminders
    func totalCompletedReminders() -> Int {
        return notifications.filter { $0.type == .binReminder && $0.response == .yes }.count
    }
    
    // MARK: - Persistence
    
    private func saveNotifications() {
        if let encoded = try? JSONEncoder().encode(notifications) {
            UserDefaults.standard.set(encoded, forKey: "notifications")
        }
        
        if let encodedTips = try? JSONEncoder().encode(recentTipIDs) {
            UserDefaults.standard.set(encodedTips, forKey: "recentTipIDs")
        }
    }
    
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: "notifications"),
           let decoded = try? JSONDecoder().decode([NotificationItem].self, from: data) {
            notifications = decoded
        }
        
        if let tipData = UserDefaults.standard.data(forKey: "recentTipIDs"),
           let decodedTips = try? JSONDecoder().decode([UUID].self, from: tipData) {
            recentTipIDs = decodedTips
        }
    }
    
    /// Clear all notification data
    func clearAllData() {
        notifications.removeAll()
        recentTipIDs.removeAll()
        saveNotifications()
        cancelAllIOSNotifications()
        print("🗑️ All notification data cleared")
    }
    
    // MARK: - Manager References
    
    public func setPickupScheduler(_ scheduler: PickupSchedulerVM) {
        self.pickupScheduler = scheduler
    }
    
    public func setRecyclingManager(_ manager: RecyclingManager) {
        self.recyclingManager = manager
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManagerVM: UNUserNotificationCenterDelegate {
    
    /// Handle notification response (when user taps action buttons)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        
        guard let notificationIdString = userInfo["notificationId"] as? String,
              let notificationId = UUID(uuidString: notificationIdString),
              let notificationIndex = notifications.firstIndex(where: { $0.id == notificationId }) else {
            completionHandler()
            return
        }
        
        let notification = notifications[notificationIndex]
        
        switch response.actionIdentifier {
        case "BIN_YES":
            // User confirmed they put out the bin
            DispatchQueue.main.async {
                self.markAsCompleted(notification)
                
                // Record completion in pickup scheduler if available
                if let binTypeString = userInfo["binType"] as? String,
                   let binType = BinType(rawValue: binTypeString) {
                    self.pickupScheduler?.recordBinCompletion(for: [binType], points: 10)
                }
            }
            print("✅ User confirmed bin was put out")
            
        case "BIN_NO":
            // User missed putting out the bin
            DispatchQueue.main.async {
                self.markAsMissed(notification)
                
                // Record missed in pickup scheduler if available
                if let binTypeString = userInfo["binType"] as? String,
                   let binType = BinType(rawValue: binTypeString) {
                    self.pickupScheduler?.recordBinMissed(for: [binType])
                }
            }
            print("❌ User confirmed bin was missed")
            
        case "TIP_DISMISS":
            // User acknowledged the tip
            DispatchQueue.main.async {
                self.markAsCompleted(notification)
            }
            print("💡 User acknowledged weekly tip")
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action button)
            print("📱 User tapped notification")
            
        default:
            break
        }
        
        completionHandler()
    }
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

// MARK: - Sample Data
extension NotificationManagerVM {
    static var sample: NotificationManagerVM {
        let manager = NotificationManagerVM()
        manager.notifications = NotificationItem.sampleNotifications
        return manager
    }
}
