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
    private static let videoPlayerEntityName = "videoPlayerEntity"
    
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
    @State private var role: UISceneSession.Role?
    
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
            withUnsafeMutablePointer(to: &content) { ptr in
                let bit = Int(bitPattern: ptr) + 0x18
                UnsafeMutablePointer<Int>(bitPattern: bit)?.pointee = .max
            }
            
            let role = Mirror(reflecting: content).descendant("role") as! UISceneSession.Role
            self.role = role
            
            switch role {
            case .immersiveSpaceApplication:
                fatalError()
            default:
                let entity = Entity()
                
                if let videoPlayerComponent = makeVideoPlayerComponent() {
                    entity.components.set(videoPlayerComponent)
                }
                
                entity.name = Self.videoPlayerEntityName
                
                content.add(entity)
                
                break
            }
        } update: { (content: inout RealityViewContent, attachments: RealityViewAttachments) in
            let entity = content.entities.first { $0.name == Self.videoPlayerEntityName }!
                    
            if let input {
                let videoPlayerComponent = entity.components[VideoPlayerComponent.self]!
                
                let shouldUpdate: Bool
                if let avPlayer = input.avPlayer, videoPlayerComponent.avPlayer != avPlayer {
                    shouldUpdate = true
                } else if let videoRenderer = input.videoRenderer, videoPlayerComponent.videoRenderer != videoRenderer {
                    shouldUpdate = true
                } else {
                    shouldUpdate = false
                }
                
                if shouldUpdate {
                    entity.components.remove(VideoPlayerComponent.self)
                    entity.components.set(makeVideoPlayerComponent()!)
                }
            } else {
                entity.components.remove(VideoPlayerComponent.self)
            }
                    
        } attachments: {
            
        }
    }
    
    private func makeVideoPlayerComponent() -> VideoPlayerComponent? {
        var component: VideoPlayerComponent
        switch input {
        case .avPlayer(let avPlayer):
            component = .init(avPlayer: avPlayer)
        case .videoRenderer(let videoRenderer):
            component = .init(videoRenderer: videoRenderer)
        case nil:
            return nil
        }
        
        return component
    }
}

#endif
