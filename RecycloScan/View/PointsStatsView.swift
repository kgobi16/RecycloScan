//
//  PointsStatsView.swift
//  RecycloScan
//
//  Created by Yu on 10/14/25.
//

//  Kate's part
//  Shows total points and recycling statistics


import SwiftUI

struct PointsStatsView: View {
    @ObservedObject var manager: RecyclingManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Total Points Header
                    totalPointsHeader
                    
                    // Quick Stats Grid
                    quickStatsGrid
                    
                    // Category Breakdown
                    categoryBreakdownSection
                    
                    // Recent Pickups
                    if !manager.pickupHistory.isEmpty {
                        recentPickupsSection
                    }
                    
                }
                .padding()
            }
            .background(Color.BackgroundBeige.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Your Points")
                        .font(.headingLarge)
                        .foregroundColor(.ForestGreen)
                }
            }
        }
    }
    
    // MARK: - Total Points Header
    
    private var totalPointsHeader: some View {
        VStack(spacing: 12) {
            Text("Total Points")
                .headingMediumStyle()
                .foregroundColor(.SurfaceWhite)
            
            Text("\(manager.totalPoints)")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.SurfaceWhite)
            
            Text("Keep recycling to earn more!")
                .foregroundColor(.SurfaceWhite.opacity(0.9))
                .bodyMediumStyle()
                
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.heroGradient)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.SurfaceWhite.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Stats Grid
    
    private var quickStatsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                PointsStatCard(
                    title: "Items Recycled",
                    value: "\(manager.getTotalItemsRecycled())",
                    icon: "arrow.3.trianglepath",
                    color: .GrassGreen
                )
                
                PointsStatCard(
                    title: "Total Pickups",
                    value: "\(manager.getTotalPickups())",
                    icon: "truck.box.fill",
                    color: .WarmOrange
                )
            }
            
            HStack(spacing: 12) {
                PointsStatCard(
                    title: "Pending Items",
                    value: "\(manager.getPendingItemCount())",
                    icon: "clock.fill",
                    color: .PlasticBlue
                )
                
                PointsStatCard(
                    title: "This Month",
                    value: "\(manager.getPointsThisMonth())",
                    icon: "star.fill",
                    color: .OrganicOrange
                )
            }
        }
    }
    
    // MARK: - Category Breakdown
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recycling Breakdown")
                .headingMediumStyle()
                .padding(.horizontal, 4)
            
            let breakdown = manager.getAllRecycledItemsByType()
            let sortedBreakdown = breakdown.sorted { $0.value > $1.value }
            
            if sortedBreakdown.isEmpty {
                emptyBreakdown
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedBreakdown, id: \.key) { type, count in
                        CategoryRow(type: type, count: count)
                    }
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var emptyBreakdown: some View {
        VStack(spacing: 8) {
            Text("🌍")
                .font(.system(size: 48))
            
            Text("Start recycling to see your impact")
                .bodySmallStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Recent Pickups
    
    private var recentPickupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Pickups")
                .headingMediumStyle()
                .padding(.horizontal, 4)
            
            let recentPickups = Array(manager.pickupHistory.suffix(5).reversed())
            
            VStack(spacing: 12) {
                ForEach(recentPickups) { pickup in
                    PickupHistoryCard(pickup: pickup)
                }
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Points Stat Card Component (renamed to avoid conflict with ContentView's StatCard)

struct PointsStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.TextPrimary)
            
            Text(title)
                .captionStyle()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Category Row Component

struct CategoryRow: View {
    let type: RecyclableType
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(type.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(type.icon)
                    .font(.system(size: 20))
            }
            
            // Type name
            Text(type.displayName)
                .headingSmallStyle()
            
            Spacer()
            
            // Count
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.TextPrimary)
                
                Text("items")
                    .captionSmallStyle()
            }
            
            // Points
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count * type.pointValue)")
                    .font(.buttonMedium)
                    .foregroundColor(.GrassGreen)
                
                Text("pts")
                    .captionSmallStyle()
            }
            .frame(width: 60)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Pickup History Card

struct PickupHistoryCard: View {
    let pickup: PickupEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.GrassGreen)
                
                Text(pickup.formattedDate)
                    .bodySmallStyle()
                
                Spacer()
                
                Text("+\(pickup.pointsAwarded)")
                    .font(.buttonMedium)
                    .foregroundColor(.ForestGreen)
            }
            
            Text("\(pickup.itemCount) items collected")
                .captionStyle()
        }
        .padding()
        .background(Color.BackgroundBeige)
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct PointsStatsView_Previews: PreviewProvider {
    static var previews: some View {
        PointsStatsView(manager: RecyclingManager.sample)
    }
}
