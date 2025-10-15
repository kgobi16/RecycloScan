//
//  NotificationCenterView.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 15/10/2025.
//

import SwiftUI

struct NotificationCenterView: View {
    @ObservedObject var viewModel: NotificationManagerVM
    @State private var selectedFilter: NotificationFilter = .active
    
    init(viewModel: NotificationManagerVM = NotificationManagerVM.sample) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.BackgroundBeige
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Tabs
                    filterTabs
                    
                    // Notifications List
                    ScrollView {
                        VStack(spacing: 16) {
                            if filteredNotifications.isEmpty {
                                emptyState
                            } else {
                                ForEach(filteredNotifications) { notification in
                                    NotificationCard(
                                        notification: notification,
                                        onYes: {
                                            viewModel.markAsCompleted(notification)
                                        },
                                        onNo: {
                                            viewModel.markAsMissed(notification)
                                        }
                                    )
                                }
                            }
                            
                            // Stats Card
                            if !viewModel.notifications.isEmpty {
                                statsCard
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.requestNotificationPermission()
                    }) {
                        Image(systemName: "bell.badge")
                            .foregroundColor(.ForestGreen)
                    }
                }
            }
        }
    }
    
    // MARK: - Filter Tabs
    private var filterTabs: some View {
        HStack(spacing: 0) {
            ForEach(NotificationFilter.allCases, id: \.self) { filter in
                Button(action: {
                    withAnimation {
                        selectedFilter = filter
                    }
                }) {
                    VStack(spacing: 4) {
                        Text(filter.title)
                            .font(.bodyMedium)
                            .foregroundColor(selectedFilter == filter ? .ForestGreen : .TextSecondary)
                        
                        if selectedFilter == filter {
                            Rectangle()
                                .fill(Color.ForestGreen)
                                .frame(height: 3)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.SurfaceWhite)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Filtered Notifications
    private var filteredNotifications: [NotificationItem] {
        switch selectedFilter {
        case .active:
            return viewModel.activeNotifications
        case .completed:
            return viewModel.completedNotifications
        case .missed:
            return viewModel.missedNotifications
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.emptyIcon)
                .font(.system(size: 60))
                .foregroundColor(.TextSecondary)
            
            Text(selectedFilter.emptyMessage)
                .bodyLargeStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Stats Card
    private var statsCard: some View {
        VStack(spacing: 16) {
            Text("Your Stats")
                .headingMediumStyle()
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Completion Rate",
                    value: "\(Int(viewModel.binReminderCompletionRate() * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .GrassGreen
                )
                
                Divider()
                    .frame(height: 50)
                
                StatItem(
                    title: "Completed",
                    value: "\(viewModel.totalCompletedReminders())",
                    icon: "checkmark.circle.fill",
                    color: .ForestGreen
                )
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Notification Filter
enum NotificationFilter: CaseIterable {
    case active
    case completed
    case missed
    
    var title: String {
        switch self {
        case .active: return "Active"
        case .completed: return "Completed"
        case .missed: return "Missed"
        }
    }
    
    var emptyIcon: String {
        switch self {
        case .active: return "bell.slash"
        case .completed: return "checkmark.circle"
        case .missed: return "xmark.circle"
        }
    }
    
    var emptyMessage: String {
        switch self {
        case .active: return "No active notifications.\nYou're all caught up!"
        case .completed: return "No completed notifications yet.\nStart responding to notifications!"
        case .missed: return "No missed notifications.\nGreat job staying on track!"
        }
    }
}

// MARK: - Notification Card
struct NotificationCard: View {
    let notification: NotificationItem
    let onYes: () -> Void
    let onNo: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: notification.type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                
                Text(notification.title)
                    .headingSmallStyle()
                
                Spacer()
                
                Text(notification.relativeTimeString)
                    .captionStyle()
            }
            
            // Message
            Text(notification.message)
                .bodyMediumStyle()
            
            // Bin Type Badge (if applicable)
            if let binType = notification.binType {
                HStack(spacing: 8) {
                    Circle()
                        .fill(binType.color)
                        .frame(width: 20, height: 20)
                    
                    Text(binType.displayName)
                        .bodySmallStyle()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(binType.color.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Action Buttons (only for pending)
            if notification.response == .pending {
                HStack(spacing: 12) {
                    Button(action: onNo) {
                        Label("No", systemImage: "xmark")
                            .font(.bodyMedium)
                            .foregroundColor(.TextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.BackgroundBeige)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onYes) {
                        Label("Yes", systemImage: "checkmark")
                            .font(.bodyMedium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.ForestGreen)
                            .cornerRadius(12)
                    }
                }
            } else {
                // Response Badge
                HStack {
                    Image(systemName: notification.response == .yes ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(notification.response == .yes ? .ForestGreen : .TextSecondary)
                    
                    Text(notification.response.displayText)
                        .bodySmallStyle()
                        .foregroundColor(notification.response == .yes ? .ForestGreen : .TextSecondary)
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var iconColor: Color {
        switch notification.type {
        case .binReminder:
            return notification.binType?.color ?? .ForestGreen
        case .weeklyTip:
            return .WarmOrange
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.displayMedium)
                .foregroundColor(.TextPrimary)
            
            Text(title)
                .captionStyle()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews
#Preview("Notification Center - Active") {
    NotificationCenterView()
}

#Preview("Notification Center - Empty") {
    NotificationCenterView(viewModel: NotificationManagerVM())
}

#Preview("Notification Card - Pending") {
    NotificationCard(
        notification: NotificationItem.sampleBinReminder,
        onYes: {},
        onNo: {}
    )
    .padding()
    .background(Color.BackgroundBeige)
}

#Preview("Notification Card - Weekly Tip") {
    NotificationCard(
        notification: NotificationItem.sampleWeeklyTip,
        onYes: {},
        onNo: {}
    )
    .padding()
    .background(Color.BackgroundBeige)
}

#Preview("Stats Card") {
    VStack(spacing: 16) {
        Text("Your Stats")
            .headingMediumStyle()
        
        HStack(spacing: 20) {
            StatItem(
                title: "Completion Rate",
                value: "87%",
                icon: "chart.line.uptrend.xyaxis",
                color: .GrassGreen
            )
            
            Divider()
                .frame(height: 50)
            
            StatItem(
                title: "Completed",
                value: "24",
                icon: "checkmark.circle.fill",
                color: .ForestGreen
            )
        }
    }
    .padding()
    .background(Color.SurfaceWhite)
    .cornerRadius(16)
    .padding()
    .background(Color.BackgroundBeige)
}
