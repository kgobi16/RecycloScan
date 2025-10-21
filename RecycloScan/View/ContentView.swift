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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView(
                recyclingManager: recyclingManager,
                pickupScheduler: pickupScheduler,
                notificationManager: notificationManager,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Scan Tab (Ariel's)
            //ScanPlaceholderView()
            WasteScannerView(recyclingManager: recyclingManager)
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .tag(1)
            
            // Schedule Tab (Kobi's)
            PickupAppointmentView(viewModel: pickupScheduler)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
            
            // Points Tab (Yu's)
            PointsStatsView(manager: recyclingManager)
                .tabItem {
                    Label("Points", systemImage: "star.fill")
                }
                .tag(3)
        }
        .accentColor(.ForestGreen)
        .onAppear {
            // Connect the managers after views are loaded
            pickupScheduler.setRecyclingManager(recyclingManager)
            
            // Update widget data
            let nextPickup = pickupScheduler.getNextPickup()
            recyclingManager.updateWidgetData(nextPickup: nextPickup)
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @ObservedObject var recyclingManager: RecyclingManager
    @ObservedObject var pickupScheduler: PickupSchedulerVM
    @ObservedObject var notificationManager: NotificationManagerVM
    @State private var showingNotifications = false
    @Binding var selectedTab: Int
    
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
                        
                        // Quick Stats
                        quickStatsSection
                        
                        // Pending Items Card (if any)
                        if recyclingManager.getPendingItemCount() > 0 {
                            pendingCollectionCard
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
                            activeAlertsCard
                        }
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
            .sheet(isPresented: $showingNotifications) {
                NotificationCenterView(viewModel: notificationManager)
            }
        }
    }
    
    // MARK: - Hero Section
    
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
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    selectedTab = 3  // Navigate to Points tab
                }) {
                    StatCard(
                        title: "Your Points",
                        value: "\(recyclingManager.totalPoints)",
                        icon: "star.fill",
                        color: .ForestGreen
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Pending Items - non-clickable (already shown below)
                StatCard(
                    title: "Pending Items",
                    value: "\(recyclingManager.getPendingItemCount())",
                    icon: "tray.fill",
                    color: .GrassGreen
                )
            }
            
            HStack(spacing: 12) {
                // Next Pickup - non-clickable (just info display)
                StatCard(
                    title: "Next Pickup",
                    value: nextPickupDays(),
                    icon: "calendar",
                    color: .PlasticBlue
                )
                
                Button(action: {
                    showingNotifications = true  // Show notifications sheet
                }) {
                    StatCard(
                        title: "Active Alerts",
                        value: "\(notificationManager.activeNotifications.count)",
                        icon: "bell.fill",
                        color: .WarmOrange
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func nextPickupDays() -> String {
        guard let nextPickup = pickupScheduler.getNextPickup() else {
            return "None"
        }
        
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextPickup.date).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1d"
        } else {
            return "\(days)d"
        }
    }
    
    // MARK: - Pending Collection Card (Quick Action)
    
    private var pendingCollectionCard: some View {
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
            }
            
            // Show breakdown if there are items
            if recyclingManager.getPendingItemCount() > 0 {
                Divider()
                    .padding(.vertical, 4)
                
                let breakdown = recyclingManager.getPendingItemsByType()
                let sortedBreakdown = breakdown.sorted { $0.value > $1.value }.prefix(3)
                
                VStack(spacing: 8) {
                    ForEach(Array(sortedBreakdown), id: \.key) { type, count in
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundColor(type.color)
                            
                            Text(type.displayName)
                                .bodySmallStyle()
                            
                            Spacer()
                            
                            Text("\(count) items")
                                .captionStyle()
                        }
                    }
                }
            }
            
            Text("💡 Schedule a pickup to earn your points!")
                .captionStyle()
                .padding(.top, 4)
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Today's Pickups Card
    
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
    
    // MARK: - Next Pickup Card
    
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
    
    // MARK: - Active Alerts Card (Quick Action)
    
    private var activeAlertsCard: some View {
        Button(action: {
            showingNotifications = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.WarmOrange)
                    
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
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.TextSecondary)
                }
                
                VStack(spacing: 8) {
                    ForEach(notificationManager.activeNotifications.prefix(3)) { notification in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(notificationColor(for: notification))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(notification.title)
                                    .bodyMediumStyle()
                                    .lineLimit(1)
                                
                                Text(notification.relativeTimeString)
                                    .captionSmallStyle()
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                if notificationManager.activeNotifications.count > 3 {
                    Text("Tap to see all \(notificationManager.activeNotifications.count) alerts")
                        .captionStyle()
                        .foregroundColor(.ForestGreen)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(Color.SurfaceWhite)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func notificationColor(for notification: NotificationItem) -> Color {
        switch notification.type {
        case .binReminder:
            return notification.binType?.color ?? .ForestGreen
        case .weeklyTip:
            return .WarmOrange
        }
    }
    
    // MARK: - Helpers
    
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

// MARK: - Supporting Views

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

// Ariel's Scanner Placeholder (will be replaced by actual WasteScannerView)
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
                
                Text("Ariel's AI scanner will go here")
                    .bodyMediumStyle()
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Previews

#Preview("Content View") {
    ContentView()
}

#Preview("Home View") {
    HomeView(
        recyclingManager: RecyclingManager.sample,
        pickupScheduler: PickupSchedulerVM.sample,
        notificationManager: NotificationManagerVM.sample,
        selectedTab: .constant(0)
    )
}
