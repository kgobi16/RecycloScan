//
//  BinCardView.swift
//  RecycloScan
//
//  Created by Kgobi on 10/22/25.
//

import SwiftUI
import UserNotifications

struct BinCardView: View {
    let binType: BinType
    @ObservedObject var viewModel: PickupSchedulerVM
    @ObservedObject var recyclingManager: RecyclingManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDays: Set<WeekDay> = []
    @State private var reminderHours: Double = 12
    @State private var showingTestNotificationAlert = false
    @State private var showingCompletionAlert = false
    @State private var pointsAwarded = 0
    
    private var schedule: BinSchedule? {
        viewModel.pickupSchedule.schedule(for: binType)
    }
    
    private var stats: BinStats {
        viewModel.getStats(for: binType)
    }
    
    // Filter pending items by bin type
    private var binPendingItems: [RecyclableItem] {
        recyclingManager.pendingItems.filter { item in
            item.type.binType == binType
        }
    }
    
    private var totalPendingPoints: Int {
        binPendingItems.reduce(0) { $0 + $1.type.pointValue }
    }
    
    var body: some View {
        ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Statistics Section
                    statisticsSection
                    
                    // Pending Items Section
                    if !binPendingItems.isEmpty {
                        pendingItemsSection
                    }
                    
                    // Schedule Configuration
                    scheduleSection
                    
                    // Actions Section
                    actionsSection
                }
                .padding()
            }
            .background(Color.BackgroundBeige.ignoresSafeArea())
            .navigationTitle(binType.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(.ForestGreen)
                    .fontWeight(.semibold)
                }
            }
        .onAppear {
            loadCurrentSchedule()
        }
        .alert("Test Notification Sent!", isPresented: $showingTestNotificationAlert) {
            Button("OK") { }
        } message: {
            Text("Check your notifications in 15 seconds!")
        }
        .alert("Collection Complete! 🎉", isPresented: $showingCompletionAlert) {
            Button("Awesome!") { }
        } message: {
            Text("You earned \(pointsAwarded) points from \(binPendingItems.count) items!")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Bin Icon and Info
            HStack {
                Circle()
                    .fill(binType.color)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: binType.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(binType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.TextPrimary)
                    
                    Text(binType.wasteType)
                        .font(.subheadline)
                        .foregroundColor(.TextSecondary)
                    
                    Text(binType.description)
                        .font(.caption)
                        .foregroundColor(.TextSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.SurfaceWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Your Statistics")
                    .font(.headline)
                    .foregroundColor(.TextPrimary)
                Spacer()
            }
            
            // Top Row Stats
            HStack(spacing: 12) {
                StatBox(
                    title: "Total Points",
                    value: "\(stats.totalPointsEarned)",
                    icon: "star.fill",
                    color: .WarmOrange
                )
                
                StatBox(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    icon: "flame.fill",
                    color: .BinRed
                )
                
                StatBox(
                    title: "Best Streak",
                    value: "\(stats.bestStreak)",
                    icon: "trophy.fill",
                    color: .ForestGreen
                )
            }
            
            // Bottom Row Stats
            HStack(spacing: 12) {
                StatBox(
                    title: "Completed",
                    value: "\(stats.completedPickups)",
                    icon: "checkmark.circle.fill",
                    color: .GrassGreen
                )
                
                StatBox(
                    title: "Missed",
                    value: "\(stats.missedPickups)",
                    icon: "xmark.circle.fill",
                    color: .EWasteRed
                )
                
                StatBox(
                    title: "Success Rate",
                    value: "\(Int(stats.completionRate * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: binType.color
                )
            }
            
            // Last Pickup Info
            if let lastPickup = stats.lastPickupDate {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.TextSecondary)
                    
                    Text("Last pickup: \(formatDate(lastPickup))")
                        .font(.caption)
                        .foregroundColor(.TextSecondary)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Pending Items Section
    
    private var pendingItemsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pending Items for This Bin")
                    .font(.headline)
                    .foregroundColor(.TextPrimary)
                
                Spacer()
                
                Text("\(totalPendingPoints) pts")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.WarmOrange)
            }
            
            VStack(spacing: 8) {
                ForEach(binPendingItems) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(item.type.color)
                            .frame(width: 12, height: 12)
                        
                        Image(systemName: item.type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(item.type.color)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.type.displayName)
                                .font(.subheadline)
                                .foregroundColor(.TextPrimary)
                            
                            Text("Scanned \(item.relativeDate)")
                                .font(.caption)
                                .foregroundColor(.TextSecondary)
                        }
                        
                        Spacer()
                        
                        Text("+\(item.type.pointValue)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.WarmOrange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.WarmOrange.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.BackgroundBeige.opacity(0.5))
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Schedule Section
    
    private var scheduleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Collection Schedule")
                    .font(.headline)
                    .foregroundColor(.TextPrimary)
                Spacer()
            }
            
            // Day Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Pickup Days")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.TextPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                    ForEach(WeekDay.allCases) { day in
                        DayButton(
                            day: day,
                            isSelected: selectedDays.contains(day),
                            color: binType.color
                        ) {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    }
                }
            }
            
            // Reminder Time
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Reminder Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.TextPrimary)
                    
                    Spacer()
                    
                    Text("\(Int(reminderHours)) hours before")
                        .font(.caption)
                        .foregroundColor(.TextSecondary)
                }
                
                Slider(value: $reminderHours, in: 1...24, step: 1) {
                    Text("Reminder Hours")
                } minimumValueLabel: {
                    Text("1h")
                        .font(.caption)
                } maximumValueLabel: {
                    Text("24h")
                        .font(.caption)
                }
                .accentColor(binType.color)
            }
            
            // Next pickup display
            if !selectedDays.isEmpty {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.ForestGreen)
                    
                    Text("Next pickup: \(nextPickupDate())")
                        .font(.subheadline)
                        .foregroundColor(.ForestGreen)
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Complete Collection Button (only show if there are pending items)
            if !binPendingItems.isEmpty {
                Button(action: completeBinCollection) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Complete Collection")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Process \(binPendingItems.count) items • Earn \(totalPendingPoints) points")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [binType.color, binType.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
            }
            
            // Test Notification Button
            Button(action: sendTestNotification) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 18))
                    
                    Text("Send Test Notification")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
                .padding()
                .foregroundColor(binType.color)
                .background(binType.color.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(binType.color.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Helper Methods

extension BinCardView {
    private func loadCurrentSchedule() {
        if let schedule = schedule {
            selectedDays = Set(schedule.pickupDays)
        }
        reminderHours = Double(viewModel.pickupSchedule.reminderTimeBeforePickup / 3600)
    }
    
    private func saveChanges() {
        viewModel.updatePickupDays(for: binType, days: Array(selectedDays))
        viewModel.updateReminderTime(hours: reminderHours)
    }
    
    private func completeBinCollection() {
        let pointsEarned = totalPendingPoints
        
        // Process the bin collection manually (without notification)
        viewModel.recordBinCompletion(for: [binType], points: 10)
        recyclingManager.recordBinCompletion(binTypes: [binType], date: Date())
        
        pointsAwarded = pointsEarned
        showingCompletionAlert = true
    }
    
    private func nextPickupDate() -> String {
        guard !selectedDays.isEmpty else { return "No days selected" }
        
        let calendar = Calendar.current
        let today = Date()
        
        // Find next occurrence
        for i in 0...6 {
            let futureDate = calendar.date(byAdding: .day, value: i, to: today)!
            let weekday = calendar.component(.weekday, from: futureDate)
            let weekDay = WeekDay.fromCalendarWeekday(weekday)
            
            if selectedDays.contains(weekDay) {
                if i == 0 {
                    return "Today"
                } else if i == 1 {
                    return "Tomorrow"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEEE, MMM d"
                    return formatter.string(from: futureDate)
                }
            }
        }
        
        return "Next week"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func sendTestNotification() {
        // Request notification permission first
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                // Setup notification categories with actions
                let yesAction = UNNotificationAction(
                    identifier: "TEST_YES",
                    title: "✅ Yes, it works!",
                    options: [.foreground]
                )
                
                let noAction = UNNotificationAction(
                    identifier: "TEST_NO",
                    title: "❌ Not working",
                    options: []
                )
                
                let testCategory = UNNotificationCategory(
                    identifier: "TEST_NOTIFICATION",
                    actions: [yesAction, noAction],
                    intentIdentifiers: [],
                    options: []
                )
                
                UNUserNotificationCenter.current().setNotificationCategories([testCategory])
                
                // Schedule test notification for 15 seconds from now
                let content = UNMutableNotificationContent()
                content.title = "Test Notification - \(binType.displayName)"
                content.body = "Great! Your notifications are working correctly. You'll be reminded before your \(binType.displayName.lowercased()) collection day."
                content.sound = .default
                content.categoryIdentifier = "TEST_NOTIFICATION"
                
                // Add binType to userInfo so the delegate can process points
                content.userInfo = [
                    "binType": binType.rawValue,
                    "type": "testNotification"
                ]
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "test-notification-\(UUID().uuidString)",
                    content: content,
                    trigger: trigger
                )
                
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if error == nil {
                            showingTestNotificationAlert = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct DayButton: View {
    let day: WeekDay
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 40, height: 40)
                .background(isSelected ? color : Color.BackgroundBeige)
                .foregroundColor(isSelected ? .white : .TextSecondary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                )
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.TextPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.TextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Extensions

extension RecyclableType {
    var binType: BinType {
        switch self {
        case .plastic, .metal, .glass:
            return .yellow // Mixed Container Recycling
        case .paper:
            return .blue   // Paper & Cardboard
        case .organic:
            return .green  // Vegetation & Garden Waste
        case .electronic, .general:
            return .red    // General Waste
        }
    }
}

extension WeekDay {
    static func fromCalendarWeekday(_ weekday: Int) -> WeekDay {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .monday
        }
    }
}

// MARK: - Preview

#Preview {
    BinCardView(
        binType: .yellow,
        viewModel: PickupSchedulerVM.sample,
        recyclingManager: RecyclingManager.sample
    )
}