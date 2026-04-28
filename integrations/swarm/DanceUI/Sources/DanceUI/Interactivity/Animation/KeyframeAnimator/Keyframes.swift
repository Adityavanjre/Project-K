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

@available(iOS 13.0, *)
internal struct CombinedKeyframes<Value, First: Keyframes, Second: Keyframes>: PrimitiveKeyframes where Value == First.Value, First.Value == Second.Value {
    
    internal typealias Value = Value
    
    internal var first: First
    
    internal var second: Second
    
    internal func _resolve(into resolved: inout _ResolvedKeyframes<Value>,
                           initialValue: Value,
                           initialVelocity: Value?) {
        first._resolve(into: &resolved,
                       initialValue: initialValue,
                       initialVelocity: initialVelocity)
        second._resolve(into: &resolved,
                        initialValue: initialValue,
                        initialVelocity: initialVelocity)
    }
    
    
}

@available(iOS 13.0, *)
internal struct EmptyKeyframes<Value>: PrimitiveKeyframes {
    
    internal typealias Value = Value
    
    internal func _resolve(into resolved: inout _ResolvedKeyframes<Value>,
                           initialValue: Value,
                           initialVelocity: Value?) {
        _intentionallyLeftBlank()
    }
    
}


/// A sequence of keyframes animating a single property of a root type.
@available(iOS 13.0, *)
public struct KeyframeTrack<Root, Value, Content: KeyframeTrackContent>: PrimitiveKeyframes where Value == Content.Value {
    
    public typealias Value = Root
    
    public var keyPath: WritableKeyPath<Root, Value>
    
    public var content: Content
    
    /// Creates an instance that animates the entire value from the root of the key path.
    ///
    /// - Parameter keyframes: A keyframe collection builder closure containing
    ///   the keyframes that control the interpolation curve.
    public init(@KeyframeTrackContentBuilder<Root> content: () -> Content) where Root == Value {
        self.keyPath = \Root.self
        self.content = content()
    }
    
    /// Creates an instance that animates the property of the root value
    /// at the given key path.
    ///
    /// - Parameter keyPath: The property to animate.
    /// - Parameter keyframes: A keyframe collection builder closure containing
    ///   the keyframes that control the interpolation curve.
    public init(_ keyPath: WritableKeyPath<Root, Value>, @KeyframeTrackContentBuilder<Value> content: () -> Content) {
        self.keyPath = keyPath
        self.content = content()
    }
    
    public func _resolve(into resolved: inout _ResolvedKeyframes<Root>,
                         initialValue: Root,
                         initialVelocity: Root?) {
        let value = initialValue[keyPath: keyPath]
        var velocity: Value? = nil
        if let initialVelocity = initialVelocity {
            velocity = initialVelocity[keyPath: keyPath]
        }
        let path = resolve(value, initialVelocity: velocity)
        resolved.append(keyPath: keyPath, animationPath: path)
    }
    
    internal func resolve(_ initialValue: Value, initialVelocity: Value?) -> AnimationPath<Value> {
        var trackContent = _ResolvedKeyframeTrackContent<Value>(segments: [])
        self.content._resolve(into: &trackContent)
        return AnimationPath { path in
            guard !trackContent.segments.isEmpty else {
                return
            }
            for (index, segment) in trackContent.segments.enumerated() {
                switch segment {
                case .move(let animatableData):
                    path.append(.move(animatableData))
                case .cubic(let cubic):
                    let start: Value.AnimatableData
                    if let element = path.elements.last {
                        start = element.end
                    } else {
                        start = initialValue.animatableData
                    }
                    var helper = CubicKeyframeHelper<Value>(from: start,
                                                            to: cubic.to,
                                                            duration: cubic.duration,
                                                            start: .none,
                                                            end: .none)
                    helper.updateStartVelocity(value: initialValue,
                                               velocity: initialVelocity,
                                               startVelocity: cubic.startVelocity,
                                               index: index,
                                               trackContent: trackContent, 
                                               path: path)
                    
                    helper.updateEndVelocity(velocity: cubic.to,
                                             endVelocity: cubic.endVelocity,
                                             index: index,
                                             trackContent: trackContent,
                                             duration: cubic.duration)
                    
                    let curve = helper.curve()
                    let element = AnimationPath<Value>.CurveElement(curve: curve,
                                                                    duration: helper.duration,
                                                                    constantVelocity: false,
                                                                    timingCurve: .linear)
                    path.append(.curve(element))
                case .spring(let spring):
                    let velocity: Value.AnimatableData
                    if let startVelocity = spring.startVelocity {
                        velocity = startVelocity
                    } else {
                        if let element = path.elements.last {
                            velocity = element.endVelocity
                        } else {
                            velocity = initialVelocity?.animatableData ?? .zero
                        }
                    }
                    let start: Value.AnimatableData
                    if let element = path.elements.last {
                        start = element.end
                    } else {
                        start = initialValue.animatableData
                    }
                    let time: Double
                    if let duration = spring.duration {
                        time = duration
                    } else {
                        time = spring.spring.settlingDuration(target: spring.to - start,
                                                              initialVelocity: velocity,
                                                              epsilon: 0.0001)
                    }
                    let value = spring.spring.value(target: spring.to - start,
                                                   initialVelocity: velocity,
                                                   time: time)
                    let end = start + value
                    path.append(.spring(.init(spring: spring.spring,
                                              from: start,
                                              to: spring.to,
                                              initialVelocity: velocity,
                                              end: end,
                                              duration: time)))
                case .linear(let linear):
                    let start: Value.AnimatableData
                    if let element = path.elements.last {
                        start = element.end
                    } else {
                        start = initialValue.animatableData
                    }
                    let curve = HermiteCurve<Value>(start: start,
                                                    end: linear.to)
                    let element = AnimationPath<Value>.CurveElement(curve: curve,
                                                                    duration: linear.duration,
                                                                    constantVelocity: false,
                                                                    timingCurve: linear.timingCurve)
                    path.append(.curve(element))
                }
            }
        }
    }
    
}

@available(iOS 13.0, *)
private struct CubicKeyframeHelper<Value: Animatable> {
    
    internal var from: Value.AnimatableData

    internal var to: Value.AnimatableData

    internal var duration: Double

    internal var start: Connection

    internal var end: Connection
    
    fileprivate enum Connection {
        
        case custom(velocity: Value.AnimatableData)
        
        case automatic(duration: Double, value: Value.AnimatableData)
        
        case none
        
        
    }
    
    @inline(__always)
    internal func curve() -> HermiteCurve<Value> {
        var startTangent: Value.AnimatableData
        switch start {
        case .custom(let velocity):
            startTangent = velocity
            if duration > 0 {
                startTangent.scale(by: duration)
            }
        case .automatic(let duration, let value):
            let f = (self.from - value).scaled(by: 0.5)
            let t = (self.to - self.from).scaled(by: 0.5)
            startTangent = (f + t)
            if self.duration > 0 && duration > 0 {
                let scale = (self.duration * 2) / (duration + self.duration)
                startTangent.scale(by: scale)
            }
        case .none:
            startTangent = .zero
        }
        
        var endTangent: Value.AnimatableData
        switch end {
        case .custom(let velocity):
            endTangent = velocity
            if duration > 0 {
                endTangent.scale(by: duration)
            }
        case .automatic(let duration, let value):
            let f = (value - self.to).scaled(by: 0.5)
            let t = (self.to - self.from).scaled(by: 0.5)
            endTangent = (f + t)
            if self.duration > 0 && duration > 0 {
                let scale = (self.duration * 2) / (duration + self.duration)
                endTangent.scale(by: scale)
            }
        case .none:
            endTangent = .zero
        }
        return .hermite(start: self.from,
                        end: self.to,
                        startTangent: startTangent,
                        endTangent: endTangent)
    }
    
    @inline(__always)
    internal mutating func updateStartVelocity(value: Value,
                                               velocity: Value?,
                                               startVelocity: Value.AnimatableData?,
                                               index: Int,
                                               trackContent: _ResolvedKeyframeTrackContent<Value>,
                                               path: AnimationPath<Value>) {
        if let startVelocity = startVelocity {
            self.start = .custom(velocity: startVelocity)
        } else {
            if index > 0 {
                let previousIndex = index - 1
                let previousSegment = trackContent.segments[previousIndex]
                switch previousSegment {
                case .move:
                    self.start = .custom(velocity: .zero)
                case .cubic(let cubic):
                    if index < 2 {
                        self.start = .automatic(duration: cubic.duration,
                                                value: value.animatableData)
                    } else {
                        if let v = cubic.endVelocity {
                            self.start = .custom(velocity: v)
                        } else {
                            let segment = trackContent.segments[index - 2]
                            self.start = .automatic(duration: cubic.duration,
                                                    value: segment.end)
                        }
                    }
                case .spring:
                    self.start = .custom(velocity: path.currentVelocity())
                case .linear(let linear):
                    let consumedValue: Value.AnimatableData
                    if index < 2 {
                        consumedValue = value.animatableData
                    } else {
                        let segment = trackContent.segments[index - 2]
                        consumedValue = segment.end
                    }
                    var value = (linear.to - consumedValue).scaled(by: (1.0 / linear.duration))
                    let scale = linear.timingCurve.velocity(at: 1.0)
                    value.scale(by: scale)
                    self.start = .custom(velocity: value)
                }
            } else {
                guard let velocity = velocity else {
                    self.start = .none
                    return
                }
                self.start = .custom(velocity: velocity.animatableData)
            }
        }
    }
    
    @inline(__always)
    internal mutating func updateEndVelocity(velocity: Value.AnimatableData,
                                             endVelocity: Value.AnimatableData?,
                                             index: Int,
                                             trackContent: _ResolvedKeyframeTrackContent<Value>,
                                             duration: Double) {
        if let endVelocity = endVelocity {
            self.end = .custom(velocity: endVelocity)
        } else {
            if index == trackContent.segments.count - 1 {
                self.end = .none
            } else {
                let segment = trackContent.segments[index + 1]
                switch segment {
                case .move:
                    self.end = .custom(velocity: .zero)
                case .cubic(let cubic):
                    if let v = cubic.startVelocity {
                        self.end = .custom(velocity: v)
                    } else {
                        self.end = .automatic(duration: cubic.duration,
                                              value: cubic.to)
                    }
                case .spring(let spring):
                    if let v = spring.startVelocity {
                        self.end = .custom(velocity: v)
                    } else {
                        self.end = .automatic(duration: duration,
                                              value: spring.to)
                    }
                case .linear(let linear):
                    var value = (linear.to - velocity).scaled(by: (1.0 / linear.duration))
                    let scale = linear.timingCurve.velocity(at: 0)
                    value.scale(by: scale)
                    self.end = .custom(velocity: value)
                }
                
            }
        }
    }
    
    
}


/// A keyframe that uses simple linear interpolation.
@available(iOS 13.0, *)
public struct LinearKeyframe<Value: Animatable>: PrimitiveKeyframeTrackContent {
    
    internal var segment : _ResolvedKeyframeTrackContent<Value>.Linear
    
    /// Creates a new keyframe using the given value and timestamp.
    ///
    /// - Parameters:
    ///   - to: The value of the keyframe.
    ///   - duration: The duration of the segment defined by this keyframe.
    ///   - timingCurve: A unit curve that controls the speed of interpolation.
    public init(_ to: Value,
                duration: TimeInterval,
                timingCurve: UnitCurve = .linear) {
        segment = .init(to: to.animatableData, duration: duration, timingCurve: timingCurve)
    }
    
    public func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<Value>) {
        resolved.segments.append(.linear(segment))
    }
    
}

/// A keyframe that uses a cubic curve to smoothly interpolate between values.
///
/// If you don't specify a start or end velocity, a curve that maintains
/// smooth motion between keyframes will be automatically computed.
///
/// Adjacent cubic keyframes result in a Catmull-Rom spline.
///
/// If a cubic keyframe follows a different type of keyframe, such as a linear
/// keyframe, the end velocity of the segment defined by the previous keyframe
/// will be used as the starting velocity.
///
/// Likewise, if a cubic keyframe is followed by a different type of keyframe,
/// the initial velocity of the next segment is used as the end velocity of the
/// segment defined by this keyframe.
@available(iOS 13.0, *)
public struct CubicKeyframe<Value: Animatable>: PrimitiveKeyframeTrackContent {
    
    internal var segment : _ResolvedKeyframeTrackContent<Value>.Cubic
    
    /// Creates a new keyframe using the given value and timestamp.
    ///
    /// - Parameters:
    ///   - to: The value of the keyframe.
    ///   - startVelocity: The velocity of the value at the beginning of the
    ///     segment, or `nil` to automatically compute the velocity to maintain
    ///     smooth motion.
    ///   - endVelocity: The velocity of the value at the end of the segment,
    ///     or `nil` to automatically compute the velocity to maintain smooth
    ///     motion.
    ///   - duration: The duration of the segment defined by this keyframe.
    public init(_ to: Value,
                duration: TimeInterval,
                startVelocity: Value? = nil,
                endVelocity: Value? = nil) {
        segment = .init(to: to.animatableData,
                        startVelocity: startVelocity?.animatableData,
                        endVelocity: endVelocity?.animatableData,
                        duration: duration)
    }
    
    public func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<Value>) {
        resolved.segments.append(.cubic(segment))
    }
}

/// A keyframe that immediately moves to the given value without interpolating.
@available(iOS 13.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
public struct MoveKeyframe<Value: Animatable> : PrimitiveKeyframeTrackContent {
    
    internal var value: Value
    
    /// Creates a new keyframe using the given value.
    ///
    /// - Parameters:
    ///   - to: The value of the keyframe.
    public init(_ to: Value) {
        self.value = to
    }
    
    public func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<Value>) {
        resolved.segments.append(.move(value.animatableData))
    }
    
}

/// A keyframe that uses a spring function to interpolate to the given value.
@available(iOS 13.0, *)
public struct SpringKeyframe<Value: Animatable> : PrimitiveKeyframeTrackContent {
    
    internal var segment: _ResolvedKeyframeTrackContent<Value>.Spring

    /// Creates a new keyframe using the given value and timestamp.
    ///
    /// - Parameters:
    ///   - to: The value of the keyframe.
    ///   - duration: The duration of the segment defined by this keyframe,
    ///     or nil to use the settling duration of the spring.
    ///   - spring: The spring that defines the shape of the segment befire
    ///     this keyframe
    ///   - startVelocity: The velocity of the value at the start of the
    ///     segment, or `nil` to automatically compute the velocity to maintain
    ///     smooth motion.
    public init(_ to: Value,
                duration: TimeInterval? = nil,
                spring: Spring = Spring(),
                startVelocity: Value? = nil) {
        segment = .init(to: to.animatableData,
                        spring: spring,
                        startVelocity: startVelocity?.animatableData,
                        duration: duration)
    }

    public func _resolve(into resolved: inout _ResolvedKeyframeTrackContent<Value>) {
        resolved.segments.append(.spring(segment))
    }
}
