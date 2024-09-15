//
//  MyCamCaptureIntent.swift
//  MyWidgetExtension
//
//  Created by Jinwoo Kim on 9/16/24.
//

import AppIntents

struct MyCamCaptureIntent: CameraCaptureIntent {
    struct MyAppContext: Codable {
    }
    
    typealias AppContext = MyAppContext
    
    static let title: LocalizedStringResource = "MyCamCaptureInput"
    static let description = IntentDescription("Capture photos with MyApp.")
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
