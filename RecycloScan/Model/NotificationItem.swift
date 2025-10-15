//
//  NotificationItem.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import Foundation

enum NotificationType: String, Codable {
    case binReminder
    case weeklyTip
    
    var icon: String {
        switch self {
        case .binReminder: return "bell.fill"
        case .weeklyTip: return "lightbulb.fill"
        }
    }
}

enum NotificationResponse: String, Codable {
    case yes
    case no
    case pending
    
    var displayText: String {
        switch self {
        case .yes: return "Completed"
        case .no: return "Missed"
        case .pending: return "Pending"
        }
    }
}

struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let scheduledDate: Date
    var response: NotificationResponse
    var respondedDate: Date?
    
    // For bin reminders
    var binType: BinType?
    
    // For weekly tips
    var tipCategory: String?
    
    init(
        type: NotificationType,
        title: String,
        message: String,
        scheduledDate: Date,
        binType: BinType? = nil,
        tipCategory: String? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.scheduledDate = scheduledDate
        self.response = .pending
        self.respondedDate = nil
        self.binType = binType
        self.tipCategory = tipCategory
    }
    
    // Mark notification as completed (Yes)
    mutating func markAsCompleted() {
        self.response = .yes
        self.respondedDate = Date()
    }
    
    // Mark notification as missed (No)
    mutating func markAsMissed() {
        self.response = .no
        self.respondedDate = Date()
    }
    
    // Check if notification is overdue
    var isOverdue: Bool {
        return response == .pending && Date() > scheduledDate.addingTimeInterval(86400) // 24 hours
    }
    
    // Check if notification is active (today or future)
    var isActive: Bool {
        let calendar = Calendar.current
        return response == .pending && calendar.isDateInToday(scheduledDate) || scheduledDate > Date()
    }
    
    // Formatted scheduled date
    var formattedScheduledDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(scheduledDate) {
            formatter.timeStyle = .short
            return "Today at \(formatter.string(from: scheduledDate))"
        } else if calendar.isDateInTomorrow(scheduledDate) {
            formatter.timeStyle = .short
            return "Tomorrow at \(formatter.string(from: scheduledDate))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: scheduledDate)
        }
    }
    
    // Relative time string
    var relativeTimeString: String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(scheduledDate) {
            let components = calendar.dateComponents([.hour, .minute], from: now, to: scheduledDate)
            
            if let hours = components.hour, hours > 0 {
                return "in \(hours)h"
            } else if let minutes = components.minute, minutes > 0 {
                return "in \(minutes)m"
            } else if let minutes = components.minute, minutes < 0 {
                return "\(abs(minutes))m ago"
            }
            return "now"
        } else if calendar.isDateInTomorrow(scheduledDate) {
            return "tomorrow"
        } else if calendar.isDateInYesterday(scheduledDate) {
            return "yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: scheduledDate)
        }
    }
}

// Sample Notification Data for Testing
extension NotificationItem {
    static var sampleBinReminder: NotificationItem {
        NotificationItem(
            type: .binReminder,
            title: "Red Bin Collection Tomorrow",
            message: "Don't forget to put out your red bin (general waste) tonight!",
            scheduledDate: Calendar.current.date(byAdding: .hour, value: 18, to: Date())!,
            binType: .red
        )
    }
    
    static var sampleWeeklyTip: NotificationItem {
        NotificationItem(
            type: .weeklyTip,
            title: "Recycling Tip of the Week",
            message: "Rinse containers before recycling to prevent contamination and improve recycling quality.",
            scheduledDate: Date(),
            tipCategory: "Containers"
        )
    }
    
    static var sampleNotifications: [NotificationItem] {
        [
            NotificationItem(
                type: .binReminder,
                title: "Yellow Bin Collection Today",
                message: "Time to put out your yellow bin for mixed container recycling!",
                scheduledDate: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
                binType: .yellow
            ),
            sampleBinReminder,
            NotificationItem(
                type: .weeklyTip,
                title: "Recycling Tip: Cardboard",
                message: "Flatten cardboard boxes to save space in your blue bin and help collection.",
                scheduledDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
                tipCategory: "Paper"
            ),
            NotificationItem(
                type: .binReminder,
                title: "Green Bin Collection",
                message: "Garden waste collection in 2 days. Start gathering your green waste!",
                scheduledDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                binType: .green
            )
        ]
    }
}
