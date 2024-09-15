//
//  MyWidgetControl.swift
//  MyWidget
//
//  Created by Jinwoo Kim on 9/15/24.
//

import AppIntents
import SwiftUI
import WidgetKit

struct MyWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.pookjw.MyCam.MyWidget.Control"
        ) {
            ControlWidgetButton(action: MyCamCaptureIntent()) {
                Label("Camera", systemImage: "camera.metering.center.weighted")
            }
        }
        .displayName("Camera")
        .description("A an example control that runs a camera.")
    }
}
