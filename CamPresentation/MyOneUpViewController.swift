//
//  MyOneUpViewController.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 2/11/25.
//

import UIKit
import SwiftUI
import PhotosUIFoundation
import PhotosUICore
import PhotosXRUI
import Photos

@objc(MyOneUpViewController)
final class MyOneUpViewController: UIViewController {
    private let manager: OneUpManager
    private let hostingController: UIHostingController<OneUpView>
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let manager = OneUpManager()
        let hostingController = UIHostingController<OneUpView>(rootView: OneUpView(oneUpManager: manager))
        
        self.manager = manager
        self.hostingController = hostingController
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSpatial, options: nil)
        let _manager = PXPhotoKitAssetsDataSourceManager.init(for: collections.firstObject!)
        print(_manager)
        print(_manager.dataSource)
        manager.showOneUp(for: _manager, atIndexPath: PXSimpleIndexPathNull, showHeaderBadges: true, immersionState: .none, alwaysPromptSharePlayPermissions: true, isInvokedViaSharePlayIntent: true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
//        hostingController.view.frame = view.bounds
//        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostingController.didMove(toParent: self)
        
        print(manager.oneUpContext)
        manager.delegate = self
    }
}

extension MyOneUpViewController: OneUpManagerDelegate {
    var windowScene: UIWindowScene? {
        view.window?.windowScene
    }
}
