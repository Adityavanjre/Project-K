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

import Foundation

/// A description of how a value changes over time, modeled using keyframes.
///
/// Unlike other animations (using ``Animation``), keyframes don't
/// interpolate between from and to values provided as state changes.
/// Instead, keyframes fully define the path that a value takes over time
/// using the tracks that make up their body.
///
/// `Keyframes` values are roughly analogous to video clips;
/// they have a set duration, and you can scrub and evaluate them for any
/// time within the duration.
///
/// The `Keyframes` structure also allows you to compute an interpolated
/// value at a specific time, which you can use when integrating keyframes
/// into custom use cases.
///
/// For example, you can use a `Keyframes` instance to define animations for a
/// type conforming to `Animatable:`
///
///     let keyframes = KeyframeTimeline(initialValue: CGPoint.zero) {
///         CubcKeyframe(.init(x: 0, y: 100), duration: 0.3)
///         CubicKeyframe(.init(x: 0, y: 0), duration: 0.7)
///     }
///
///     let value = keyframes.value(time: 0.45
///
/// For animations that involve multiple coordinated changes, you can include
/// multiple nested tracks:
///
///     struct Values {
///         var rotation = Angle.zero
///         var scale = 1.0
///     }
///
///     let keyframes = KeyframeTimeline(initialValue: Values()) {
///         KeyframeTrack(\.rotation) {
///             CubicKeyframe(.zero, duration: 0.2)
///             CubicKeyframe(.degrees(45), duration: 0.3)
///         }
///         KeyframeTrack(\.scale) {
///             CubicKeyframe(value: 1.2, duration: 0.5)
///             CubicKeyframe(value: 0.9, duration: 0.2)
///             CubicKeyframe(value: 1.0, duration: 0.3)
///         }
///     }
///
/// Multiple nested tracks update the initial value in the order that they are
/// declared. This means that if multiple nested plans change the same property
/// of the root value, the value from the last competing track will be used.
///
@available(iOS 13.0, *)
public struct KeyframeTimeline<Value> {
    
    internal var initialValue: Value
    
    internal var content: _ResolvedKeyframes<Value>

    /// Creates a new instance using the initial value and content that you
    /// provide.
    public init(initialValue: Value, 
                @KeyframesBuilder<Value> content: () -> some Keyframes<Value>) {
        self.initialValue = initialValue
        var keyFrames = _ResolvedKeyframes<Value>(tracks: [])
        content()._resolve(into: &keyFrames, initialValue: initialValue, initialVelocity: nil)
        self.content = keyFrames
    }
    
    internal init(initialValue: Value, 
                  initialVelocity: Value? = nil,
                  @KeyframesBuilder<Value> content: () -> some Keyframes<Value>) {
        self.initialValue = initialValue
        var keyFrames = _ResolvedKeyframes<Value>(tracks: [])
        content()._resolve(into: &keyFrames, initialValue: initialValue, initialVelocity: initialVelocity)
        self.content = keyFrames
    }

    /// The duration of the content in seconds.
    public var duration: TimeInterval {
        guard !content.tracks.isEmpty else {
            return 0
        }
        return content.tracks.reduce(0, {.maximum($0, $1.duration)})
    }

    /// Returns the interpolated value at the given time.
    public func value(time: Double) -> Value {
        var value = initialValue
        guard !content.tracks.isEmpty else {
            return value
        }
        for track in content.tracks {
            track.update(&value, time)
        }
        return value
    }

    /// Returns the interpolated value at the given progress in the range zero to one.
    public func value(progress: Double) -> Value {
        value(time: duration * progress)
    }
    
    internal func velocity(time: Double) -> Value {
        var value = initialValue
        guard !content.tracks.isEmpty else {
            return value
        }
        for track in content.tracks {
            track.updateVelocity(&value, time)
        }
        return value
    }
}
