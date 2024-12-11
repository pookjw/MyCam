//
//  RealityPlayerView_Vision.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/11/24.
//

#if os(visionOS)

import SwiftUI
import RealityKit
import AVFoundation
import Darwin.POSIX.dlfcn

struct RealityPlayerView_Vision: View {
    private enum Input {
        case avPlayer(AVPlayer)
        case videoRenderer(AVSampleBufferVideoRenderer)
        
        var avPlayer: AVPlayer? {
            guard case let .avPlayer(avPlayer) = self else {
                return nil
            }
            
            return avPlayer
        }
        
        var videoRenderer: AVSampleBufferVideoRenderer? {
            guard case let .videoRenderer(videoRenderer) = self else {
                return nil
            }
            
            return videoRenderer
        }
    }
    
    var avPlayer: AVPlayer? {
        get {
            input?.avPlayer
        }
        set {
            if let newValue {
                input = .avPlayer(newValue)
            } else {
                input = nil
            }
        }
    }
    
    var videoRenderer: AVSampleBufferVideoRenderer? {
        get {
            input?.videoRenderer
        }
        set {
            if let newValue {
                input = .videoRenderer(newValue)
            } else {
                input = nil
            }
        }
    }
    
    private var input: Input?
    
    init(avPlayer: AVPlayer) {
        self.init(input: .avPlayer(avPlayer))
    }
    
    init(videoRenderer: AVSampleBufferVideoRenderer) {
        self.init(input: .videoRenderer(videoRenderer))
    }
    
    init() {
        self.init(input: nil)
    }
    
    private init(input: Input?) {
        self.input = input
    }
    
    var body: some View {
        RealityView.init { (content: inout RealityViewContent, attachments: RealityViewAttachments) in
            let _RealityKit_SwiftUI = dlopen("/System/Library/Frameworks/_RealityKit_SwiftUI.framework/_RealityKit_SwiftUI", RTLD_NOW)!
            let symbol = dlsym(_RealityKit_SwiftUI, "$s19_RealityKit_SwiftUI0A17ViewCameraContentV22_proto_debugOptions_v10aB06ARViewC05DebugJ0Vvg")
            let casted = unsafeBitCast(symbol, to: (@convention(thin) (RealityViewContent) -> Int).self)
            print(casted(content))
            // $s19_RealityKit_SwiftUI0A17ViewCameraContentV22_proto_debugOptions_v10aB06ARViewC05DebugJ0Vvs
            for child in Mirror(reflecting: content).children {
                print(child)
                for child in Mirror(reflecting: child.value).children {
                    print("   " + "\(child)")
                }
            }
        } update: { (content: inout RealityViewContent, attachments: RealityViewAttachments) in
            
        } attachments: {
            
        }
    }
}

#endif
