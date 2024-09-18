//
//  MyCaptureExtension_Swift.swift
//  MyCaptureExtension-Swift
//
//  Created by Jinwoo Kim on 9/15/24.
//

import Foundation
import LockedCameraCapture
import SwiftUI

@main
struct MyCaptureExtension_Swift: LockedCameraCaptureExtension {
    var body: some LockedCameraCaptureExtensionScene {
        LockedCameraCaptureUIScene { session in
            MyCaptureExtension_SwiftViewFinder(session: session)
                .ignoresSafeArea()
        }
    }
}
