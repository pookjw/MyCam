//
//  RealityPlayerView_IOS.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 11/18/24.
//

#if os(iOS)

@preconcurrency import Foundation
import SwiftUI
import ARKit
import RealityKit
import AVFoundation
import Darwin.POSIX.dlfcn

struct RealityPlayerView_IOS: View {
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
    
    private enum Playback {
        case unavailable
        case playing
        case paused
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
    @State private var viewModel = ARVideoPlayerViewModel()
    @State private var status: AVPlayer.Status?
    @State private var rate: Float?
    
    init(avPlayer: AVPlayer?, arSessionHandler: (@MainActor (ARSession) -> Void)?) {
        if let avPlayer {
            input = .avPlayer(avPlayer)
        } else {
            input = nil
        }
        viewModel.arSessionHandler = arSessionHandler
    }
    
    init (videoRenderer: AVSampleBufferVideoRenderer?, arSessionHandler: (@MainActor (ARSession) -> Void)?) {
        if let videoRenderer {
            input = .videoRenderer(videoRenderer)
        } else {
            input = nil
        }
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
                let addedEntity = content.entities.first { $0.name == RealityPlayerView_IOS.videoPlayerEntityName }
                
                if let input {
                    let entity: Entity
                    
                    if let addedEntity {
                        let videoPlayerComponent = addedEntity.components[VideoPlayerComponent.self]!
                        
                        let shouldUpdate: Bool
                        if let avPlayer = input.avPlayer, videoPlayerComponent.avPlayer != avPlayer {
                            shouldUpdate = true
                        } else if let videoRenderer = input.videoRenderer, videoPlayerComponent.videoRenderer != videoRenderer {
                            shouldUpdate = true
                        } else {
                            shouldUpdate = false
                        }
                        
                        if shouldUpdate {
                            addedEntity.components.remove(VideoPlayerComponent.self)
                            addedEntity.components.set(makeVideoPlayerComponent()!)
                        }
                        
                        entity = addedEntity
                    } else {
                        entity = .init()
                        entity.components.set(makeVideoPlayerComponent()!)
                        entity.name = RealityPlayerView_IOS.videoPlayerEntityName
                        content.add(entity)
                        
                    }
                    
                    if viewModel.originID != viewModel.lastUpdatedOriginID {
                        viewModel.lastUpdatedOriginID = viewModel.__originID
                        
                        let arView = Mirror(reflecting: content).descendant("view") as! ARView
                        let arSession = arView.session
                        
                        let bounds: CGRect = arView.bounds
                        
                        guard let query: ARRaycastQuery = arView
                            .makeRaycastQuery(from: CGPoint(x: bounds.midX, y: bounds.midY),
                                              allowing: .estimatedPlane,
                                              alignment: .any) else {
                            return
                        }
                        
                        let raycasts: [ARRaycastResult] = arSession.raycast(query)
                        guard let firstRaycast: ARRaycastResult = raycasts.first else { return }
                        
                        
                        var transform = Transform(matrix: firstRaycast.worldTransform)
                        
                        viewModel.originalScale = transform.scale
                        
                        if let minXHitTest = content.hitTest(point: CGPoint(x: bounds.minX, y: bounds.midY), in: .local, query: .nearest, mask: .sceneUnderstanding).first,
                           let maxXHitTest = content.hitTest(point: CGPoint(x: bounds.maxX, y: bounds.midY), in: .local, query: .nearest, mask: .sceneUnderstanding).first,
                           let minYHitTest = content.hitTest(point: CGPoint(x: bounds.midX, y: bounds.minY), in: .local, query: .nearest, mask: .sceneUnderstanding).first,
                           let maxYHitTest = content.hitTest(point: CGPoint(x: bounds.midX, y: bounds.maxY), in: .local, query: .nearest, mask: .sceneUnderstanding).first
                        {
                            let distanceToEntity = simd_distance(arView.cameraTransform.translation, transform.translation)
                            let videoSize = entity.components[VideoPlayerComponent.self]!.playerScreenSize
                            let screenRatio = (maxXHitTest.position.x - minXHitTest.position.x) / (maxYHitTest.position.y - minYHitTest.position.y)
                            let vidioRatio = (videoSize.x / videoSize.y)
                            
                            var scale: Float
                            if screenRatio > vidioRatio {
                                let screenWorldWidth = maxXHitTest.position.x - minXHitTest.position.x
                                scale = (screenWorldWidth / videoSize.x) * (1.0 / distanceToEntity)
                            } else {
                                let screenWorldHeight = maxYHitTest.position.y - minYHitTest.position.y
                                scale = (screenWorldHeight / videoSize.y) * (1.0 / distanceToEntity)
                            }
                            
                            viewModel.__scale = scale
                        }
                        
                        transform.rotation *= simd_quatf(angle: .pi / 2.0, axis: SIMD3<Float>(1.0, .zero, .zero))
                        
                        entity.transform = transform
                    }
                    
                    entity.transform.scale.x = viewModel.originalScale.x * viewModel.scale
                    entity.transform.scale.y = viewModel.originalScale.y * viewModel.scale
                } else {
                    addedEntity?.components.remove(VideoPlayerComponent.self)
                }
            }
        }
        .ignoresSafeArea()
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    let magnificationOriginalScale: Float
                    if let _magnificationOriginalScale = viewModel.magnificationOriginalScale {
                        magnificationOriginalScale = _magnificationOriginalScale
                    } else {
                        viewModel.magnificationOriginalScale = viewModel.__scale
                        magnificationOriginalScale = viewModel.__scale
                    }
                    
                    viewModel.scale = magnificationOriginalScale * Float(value.magnification)
                }
                .onEnded { _ in
                    viewModel.magnificationOriginalScale = nil
                }
        )
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

@MainActor
@Observable
fileprivate final class ARVideoPlayerViewModel {
    var originID: UUID?
    var __originID: UUID? {
        _originID
    }
    @ObservationIgnored var lastUpdatedOriginID: UUID?
    @ObservationIgnored var arSessionHandler: (@MainActor (ARSession) -> Void)?
    @ObservationIgnored var originalScale: SIMD3<Float> = .zero
    var scale: Float = 0.75
    var __scale: Float {
        get {
            _scale
        }
        set {
            _scale = newValue
        }
    }
    @ObservationIgnored var magnificationOriginalScale: Float?
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
