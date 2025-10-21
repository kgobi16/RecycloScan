//
//  RecycloScanWidgetLiveActivity.swift
//  RecycloScanWidget
//
//  Created by Yu on 10/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RecycloScanWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RecycloScanWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecycloScanWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RecycloScanWidgetAttributes {
    fileprivate static var preview: RecycloScanWidgetAttributes {
        RecycloScanWidgetAttributes(name: "World")
    }
}

extension RecycloScanWidgetAttributes.ContentState {
    fileprivate static var smiley: RecycloScanWidgetAttributes.ContentState {
        RecycloScanWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RecycloScanWidgetAttributes.ContentState {
         RecycloScanWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RecycloScanWidgetAttributes.preview) {
   RecycloScanWidgetLiveActivity()
} contentStates: {
    RecycloScanWidgetAttributes.ContentState.smiley
    RecycloScanWidgetAttributes.ContentState.starEyes
}
