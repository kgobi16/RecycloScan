//
//  PendingCollectionView.swift
//  RecycloScan
//
//  Created by Yu on 10/14/25.
//

//  Shows items waiting for pickup


import SwiftUI

struct PendingCollectionView: View {
    @ObservedObject var manager: RecyclingManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Header
                VStack(spacing: 8) {
                    Text("Pending Collection")
                        .displayMediumStyle()
                    
                    Text("\(manager.getPendingItemCount()) items waiting")
                        .bodyMediumStyle()
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // Potential Points Card
                if !manager.pendingItems.isEmpty {
                    potentialPointsCard
                }
                
                // Pending Items List
                if manager.pendingItems.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
            .padding()
        }
        .background(Color.BackgroundBeige.ignoresSafeArea())
    }
    
    // MARK: - Potential Points Card
    
    private var potentialPointsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Potential Points")
                        .headingSmallStyle()
                    
                    Text("Schedule pickup to earn")
                        .bodySmallStyle()
                }
                
                Spacer()
                
                Text("\(manager.getPotentialPoints())")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.ForestGreen)
            }
            
            // Category Breakdown
            categoryBreakdown
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var categoryBreakdown: some View {
        let breakdown = manager.getPendingItemsByType()
        let sortedBreakdown = breakdown.sorted { $0.value > $1.value }
        
        return VStack(alignment: .leading, spacing: 8) {
            ForEach(sortedBreakdown, id: \.key) { type, count in
                HStack(spacing: 8) {
                    Text(type.icon)
                        .font(.system(size: 16))
                    
                    Text(type.displayName)
                        .bodySmallStyle()
                    
                    Spacer()
                    
                    Text("\(count) × \(type.pointValue)")
                        .captionStyle()
                        .foregroundColor(type.color)
                    
                    Text("= \(count * type.pointValue)")
                        .font(.buttonMedium)
                        .foregroundColor(.ForestGreen)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Items List
    
    private var itemsList: some View {
        VStack(spacing: 12) {
            ForEach(manager.pendingItems) { item in
                ItemCard(item: item, onRemove: {
                    withAnimation {
                        manager.removePendingItem(item)
                    }
                })
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🌱")
                .font(.system(size: 64))
            
            Text("No Items Yet")
                .headingMediumStyle()
            
            Text("Scan items to add them to your collection")
                .bodyMediumStyle()
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Item Card Component

struct ItemCard: View {
    let item: RecyclableItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(item.type.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Text(item.type.icon)
                    .font(.system(size: 24))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type.displayName)
                    .headingSmallStyle()
                
                Text(item.relativeDate)
                    .captionStyle()
            }
            
            Spacer()
            
            // Points
            VStack(alignment: .trailing, spacing: 4) {
                Text("+\(item.type.pointValue)")
                    .font(.buttonMedium)
                    .foregroundColor(.GrassGreen)
                
                Text("points")
                    .captionSmallStyle()
            }
            
            // Remove Button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.TextSecondary)
            }
        }
        .padding()
        .background(Color.SurfaceWhite)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

struct PendingCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = RecyclingManager()
        manager.addScannedItem(type: .plastic)
        manager.addScannedItem(type: .paper)
        manager.addScannedItem(type: .metal)
        
        return PendingCollectionView(manager: manager)
    }
}
