//
//  ARVideoPlayerView.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

@preconcurrency import Foundation
import UIKit
import SwiftUI
import ARKit
import RealityKit
@preconcurrency import AVFoundation

@_expose(Cxx)
public nonisolated func newARVideoPlayerHostingController(avPlayer: AVPlayer) -> UIViewController {
    MainActor.assumeIsolated {
        UIHostingController(rootView: ARVideoPlayerView(avPlayer: avPlayer))
    }
}

@_expose(Cxx)
public nonisolated func newARVideoPlayerHostingController(videoRenderer: AVSampleBufferVideoRenderer) -> UIViewController {
    MainActor.assumeIsolated {
        UIHostingController(rootView: ARVideoPlayerView(videoRenderer: videoRenderer))
    }
}

fileprivate struct ARVideoPlayerView: View {
    private static let videoPlayerEntityName = "videoPlayerEntity"
    
    private enum Input {
        case avPlayer(AVPlayer)
        case videoRenderer(AVSampleBufferVideoRenderer)
    }
    
    private enum Playback {
        case unavailable
        case playing
        case paused
    }
    
    private let input: Input
    @State private var originID: UUID?
    @State private var status: AVPlayer.Status?
    @State private var rate: Float?
    
    init(avPlayer: AVPlayer) {
        input = .avPlayer(avPlayer)
    }
    
    init (videoRenderer: AVSampleBufferVideoRenderer) {
        input = .videoRenderer(videoRenderer)
    }
    
    var body: some View {
        GeometryReader { proxy in
            RealityView { (content: inout RealityViewCameraContent) in
                content.camera = .spatialTracking
            } update: { (content: inout RealityViewCameraContent) in
                if let _ = originID {
                    let frame = proxy.frame(in: .local)
                    let center = CGPoint(x: frame.midX, y: frame.midY)
                    guard let hit = content.hitTest(point: center, in: .local, query: .nearest, mask: .sceneUnderstanding).first else {
                        return
                    }
                    
                    let entity: Entity
                    if let _entity = content.entities.first(where: { $0.name == ARVideoPlayerView.videoPlayerEntityName }) {
                        entity = _entity
                    } else {
                        let videoPlayerComponent: VideoPlayerComponent = makeVideoPlayerComponent()
                        entity = .init()
                        entity.components.set(videoPlayerComponent)
                        entity.name = ARVideoPlayerView.videoPlayerEntityName
                        content.add(entity)
                    }
                    
                    entity.transform = .init(rotation: .init(vector: .init(hit.normal, .zero)), translation: hit.position)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            HStack {
                Button("Locate") {
                    originID = .init()
                }
                .buttonStyle(.bordered)
                
                if case let .avPlayer(avPlayer) = input {
                    Button {
                        if avPlayer.rate == .zero {
                            avPlayer.play()
                        } else {
                            avPlayer.pause()
                        }
                    } label: {
                        if let rate, rate > .zero {
                            Image(systemName: "pause.fill")
                        } else {
                            Image(systemName: "play.fill")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(status != .readyToPlay)
                }
            }
        }
        .task {
            guard case let .avPlayer(avPlayer) = input else { return }
            
            let statusTask = Task { [statusState = _status] in
                statusState.wrappedValue = avPlayer.status
                
                for await change in avPlayer.observe(\.status, options: .new) {
                    statusState.wrappedValue = change.newValue
                }
            }
            
            let rateTask = Task { [rateState = _rate] in
                rateState.wrappedValue = avPlayer.rate
                
                for await change in avPlayer.observe(\.rate, options: .new) {
                    rateState.wrappedValue = change.newValue
                }
            }
            
            let didPlayToEndTimeTask = Task {
                for await notification in NotificationCenter.default.notifications(named: .AVPlayerItemDidPlayToEndTime) {
                    if avPlayer.currentItem?.isEqual(notification.object) ?? false {
                        await avPlayer.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
                    }
                }
            }
            
            await withTaskCancellationHandler {
                await statusTask.value
                await rateTask.value
                await didPlayToEndTimeTask.value
            } onCancel: {
                statusTask.cancel()
                rateTask.cancel()
                didPlayToEndTimeTask.cancel()
            }
        }
    }
    
    private func makeVideoPlayerComponent() -> VideoPlayerComponent {
        var component: VideoPlayerComponent
        switch input {
        case .avPlayer(let avPlayer):
            print(avPlayer)
            component = .init(avPlayer: avPlayer)
        case .videoRenderer(let videoRenderer):
            component = .init(videoRenderer: videoRenderer)
        }
        
        return component
    }
}

extension _KeyValueCodingAndObserving {
    func observe<Value>(
        _ keyPath: KeyPath<Self, Value>,
        options: NSKeyValueObservingOptions = [],
        bufferingPolicy limit: AsyncStream<NSKeyValueObservedChange<Value>>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<NSKeyValueObservedChange<Value>> {
        guard !options.contains(.initial) else { fatalError() }
        
        let (stream, continuation) = AsyncStream<NSKeyValueObservedChange<Value>>.makeStream(bufferingPolicy: limit)
        
        let observation = observe(keyPath, options: options) { object, change in
            continuation.yield(change)
        }
        
        continuation.onTermination = { _ in
            observation.invalidate()
        }
        
        return stream
    }
}
