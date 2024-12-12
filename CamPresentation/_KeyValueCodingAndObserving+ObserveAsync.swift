//
//  _KeyValueCodingAndObserving+ObserveAsync.swift
//  CamPresentation
//
//  Created by Jinwoo Kim on 12/12/24.
//

@preconcurrency import Foundation

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
