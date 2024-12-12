//
//  ARVideoPlayerView_IOS+Bridge.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/10/24.
//

#if os(iOS)

import UIKit
import SwiftUI
import ARKit
@preconcurrency import AVFoundation

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingControllerFromPlayer_IOS(
    avPlayer: AVPlayer,
    arSessionHandler: UnsafeRawPointer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView: RealityPlayerView_IOS
        
        if Int(bitPattern: arSessionHandler) == .zero {
            rootView = RealityPlayerView_IOS(avPlayer: avPlayer, arSessionHandler: nil)
        } else {
            let copy = unsafeBitCast(arSessionHandler, to: AnyObject.self).copy()
            
            rootView = RealityPlayerView_IOS(avPlayer: avPlayer) { arSession in
                let block = unsafeBitCast(copy, to: (@convention(block) (ARSession) -> Void).self)
                block(arSession)
            }
        }
        
        return UIHostingController(rootView: rootView)
    }
}

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingControllerFromVideoRenderer_IOS(
    videoRenderer: AVSampleBufferVideoRenderer,
    arSessionHandler: UnsafeRawPointer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView: RealityPlayerView_IOS
        
        if Int(bitPattern: arSessionHandler) == .zero {
            rootView = RealityPlayerView_IOS(videoRenderer: videoRenderer, arSessionHandler: nil)
        } else {
            let copy = unsafeBitCast(arSessionHandler, to: AnyObject.self).copy()
            
            rootView = RealityPlayerView_IOS(videoRenderer: videoRenderer) { arSession in
                let block = unsafeBitCast(copy, to: (@convention(block) (ARSession) -> Void).self)
                block(arSession)
            }
        }
        
        return UIHostingController(rootView: rootView)
    }
}

@_expose(Cxx)
public nonisolated func newRealityPlayerHostingController_IOS(
    arSessionHandler: UnsafeRawPointer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView: RealityPlayerView_IOS
        
        if Int(bitPattern: arSessionHandler) == .zero {
            rootView = RealityPlayerView_IOS(arSessionHandler: nil)
        } else {
            let copy = unsafeBitCast(arSessionHandler, to: AnyObject.self).copy()
            
            rootView = RealityPlayerView_IOS { arSession in
                let block = unsafeBitCast(copy, to: (@convention(block) (ARSession) -> Void).self)
                block(arSession)
            }
        }
        
        return UIHostingController(rootView: rootView)
    }
}

@_expose(Cxx)
public nonisolated func avPlayerFromRealityPlayerHostingController_IOS(_ realityPlayerHostingController: UIViewController) -> AVPlayer? {
    MainActor.assumeIsolated { 
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_IOS>
        return realityPlayerHostingController.rootView.avPlayer
    }
}

@_expose(Cxx)
public nonisolated func setAVPlayer_IOS(_ avPlayer: AVPlayer?, _ realityPlayerHostingController: UIViewController) {
    MainActor.assumeIsolated { 
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_IOS>
        
        var rootView = realityPlayerHostingController.rootView
        
        guard rootView.avPlayer != avPlayer else { return }
        
        rootView.avPlayer = avPlayer
        realityPlayerHostingController.rootView = rootView
    }
}

@_expose(Cxx)
public nonisolated func videoRendererFromRealityPlayerHostingController_IOS(_ realityPlayerHostingController: UIViewController) -> AVSampleBufferVideoRenderer? {
    MainActor.assumeIsolated { 
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_IOS>
        return realityPlayerHostingController.rootView.videoRenderer
    }
}

@_expose(Cxx)
public nonisolated func setVideoRenderer_IOS(_ videoRenderer: AVSampleBufferVideoRenderer?, _ realityPlayerHostingController: UIViewController) {
    MainActor.assumeIsolated { 
        let realityPlayerHostingController = realityPlayerHostingController as! UIHostingController<RealityPlayerView_IOS>
        
        var rootView = realityPlayerHostingController.rootView
        
        guard rootView.videoRenderer != videoRenderer else { return }
        
        rootView.videoRenderer = videoRenderer
        realityPlayerHostingController.rootView = rootView
    }
}

extension AVSampleBufferVideoRenderer: @retroactive @unchecked Sendable {}

#endif
