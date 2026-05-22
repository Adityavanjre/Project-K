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

@usableFromInline
@available(iOS 13.0, *)
internal struct TrimmedPath: Equatable {
    
    internal let path: Path
    
    internal let start: CGFloat
    
    internal let end: CGFloat
    
    @DestroyableBox
    internal var cachedPath: UnsafeAtomicLazy<Path.PathBox>
    
    internal init(path: Path, start: CGFloat, end: CGFloat) {
        self.path = path
        self.start = start
        self.end = end
        _cachedPath = DestroyableBox(wrappedValue: UnsafeAtomicLazy<Path.PathBox>(cache: nil))
    }
    
    @usableFromInline
    internal static func == (lhs: TrimmedPath, rhs: TrimmedPath) -> Bool {
        lhs.path == rhs.path &&
        lhs.start == rhs.start &&
        lhs.end == rhs.end
    }
    
    internal func trimmed(from: CGFloat, to: CGFloat) -> TrimmedPath {
        if from == 0 && to == 1 {
            return self
        }
        
        let diff = end - start
        let newStart = start + diff * from
        let newEnd = start + diff * to
        return TrimmedPath(path: path, start: newStart, end: newEnd)
    }
}

@available(iOS 13.0, *)
extension TrimmedPath: PathValuable {
    
    internal var cgPath: CGPath {
        if let pathBox = cachedPath.cache {
            return pathBox.cgPath
        }
        
        let trimmedPath = path.cgPath.copyTrimmedPath(from: start, to: end)
        let pathBox = Path.PathBox(trimmedPath)
        cachedPath.cache = pathBox
        return pathBox.cgPath
    }
}

@available(iOS 13.0, *)
extension CGPath {
    
    internal func copyTrimmedPath(from: CGFloat, to: CGFloat) -> CGPath {
        let fromValue = from < 0 ? 0 : min(1, from)
        let toValue = to < 0 ? 0 : min(1, to)
        
        if fromValue > 0 || toValue < 1 {
            guard toValue > fromValue else {
                return CGPath(rect: CGRect.null, transform: nil)
            }
            
            let segements = segmentLengths()
            
            guard !segements.total.isNaN else {
                return CGMutablePath()
            }
            
            guard segements.lengths.count > 0 && segements.total > 0 else {
                return CGPath(rect: CGRect.null, transform: nil)
            }
            
            let startTotalLength = segements.total * fromValue
            let endTotalLength = segements.total * toValue
            var pathAccumulator = PathAccumulator(start: .zero, current: .zero, last: nil, path: CGMutablePath())
            var index = 0
            var lastLengths: CGFloat = 0
            
            rx_applyWithBlock { elementPtr in
                let type = elementPtr.pointee.type
                let points = elementPtr.pointee.points
                switch type {
                    
                case .moveToPoint:
                    let currentPoint = points.pointee
                    pathAccumulator.start = currentPoint
                    pathAccumulator.current = currentPoint
                    
                default:
                    if endTotalLength > lastLengths &&
                        !endTotalLength.isNaN &&
                        index < segements.lengths.count {
                        var fromFraction: CGFloat = 0
                        var toFraction: CGFloat = 1
                        let currentLength = segements.lengths[index]
                        let lengths = lastLengths + currentLength
                        
                        if lastLengths < startTotalLength && currentLength > 0 {
                            fromFraction = (startTotalLength - lastLengths) / currentLength
                        }
                        
                        if endTotalLength < lengths && currentLength > 0 {
                            toFraction = (endTotalLength - lastLengths) / currentLength
                        }
                        
                        pathAccumulator.addSegment(elementPtr: elementPtr, fromFraction: fromFraction, toFraction: toFraction)
                        lastLengths = lengths
                        index += 1
                    }
                }
            }
            return pathAccumulator.path
        } else {
            return self
        }
    }
    
    fileprivate func __CubicBezierLength(startPoint: CGPoint,
                                         controlPoint1: CGPoint,
                                         controlPoint2: CGPoint,
                                         endPoint: CGPoint,
                                         arg0: CGFloat) -> CGFloat {
        return cubicBezierLength(startPointX: startPoint.x,
                                 startPointY: startPoint.y,
                                 cp1X: controlPoint1.x,
                                 cp1Y: controlPoint1.y,
                                 cp2X: controlPoint2.x,
                                 cp2Y: controlPoint2.y,
                                 endPointX: endPoint.x,
                                 endPointY: endPoint.y,
                                 loopCount: 40)
    }
    
    fileprivate func cubicKeyPoint(t: CGFloat,
                                   ax: CGFloat,
                                   ay: CGFloat,
                                   bx: CGFloat,
                                   by: CGFloat,
                                   cx: CGFloat,
                                   cy: CGFloat,
                                   dx: CGFloat,
                                   dy: CGFloat) -> (x: CGFloat, y: CGFloat) {
        let ax1 = (bx - ax) * t + ax
        let bx1 = (cx - bx) * t + bx
        let cx1 = (dx - cx) * t + cx
        let ax2 = (bx1 - ax1) * t + ax1
        let bx2 = (cx1 - bx1) * t + bx1
        
        let ay1 = (by - ay) * t + ay
        let by1 = (cy - by) * t + by
        let cy1 = (dy - cy) * t + cy
        let ay2 = (by1 - ay1) * t + ay1
        let by2 = (cy1 - by1) * t + by1
        
        return (ax2 + (bx2 - ax2) * t, ay2 + (by2 - ay2) * t)
    }
    
    func cubicBezierLength(startPointX: CGFloat,
                           startPointY: CGFloat,
                           cp1X: CGFloat,
                           cp1Y: CGFloat,
                           cp2X: CGFloat,
                           cp2Y: CGFloat,
                           endPointX: CGFloat,
                           endPointY: CGFloat,
                           loopCount: CGFloat) -> CGFloat {
        var totDist: CGFloat = 0
        var lastX = startPointX
        var lastY = startPointY
        var dx: CGFloat = 0 ,dy: CGFloat = 0
        for index in 1..<Int(loopCount) {
            let pt = cubicKeyPoint(t: CGFloat(index) / (loopCount - 1),
                                   ax: startPointX,
                                   ay: startPointY,
                                   bx: cp1X,
                                   by: cp1Y,
                                   cx: cp2X,
                                   cy: cp2Y,
                                   dx: endPointX,
                                   dy: endPointY)
            dx = pt.x - lastX
            dy = pt.y - lastY
            let temp = CGFloat(dx * dx + dy * dy).squareRoot()
            totDist += temp
            lastX = pt.x
            lastY = pt.y
        }
        
        dx = endPointX - lastX
        dy = endPointY - lastY
        let tempNum = CGFloat(dx * dx + dy * dy).squareRoot()
        totDist += tempNum
        return totDist
    }
    
    fileprivate func quadLength(startPoint: CGPoint,
                                controlPoint: CGPoint,
                                endPoint: CGPoint) -> CGFloat {
        let base = CGFloat(1.0 / 3.0)
        let controlPoint1X = (controlPoint.x * 2 + startPoint.x) * base
        let controlPoint1Y = (controlPoint.y * 2 + startPoint.y) * base
        let controlPoint2X = (controlPoint.x * 2 + endPoint.x) * base
        let controlPoint2Y = (controlPoint.y * 2 + endPoint.y) * base
        return __CubicBezierLength(startPoint: startPoint,
                                   controlPoint1: CGPoint(x: controlPoint1X,
                                                          y: controlPoint1Y),
                                   controlPoint2: CGPoint(x: controlPoint2X,
                                                          y: controlPoint2Y),
                                   endPoint: endPoint,
                                   arg0: 1.0)
    }
    
    fileprivate func segmentLengths() -> SegmentLengths {
        
        var lengths: [CGFloat] = []
        var total: CGFloat = 0
        var lastPoint: CGPoint?
        var startPoint: CGPoint?
        
        rx_applyWithBlock { elementPtr in
            let element = elementPtr.pointee
            let points = element.points
            switch element.type {
                
            case .moveToPoint:
                let point = points.pointee
                lastPoint = point
                startPoint = point
                
            case .addLineToPoint:
                let currentPoint = points.pointee
                if let lastPointValue = lastPoint {
                    let xDiff = currentPoint.x - lastPointValue.x
                    let yDiff = currentPoint.y - lastPointValue.y
                    let lineLength = CGFloat(xDiff * xDiff + yDiff * yDiff).squareRoot()
                    lengths.append(lineLength)
                    total += lineLength
                    lastPoint = currentPoint
                }
                
            case .addQuadCurveToPoint:
                let controlPoint = points.pointee
                let endPoint = (points + 1).pointee
                if let lastPointValue = lastPoint {
                    let quadLength = quadLength(startPoint: lastPointValue, controlPoint: controlPoint, endPoint: endPoint)
                    lastPoint = endPoint
                    lengths.append(quadLength)
                    total += quadLength
                }
                
            case .addCurveToPoint:
                let controlPoint1 = points.pointee
                let controlPoint2 = (points + 1).pointee
                let endPoint = (points + 2).pointee
                if let lastPointValue = lastPoint {
                    let curveLength = __CubicBezierLength(startPoint: lastPointValue, controlPoint1: controlPoint1, controlPoint2: controlPoint2, endPoint: endPoint, arg0: 1.0)
                    lengths.append(curveLength)
                    total += curveLength
                    lastPoint = endPoint
                }
                
            case .closeSubpath:
                if let lastPointValue = lastPoint,
                   let startPointValue = startPoint {
                    let xDiff = startPointValue.x - lastPointValue.x
                    let yDiff = startPointValue.y - lastPointValue.y
                    let lineLength = CGFloat(xDiff * xDiff + yDiff * yDiff).squareRoot()
                    lengths.append(lineLength)
                    total += lineLength
                    lastPoint = startPointValue
                }
                
            @unknown default:
                _danceuiFatalError()
            }
        }
        
        return SegmentLengths(lengths: lengths, total: total)
    }
}

@available(iOS 13.0, *)
fileprivate struct SegmentLengths {
    
    fileprivate var lengths: [CGFloat]
    
    fileprivate var total: CGFloat
}

@available(iOS 13.0, *)
fileprivate struct PathAccumulator {
    
    fileprivate var start: CGPoint
    
    fileprivate var current: CGPoint
    
    fileprivate var last: CGPoint?
    
    fileprivate var path: CGMutablePath
    
    fileprivate mutating func addSegment(elementPtr: UnsafePointer<CGPathElement>,
                                         fromFraction: CGFloat,
                                         toFraction: CGFloat) {
        let points = elementPtr.pointee.points
        let fromFractionValue = max(fromFraction, 0)
        let toFractionValue = min(toFraction, 1)
        let type = elementPtr.pointee.type
        
        if toFractionValue > fromFractionValue {
            switch type {
                
            case .moveToPoint:
                break
                
            case .addLineToPoint:
                let point = points.pointee
                addLineSegment(to: point, fromFraction: fromFractionValue, toFraction: toFractionValue)
                
            case .addQuadCurveToPoint:
                let toPoint = (points + 1).pointee
                let controlPoint = points.pointee
                addQuadSegment(to: toPoint, control: controlPoint, fromFraction: fromFractionValue, toFraction: toFractionValue)
                
            case .addCurveToPoint:
                let toPoint = (points + 2).pointee
                let controlPoint1 = points.pointee
                let controlPoint2 = (points + 1).pointee
                addCubicSegment(to: toPoint, control1: controlPoint1, control2: controlPoint2, fromFraction: fromFractionValue, toFraction: toFractionValue)
                
            case .closeSubpath:
                addLineSegment(to: start, fromFraction: fromFractionValue, toFraction: toFractionValue)
                
            @unknown default:
                _danceuiFatalError()
            }
        } else {
            switch type {
            case .moveToPoint:
                break
            case .addLineToPoint:
                current = points.pointee
            case .addQuadCurveToPoint:
                current = (points + 1).pointee
            case .addCurveToPoint:
                current = (points + 2).pointee
            case .closeSubpath:
                current = start
            @unknown default:
                _danceuiFatalError()
            }
        }
    }
    
    fileprivate mutating func addLineSegment(to: CGPoint,
                                             fromFraction: CGFloat,
                                             toFraction: CGFloat) {
        let xDiff = to.x - current.x
        let yDiff = to.y - current.y
        let toFractionX = xDiff * toFraction + current.x
        let toFractionY = yDiff * toFraction + current.y
        let fromFractionX = xDiff * fromFraction + current.x
        let fromFractionY = yDiff * fromFraction + current.y
        
        if let lastPoint = last {
            
            if lastPoint.x != fromFractionX || lastPoint.y != fromFractionY {
                path.move(to: CGPoint(x: fromFractionX, y: fromFractionY))
            }
            
            let endPoint = CGPoint(x: toFractionX, y: toFractionY)
            path.addLine(to: endPoint)
            current = endPoint
            last = endPoint
        } else {
            let endPoint = CGPoint(x: toFractionX, y: toFractionY)
            path.move(to: CGPoint(x: fromFractionX, y: fromFractionY))
            path.addLine(to: endPoint)
            current = endPoint
            last = endPoint
        }
    }
    
    fileprivate mutating func addQuadSegment(to: CGPoint,
                                             control: CGPoint,
                                             fromFraction: CGFloat,
                                             toFraction: CGFloat) {
        let base = (1.0 / 3.0)
        let control1X = (current.x + control.x * 2) * base
        let control1Y = (current.y + control.y * 2) * base
        let control2X = (to.x + control.x * 2) * base
        let control2Y = (to.y + control.y * 2) * base
        return addCubicSegment(to: to,
                               control1: CGPoint(x: control1X, y: control1Y),
                               control2: CGPoint(x: control2X, y: control2Y),
                               fromFraction: fromFraction,
                               toFraction: toFraction)
    }
    
    fileprivate mutating func addCubicSegment(to: CGPoint,
                                              control1: CGPoint,
                                              control2: CGPoint,
                                              fromFraction: CGFloat,
                                              toFraction: CGFloat) {
        
        var p1 = current
        var cp1 = control1
        var cp2 = control2
        var p2 = to
        
        var toFractionValue = toFraction
        if abs(fromFraction) > 0.001 {
            let (point1, controlPoint1, controlPoint2, point2) = cubicPointsByTrimmingLeft(point1: current, point2: control1, point3: control2, point4: to, to: fromFraction)
            let fractionDiff = toFraction - fromFraction
            toFractionValue = fractionDiff / (1 - fromFraction)
            p1 = point1
            cp1 = controlPoint1
            cp2 = controlPoint2
            p2 = point2
        }
        
        if abs(toFractionValue - 1) > 0.001 {
            let (point1, controlPoint1, controlPoint2, point2) = cubicPointsByTrimmingRight(point1: p1, point2: cp1, point3: cp2, point4: p2, from: toFractionValue)
            p1 = point1
            cp1 = controlPoint1
            cp2 = controlPoint2
            p2 = point2
        }
        
        if let lastValue = last {
            if lastValue.x != p1.x || lastValue.y != p1.y {
                path.move(to: p1)
            }
        } else {
            path.move(to: p1)
        }
        
        path.addCurve(to: p2, control1: cp1, control2: cp2)
        last = to
        current = to
    }
    
    fileprivate func cubicPointsByTrimmingLeft(point1: CGPoint,
                                               point2: CGPoint,
                                               point3: CGPoint,
                                               point4: CGPoint,
                                               to: CGFloat) -> (p1: CGPoint,
                                                                cp1: CGPoint,
                                                                cp2: CGPoint,
                                                                p2: CGPoint) {
        
        let threeP3MinusP2 = point3.subPoint(point2).multiply(by: 3)
        
        var p4MinusP3 = point4.subPoint(point3)
        
        var secondDerivativeEnd = point4.subPoint(point3.multiply(by: 2)).addPoint(point2)
        
        var secondDerivativeStart = point1.subPoint(point2.multiply(by: 2)).addPoint(point3)
        
        var p2MinusP1 = point2.subPoint(point1)
        
        var cubicCoefficient = point4.subPoint(threeP3MinusP2).subPoint(point1)
        
        secondDerivativeStart = secondDerivativeStart.multiply(by: 3)
        
        p2MinusP1 = p2MinusP1.multiply(by: 3)
        
        let trimmedStartPoint = cubicCoefficient.multiply(by: to)
            .addPoint(secondDerivativeStart)
            .multiply(by: to)
            .addPoint(p2MinusP1)
            .multiply(by: to)
            .addPoint(point1)
        
        let doubleP4MinusP3 = p4MinusP3.multiply(by: 2)
        
        let trimmedControlPoint1 = secondDerivativeEnd.multiply(by: 1 - to)
            .subPoint(doubleP4MinusP3)
            .multiply(by: 1 - to)
            .addPoint(point4)
        
        p4MinusP3 = p4MinusP3.multiply(by: 1 - to)
        
        let trimmedControlPoint2 = point4.subPoint(p4MinusP3)
        
        return (trimmedStartPoint, trimmedControlPoint1, trimmedControlPoint2, point4)
    }
    
    fileprivate func cubicPointsByTrimmingRight(point1: CGPoint,
                                                point2: CGPoint,
                                                point3: CGPoint,
                                                point4: CGPoint,
                                                from: CGFloat) -> (p1: CGPoint,
                                                                   cp1: CGPoint,
                                                                   cp2: CGPoint,
                                                                   p2: CGPoint) {
        
        let firstLevelPoint = point2.subPoint(point1)
            .multiply(by: from)
            .addPoint(point1)
        
        var secondDerivativeBase = point1.subPoint(point2.multiply(by: 2))
            .addPoint(point3)
        
        let doubledFirstDelta = point2.subPoint(point1)
            .multiply(by: 2)
        
        let secondLevelPoint = secondDerivativeBase.multiply(by: from)
            .addPoint(doubledFirstDelta)
            .multiply(by: from)
            .addPoint(point1)
        
        let tripledSecondDelta = point3.subPoint(point2)
            .multiply(by: 3)
        
        secondDerivativeBase = secondDerivativeBase.multiply(by: 3)
        
        let tripledFirstDelta = point2.subPoint(point1)
            .multiply(by: 3)
        
        let trimmedEndPoint = point4.subPoint(tripledSecondDelta)
            .subPoint(point1)
            .multiply(by: from)
            .addPoint(secondDerivativeBase)
            .multiply(by: from)
            .addPoint(tripledFirstDelta)
            .multiply(by: from)
            .addPoint(point1)
        
        return (point1, firstLevelPoint, secondLevelPoint, trimmedEndPoint)
    }
    
}

@available(iOS 13.0, *)
extension CGPoint {
    
    @inline(__always)
    internal func multiply(by: CGFloat) -> CGPoint {
        CGPoint(x: x * by, y: y * by)
    }
    
    @inline(__always)
    internal func addPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: x + point.x, y: y + point.y)
    }
    
    @inline(__always)
    internal func subPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(x: x - point.x, y: y - point.y)
    }
    
    @inline(__always)
    internal func multiplyBy(_ point: CGPoint) -> CGPoint {
        CGPoint(x: x * point.x, y: y * point.y)
    }
    
    @inline(__always)
    internal func dividedBy(_ point: CGPoint) -> CGPoint {
        CGPoint(x: x / point.x, y: y / point.y)
    }
    
    @inline(__always)
    internal func reverse() -> CGPoint {
        CGPoint(x: y, y: x)
    }
}
