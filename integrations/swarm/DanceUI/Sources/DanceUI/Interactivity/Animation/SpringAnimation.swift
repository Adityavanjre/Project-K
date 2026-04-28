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
private let epsilon: Double = 0.001
@available(iOS 13.0, *)
private let tau: Double = 2*Double.pi
@available(iOS 13.0, *)
private let minEpsilon: Double = 1.0 / pow(2, 20)

@available(iOS 13.0, *)
internal struct SpringAnimation: Hashable, InternalCustomAnimation {

    internal var mass: Double

    internal var stiffness: Double

    internal var damping: Double

    internal var initialVelocity: _Velocity<Double>
    
    internal func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
        let model = SpringModel(self)
        let duration = model.duration(epsilon: epsilon)
        guard duration > time else {
            return nil
        }
        let sample = model.sample(at: time)
        guard sample.isFinite else {
            return nil
        }
        var endTime = 0.0
        
        if stiffness.isFinite {
            endTime = tau / sqrt(stiffness)
        }
        if time >= endTime {
            context.isLogicallyComplete = true
        }
        return value.scaled(by: sample)
    }
        
}

@available(iOS 13.0, *)
private struct SpringModel {
    
    internal let angularFrequency: Double
    internal let dampingRatio: Double
    internal let decayFactor: Double
    internal let constant: Double
    internal let adjustedFrequency: Double
    
    internal init(_ spring: SpringAnimation) {
        let angularFrequency = sqrt(spring.stiffness / spring.mass)
        let dampingRatio = spring.damping / (sqrt(spring.mass * spring.stiffness) * 2)
        let decayFactor: Double
        let adjustedFrequency: Double
        if dampingRatio >= 1 {
            decayFactor = 0
            adjustedFrequency = angularFrequency - spring.initialVelocity.valuePerSecond
        } else {
            decayFactor =  sqrt(1 - pow(dampingRatio, 2)) * angularFrequency
            adjustedFrequency = ((angularFrequency * dampingRatio) - spring.initialVelocity.valuePerSecond) / decayFactor
        }
        self.angularFrequency = angularFrequency
        self.dampingRatio = dampingRatio
        self.decayFactor = decayFactor
        self.constant = 1
        self.adjustedFrequency = adjustedFrequency
    }
    
    internal func duration(epsilon: Double) -> Double {
        let epsilon = epsilon <= minEpsilon ? minEpsilon : epsilon
        guard self.dampingRatio != 0 else {
            return .infinity
        }
        guard self.dampingRatio >= 1 else {
            let v = epsilon / (fabs(constant) + fabs(adjustedFrequency))
            let duration = -log(v) / (self.dampingRatio * self.angularFrequency)
            return .maximum(duration, 0)
        }
        var time = 0.0
        var minValue: Double = .infinity
        var minTime: Double = -1
        var count = 0x400
        while count != 0 {
            let totalForce: Double
            let exponentialDecay: Double
            if self.dampingRatio >= 1 {
                totalForce = (adjustedFrequency * time) + constant
                exponentialDecay = exp(-time * angularFrequency)
            } else {
                totalForce = exp((angularFrequency * -dampingRatio) * time)
                let sincos = __sincos_stret(decayFactor * time)
                exponentialDecay = (constant * sincos.__sinval) + (adjustedFrequency * sincos.__cosval)
            }
            
            let value = fabs(((exponentialDecay * totalForce) - 1) + 1)
            guard value.isFinite else {
                return 0
            }
            if epsilon <= minValue {
                minTime = value < minValue ? time : minTime
                minValue = .minimum(value, minValue)
            } else if epsilon <= value {
                minValue = .infinity
            } else {
                guard time - minTime <= 1 else {
                    return minTime
                }
            }
            time += 0.1
            count &-= 1
        }
        return 0
    }
    
    internal func sample(at time: Double) -> Double {
        let amplitudeFactor: Double
        let exponentialDecay: Double
        if dampingRatio >= 1 {
            amplitudeFactor = (adjustedFrequency * time) + constant
            exponentialDecay = exp(-time * angularFrequency)
        } else {
            amplitudeFactor = exp((-dampingRatio * angularFrequency) * time)
            let sincos = __sincos_stret(decayFactor * time)
            exponentialDecay = (constant * sincos.__cosval) + (adjustedFrequency * sincos.__sinval)
        }
        return 1 - (amplitudeFactor * exponentialDecay)
    }
}

@available(iOS 13.0, *)
extension Animation {
    
    /// An interpolating spring animation that uses a damped spring
    /// model to produce values in the range [0, 1] that are then used
    /// to interpolate within the [from, to] range of the animated
    /// property. Preserves velocity across overlapping animations by
    /// adding the effects of each animation.
    ///
    /// - Parameters:
    ///   - mass: The mass of the object attached to the spring.
    ///   - stiffness: The stiffness of the spring.
    ///   - damping: The spring damping value.
    ///   - initialVelocity: the initial velocity of the spring, as
    ///     a value in the range [0, 1] representing the magnitude of
    ///     the value being animated.
    /// - Returns: a spring animation.
    public static func interpolatingSpring(mass: Double = 1.0, stiffness: Double, damping: Double, initialVelocity: Double = 0.0) -> Animation {
        Animation(internal: SpringAnimation(mass: mass, 
                                            stiffness: stiffness,
                                            damping: damping,
                                            initialVelocity: .init(valuePerSecond: initialVelocity)))
    }
    
    /// An interpolating spring animation that uses a damped spring
    /// model to produce values in the range [0, 1] that are then used
    /// to interpolate within the [from, to] range of the animated
    /// property. Preserves velocity across overlapping animations by
    /// adding the effects of each animation.
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
    ///   - initialVelocity: the initial velocity of the spring, as
    ///     a value in the range [0, 1] representing the magnitude of
    ///     the value being animated.
    /// - Returns: a spring animation.
    @_alwaysEmitIntoClient
    public static func interpolatingSpring(duration: TimeInterval = 0.5, bounce: Double = 0.0, initialVelocity: Double = 0.0) -> Animation {
        let stiffness = springStiffness(response: duration)
        let fraction = springDampingFraction(bounce: bounce)
        let damping = springDamping(fraction: fraction, stiffness: stiffness)
        return interpolatingSpring(
            stiffness: stiffness, 
            damping: damping,
            initialVelocity: initialVelocity)
    }
    
    /// An interpolating spring animation that uses a damped spring
    /// model to produce values in the range [0, 1] that are then used
    /// to interpolate within the [from, to] range of the animated
    /// property. Preserves velocity across overlapping animations by
    /// adding the effects of each animation.
    ///
    /// This uses the default parameter values.
    @_alwaysEmitIntoClient 
    public static var interpolatingSpring: Animation {
        .interpolatingSpring()
    }
}
