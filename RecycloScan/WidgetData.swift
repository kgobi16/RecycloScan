//
//  WidgetData.swift
//  RecycloScan
//
//  Created by Yu on 10/21/25.
//

//  Shared data structure for widget

import Foundation

struct WidgetData: Codable {
    let pointsThisWeek: Int
    let nextPickupDate: Date?
    let nextPickupBinType: String?
    let lastUpdated: Date
    
    static func save(_ data: WidgetData) {
        let defaults = UserDefaults(suiteName: "group.com.yourteam.recycloscan")
        if let encoded = try? JSONEncoder().encode(data) {
            defaults?.set(encoded, forKey: "widgetData")
        }
    }
    
    static func load() -> WidgetData? {
        let defaults = UserDefaults(suiteName: "group.com.yourteam.recycloscan")
        guard let data = defaults?.data(forKey: "widgetData"),
              let decoded = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return nil
        }
        return decoded
    }
}
