//
//  RealityPlayerView_IOS+ViewModel.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/12/24.
//

#if os(iOS)

import ARKit
import Observation

extension RealityPlayerView_IOS {
    @MainActor
    @Observable
    final class ViewModel {
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
}

#endif
