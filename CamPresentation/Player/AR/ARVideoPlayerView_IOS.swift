//
//  ARVideoPlayerView.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#if os(iOS)

@preconcurrency import Foundation
import UIKit
import SwiftUI
import ARKit
import RealityKit
@preconcurrency import AVFoundation
import Darwin.POSIX.dlfcn

@_expose(Cxx)
public nonisolated func newARVideoPlayerHostingController(
    avPlayer: AVPlayer,
    arSessionHandler: UnsafeRawPointer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView: ARVideoPlayerView
        
        if Int(bitPattern: arSessionHandler) == .zero {
            rootView = ARVideoPlayerView(avPlayer: avPlayer, arSessionHandler: nil)
        } else {
            let copy = unsafeBitCast(arSessionHandler, to: AnyObject.self).copy()
            
            rootView = ARVideoPlayerView(avPlayer: avPlayer) { arSession in
                let block = unsafeBitCast(copy, to: (@convention(block) (ARSession) -> Void).self)
                block(arSession)
            }
        }
        
        return UIHostingController(rootView: rootView)
    }
}

@_expose(Cxx)
public nonisolated func newARVideoPlayerHostingController(
    videoRenderer: AVSampleBufferVideoRenderer,
    arSessionHandler: UnsafeRawPointer
) -> UIViewController {
    MainActor.assumeIsolated {
        let rootView: ARVideoPlayerView
        
        if Int(bitPattern: arSessionHandler) == .zero {
            rootView = ARVideoPlayerView(videoRenderer: videoRenderer, arSessionHandler: nil)
        } else {
            let copy = unsafeBitCast(arSessionHandler, to: AnyObject.self).copy()
            
            rootView = ARVideoPlayerView(videoRenderer: videoRenderer) { arSession in
                let block = unsafeBitCast(copy, to: (@convention(block) (ARSession) -> Void).self)
                block(arSession)
            }
        }
        
        return UIHostingController(rootView: rootView)
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
    @State private var viewModel = ARVideoPlayerViewModel()
    @State private var status: AVPlayer.Status?
    @State private var rate: Float?
    
    init(avPlayer: AVPlayer, arSessionHandler: (@MainActor (ARSession) -> Void)?) {
        input = .avPlayer(avPlayer)
        viewModel.arSessionHandler = arSessionHandler
    }
    
    init (videoRenderer: AVSampleBufferVideoRenderer, arSessionHandler: (@MainActor (ARSession) -> Void)?) {
        input = .videoRenderer(videoRenderer)
        viewModel.arSessionHandler = arSessionHandler
    }
    
    var body: some View {
        GeometryReader { proxy in
            RealityView { (content: inout RealityViewCameraContent) in
                let arView = Mirror(reflecting: content).descendant("view") as! ARView
                viewModel.arSessionHandler?(arView.session)
                viewModel.arSessionHandler = nil
                
                content.camera = .spatialTracking
            } update: { (content: inout RealityViewCameraContent) in
                if viewModel.originID != viewModel.lastUpdatedOriginID {
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
                    viewModel.lastUpdatedOriginID = viewModel.__originID
                }
            }
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) {
            HStack {
                Button("Locate") {
                    viewModel.originID = .init()
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
                for await _ in avPlayer.observe(\.status, options: [.initial, .new]) {
                    statusState.wrappedValue = avPlayer.status
                }
            }
            
            let rateTask = Task { [rateState = _rate] in
                for await _ in avPlayer.observe(\.rate, options: [.initial, .new]) {
                    rateState.wrappedValue = avPlayer.rate
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
        .onDisappear {
            let handle = dlopen("/System/Library/Frameworks/RealityFoundation.framework/RealityFoundation", RTLD_NOW)!
            
            // static RealityFoundation.SpatialTrackingManager.shared.setter
            let setter = dlsym(handle, "$s17RealityFoundation22SpatialTrackingManagerC6sharedACSgvsZ")!
            let casted = unsafeBitCast(setter, to: (@convention(thin) (AnyObject?) -> Void).self)
            
            casted(nil)
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

@MainActor
@Observable
fileprivate final class ARVideoPlayerViewModel {
    var originID: UUID?
    var __originID: UUID? {
        _originID
    }
    @ObservationIgnored var lastUpdatedOriginID: UUID?
    @ObservationIgnored var arSessionHandler: (@MainActor (ARSession) -> Void)?
}

extension _KeyValueCodingAndObserving {
    func observe<Value>(
        _ keyPath: KeyPath<Self, Value>,
        options: NSKeyValueObservingOptions = [],
        bufferingPolicy limit: AsyncStream<NSKeyValueObservedChange<Value>>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<NSKeyValueObservedChange<Value>> {
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

extension UnsafeRawPointer: @retroactive @unchecked Sendable {}

#endif
