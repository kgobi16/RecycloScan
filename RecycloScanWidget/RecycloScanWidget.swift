//
//  RecycloScanWidget.swift
//  RecycloScanWidget
//
//  Created by Yu on 10/21/25.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct WidgetEntry: TimelineEntry {
    let date: Date
    let pointsThisWeek: Int
    let nextPickupDate: Date?
    let nextPickupBinType: String?
}

// MARK: - Widget Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(
            date: Date(),
            pointsThisWeek: 125,
            nextPickupDate: Date(),
            nextPickupBinType: "Red Bin"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> Void) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetEntry>) -> Void) {
        // Load data from shared UserDefaults
        let widgetData = WidgetData.load()
        
        let entry = WidgetEntry(
            date: Date(),
            pointsThisWeek: widgetData?.pointsThisWeek ?? 0,
            nextPickupDate: widgetData?.nextPickupDate,
            nextPickupBinType: widgetData?.nextPickupBinType
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

// MARK: - Widget View
struct RecycloScanWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Points This Week
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                    
                    Text("+\(entry.pointsThisWeek)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)  // Shrinks if too long
                }
                
                Text("Points this week")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .padding(.horizontal, 20)
            
            // Next Pickup
            if let nextDate = entry.nextPickupDate,
               let binType = entry.nextPickupBinType {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(nextDate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    Text(binType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 4) {
                    Text("No pickup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text("scheduled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .containerBackground(Color(red: 0.96, green: 0.96, blue: 0.86), for: .widget)
    }
    
    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Widget Configuration
struct RecycloScanWidget: Widget {
    let kind: String = "RecycloScanWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RecycloScanWidgetView(entry: entry)
        }
        .configurationDisplayName("RecycloScan")
        .description("Track your weekly points and next pickup")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    RecycloScanWidget()
} timeline: {
    WidgetEntry(date: Date(), pointsThisWeek: 125, nextPickupDate: Date(), nextPickupBinType: "Red Bin")
}
