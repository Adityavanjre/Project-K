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

import Accelerate

@available(iOS 13.0, *)
internal struct AnimationPath<Value: Animatable> {

    internal var elements : [Element]
    
    internal init(_ body: (_ path: inout AnimationPath) -> Void) {
        var path = AnimationPath()
        body(&path)
        self = path
    }
    
    private init() {
        elements = []
    }
    
    internal var duration: Double {
        elements.reduce(0, {$0 + $1.duration})
    }
    
    internal mutating func append(_ element: Element) {
        elements.append(element)
    }
    
    internal func currentVelocity() -> Value.AnimatableData {
        guard let last = elements.last else {
            return .zero
        }
        return last.endVelocity
    }
    
    internal func animatableData(at duration: Double) -> Value.AnimatableData {
        var duration = duration
        for element in elements {
            let elementDuration = element.duration
            guard element.duration < duration else {
                return element.animatableData(at: duration)
            }
            duration -= elementDuration
        }
        let value: Value.AnimatableData
        if let element = elements.last {
            value = element.end
        } else {
            value = .zero
        }
        return value
    }
    
    internal func velocity(at duration: Double) -> Value.AnimatableData {
        var duration = duration
        for element in elements {
            let elementDuration = element.duration
            guard element.duration < duration else {
                return element.velocity(at: duration)
            }
            
            duration -= elementDuration
        }
        return .zero

    }

    internal enum Element {
        
        case curve(CurveElement)
        
        case spring(SpringElement)
        
        case move(Value.AnimatableData)
        
        @inline(__always)
        internal var end: Value.AnimatableData {
            switch self {
            case .curve(let curve):
                curve.curve.end
            case .spring(let spring):
                spring.end
            case .move(let value):
                value
            }
        }
        
        internal var endVelocity: Value.AnimatableData {
            switch self {
            case .curve(let curve):
                let curveVelociy = curve.curve.velocity(at: 1.0)
                if curve.constantVelocity {
                    let arcLength = curve.curve.arcLength
                    let velocityScale = 1 / sqrt(arcLength)
                    let scaledVelocity = curveVelociy.scaled(by: velocityScale)
                    let velocity = scaledVelocity.scaled(by: arcLength / curve.duration)
                    let timingScale = curve.timingCurve.velocity(at: 1.0)
                    return velocity.scaled(by: timingScale)
                } else {
                    let timingScale = curve.timingCurve.velocity(at: 1.0)
                    let scaledVelocity = curveVelociy.scaled(by: timingScale)
                    let velocityScale = 1 / curve.duration
                    return scaledVelocity.scaled(by: velocityScale)
                }
            case .spring(let spring):
                return spring.spring.velocity(target: spring.to - spring.from,
                                              initialVelocity: spring.initialVelocity,
                                              time: spring.duration)
            case .move:
                return .zero
            }
        }
        
        internal var duration: Double {
            switch self {
            case .curve(let curve):
                curve.duration
            case .spring(let spring):
                spring.duration
            case .move:
                0
            }
        }
        
        internal func animatableData(at duration: Double) -> Value.AnimatableData {
            switch self {
            case .curve(let curve):
                guard duration >= 0 else {
                    return curve.curve.start
                }
                guard self.duration >= duration else {
                    return curve.curve.end
                }
                let progress = duration / curve.duration
                let curveProgress = curve.timingCurve.value(at: progress)
                if curve.constantVelocity {
                    let arcLength = curve.curve.arcLength * curveProgress
                    return curve.curve.value(atArcLength: arcLength)
                } else {
                    return curve.curve.value(at: curveProgress)
                }
            case .spring(let spring):
                let value = spring.spring.value(target: spring.to - spring.from,
                                                initialVelocity: spring.initialVelocity,
                                                time: duration)
                return spring.from + value
            case .move(let animatableData):
                return animatableData
            }
        }
        
        internal func velocity(at duration: Double) -> Value.AnimatableData {
            switch self {
            case .curve(let curve):
                guard curve.duration > 0,
                        duration >= 0,
                        duration <= curve.duration else {
                    return .zero
        }
                let progress = duration / curve.duration
                let valueProgress = curve.timingCurve.value(at: progress)
                let velocityProgress = curve.timingCurve.velocity(at: progress)
                if curve.constantVelocity {
                    let arcLength = curve.curve.arcLength * valueProgress
                    return curve.curve.velocity(atArcLength: arcLength)
                } else {
                    var totalValue = curve.curve.velocity(at: valueProgress)
                    totalValue.scale(by: 1 / curve.duration)
                    return totalValue.scaled(by: velocityProgress)
                }
            case .spring(let spring):
                return spring.spring.velocity(target: spring.to - spring.from,
                                              initialVelocity: spring.initialVelocity,
                                              time: duration)
            case .move:
                
                return .zero
        
            }
        }
        
        
    }
    
    @available(iOS 13.0, *)
    internal struct CurveElement: Equatable {

        internal var curve: HermiteCurve<Value>

        internal var duration: Double

        internal var constantVelocity: Bool

        internal var timingCurve: UnitCurve
    }

    @available(iOS 13.0, *)
    internal struct SpringElement: Equatable {

        internal var spring: Spring

        internal var from: Value.AnimatableData

        internal var to: Value.AnimatableData

        internal var initialVelocity: Value.AnimatableData

        internal var end: Value.AnimatableData

        internal var duration: Double

    }

}

@available(iOS 13.0, *)
internal struct HermiteCurve<Value: Animatable>: Equatable {
    
    internal static func hermite(start: Value.AnimatableData,
                                 end: Value.AnimatableData,
                                 startTangent: Value.AnimatableData,
                                 endTangent: Value.AnimatableData) -> HermiteCurve {
        HermiteCurve(start: start,
                     end: end,
                     startTangent: startTangent,
                     endTangent: endTangent)
    }
    
    private init(start: Value.AnimatableData,
                  end: Value.AnimatableData,
                  startTangent: Value.AnimatableData,
                  endTangent: Value.AnimatableData) {
        self.start = start
        self.end = end
        self.startTangent = startTangent
        self.endTangent = endTangent
    }
    
    internal init(start: Value.AnimatableData,
                  end: Value.AnimatableData) {
        self.start = start
        self.end = end
        let tangent = end - start
        self.startTangent = tangent
        self.endTangent = tangent
    }
    

    internal var start: Value.AnimatableData

    internal var end: Value.AnimatableData

    internal var startTangent: Value.AnimatableData

    internal var endTangent: Value.AnimatableData
    
    internal var arcLength: Double {
        arcLength(at: 1.0)
    }
    
    internal func arcLength(at progress: Double) -> Double {
        let from = progress >= 0 ? 0 : progress
        let to = progress >= 0 ? progress : 0
        let quadrature = Quadrature(integrator: .qags(maxIntervals: 8),
                                    absoluteTolerance: 0.05,
                                    relativeTolerance: 0.001)
        let integrate = quadrature.integrate(over: (from...to)) { value in
            0
        }
        switch integrate {
        case .success(let success):
            return progress >= 0 ? success.integralResult : -success.integralResult
        case .failure:
            return sqrt((end - start).magnitudeSquared)
        }
    }
    
    internal func value(at progress: Double) -> Value.AnimatableData {
        let p3 = pow(progress, 3)
        let p2 = pow(progress, 2)
        let startScale = (2 * p3) - (3 * p2) + 1
        let endScale = (-2 * p3) + (3 * p2)
        
        let startTangentScale = p3 - (p2 * 2) + progress
        let endTangentScale = p3 - p2
        
        let startValue = start.scaled(by: startScale)
        let endValue = end.scaled(by: endScale)
        let startTangentValue = startTangent.scaled(by: startTangentScale)
        let endTangentValue = endTangent.scaled(by: endTangentScale)
        return startValue + endValue + startTangentValue + endTangentValue
    }
    
    internal func velocity(at progress: Double) -> Value.AnimatableData {
        let p2 = pow(progress, 2)
        let startScale = (6 * p2) - (6 * progress)
        let endScale = (-6 * p2) + (6 * progress)
        let startTangentScale = (-4 * progress) + (p2 * 3) + 1
        let endTangentScale = (p2 * 3) - (progress * 2)
        
        let startValue = start.scaled(by: startScale)
        let endValue = end.scaled(by: endScale)
        let startTangentValue = startTangent.scaled(by: startTangentScale)
        let endTangentValue = endTangent.scaled(by: endTangentScale)
        
        return startValue + endValue + startTangentValue + endTangentValue
    }
    
    internal func value(atArcLength progress: Double) -> Value.AnimatableData {
        value(at: parametricTime(forArcLength: progress))
    }
    
    internal func velocity(atArcLength progress: Double) -> Value.AnimatableData {
        velocity(at: parametricTime(forArcLength: progress))
    }
    
    internal func parametricTime(forArcLength progress: Double) -> Double {
        let length = arcLength
        guard length > 0 else {
            return 0
        }
        var time = progress / length
        var arcLengthDifference = arcLength(at: time) - progress
        guard fabs(arcLengthDifference) >= 0.1 else {
            return time
        }
        for _ in 0..<10 {
            let velocity = velocity(at: time)
            time = time - (arcLengthDifference / sqrt(velocity.magnitudeSquared))
            guard time.isFinite else {
                return 0
            }
            arcLengthDifference = (arcLength(at: time) - progress)
            guard fabs(arcLengthDifference) >= 0.1 else {
                return time
            }
        }
        return time
    }
}

