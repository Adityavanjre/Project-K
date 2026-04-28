// Copyright (c) 2025 ByteDance Ltd. and/or its affiliates
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

internal import DanceUIGraph

@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public protocol AnyHostedGestureObserving: AnyObject {
    
    /// - Note: The generic constraint `AnyValue` guarantees that the argument
    /// passed to this function with minimal effort of indirection. DO NOT
    /// change it into `Any` which stores value with an existential container.
    func _observedValue<AnyValue>(of valueType: AnyValue.Type) -> AnyValue
    
    /// - Note: The generic constraint `AnyValue` guarantees that the argument
    /// passed to this function with minimal effort of indirection. DO NOT
    /// change it into `Any` which stores value with an existential container.
    func _updateObservedValue<AnyValue>(_ value: AnyValue)
    
    /// Update the phase for a given gesture id.
    ///
    func _updatePhase(_ phase: ObservedGesturePhase<Void>, forID id: _AnyGestureID)
    
}

@available(iOS 13.0, *)
public struct _AnyGestureID: Hashable {
    
    /// Identifies the gesture phase
    ///
    /// - Note: This object alive in the duration of each
    /// `ViewGraph.sendEvent`'s invocation. Using `DGAttribute` as its internal
    /// implementation is OK.
    ///
    internal let id: DGAttribute
    
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public protocol GestureRecognizerValue {
    
    init()
    
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(tvOS, unavailable)
@available(iOS 13.0, *)
public protocol HostedGestureObserving: AnyHostedGestureObserving {
    
    associatedtype Value: GestureRecognizerValue
    
    var value: Value { get }
    
}
