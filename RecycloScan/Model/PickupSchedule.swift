//
//  PickupSchedule.swift
//  RecycloScan
//
//  Created by Tlaitirang on 10/15/25.
//

import Foundation

//Pickup Day Model
enum WeekDay: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var id: Int { rawValue }
    
    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
    
    var fullName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

//Bin Schedule Model
struct BinSchedule: Codable, Identifiable {
    let id: UUID
    let binType: BinType
    var pickupDays: [WeekDay]
    var isEnabled: Bool
    
    init(binType: BinType, pickupDays: [WeekDay] = [], isEnabled: Bool = true) {
        self.id = UUID()
        self.binType = binType
        self.pickupDays = pickupDays
        self.isEnabled = isEnabled
    }
    
    // Calculate next pickup date based on current date
    func nextPickupDate(from date: Date = Date()) -> Date? {
        guard isEnabled, !pickupDays.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let currentWeekday = calendar.component(.weekday, from: date)
        
        // Convert WeekDay enum to Calendar weekday format
        let sortedPickupDays = pickupDays.map { $0.rawValue }.sorted()
        
        // Find the next pickup day
        for pickupDay in sortedPickupDays {
            if pickupDay > currentWeekday {
                // Next pickup is this week
                var components = calendar.dateComponents([.year, .month, .weekOfYear], from: date)
                components.weekday = pickupDay
                return calendar.date(from: components)
            }
        }
        
        // Next pickup is next week (use first day from sorted list)
        if let firstPickupDay = sortedPickupDays.first {
            var components = calendar.dateComponents([.year, .month, .weekOfYear], from: date)
            components.weekOfYear! += 1
            components.weekday = firstPickupDay
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    // Days until next pickup
    func daysUntilNextPickup(from date: Date = Date()) -> Int? {
        guard let nextDate = nextPickupDate(from: date) else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date, to: nextDate)
        return components.day
    }
    
    // Formatted string for next pickup
    func nextPickupString(from date: Date = Date()) -> String {
        guard let days = daysUntilNextPickup(from: date) else {
            return "Not scheduled"
        }
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else {
            return "In \(days) days"
        }
    }
}

//Pickup Schedule for all bins
struct PickupSchedule: Codable, Identifiable {
    let id: UUID
    var binSchedules: [BinSchedule]
    var notificationsEnabled: Bool
    var reminderTimeBeforePickup: TimeInterval // seconds before pickup to remind
    var lastUpdated: Date
    
    init(
        binSchedules: [BinSchedule] = BinType.allCases.map { BinSchedule(binType: $0) },
        notificationsEnabled: Bool = true,
        reminderTimeBeforePickup: TimeInterval = 43200 // 12 hours default
    ) {
        self.id = UUID()
        self.binSchedules = binSchedules
        self.notificationsEnabled = notificationsEnabled
        self.reminderTimeBeforePickup = reminderTimeBeforePickup
        self.lastUpdated = Date()
    }
    
    // Get schedule for specific bin type
    func schedule(for binType: BinType) -> BinSchedule? {
        return binSchedules.first { $0.binType == binType }
    }
    
    // Get all enabled schedules
    var enabledSchedules: [BinSchedule] {
        return binSchedules.filter { $0.isEnabled && !$0.pickupDays.isEmpty }
    }
    
    // Get next pickup across all bins
    func nextPickup(from date: Date = Date()) -> (binType: BinType, date: Date)? {
        var nearestPickup: (BinType, Date)?
        
        for schedule in enabledSchedules {
            if let nextDate = schedule.nextPickupDate(from: date) {
                if nearestPickup == nil || nextDate < nearestPickup!.1 {
                    nearestPickup = (schedule.binType, nextDate)
                }
            }
        }
        
        return nearestPickup
    }
    
    // Get all upcoming pickups in the next week
    func upcomingPickups(days: Int = 7, from date: Date = Date()) -> [(binType: BinType, date: Date)] {
        var pickups: [(BinType, Date)] = []
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: date)!
        
        for schedule in enabledSchedules {
            var currentDate = date
            
            while let nextDate = schedule.nextPickupDate(from: currentDate), nextDate <= endDate {
                pickups.append((schedule.binType, nextDate))
                // Move to next day to find subsequent pickups
                currentDate = Calendar.current.date(byAdding: .day, value: 1, to: nextDate)!
            }
        }
        
        // Sort by date
        return pickups.sorted { (pickup1: (binType: BinType, date: Date), pickup2: (binType: BinType, date: Date)) in
            pickup1.date < pickup2.date
        }
    }
    
    // Check if any bin pickup is today
    func hasPickupToday(from date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        
        for schedule in enabledSchedules {
            if let nextDate = schedule.nextPickupDate(from: date),
               calendar.isDate(nextDate, inSameDayAs: date) {
                return true
            }
        }
        
        return false
    }
    
    // Get bins with pickup today
    func todayPickups(from date: Date = Date()) -> [BinType] {
        let calendar = Calendar.current
        var bins: [BinType] = []
        
        for schedule in enabledSchedules {
            if let nextDate = schedule.nextPickupDate(from: date),
               calendar.isDate(nextDate, inSameDayAs: date) {
                bins.append(schedule.binType)
            }
        }
        
        return bins
    }
    
    // Mutating method to update schedule
    mutating func updateSchedule(for binType: BinType, pickupDays: [WeekDay], isEnabled: Bool) {
        if let index = binSchedules.firstIndex(where: { $0.binType == binType }) {
            binSchedules[index] = BinSchedule(binType: binType, pickupDays: pickupDays, isEnabled: isEnabled)
            lastUpdated = Date()
        }
    }
}

//Sample Data for Testing
extension PickupSchedule {
    static var sample: PickupSchedule {
        var schedule = PickupSchedule()
        
        // Red bin: Monday and Thursday
        schedule.updateSchedule(for: .red, pickupDays: [.monday, .thursday], isEnabled: true)
        
        // Yellow bin: Wednesday
        schedule.updateSchedule(for: .yellow, pickupDays: [.wednesday], isEnabled: true)
        
        // Blue bin: Tuesday and Friday
        schedule.updateSchedule(for: .blue, pickupDays: [.tuesday, .friday], isEnabled: true)
        
        // Green bin: Friday
        schedule.updateSchedule(for: .green, pickupDays: [.friday], isEnabled: true)
        
        return schedule
    }
    
    static var empty: PickupSchedule {
        return PickupSchedule()
    }
}
