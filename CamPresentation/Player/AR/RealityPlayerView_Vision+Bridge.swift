//
//  RealityPlayerView_Vision+Bridge.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#if os(visionOS)

import UIKit
import SwiftUI
@preconcurrency import AVFoundation

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingControllerFromPlayer_Vision(
    avPlayer: AVPlayer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView = RealityPlayerView_Vision(avPlayer: avPlayer)
        let hostingController = UIHostingController<RealityPlayerView_Vision>(rootView: rootView)
        return hostingController
    }
}

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingControllerFromVideoRenderer_Vision(
    videoRenderer: AVSampleBufferVideoRenderer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView = RealityPlayerView_Vision(videoRenderer: videoRenderer)
        let hostingController = UIHostingController<RealityPlayerView_Vision>(rootView: rootView)
        return hostingController
    }
}

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingController_Vision() -> UIViewController {
    MainActor.assumeIsolated {
        let rootView = RealityPlayerView_Vision()
        let hostingController = UIHostingController<RealityPlayerView_Vision>(rootView: rootView)
        return hostingController
    }
}

@_expose(Cxx)
public nonisolated func avPlayerFromRealityPlayerHostingController_Vision(_ realityPlayerHostingController: UIViewController) -> AVPlayer? {
    MainActor.assumeIsolated {
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_Vision>
        return realityPlayerHostingController.rootView.avPlayer
    }
}

@_expose(Cxx)
public nonisolated func setAVPlayer_Vision(_ avPlayer: AVPlayer?, _ realityPlayerHostingController: UIViewController) {
    MainActor.assumeIsolated {
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_Vision>
        
        var rootView = realityPlayerHostingController.rootView
        
        guard rootView.avPlayer != avPlayer else { return }
        
        rootView.avPlayer = avPlayer
        realityPlayerHostingController.rootView = rootView
    }
}

@_expose(Cxx)
public nonisolated func videoRendererFromRealityPlayerHostingController_Vision(_ realityPlayerHostingController: UIViewController) -> AVSampleBufferVideoRenderer? {
    MainActor.assumeIsolated {
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_Vision>
        return realityPlayerHostingController.rootView.videoRenderer
    }
}

@_expose(Cxx)
public nonisolated func setVideoRenderer_Vision(_ videoRenderer: AVSampleBufferVideoRenderer?, _ realityPlayerHostingController: UIViewController) {
    MainActor.assumeIsolated {
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_Vision>
        
        var rootView = realityPlayerHostingController.rootView
        
        guard rootView.videoRenderer != videoRenderer else { return }
        
        rootView.videoRenderer = videoRenderer
        realityPlayerHostingController.rootView = rootView
    }
}

extension AVSampleBufferVideoRenderer: @retroactive @unchecked Sendable {}

#endif
