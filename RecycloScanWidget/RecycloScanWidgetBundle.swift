//
//  RecycloScanWidgetBundle.swift
//  RecycloScanWidget
//
//  Created by Yu on 10/21/25.
//

import WidgetKit
import SwiftUI

@main
struct RecycloScanWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecycloScanWidget()
        RecycloScanWidgetControl()
        RecycloScanWidgetLiveActivity()
    }
}
