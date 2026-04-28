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

private let tau: Double = 2*Double.pi

/// A representation of a spring's motion.
///
/// Use this type to convert between different representations of spring
/// parameters:
///
///     let spring = Spring(duration: 0.5, bounce: 0.3)
///     let (mass, stiffness, damping) = (spring.mass, spring.stiffness, spring.damping)
///     // (1.0, 157.9, 17.6)
///
///     let spring2 = Spring(mass: 1, stiffness: 100, damping: 10)
///     let (duration, bounce) = (spring2.duration, spring2.bounce)
///     // (0.63, 0.5)
///
/// You can also use it to query for a spring's position and its other properties for
/// a given set of inputs:
///
///     func unitPosition(time: TimeInterval) -> Double {
///         let spring = Spring(duration: 0.5, bounce: 0.3)
///         return spring.position(target: 1.0, time: time)
///     }
@available(iOS 13.0, *)
public struct Spring : Hashable {

    internal var angularFrequency: Double

    internal var decayConstant: Double

    internal var _mass: Double
}

/// Duration/Bounce Parameters
@available(iOS 13.0, *)
extension Spring {

    /// Creates a spring with the specified duration and bounce.
    ///
    /// - Parameters:
    ///   - duration: Defines the pace of the spring. This is approximately
    ///   equal to the settling duration, but for springs with very large
    ///   bounce values, will be the duration of the period of oscillation
    ///   for the spring.
    ///   - bounce: How bouncy the spring should be. A value of 0 indicates
    ///   no bounces (a critically damped spring), positive values indicate
    ///   increasing amounts of bounciness up to a maximum of 1.0
    ///   (corresponding to undamped oscillation), and negative values
    ///   indicate overdamped springs with a minimum value of -1.0.
    public init(duration: TimeInterval = 0.5, bounce: Double = 0.0) {
        self.init(response: duration,
                  dampingRatio: springDampingFraction(bounce: bounce))
    }

    /// The perceptual duration, which defines the pace of the spring.
    public var duration: TimeInterval {
        let angularFrequency: Double = .maximum(self.angularFrequency, -self.angularFrequency)
        return tau / sqrt(self.angularFrequency * angularFrequency + pow(decayConstant, 2))
    }

    /// How bouncy the spring is.
    ///
    /// A value of 0 indicates no bounces (a critically damped spring), positive
    /// values indicate increasing amounts of bounciness up to a maximum of 1.0
    /// (corresponding to undamped oscillation), and negative values indicate
    /// overdamped springs with a minimum value of -1.0.
    public var bounce: Double {
        let halfDecayConstant = decayConstant * 0.5
        if angularFrequency >= 0 {
            return (((-tau / sqrt(pow(angularFrequency, 2) + pow(decayConstant, 2))) * halfDecayConstant) / Double.pi) + 1
        } else {
            return (1 / (((tau / sqrt(pow(decayConstant, 2) - pow(angularFrequency, 2))) * halfDecayConstant) / Double.pi)) - 1
        }
    }
}

/// Response/DampingRatio Parameters
@available(iOS 13.0, *)
extension Spring {

    /// Creates a spring with the specified response and damping ratio.
    ///
    /// - Parameters:
    ///   - response: Defines the stiffness of the spring as an approximate
    ///   duration in seconds.
    ///   - dampingRatio: Defines the amount of drag applied as a fraction the
    ///   amount needed to produce critical damping.
    public init(response: Double, dampingRatio: Double) {
        let t = dampingRatio > 1 ? -tau : tau
        angularFrequency = ((sqrt(abs(1 - pow(dampingRatio, 2)))) * t) / response
        decayConstant = (tau * dampingRatio) / response
        _mass = 1
    }

    /// The stiffness of the spring, defined as an approximate duration in
    /// seconds.
    public var response: Double {
        duration
    }

    /// The amount of drag applied, as a fraction of the amount needed to
    /// produce critical damping.
    ///
    /// When `dampingRatio` is 1, the spring will smoothly decelerate to its
    /// final position without oscillating. Damping ratios less than 1 will
    /// oscillate more and more before coming to a complete stop.
    public var dampingRatio: Double {
        let halfDecayConstant = decayConstant * 0.5
        let angularFrequency: Double = .maximum(-self.angularFrequency, self.angularFrequency)
        return ((tau / sqrt((angularFrequency * self.angularFrequency) + pow(decayConstant, 2))) * halfDecayConstant) / Double.pi
    }
}

/// Mass/Stiffness/Damping Parameters
@available(iOS 13.0, *)
extension Spring {

    /// Creates a spring with the specified mass, stiffness, and damping.
    ///
    /// - Parameters:
    ///   - mass: Specifies that property of the object attached to the end of
    ///   the spring.
    ///   - stiffness: The corresponding spring coefficient.
    ///   - damping: Defines how the spring's motion should be damped due to the
    ///   forces of friction.
    ///   - allowOverdamping: A value of true specifies that over-damping
    ///   should be allowed when appropriate based on the other inputs, and a
    ///   value of false specifies that such cases should instead be treated as
    ///   critically damped.
    public init(mass: Double = 1.0, stiffness: Double, damping: Double, allowOverDamping: Bool = false) {
        let decayConstant = sqrt(stiffness / mass)
        let angularFrequency = mass * 2
        let overDampingDecayConstant = damping / angularFrequency
        guard allowOverDamping || overDampingDecayConstant <= decayConstant else {
            self.angularFrequency = 0
            self.decayConstant = decayConstant
            self._mass = mass
            return
        }
        let overDampingAngularFrequency = sqrt(abs((stiffness / mass) - pow(overDampingDecayConstant, 2)))
        self.angularFrequency = decayConstant < overDampingDecayConstant ? -overDampingAngularFrequency : overDampingAngularFrequency
        self.decayConstant = overDampingDecayConstant
        self._mass = mass
        
    }

    /// The mass of the object attached to the end of the spring.
    ///
    /// The default mass is 1. Increasing this value will increase the spring's
    /// effect: the attached object will be subject to more oscillations and
    /// greater overshoot, resulting in an increased settling duration.
    /// Decreasing the mass will reduce the spring effect: there will be fewer
    /// oscillations and a reduced overshoot, resulting in a decreased
    /// settling duration.
    public var mass: Double {
        _mass
    }

    /// The spring stiffness coefficient.
    ///
    /// Increasing the stiffness reduces the number of oscillations and will
    /// reduce the settling duration. Decreasing the stiffness increases the the
    /// number of oscillations and will increase the settling duration.
    public var stiffness: Double {
        (pow(angularFrequency, 2) + pow(decayConstant, 2)) * _mass
    }

    /// Defines how the spring’s motion should be damped due to the forces of
    /// friction.
    ///
    /// Reducing this value reduces the energy loss with each oscillation: the
    /// spring will overshoot its destination. Increasing the value increases
    /// the energy loss with each duration: there will be fewer and smaller
    /// oscillations.
    public var damping: Double {
        decayConstant * 2 * _mass
    }
}

/// SettlingDuration/DampingRatio Parameters
@available(iOS 13.0, *)
extension Spring {

    /// Creates a spring with the specified duration and damping ratio.
    ///
    /// - Parameters:
    ///   - settlingDuration: The approximate time it will take for the spring
    ///   to come to rest.
    ///   - dampingRatio: The amount of drag applied as a fraction of the amount
    ///   needed to produce critical damping.
    ///   - epsilon: The threshhold for how small all subsequent values need to
    ///   be before the spring is considered to have settled.
    public init(settlingDuration: TimeInterval, 
                dampingRatio: Double,
                epsilon: Double = 0.001) {
        let duration: Double = .minimum(.maximum(settlingDuration, 0.01), 10)
        let dampingRatio: Double = .minimum(.maximum(dampingRatio, 2.22045e-16), 1)
        var decayConstant = 0.0
        var value2 = 0
        var value3 = 0
        let body1: (Double) -> Double
        let body2: (Double) -> Double
        if dampingRatio >= 1 {
            let v50 = pow(duration, 2)
            body1 = { value in
                let ep = value < 0 ? -epsilon : epsilon
                let v = (duration * value) + 1
                return exp(-duration * value) * v - ep
            }
            body2 = { value in
                return ((0 - value) * v50) / exp(value * duration)
            }
        } else {
            let v60 = duration * dampingRatio
            let v50 = sqrt(1 - pow(dampingRatio, 2))
            func clouse3(_ value: Double) -> Double {
                let result = {
                    value * v50
                }
                return ((dampingRatio * value) - 0) / result()
            }
            body1 = { value in
                return epsilon - fabs(exp(-v60 * value) * clouse3(value))
            }
            body2 = { value in
                let dampedOscillation = (exp(-v60 * value) * clouse3(value))
                let zeroTerm = ((0 * value) + 0)
                let dampingSquaredTerm = -(zeroTerm - (pow(dampingRatio, 2) * pow(value, 2)))
                let selectedTerm = 0 <= dampedOscillation ? dampingSquaredTerm : zeroTerm
                return selectedTerm / (exp(value * v60) * (pow(value, 2) * v50))
            }
        }
        
        let result = process(12,
                             value: &decayConstant,
                             value2: &value2,
                             value3: &value3,
                             some: 5.0,
                             duartion: duration,
                             epsilon: epsilon,
                             body1: body1,
                             body2: body2)
        
        if !result {
            _ = process(20,
                        value: &decayConstant,
                        value2: &value2,
                        value3: &value3,
                        some: 1.0,
                        duartion: duration,
                        epsilon: epsilon,
                        body1: body1,
                        body2: body2)
        }
        let newDecayConstant = (((decayConstant * 2) * dampingRatio) * 0.5)
        var angularFrequency = 0.0
        if newDecayConstant <= decayConstant {
            angularFrequency = sqrt(fabs(pow(decayConstant, 2) - pow(newDecayConstant, 2)))
            decayConstant = newDecayConstant
        }
        self.angularFrequency = angularFrequency
        self.decayConstant = decayConstant
        self._mass = 1
        
        func process(_ count: Int, 
                     value: inout Double,
                     value2: inout Int,
                     value3: inout Int,
                     some: Double,
                     duartion: Double,
                     epsilon: Double,
                     body1: (Double) -> Double,
                     body2: (Double) -> Double) -> Bool {
            value = (1 / duration) * some
            var index = 0
            var largeChangeDetected = false
            while index != count {
                let oldValue = value
                let result1 = body1(value)
                let result2 = body2(value)
                value -= (result1 / result2)
                guard value.isFinite else {
                    value2 &+= 1
                    return false
                }
                if index > 1 && epsilon >= fabs(value - oldValue) {
                    guard !largeChangeDetected else {
                        value3 &+= 1
                        return false
                    }
                    return true

                }
                largeChangeDetected = (oldValue - value) > (epsilon * 100000.0)
                index += 1
            }
            return true
        }
        
    }
}

/// VectorArithmetic Evaluation
@available(iOS 13.0, *)
extension Spring {
    
    /// The estimated duration required for the spring system to be considered
    /// at rest.
    ///
    /// This uses a `target` of 1.0, an `initialVelocity` of 0, and an `epsilon`
    /// of 0.001.
    public var settlingDuration: TimeInterval {
        settlingDuration(target: 1, epsilon: 0.001)
    }
    
    /// The estimated duration required for the spring system to be considered
    /// at rest.
    ///
    /// The epsilon value specifies the threshhold for how small all subsequent
    /// values need to be before the spring is considered to have settled.
    public func settlingDuration<V>(target: V,
                                    initialVelocity: V = .zero,
                                    epsilon: Double) -> TimeInterval where V: VectorArithmetic {
        guard decayConstant != 0 else {
            return .infinity
        }
        guard angularFrequency <= 0 else {
            let newTarget = target.scaled(by: decayConstant) - initialVelocity
            let duration = -log(epsilon / (sqrt(target.magnitudeSquared) + sqrt(newTarget.magnitudeSquared))) / decayConstant
            return .maximum(duration, 0)
        }
        var count = 1024
        var time = 0.0
        var duration: Double = .infinity
        var currentDuration: Double = -1
        repeat {
            let value = value(target: target,
                              initialVelocity: initialVelocity,
                              time: time)
            let maxDuration = sqrt((target - value).magnitudeSquared)
            guard maxDuration.isFinite else {
                return 0
            }
            if duration >= epsilon {
                currentDuration = maxDuration < duration ? time : currentDuration
                duration = Double.minimum(maxDuration, duration)
            } else if maxDuration >= epsilon {
                duration = .infinity
            } else {
                guard (time - currentDuration) <= 1 else {
                    return currentDuration
                }
            }
            time += 0.1
            count -= 1
        } while count > 0
        return 0
    }

    /// Calculates the value of the spring at a given time given a target
    /// amount of change.
    public func value<V: VectorArithmetic>(target: V, initialVelocity: V = .zero, time: TimeInterval) -> V {
        var newTarget = target
        var velocityValue = initialVelocity
        if angularFrequency >= 0 {
            if angularFrequency == 0 {
                newTarget = newTarget.scaled(by: decayConstant)
                var currentTarget = newTarget - initialVelocity
                currentTarget = currentTarget.scaled(by: time)
                let overTarget = target + currentTarget
                let decayOverTarget = overTarget.scaled(by: exp(-decayConstant * time))
                return target - decayOverTarget
            } else {
                newTarget = newTarget.scaled(by: decayConstant)
                var currentTarget = newTarget - initialVelocity
                var totalTarget = target
                let sincos = __sincos_stret(angularFrequency * time)
                totalTarget = totalTarget.scaled(by: sincos.__cosval)
                currentTarget = currentTarget.scaled(by: sincos.__sinval / angularFrequency)
                var decayOverTarget = totalTarget + currentTarget
                decayOverTarget = decayOverTarget.scaled(by: exp(-decayConstant * time))
                return target - decayOverTarget
            }
        } else {
            let v38 = exp((-angularFrequency - decayConstant) * time)
            let v40 = exp((angularFrequency - decayConstant) * time)
            let weightedDecayTerm = (decayConstant - angularFrequency) * v38
            let combinedWeightedDecay = (-angularFrequency - decayConstant) * v40 + weightedDecayTerm

            let targetFraction = (combinedWeightedDecay / (angularFrequency * 2)) + 1
            newTarget = newTarget.scaled(by: targetFraction)
            let velocityFraction = (v38 - v40) / (angularFrequency * 2)
            velocityValue = velocityValue.scaled(by: velocityFraction)
            return newTarget - velocityValue
        }
    }

    /// Calculates the velocity of the spring at a given time given a target
    /// amount of change.
    public func velocity<V: VectorArithmetic>(target: V, initialVelocity: V = .zero, time: TimeInterval) -> V {
        if angularFrequency >= 0  {
            if angularFrequency == 0 {
                var vA = target
                vA.scale(by: decayConstant)
                vA -= initialVelocity
                
                var vB = target
                vB.scale(by: decayConstant * exp(-decayConstant * time))
                vA.scale(by: ((decayConstant * time) - 1) * exp(-decayConstant * time))
                
                return vA + vB
            } else {
                
                let v = target.scaled(by: decayConstant) - initialVelocity

                let sincos = __sincos_stret(angularFrequency * time)
                let targetScale = ((sincos.__sinval * angularFrequency) + (sincos.__cosval * decayConstant)) * exp(-decayConstant * time)
                let newTarget = target.scaled(by: targetScale)
                
                let velocityScale = (((sincos.__sinval * decayConstant) - (sincos.__cosval * angularFrequency)) * exp(-decayConstant * time)) / angularFrequency
                let newVelocity = v.scaled(by: velocityScale)
                
                return newTarget + newVelocity
            }
        } else {
            let expDecayFactors = (exp((-angularFrequency - decayConstant) * time), exp((angularFrequency - decayConstant) * time))
            let v1 = (expDecayFactors.0 * (-angularFrequency - decayConstant), expDecayFactors.1 * (angularFrequency - decayConstant))
            let targetScale = ((decayConstant - angularFrequency) * v1.0 + (-angularFrequency - decayConstant) * v1.1) / (angularFrequency * 2) + 1
            let newTarget = target.scaled(by: targetScale)
            let velocityScale = ((expDecayFactors.0 * (-angularFrequency - decayConstant)) - (expDecayFactors.1 * (angularFrequency - decayConstant))) / (angularFrequency * 2)
            let newVelocity = initialVelocity.scaled(by: velocityScale)
            return newTarget - newVelocity
        }
    }

    /// Updates the current  value and velocity of a spring.
    ///
    /// - Parameters:
    ///   - value: The current value of the spring.
    ///   - velocity: The current velocity of the spring.
    ///   - target: The target that `value` is moving towards.
    ///   - deltaTime: The amount of time that has passed since the spring was
    ///     at the position specified by `value`.
    public func update<V: VectorArithmetic>(value: inout V, velocity: inout V, target: V, deltaTime: TimeInterval) {
        let newVelocity = self.velocity(target: target - value, initialVelocity: velocity, time: deltaTime)
        value = self.value(target: target - value, initialVelocity: velocity, time: deltaTime)
        velocity = newVelocity
    }

    /// Calculates the force upon the spring given a current position, target,
    /// and velocity amount of change.
    ///
    /// This value is in units of the vector type per second squared.
    public func force<V: VectorArithmetic>(target: V, position: V, velocity: V) -> V {
        
        let velocityScale = (decayConstant * -2) * _mass
        let newVelocity = velocity.scaled(by: velocityScale)
        let t = target - position
        let targetSacle = (pow(decayConstant, 2) + pow(angularFrequency, 2)) * _mass
        let newTarget = t.scaled(by: targetSacle)
        
        return newVelocity + newTarget
    }
}

/// Animatable Evaluation
@available(iOS 13.0, *)
extension Spring {
    
    /// The estimated duration required for the spring system to be considered
    /// at rest.
    ///
    /// The epsilon value specifies the threshhold for how small all subsequent
    /// values need to be before the spring is considered to have settled.
    public func settlingDuration<V>(fromValue: V,
                                    toValue: V,
                                    initialVelocity: V,
                                    epsilon: Double) -> TimeInterval where V: Animatable {
        settlingDuration(target: toValue.animatableData - fromValue.animatableData,
                         initialVelocity: initialVelocity.animatableData,
                         epsilon: epsilon)
    }

    /// Calculates the value of the spring at a given time for a starting
    /// and ending value for the spring to travel.
    public func value<V: Animatable>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V {
        var animatableValue = fromValue
        let vectorValue = value(target: toValue.animatableData - fromValue.animatableData, initialVelocity: initialVelocity.animatableData, time: time)
        animatableValue.animatableData = vectorValue
        return animatableValue
    }

    /// Calculates the velocity of the spring at a given time given a starting
    /// and ending value for the spring to travel.
    public func velocity<V: Animatable>(fromValue: V, toValue: V, initialVelocity: V, time: TimeInterval) -> V {
        var animatableVelocity = fromValue
        let vectorValue = velocity(target: toValue.animatableData - fromValue.animatableData, initialVelocity: initialVelocity.animatableData, time: time)
        animatableVelocity.animatableData = vectorValue
        return animatableVelocity
    }

    /// Calculates the force upon the spring given a current position,
    /// velocity, and divisor from the starting and end values for the spring to travel.
    ///
    /// This value is in units of the vector type per second squared.
    public func force<V: Animatable>(fromValue: V, toValue: V, position: V, velocity: V) -> V {
        var animatableForce = fromValue
        let vectorValue = force(target: toValue.animatableData - fromValue.animatableData, position: position.animatableData, velocity: velocity.animatableData)
        animatableForce.animatableData = vectorValue
        return animatableForce
    }
}

@available(iOS 13.0, *)
extension Spring {

    /// A smooth spring with a predefined duration and no bounce.
    @_alwaysEmitIntoClient
    public static var smooth: Spring {
        .init()
    }

    /// A smooth spring with a predefined duration and no bounce that can be
    /// tuned.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - extraBounce: How much additional bounce should be added to the base
    ///     bounce of 0.
    @_alwaysEmitIntoClient
    public static func smooth(duration: TimeInterval = 0.5, extraBounce: Double = 0.0) -> Spring {
        .init(duration: duration, bounce: extraBounce)
    }

    /// A spring with a predefined duration and small amount of bounce that
    /// feels more snappy.
    @_alwaysEmitIntoClient
    public static var snappy: Spring {
        .init(bounce: 0.15)
    }

    /// A spring with a predefined duration and small amount of bounce that
    /// feels more snappy and can be tuned.
    ///
    /// - Parameters:
    ///   - duration: The perceptual duration, which defines the pace of the
    ///     spring. This is approximately equal to the settling duration, but
    ///     for very bouncy springs, will be the duration of the period of
    ///     oscillation for the spring.
    ///   - extraBounce: How much additional bounciness should be added to the
    ///     base bounce of 0.15.
    @_alwaysEmitIntoClient
    public static func snappy(duration: TimeInterval = 0.5, extraBounce: Double = 0.0) -> Spring {
        .init(duration: duration, bounce: extraBounce + 0.15)
    }

    /// A spring with a predefined duration and higher amount of bounce.
    @_alwaysEmitIntoClient
    public static var bouncy: Spring {
        .init(bounce: 0.3)
    }

    /// A spring with a predefined duration and higher amount of bounce that
    /// can be tuned.
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
    public static func bouncy(duration: TimeInterval = 0.5, extraBounce: Double = 0.0) -> Spring {
        .init(duration: duration, bounce: extraBounce + 0.3)
    }
}

@available(iOS 13.0, *)
extension Animation {

    /// A persistent spring animation.
    ///
    /// When mixed with other `spring()`
    /// or `interactiveSpring()` animations on the same property, each
    /// animation will be replaced by their successor, preserving
    /// velocity from one animation to the next. Optionally blends the
    /// duration values between springs over a time period.
    public static func spring(_ spring: Spring, blendDuration: TimeInterval = 0.0) -> Animation {
        Animation(internal: FluidSpringAnimation(response: spring.response,
                                                 dampingFraction: springDampingFraction(bounce: spring.bounce),
                                                 blendDuration: blendDuration))
    }

    /// An interpolating spring animation that uses a damped spring
    /// model to produce values in the range of one to zero.
    ///
    /// These vales are used to interpolate within the `[from, to]` range
    /// of the animated
    /// property. Preserves velocity across overlapping animations by
    /// adding the effects of each animation.
    public static func interpolatingSpring(_ spring: Spring, initialVelocity: Double = 0.0) -> Animation {
        Animation(internal: SpringAnimation(mass: 1, stiffness: spring.stiffness, damping: spring.damping, initialVelocity: .init(valuePerSecond: initialVelocity)))
    }
}

@_alwaysEmitIntoClient
internal func springStiffness(response: Double) -> Double {
    if response <= 0 {
        return .infinity
    } else {
        let freq = (2.0 * Double.pi) / response
        return freq * freq
    }
}
@_alwaysEmitIntoClient
internal func springDamping(fraction: Double, stiffness: Double) -> Double {
    let criticalDamping = 2 * stiffness.squareRoot()
    return criticalDamping * fraction
}
@_alwaysEmitIntoClient
internal func springDampingFraction(bounce: Double) -> Double {
    (bounce < 0.0) ? 1.0 / (bounce + 1.0) : 1.0 - bounce
}
