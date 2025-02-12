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
    private var pxgView: PXGView!
    private let hostingController: UIHostingController<OneUpView>
    private var viewModel: PXCuratedLibraryViewModel!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        let manager = OneUpManager()
        let hostingController = UIHostingController<OneUpView>(rootView: OneUpView(oneUpManager: manager))
        
        self.manager = manager
        self.hostingController = hostingController
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        manager.gridSize = CGSize(width: 300, height: 300)
        manager.delegate = self
        
        let configuration = PXCuratedLibraryAssetsDataSourceManagerConfiguration(photoLibrary: .shared(), enableDays: true)
        let _manager = PXCuratedLibraryAssetsDataSourceManager(configuration: configuration)
        
        let viewModel = PXCuratedLibraryViewModel(
            configuration: PXCuratedLibraryViewConfiguration(photoLibrary: .shared()),
            assetsDataSourceManagerConfiguration: _PXPhotoLibraryCuratedLibraryAssetsDataSourceManagerConfiguration(photoLibrary: .shared()),
            zoomLevel: 4,
            mediaProvider: PXPhotoKitUIMediaProvider(),
            specManager: PXCuratedLibraryLayoutSpecManager(),
            styleGuide: PXCuratedLibraryStyleGuide(extendedTraitCollection: PXExtendedTraitCollection(viewController: self))
        )
        
        let presenter = PXCuratedLibraryLayout(viewModel: viewModel)
        viewModel.addPresenter(presenter)
        
        let pxgView = PXGView(frame: view.bounds)
        pxgView.rootLayout = presenter
        view.addSubview(pxgView)
        pxgView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.pxgView = pxgView
        
        viewModel.addView(pxgView)
        
        _manager.delegate = viewModel
        self.viewModel = viewModel
        
        manager.showOneUp(for: _manager, atIndexPath: PXSimpleIndexPathNull, showHeaderBadges: true, immersionState: .none, alwaysPromptSharePlayPermissions: true, isInvokedViaSharePlayIntent: true)
    }
}

extension MyOneUpViewController: OneUpManagerDelegate {
    var windowScene: UIWindowScene? {
        guard let windowScene = view.window?.windowScene else {
            fatalError()
        }
        
        return windowScene
    }
}
