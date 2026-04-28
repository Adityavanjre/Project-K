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
private let tau: Double = 2*Double.pi
@available(iOS 13.0, *)
private let timeInterval = 0.0033333333333333335
@available(iOS 13.0, *)
private let second = 0.0016666666666666668
@available(iOS 13.0, *)
private let threshold = 0.0036

@available(iOS 13.0, *)
internal struct FluidSpringAnimation: InternalCustomAnimation, CustomAnimation, Hashable {
    
    internal var response: Double
    
    internal var dampingFraction: Double
    
    internal var blendDuration: Double
    
    internal func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
        var state = context.state[SpringState<V>.self]
        
        let duration: Double
        if blendDuration > 0 && state.blendInterval != 0 {
            let p = (time - state.blendStart) / blendDuration
            let progress: Double
            if p >= 0 {
                progress = .minimum(1, p)
            } else {
                progress = 0
            }
            
            let progressFactor = progress * 2
            let blendIntervalFactor = state.blendInterval * (1 - ((3 - progressFactor) * pow(progress, 2)))
            duration = response + blendIntervalFactor
        } else {
            duration = response
        }
        
        if time - state.startTime >= duration { // finshed
            context.isLogicallyComplete = true
        }
        
        var t = state.time
        if time - state.time > 1 {
            state.time = time - second
            t = -second
        }
        
        if time > t {
            repeat {
                var springConstantSquared = duration <= 0 ? .infinity : pow(tau / duration, 2)
                springConstantSquared = .minimum(springConstantSquared, 45000)
                let dampingFactor = sqrt(springConstantSquared) * -2 * dampingFraction
                var totalForce = state.force
                totalForce.scale(by: second)
                totalForce += state.velocity
                let offsetIncrement = totalForce.scaled(by: timeInterval)
                state.offset += offsetIncrement
                var dampingForce = totalForce
                dampingForce.scale(by: dampingFactor)
                var forceIncrement = value
                forceIncrement -= state.offset
                forceIncrement.scale(by: springConstantSquared)
                state.force = dampingForce
                state.force += forceIncrement
                state.velocity = state.force
                state.velocity.scale(by: second)
                state.velocity += totalForce
                state.time += timeInterval
            } while time > state.time
        }
        
        context.state[SpringState<V>.self] = state
        
        
        let squaredVelocity = state.velocity.magnitudeSquared
        let squaredForce = state.force.magnitudeSquared
        
        guard Double.maximum(squaredVelocity, squaredForce) <= threshold else {
            return state.offset
        }
        let vd0 = value.scaled(by: 0.01)
        let vc8 = value - state.offset
        guard vd0.magnitudeSquared > 0, vc8.magnitudeSquared > vd0.magnitudeSquared else {
            return nil
        }
        return state.offset
    }
    
    internal func velocity<V>(value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic {
        context.state[SpringState<V>.self].velocity
    }
    
    internal func shouldMerge<V>(previous: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> Bool where V : VectorArithmetic {
        var state = context.state[SpringState<V>.self]
        if let velocity = previous.velocity(value: value, time: time, context: context) {
            state.velocity = velocity
        }
        if let value = previous.animate(value: value, time: time, context: &context) {
            state.offset = value
        }
        state.time = time
        state.startTime = time
        
        if let box = previous.base as? Self, box.response != self.response {
            state.blendInterval = box.response - self.response
            state.blendStart = time
        }
        context.state[SpringState<V>.self] = state
        return true
    }
    
}

@available(iOS 13.0, *)
private struct SpringState<ValueType: VectorArithmetic>: AnimationStateKey {
    
    fileprivate typealias Value = SpringState
    
    fileprivate static var defaultValue: SpringState {
        SpringState(offset: .zero,
                    velocity: .zero,
                    force: .zero,
                    time: 0,
                    startTime: 0,
                    blendStart: 0,
                    blendInterval: 0)
    }
    
    fileprivate var offset: ValueType

    fileprivate var velocity: ValueType

    fileprivate var force: ValueType

    fileprivate var time: Double

    fileprivate var startTime: Double

    fileprivate var blendStart: Double

    fileprivate var blendInterval: Double
    
}

@available(iOS 13.0, *)
extension Animation {
    
    /// A persistent spring animation. When mixed with other `spring()`
    /// or `interactiveSpring()` animations on the same property, each
    /// animation will be replaced by their successor, preserving
    /// velocity from one animation to the next. Optionally blends the
    /// response values between springs over a time period.
    ///
    /// This uses the default parameter values.
    @_alwaysEmitIntoClient
    public static var spring: Animation {
        spring()
    }
    
    /// A persistent spring animation. When mixed with other `spring()`
    /// or `interactiveSpring()` animations on the same property, each
    /// animation will be replaced by their successor, preserving
    /// velocity from one animation to the next. Optionally blends the
    /// response values between springs over a time period.
    ///
    /// - Parameters:
    ///   - response: The stiffness of the spring, defined as an
    ///     approximate duration in seconds. A value of zero requests
    ///     an infinitely-stiff spring, suitable for driving
    ///     interactive animations.
    ///   - dampingFraction: The amount of drag applied to the value
    ///     being animated, as a fraction of an estimate of amount
    ///     needed to produce critical damping.
    ///   - blendDuration: The duration in seconds over which to
    ///     interpolate changes to the response value of the spring.
    /// - Returns: a spring animation.
    @_disfavoredOverload
    public static func spring(response: Double = 0.5, dampingFraction: Double = 0.825, blendDuration: Double = 0) -> Animation {
        Animation(internal: FluidSpringAnimation(response: response,
                                                 dampingFraction: dampingFraction,
                                                 blendDuration: blendDuration))
    }
    
    /// A persistent spring animation. When mixed with other `spring()`
    /// or `interactiveSpring()` animations on the same property, each
    /// animation will be replaced by their successor, preserving
    /// velocity from one animation to the next. Optionally blends the
    /// duration values between springs over a time period.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - bounce: How bouncy the spring should be. A value of 0 indicates
    ///     no bounces (a critically damped spring), positive values indicate
    ///     increasing amounts of bounciness up to a maximum of 1.0
    ///     (corresponding to undamped oscillation), and negative values
    ///     indicate overdamped springs with a minimum value of -1.0.
    ///   - blendDuration: The duration in seconds over which to
    ///     interpolate changes to the duration.
    /// - Returns: a spring animation.
    @_alwaysEmitIntoClient
    public static func spring(duration: TimeInterval = 0.5, bounce: Double = 0.0, blendDuration: Double = 0) -> Animation {
        return .spring(response: duration,
                       dampingFraction: springDampingFraction(bounce: bounce),
                       blendDuration: blendDuration)
    }
    
    /// A convenience for a `spring` animation with a lower
    /// `duration` value, intended for driving interactive animations.
    ///
    /// This uses the default parameter values.
    @_alwaysEmitIntoClient
    public static var interactiveSpring: Animation {
        interactiveSpring()
    }
    
    /// A convenience for a `spring()` animation with a lower
    /// `response` value, intended for driving interactive animations.
    @_disfavoredOverload
    public static func interactiveSpring(response: Double = 0.15, dampingFraction: Double = 0.86, blendDuration: Double = 0.25) -> Animation {
        Animation(internal: FluidSpringAnimation(response: response,
                                                 dampingFraction: dampingFraction,
                                                 blendDuration: blendDuration))
    }
    
    
    /// A convenience for a `spring` animation with a lower
    /// `response` value, intended for driving interactive animations.
    @_alwaysEmitIntoClient
    public static func interactiveSpring(duration: TimeInterval = 0.15, extraBounce: Double = 0.0, blendDuration: TimeInterval = 0.25) -> Animation {
        spring(duration: duration,
               bounce: 0.15 + extraBounce,
               blendDuration: blendDuration)
    }
    
    /// A smooth spring animation with a predefined duration and no bounce.
    @_alwaysEmitIntoClient
    public static var smooth: Animation {
        smooth()
    }
    
    /// A smooth spring animation with a predefined duration and no bounce
    /// that can be tuned.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - extraBounce: How much additional bounce should be added to the base
    ///     bounce of 0.
    ///   - blendDuration: The duration in seconds over which to interpolate
    ///     changes to the duration.
    @_alwaysEmitIntoClient
    public static func smooth(duration: TimeInterval = 0.5,
                              extraBounce: Double = 0.0) -> Animation {
        spring(duration: duration, bounce: extraBounce)
    }
    
    /// A spring animation with a predefined duration and small amount of
    /// bounce that feels more snappy.
    @_alwaysEmitIntoClient
    public static var snappy: Animation {
        snappy()
    }
    
    /// A spring animation with a predefined duration and small amount of
    /// bounce that feels more snappy and can be tuned.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - extraBounce: How much additional bounce should be added to the base
    ///     bounce of 0.15.
    ///   - blendDuration: The duration in seconds over which to interpolate
    ///     changes to the duration.
    @_alwaysEmitIntoClient
    public static func snappy(duration: TimeInterval = 0.5,
                              extraBounce: Double = 0.0) -> Animation {
        spring(duration: duration, bounce: 0.15 + extraBounce)
    }
    
    /// A spring animation with a predefined duration and higher amount of
    /// bounce.
    @_alwaysEmitIntoClient
    public static var bouncy: Animation {
        bouncy()
    }
    
    /// A spring animation with a predefined duration and higher amount of
    /// bounce that can be tuned.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - extraBounce: How much additional bounce should be added to the base
    ///     bounce of 0.3.
    ///   - blendDuration: The duration in seconds over which to interpolate
    ///     changes to the duration.
    @_alwaysEmitIntoClient
    public static func bouncy(duration: TimeInterval = 0.5,
                              extraBounce: Double = 0.0) -> Animation {
        spring(duration: duration, bounce: 0.3 + extraBounce)
    }
    
}
