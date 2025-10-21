//
//  PickupAppointmentView.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import SwiftUI
import UserNotifications

struct PickupAppointmentView: View {
    @ObservedObject var viewModel: PickupSchedulerVM
    @State private var selectedBin: BinType?
    @State private var showingBinEditor = false
    
    init(viewModel: PickupSchedulerVM = PickupSchedulerVM.sample) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.BackgroundBeige
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Next Pickup Card
                        if let nextPickup = viewModel.getNextPickup() {
                            nextPickupCard(binType: nextPickup.binType, date: nextPickup.date)
                        }
                        
                        // Bin Schedule Cards
                        VStack(spacing: 16) {
                            ForEach(BinType.allCases) { binType in
                                BinScheduleCard(
                                    binType: binType,
                                    schedule: viewModel.pickupSchedule.schedule(for: binType),
                                    onTap: {
                                        selectedBin = binType
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            showingBinEditor = true
                                        }
                                    },
                                    onToggle: {
                                        viewModel.toggleBinSchedule(for: binType)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        // Weekly Calendar View
                        weeklyCalendarSection
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBinEditor) {
                if let binType = selectedBin {
                    BinScheduleEditorSheet(
                        binType: binType,
                        viewModel: viewModel,
                        isPresented: $showingBinEditor
                    )
                    .id(binType.rawValue)
                }
            }
        }
    }
    
    //Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Bin Collection Schedule")
                .displayLargeStyle()
            
            Text("Set your pickup days for each bin type")
                .bodyMediumStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // MARK: - Next Pickup Card
    private func nextPickupCard(binType: BinType, date: Date) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundColor(.ForestGreen)
                
                Text("Next Pickup")
                    .headingMediumStyle()
                
                Spacer()
            }
            
            HStack {
                Circle()
                    .fill(binType.color)
                    .frame(width: 12, height: 12)
                
                Text(binType.displayName)
                    .headingSmallStyle()
                
                Spacer()
                
                Text(formatDate(date))
                    .bodyMediumStyle()
            }
            .padding()
            .background(binType.color.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    //Weekly Calendar Section
    private var weeklyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Pickups")
                .headingLargeStyle()
                .padding(.horizontal)
            
            WeeklyCalendarView(viewModel: viewModel)
                .padding(.horizontal)
        }
    }
    
    //Helper
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// Bin Schedule Card
struct BinScheduleCard: View {
    let binType: BinType
    let schedule: BinSchedule?
    let onTap: () -> Void
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    // Bin Icon
                    Circle()
                        .fill(binType.color)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: binType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(binType.displayName)
                            .headingMediumStyle()
                        
                        Text(binType.wasteType)
                            .bodySmallStyle()
                    }
                    
                    Spacer()
                    
                    // Toggle
                    Toggle("", isOn: Binding(
                        get: { schedule?.isEnabled ?? false },
                        set: { _ in onToggle() }
                    ))
                    .labelsHidden()
                }
                
                // Pickup Days
                if let schedule = schedule, schedule.isEnabled {
                    Divider()
                    
                    HStack {
                        if schedule.pickupDays.isEmpty {
                            Text("No days selected")
                                .bodySmallStyle()
                                .foregroundColor(.TextSecondary)
                        } else {
                            HStack(spacing: 8) {
                                ForEach(WeekDay.allCases) { day in
                                    DayBadge(
                                        day: day,
                                        isSelected: schedule.pickupDays.contains(day),
                                        color: binType.color
                                    )
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if !schedule.pickupDays.isEmpty {
                            Text(schedule.nextPickupString())
                                .bodySmallStyle()
                                .foregroundColor(.ForestGreen)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .padding()
            .background(Color.SurfaceWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//Day Badge
struct DayBadge: View {
    let day: WeekDay
    let isSelected: Bool
    let color: Color
    
    var body: some View {
        Text(day.shortName)
            .font(.caption)
            .fontWeight(.medium)
            .frame(width: 32, height: 32)
            .background(isSelected ? color : Color.BackgroundBeige)
            .foregroundColor(isSelected ? .white : .TextSecondary)
            .cornerRadius(8)
    }
}

//Weekly Calendar View
struct WeeklyCalendarView: View {
    @ObservedObject var viewModel: PickupSchedulerVM
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(getNext7Days(), id: \.self) { date in
                WeeklyCalendarRow(
                    date: date,
                    pickups: getPickupsFor(date: date)
                )
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func getNext7Days() -> [Date] {
        var days: [Date] = []
        let calendar = Calendar.current
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: i, to: Date()) {
                days.append(date)
            }
        }
        return days
    }
    
    private func getPickupsFor(date: Date) -> [BinType] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        return viewModel.pickupSchedule.enabledSchedules.compactMap { schedule in
            if schedule.pickupDays.map({ $0.rawValue }).contains(weekday) {
                return schedule.binType
            }
            return nil
        }
    }
}

//Weekly Calendar Row
struct WeeklyCalendarRow: View {
    let date: Date
    let pickups: [BinType]
    
    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(dayName)
                    .bodyMediumStyle()
                    .fontWeight(.semibold)
                
                Text(dayNumber)
                    .captionStyle()
            }
            .frame(width: 80, alignment: .leading)
            
            Spacer()
            
            // Pickup Bins
            if pickups.isEmpty {
                Text("No pickups")
                    .bodySmallStyle()
                    .foregroundColor(.TextSecondary)
            } else {
                HStack(spacing: 8) {
                    ForEach(pickups, id: \.self) { binType in
                        Circle()
                            .fill(binType.color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: binType.icon)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

//Bin Schedule Editor Sheet
struct BinScheduleEditorSheet: View {
    let binType: BinType
    @ObservedObject var viewModel: PickupSchedulerVM
    @Binding var isPresented: Bool
    
    @State private var selectedDays: Set<WeekDay> = []
    @State private var reminderHours: Double = 12.0
    @State private var showingTestNotificationAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.BackgroundBeige
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Bin Info Header
                        binInfoHeader
                        
                        // Statistics Card
                        statisticsCard
                        
                        // Day Selector
                        daySelector
                        
                        // Notification Settings
                        notificationSettingsSection
                        
                        // Test Notification Button
                        testNotificationButton
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveDays()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if let schedule = viewModel.pickupSchedule.schedule(for: binType) {
                selectedDays = Set(schedule.pickupDays)
            }
            // Load reminder time
            reminderHours = viewModel.pickupSchedule.reminderTimeBeforePickup / 3600 // Convert seconds to hours
        }
    }
    
    // MARK: - Bin Info Header
    private var binInfoHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(binType.color)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: binType.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            Text(binType.displayName)
                .displayMediumStyle()
            
            Text(binType.wasteType)
                .bodyMediumStyle()
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    // MARK: - Statistics Card
    private var statisticsCard: some View {
        let stats = viewModel.getStats(for: binType)
        
        return VStack(spacing: 12) {
            Text("Your Statistics")
                .headingMediumStyle()
            
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
                VStack(spacing: 4) {
                    Text("Last Pickup")
                        .captionStyle()
                    Text(formatDate(lastPickup))
                        .bodySmallStyle()
                        .foregroundColor(.ForestGreen)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Day Selector
    private var daySelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Pickup Days")
                .headingMediumStyle()
            
            VStack(spacing: 12) {
                ForEach(WeekDay.allCases) { day in
                    DaySelectorRow(
                        day: day,
                        isSelected: selectedDays.contains(day),
                        color: binType.color,
                        onTap: {
                            if selectedDays.contains(day) {
                                selectedDays.remove(day)
                            } else {
                                selectedDays.insert(day)
                            }
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Notification Settings Section
    private var notificationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Settings")
                .headingMediumStyle()
            
            VStack(spacing: 16) {
                // Reminder time slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Remind me")
                            .bodyMediumStyle()
                        
                        Spacer()
                        
                        Text("\(Int(reminderHours)) hours before")
                            .font(.buttonMedium)
                            .foregroundColor(binType.color)
                    }
                    
                    Slider(value: $reminderHours, in: 1...24, step: 1)
                        .tint(binType.color)
                    
                    HStack {
                        Text("1 hour")
                            .captionStyle()
                        Spacer()
                        Text("24 hours")
                            .captionStyle()
                    }
                }
                .padding()
                .background(Color.BackgroundBeige.opacity(0.5))
                .cornerRadius(12)
                
                Text("You'll receive a notification \(Int(reminderHours)) hours before your bin collection day.")
                    .captionStyle()
                    .foregroundColor(.TextSecondary)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Test Notification Button
    private var testNotificationButton: some View {
        VStack(spacing: 12) {
            Button(action: {
                sendTestNotification()
            }) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 20))
                    
                    Text("Send Test Notification")
                        .font(.buttonMedium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(binType.color)
                .cornerRadius(12)
            }
            
            Text("📱 This unique feature tests if notifications are set up correctly.\nYou'll receive a notification within 15 seconds.\n\n💡 Press and hold (or swipe) the notification to see Yes/No action buttons!")
                .captionStyle()
                .foregroundColor(.TextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .alert("Test Notification Sent!", isPresented: $showingTestNotificationAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Check your notifications in 15 seconds!\n\nPress and hold (or swipe left) on the notification to reveal the Yes/No action buttons to confirm everything is working correctly!")
        }
    }
    
    private func saveDays() {
        viewModel.updatePickupDays(for: binType, days: Array(selectedDays))
        viewModel.updateReminderTime(hours: reminderHours)
        isPresented = false
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - StatBox Component
struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.TextPrimary)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.TextSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

//Day Selector Row
struct DaySelectorRow: View {
    let day: WeekDay
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(day.fullName)
                    .bodyMediumStyle()
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? color : .TextSecondary)
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//Preview
#Preview("Pickup Appointment") {
    PickupAppointmentView()
}

#Preview("Empty Schedule") {
    PickupAppointmentView(viewModel: PickupSchedulerVM.empty)
}

#Preview("Bin Schedule Card") {
    VStack(spacing: 16) {
        BinScheduleCard(
            binType: .red,
            schedule: BinSchedule(binType: .red, pickupDays: [.monday, .thursday]),
            onTap: {},
            onToggle: {}
        )
        
        BinScheduleCard(
            binType: .yellow,
            schedule: BinSchedule(binType: .yellow, pickupDays: []),
            onTap: {},
            onToggle: {}
        )
    }
    .padding()
    .background(Color.BackgroundBeige)
}

#Preview("Weekly Calendar") {
    WeeklyCalendarView(viewModel: PickupSchedulerVM.sample)
        .padding()
        .background(Color.BackgroundBeige)
}
