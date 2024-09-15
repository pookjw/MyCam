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

struct MyCaptureExtension_SwiftViewFinder: UIViewControllerRepresentable {
    let session: LockedCameraCaptureSession
    var sourceType: UIImagePickerController.SourceType = .camera

    init(session: LockedCameraCaptureSession) {
        self.session = session
    }
 
    func makeUIViewController(context: Self.Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.mediaTypes = [UTType.image.identifier, UTType.movie.identifier]
        imagePicker.cameraDevice = .rear
 
        return imagePicker
    }
 
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Self.Context) {
    }
}
