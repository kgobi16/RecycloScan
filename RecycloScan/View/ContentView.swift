//
//  ContentView.swift
//  RecycloScan
//
//  Created by Tlaitirang Rathete on 9/10/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var recyclingManager = RecyclingManager()
    @StateObject private var pickupScheduler = PickupSchedulerVM.sample
    @StateObject private var notificationManager = NotificationManagerVM.sample
    @State private var selectedTab = 0
    
    init() {
        // Set up the connection between managers
        // This allows Kobi's scheduler to trigger your points system
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(
                recyclingManager: recyclingManager,
                pickupScheduler: pickupScheduler,
                notificationManager: notificationManager
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Scan Tab
            WasteScannerView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Collection Tab (Yu's pending items)
            PendingCollectionView(manager: recyclingManager)
                .tabItem {
                    Label("Collection", systemImage: "tray.fill")
                }
                .tag(2)
            
            // Points Tab (Yu's points & stats)
            PointsStatsView(manager: recyclingManager)
                .tabItem {
                    Label("Points", systemImage: "star.fill")
                }
                .tag(3)
            
            // Schedule Tab (Kobi's)
            PickupAppointmentView(viewModel: pickupScheduler)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(4)
            
            // Notifications Tab
            NotificationCenterView(viewModel: notificationManager)
                .tabItem {
                    Label("Alerts", systemImage: "bell.fill")
                }
                .tag(5)
        }
        .accentColor(.ForestGreen)
        .onAppear {
            // Connect the managers after views are loaded
            pickupScheduler.setRecyclingManager(recyclingManager)
        }
    }
}

// Home View (updated with points info)
struct HomeView: View {
    @ObservedObject var recyclingManager: RecyclingManager
    @ObservedObject var pickupScheduler: PickupSchedulerVM
    @ObservedObject var notificationManager: NotificationManagerVM
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with gradient
                LinearGradient(
                    colors: [Color.GrassGreen.opacity(0.1), Color.BackgroundBeige],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Section
                        heroSection
                        
                        // Quick Stats (Updated to include points)
                        quickStatsSection
                        
                        // Pending Items Card (if any)
                        if recyclingManager.getPendingItemCount() > 0 {
                            pendingItemsCard
                        }
                        
                        // Today's Pickups
                        if pickupScheduler.hasPickupToday() {
                            todayPickupsCard
                        }
                        
                        // Next Pickup
                        if let nextPickup = pickupScheduler.getNextPickup() {
                            nextPickupCard(binType: nextPickup.binType, date: nextPickup.date)
                        }
                        
                        // Active Notifications
                        if !notificationManager.activeNotifications.isEmpty {
                            activeNotificationsSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("RecycloScan")
                            .font(.headingLarge)
                            .foregroundColor(.ForestGreen)
                    }
                }
            }
        }
    }
    
    // Hero Section
    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.GrassGreen)
            
            Text("Smart Sorting Made Simple")
                .bodyLargeStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // Quick Stats Section (Updated with points)
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Your Points",
                    value: "\(recyclingManager.totalPoints)",
                    icon: "star.fill",
                    color: .ForestGreen
                )
                
                StatCard(
                    title: "Pending Items",
                    value: "\(recyclingManager.getPendingItemCount())",
                    icon: "tray.fill",
                    color: .GrassGreen
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Scheduled Bins",
                    value: "\(pickupScheduler.enabledBinCount())",
                    icon: "trash.circle.fill",
                    color: .PlasticBlue
                )
                
                StatCard(
                    title: "Active Alerts",
                    value: "\(notificationManager.activeNotifications.count)",
                    icon: "bell.circle.fill",
                    color: .WarmOrange
                )
            }
        }
    }
    
    // Pending Items Card
    private var pendingItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.GrassGreen)
                
                Text("Items Ready to Recycle")
                    .headingMediumStyle()
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(recyclingManager.getPendingItemCount()) items")
                        .font(.displayMedium)
                        .foregroundColor(.TextPrimary)
                    
                    Text("Potential: \(recyclingManager.getPotentialPoints()) points")
                        .bodySmallStyle()
                        .foregroundColor(.GrassGreen)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.TextSecondary)
            }
            
            Text("Schedule a pickup to earn your points!")
                .captionStyle()
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // Today's Pickups Card
    private var todayPickupsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 24))
                    .foregroundColor(.WarmOrange)
                
                Text("Collection Today!")
                    .headingMediumStyle()
                
                Spacer()
            }
            
            Text("Don't forget to put out these bins:")
                .bodyMediumStyle()
            
            VStack(spacing: 8) {
                ForEach(pickupScheduler.getTodayPickups(), id: \.self) { binType in
                    HStack {
                        Circle()
                            .fill(binType.color)
                            .frame(width: 12, height: 12)
                        
                        Text(binType.displayName)
                            .bodyLargeStyle()
                        
                        Spacer()
                        
                        Image(systemName: binType.icon)
                            .foregroundColor(binType.color)
                    }
                    .padding()
                    .background(binType.color.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // Next Pickup Card
    private func nextPickupCard(binType: BinType, date: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.ForestGreen)
                
                Text("Next Pickup")
                    .headingMediumStyle()
                
                Spacer()
            }
            
            HStack(spacing: 12) {
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
                        .headingSmallStyle()
                    
                    Text(formatDate(date))
                        .bodySmallStyle()
                        .foregroundColor(.TextSecondary)
                }
                
                Spacer()
                
                Text(daysUntil(date))
                    .font(.displayMedium)
                    .foregroundColor(.ForestGreen)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // Active Notifications Section
    private var activeNotificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Alerts")
                    .headingMediumStyle()
                
                Spacer()
                
                Text("\(notificationManager.activeNotifications.count)")
                    .bodySmallStyle()
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.WarmOrange.opacity(0.2))
                    .foregroundColor(.WarmOrange)
                    .cornerRadius(12)
            }
            
            VStack(spacing: 8) {
                ForEach(notificationManager.activeNotifications.prefix(3)) { notification in
                    CompactNotificationRow(notification: notification)
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Schedule",
                    icon: "calendar.badge.plus",
                    color: .ForestGreen
                ) {
                    // Navigate to schedule tab
                }
                
                QuickActionButton(
                    title: "Scan Item",
                    icon: "camera.fill",
                    color: .GrassGreen
                ) {
                    // Navigate to scan tab
                }
            }
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Collection",
                    icon: "tray.fill",
                    color: .PlasticBlue
                ) {
                    // Navigate to collection tab
                }
                
                QuickActionButton(
                    title: "Points",
                    icon: "star.fill",
                    color: .organicOrange
                ) {
                    // Navigate to points tab
                }
            }
        }
    }
    
    // Helpers
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func daysUntil(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
}

// Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.displayMedium)
                .foregroundColor(.TextPrimary)
            
            Text(title)
                .captionStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Compact Notification Row
struct CompactNotificationRow: View {
    let notification: NotificationItem
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .bodyMediumStyle()
                    .lineLimit(1)
                
                Text(notification.relativeTimeString)
                    .captionSmallStyle()
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.TextSecondary)
        }
        .padding(.vertical, 8)
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

// Quick Action Button
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.bodySmall)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(16)
        }
    }
}

// Scan Placeholder View (Ariel will replace this)
struct ScanPlaceholderView: View {
    var body: some View {
        ZStack {
            Color.BackgroundBeige
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.GrassGreen)
                
                Text("Scanner Coming Soon")
                    .displayMediumStyle()
                
                Text("This is where Ariel's scanner will go")
                    .bodyMediumStyle()
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// Previews
#Preview("Content View") {
    ContentView()
}

#Preview("Home View") {
    HomeView(
        recyclingManager: RecyclingManager.sample,
        pickupScheduler: PickupSchedulerVM.sample,
        notificationManager: NotificationManagerVM.sample
    )
}

#Preview("Stat Card") {
    StatCard(
        title: "Your Points",
        value: "150",
        icon: "star.fill",
        color: .ForestGreen
    )
    .padding()
    .background(Color.BackgroundBeige)
}

#Preview("Quick Actions") {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Schedule",
                icon: "calendar.badge.plus",
                color: .ForestGreen
            ) {}
            
            QuickActionButton(
                title: "Scan Item",
                icon: "camera.fill",
                color: .GrassGreen
            ) {}
        }
    }
    .padding()
    .background(Color.BackgroundBeige)
}
