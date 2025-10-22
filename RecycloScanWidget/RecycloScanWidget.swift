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
        var entries: [WidgetEntry] = []
        let currentDate = Date()
        
        // Load data from shared UserDefaults
        let widgetData = WidgetData.load()
        
        // Create entries for the next 24 hours (updating every 15 minutes)
        for hourOffset in 0..<96 { // 96 = 24 hours * 4 (15-minute intervals)
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset * 15, to: currentDate)!
            
            let entry = WidgetEntry(
                date: entryDate,
                pointsThisWeek: widgetData?.pointsThisWeek ?? 0,
                nextPickupDate: widgetData?.nextPickupDate,
                nextPickupBinType: widgetData?.nextPickupBinType
            )
            entries.append(entry)
        }
        
        // Update more frequently - every 15 minutes, but allow reload on change
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Widget View
struct RecycloScanWidgetView: View {
    let entry: WidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        VStack(spacing: 6) {
            // Compact Header
            HStack {
                Image(systemName: "leaf.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                
                Text("RecycloScan")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
            }
            
            Spacer()
            
            // Points This Week - Main Focus
            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    Text("\(entry.pointsThisWeek)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Text("Points this week")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.1))
            )
            
            Spacer()
            
            // Next Pickup - Compact Info
            HStack(spacing: 6) {
                if let nextDate = entry.nextPickupDate,
                   let binType = entry.nextPickupBinType {
                    // Bin color indicator
                    Circle()
                        .fill(binColor(for: binType))
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(formatDate(nextDate))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text(simplifiedBinName(binType))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                } else {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("No pickup")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.06))
            )
        }
        .padding(8)
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.92), for: .widget)
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: WidgetEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // Left Side - Points
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    
                    Text("RecycloScan")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Spacer()
                }
                
                VStack(spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text("\(entry.pointsThisWeek)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Text("Points this week")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                )
                
                Spacer()
            }
            
            // Right Side - Next Pickup & Additional Info
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Pickup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let nextDate = entry.nextPickupDate,
                       let binType = entry.nextPickupBinType {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(binColor(for: binType))
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(formatDate(nextDate))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                
                                Text(simplifiedBinName(binType))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                            
                            Spacer()
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("No pickup")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.06))
                )
                
                // Compact quick stats
                HStack(spacing: 4) {
                    VStack(spacing: 1) {
                        Text("♻️")
                            .font(.caption)
                        Text("Recycle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    VStack(spacing: 1) {
                        Text("🌱")
                            .font(.caption)
                        Text("Earn")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    
                    VStack(spacing: 1) {
                        Text("🏆")
                            .font(.caption)
                        Text("Win")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
        }
        .padding(12)
        .containerBackground(Color(red: 0.98, green: 0.97, blue: 0.92), for: .widget)
    }
}

// MARK: - Helper Functions

private func binColor(for binType: String) -> Color {
    switch binType.lowercased() {
    case "red bin":
        return .red
    case "yellow bin":
        return .yellow
    case "blue bin":
        return .blue
    case "green bin":
        return .green
    default:
        return .gray
    }
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

private func simplifiedBinName(_ binType: String) -> String {
    switch binType.lowercased() {
    case "red bin":
        return "Red"
    case "yellow bin":
        return "Yellow"
    case "blue bin":
        return "Blue"
    case "green bin":
        return "Green"
    default:
        return binType.replacingOccurrences(of: " Bin", with: "")
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
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    RecycloScanWidget()
} timeline: {
    WidgetEntry(date: Date(), pointsThisWeek: 125, nextPickupDate: Date(), nextPickupBinType: "Red Bin")
}
