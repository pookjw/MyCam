//
//  MyCaptureExtension_SwiftViewFinder.swift
//  MyCaptureExtension-Swift
//
//  Created by Jinwoo Kim on 9/15/24.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import LockedCameraCapture
import CamPresentation

struct MyCaptureExtension_SwiftViewFinder: UIViewControllerRepresentable {
    let session: LockedCameraCaptureSession

    init(session: LockedCameraCaptureSession) {
        self.session = session
    }
 
    func makeUIViewController(context: Self.Context) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: CameraRootViewController())
        
        navigationController.setToolbarHidden(false, animated: false)
        let toolbar = navigationController.toolbar!
        
        let toolbarAppearance = UIToolbarAppearance()
        toolbarAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterialDark)
        
        toolbar.compactAppearance = toolbarAppearance
        toolbar.standardAppearance = toolbarAppearance
        toolbar.scrollEdgeAppearance = toolbarAppearance
        
        return navigationController
    }
 
    func updateUIViewController(_ uiViewController: UINavigationController, context: Self.Context) {
    }
}
