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
private let epsilon: Double = 1.0 / pow(2, 20)

@available(iOS 13.0, *)
/// A  function defined by a two-dimensional curve that maps an input
/// progress in the range [0,1] to an output progress that is also in the
/// range [0,1]. By changing the shape of the curve, the effective speed
/// of an animation or other interpolation can be changed.
///
/// The horizontal (x) axis defines the input progress: a single input
/// progress value in the range [0,1] must be provided when evaluating a
/// curve.
///
/// The vertical (y) axis maps to the output progress: when a curve is
/// evaluated, the y component of the point that intersects the input progress
/// is returned.
public struct UnitCurve: Hashable {
    
    internal var function: Function
    
    /// Creates a new curve using bezier control points.
    ///
    /// The x components of the control points are clamped to the range [0,1] when
    /// the curve is evaluated.
    ///
    /// - Parameters:
    ///   - startControlPoint: The cubic Bézier control point associated with
    ///     the curve's start point at (0, 0). The tangent vector from the
    ///     start point to its control point defines the initial velocity of
    ///     the timing function.
    ///   - endControlPoint: The cubic Bézier control point associated with the
    ///     curve's end point at (1, 1). The tangent vector from the end point
    ///     to its control point defines the final velocity of the timing
    ///     function.
    public static func bezier(startControlPoint: UnitPoint, endControlPoint: UnitPoint) -> UnitCurve {
        .init(function: .bezier(startControlPoint: startControlPoint, endControlPoint: endControlPoint))
    }
    
    /// A bezier curve that starts out slowly, speeds up over the middle, then
    /// slows down again as it approaches the end.
    ///
    /// The start and end control points are located at (x: 0.42, y: 0) and
    /// (x: 0.58, y: 1).
    public static let easeInOut: UnitCurve = UnitCurve(function: .bezier(startControlPoint: UnitPoint(x: 0.42, y: 0), endControlPoint: UnitPoint(x: 0.58, y: 1)))

    /// A bezier curve that starts out slowly, then speeds up as it finishes.
    ///
    /// The start and end control points are located at (x: 0.42, y: 0) and
    /// (x: 1, y: 1).
    public static let easeIn: UnitCurve = UnitCurve(function: .bezier(startControlPoint: UnitPoint(x: 0.42, y: 0), endControlPoint: UnitPoint(x: 1, y: 1)))

    /// A bezier curve that starts out quickly, then slows down as it
    /// approaches the end.
    ///
    /// The start and end control points are located at (x: 0, y: 0) and
    /// (x: 0.58, y: 1).
    public static let easeOut: UnitCurve = UnitCurve(function: .bezier(startControlPoint: UnitPoint(x: 0, y: 0), endControlPoint: UnitPoint(x: 0.58, y: 1)))

    /// A curve that starts out slowly, then speeds up as it finishes.
    ///
    /// The shape of the curve is equal to the fourth (bottom right) quadrant
    /// of a unit circle.
    public static let circularEaseIn: UnitCurve = UnitCurve(function: .circularEaseIn)

    /// A circular curve that starts out quickly, then slows down as it
    /// approaches the end.
    ///
    /// The shape of the curve is equal to the second (top left) quadrant of
    /// a unit circle.
    public static let circularEaseOut: UnitCurve = UnitCurve(function: .circularEaseOut)

    /// A circular curve that starts out slowly, speeds up over the middle,
    /// then slows down again as it approaches the end.
    ///
    /// The shape of the curve is defined by a piecewise combination of
    /// `circularEaseIn` and `circularEaseOut`.
    public static let circularEaseInOut: UnitCurve = UnitCurve(function: .circularEaseInOut)

    /// A linear curve.
    ///
    /// As the linear curve is a straight line from (0, 0) to (1, 1),
    /// the output progress is always equal to the input progress, and
    /// the velocity is always equal to 1.0.
    public static let linear: UnitCurve = UnitCurve(function: .linear)
    
    /// Returns the output value (y component) of the curve at the given time.
    ///
    /// - Parameters:
    ///   - time: The input progress (x component). The provided value is
    ///     clamped to the range [0,1].
    ///
    /// - Returns: The output value (y component) of the curve at the given
    ///   progress.
    public func value(at progress: Double) -> Double {
        switch function {
        case .bezier:
            return function.solver.value(progress)
        case .linear:
            return progress
        case .circularEaseIn:
            return 1 - sqrt(1 - pow(progress, 2))
        case .circularEaseOut:
            return sqrt(1 - pow(progress - 1, 2))
        case .circularEaseInOut:
            if progress < 0.5 {
                return (1 - sqrt(1 - (4 * pow(progress, 2)))) * 0.5
            } else {
                return (sqrt(((8 - (4 * progress)) * progress) - 3) + 1) * 0.5
            }
        }
    }
    
    /// Returns the rate of change (first derivative) of the output value of
    /// the curve at the given time.
    ///
    /// - Parameters:
    ///   - progress: The input progress (x component). The provided value is
    ///     clamped to the range [0,1].
    ///
    /// - Returns: The velocity of the output value (y component) of the curve
    ///   at the given time.
    public func velocity(at progress: Double) -> Double {
        switch function {
        case .bezier:
            return function.solver.velocity(.minimum(.maximum(progress, 0), 1))
        case .linear:
            return 1.0
        case .circularEaseIn:
            return abs(progress / sqrt(1 - pow(progress, 2)))
        case .circularEaseOut:
            return abs((progress - 1) / sqrt(-(progress - 2) * progress))
        case .circularEaseInOut:
            if progress < 0.5 {
                return abs((progress * 2) / sqrt((-4 * pow(progress, 2)) + 1))
            } else {
                return abs(((progress * 2) - 2) / sqrt((((-4 * progress) + 8) * progress) - 3))
            }
        }
    }
    
    /// Returns a copy of the curve with its x and y components swapped.
    ///
    /// The inverse can be used to solve a curve in reverse: given a
    /// known output (y) value, the corresponding input (x) value can be found
    /// by using `inverse`:
    ///
    ///     let curve = UnitCurve.easeInOut
    ///
    ///     /// The input time for which an easeInOut curve returns 0.6.
    ///     let inputTime = curve.inverse.evaluate(at: 0.6)
    ///
    public var inverse: UnitCurve {
        switch function {
        case .linear, .circularEaseInOut:
            self
        case .circularEaseIn:
            .circularEaseOut
        case .circularEaseOut:
            .circularEaseIn
        case .bezier(let startControlPoint, let endControlPoint):
            .bezier(
                startControlPoint: UnitPoint(x: startControlPoint.y, y: startControlPoint.x),
                endControlPoint: UnitPoint(x: endControlPoint.y, y: endControlPoint.x)
            )
        }
    }
    
    @inline(__always)
    internal var solver: Function.CubicSolver {
        function.solver
    }
}

@available(iOS 13.0, *)
extension UnitCurve {
    internal enum Function: Hashable {
        
        case bezier(startControlPoint: UnitPoint, endControlPoint: UnitPoint)
        
        case linear
        
        case circularEaseIn
        
        case circularEaseOut
        
        case circularEaseInOut
        
        internal struct CubicSolver: Hashable {
            
            internal var ax: Double
            
            internal var bx: Double
            
            internal var cx: Double
            
            internal var ay: Double
            
            internal var by: Double
            
            internal var cy: Double
            
            @inline(__always)
            internal func value(_ progress: Double) -> Double {
                let p = solveX(progress, epsilon: epsilon)
                let value = round(((((ay * p) + by) * p) + cy) * p * pow(2, 20)) * epsilon
                return value
            }
            
            internal func velocity(_ progress: Double) -> Double {
                let p = solveX(progress, epsilon: epsilon)
                let derivativeX = (((ax * 3 * p) + (bx * 2)) * p + cx)
                let derivativeY = (((ay * 3 * p) + (by * 2)) * p + cy)
                guard derivativeY != derivativeX else {
                    return 1.0
                }
                if derivativeX != 0 {
                    return round((derivativeY / derivativeX) * pow(2, 20)) * epsilon
                } else {
                    return derivativeY == 0 ? -.infinity : .infinity
                }
            }
            
            internal init(startPoint: CGPoint, endPoint: CGPoint) {
                let cx = startPoint.x * 3
                let bx = (endPoint.x - startPoint.x) * 3 - cx
                let ax = 1 - cx - bx
                
                let cy = startPoint.y * 3
                let by = (endPoint.y - startPoint.y) * 3 - cy
                let ay = 1 - cy - by
                self.init(ax: ax, bx: bx, cx: cx, ay: ay, by: by, cy: cy)
            }
            
            internal init(ax: Double,
                          bx: Double,
                          cx: Double,
                          ay: Double,
                          by: Double,
                          cy: Double) {
                self.ax = ax
                self.bx = bx
                self.cx = cx
                self.ay = ay
                self.by = by
                self.cy = cy
            }
            
            internal func solveX(_ progress: Double,
                                 epsilon: Double) -> Double {
                var functionValue = ax
                functionValue *= progress
                functionValue += bx
                functionValue *= progress
                functionValue += cx
                functionValue *= progress
                functionValue -= progress
                
                var newtonValue = functionValue
                var t = progress
                guard epsilon <= abs(functionValue) else {
                    return progress
                }
                
                let derivativeA = 3 * ax
                var derivativeB = bx + bx
                
                for _ in 0..<7 {
                    var derivative = derivativeA
                    derivative *= t
                    derivative += derivativeB
                    derivative *= t
                    derivative += cx
                    guard epsilon <= abs(derivative) else {
                        break
                    }
                    newtonValue /= derivative
                    t -= newtonValue
                    newtonValue = ax
                    newtonValue *= t
                    newtonValue += bx
                    newtonValue *= t
                    newtonValue += cx
                    newtonValue *= t
                    newtonValue -= progress
                    
                    guard epsilon <= abs(newtonValue) else {
                        return t
                    }
                }
                guard progress >= 0 else {
                    return 0
                }

                guard progress <= 1 else {
                    return 1
                }
                var iterationCounter = -1023
                var upperBound = 1.0
                var lowerBound = 0.0
                t = progress
                while true {
                    let previousValue = functionValue
                    if previousValue < 0 {
                        lowerBound = t
                    } else {
                        upperBound = t
                    }
                    t = upperBound
                    t -= lowerBound
                    t *= 0.5
                    t += lowerBound
                    
                    guard iterationCounter != 0 || upperBound > lowerBound else {
                        return t
                    }
                    var bisectionValue = ax
                    bisectionValue *= t
                    bisectionValue += bx
                    bisectionValue *= t
                    bisectionValue += cx
                    bisectionValue *= t
                    bisectionValue -= progress
                    functionValue = bisectionValue
                    iterationCounter += 1
                    guard epsilon <= abs(bisectionValue) else {
                        return t
                    }
                }
            }
            
            
        }
        
        
        internal var solver: CubicSolver {
            
            switch self {
            case .bezier(startControlPoint: let start, endControlPoint: let end):
                let startPoint = CGPoint(x: .minimum(.maximum(start.x, 0), 1),
                                         y: start.y)
                let endPoint = CGPoint(x: .minimum(.maximum(end.x, 0), 1),
                                         y: end.y)
                return CubicSolver(startPoint: startPoint, endPoint: endPoint)
            case .linear:
                return CubicSolver(ax: -2, bx: 3, cx: 0, ay: -2.0, by: 3.0, cy: 0)
            case .circularEaseIn:
                return CubicSolver(ax: -0.14, bx: -0.66, cx: 1.8, ay: 0.114, by: 0.765, cy: 0.12)
            case .circularEaseOut:
                return CubicSolver(ax: 0.73, bx: 0.045, cx: 0.225, ay: 0.46, by: -1.92, cy: 2.46)
            case .circularEaseInOut:
                return CubicSolver(ax: 2.9, bx: -4.26, cx: 2.355, ay: -1.175, by: 1.77, cy: 0.405)
            }
            
        }
    }
}
