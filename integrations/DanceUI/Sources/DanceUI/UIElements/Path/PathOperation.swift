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
extension Path {
    
    /// An element of a path.
    @frozen
    public enum Element: Equatable, CustomStringConvertible {
        
        /// A path element that terminates the current subpath (without closing
        /// it) and defines a new current point.
        case move(to: CGPoint)
        
        /// A line from the previous current point to the given point, which
        /// becomes the new current point.
        case line(to: CGPoint)
        
        /// A quadratic Bézier curve from the previous current point to the
        /// given end-point, using the single control point to define the curve.
        ///
        /// The end-point of the curve becomes the new current point.
        case quadCurve(to: CGPoint, control: CGPoint)
        
        /// A cubic Bézier curve from the previous current point to the given
        /// end-point, using the two control points to define the curve.
        ///
        /// The end-point of the curve becomes the new current point.
        case curve(to: CGPoint, control1: CGPoint, control2: CGPoint)
        
        /// A line from the start point of the current subpath (if any) to the
        /// current point, which terminates the subpath.
        ///
        /// After closing the subpath, the current point becomes undefined.
        case closeSubpath
        
        public var description: String {
            switch self {
            case .move(to: let p):
                return "\(p.pathEncodingString) m"    // 0x6d
            case .line(to: let p):
                return "\(p.pathEncodingString) l"    // 0x6c
            case .quadCurve(to: let p1, control: let p0):
                return "\(p0.pathEncodingString) \(p1.pathEncodingString) q"
            case .curve(to: let p2, control1: let p0, control2: let p1):
                return "\(p0.pathEncodingString) \(p1.pathEncodingString) \(p2.pathEncodingString) c" // 0x63
            case .closeSubpath:
                return "h"  // 0x68
            }
        }
    }
    
    /// Calls `body` with each element in the path.
    public func forEach(_ body: (Path.Element) -> Void) {
        cgPath.rx_applyWithBlock { (elementPtr) in
            let element = elementPtr.pointee
            let points = element.points
            switch element.type {
            case .moveToPoint:
                let p = points.pointee
                body(.move(to: p))
            case .addLineToPoint:
                let p = points.pointee
                body(.line(to: p))
            case .addQuadCurveToPoint:
                let p0 = points.pointee
                let p1 = (points + 1).pointee
                body(.quadCurve(to: p1, control: p0))
            case .addCurveToPoint:
                let p0 = points.pointee
                let p1 = (points + 1).pointee
                let p2 = (points + 2).pointee
                body(.curve(to: p2, control1: p0, control2: p1))
            case .closeSubpath:
                body(.closeSubpath)
            @unknown default:
                _danceuiFatalError()
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension Path {
    
    internal mutating func mutableCGPath() -> CGMutablePath {
        switch storage {
        case .empty: fallthrough
        case .ellipse: fallthrough
        case .rect: fallthrough
        case .stroked: fallthrough
        case .trimmed: fallthrough
        case .roundedRect:
            let path = CGMutablePath()
            path.addPath(self, transform: .identity)
            let box = PathBox(path)
            storage = .path(box)
            return path
        case .path(var box):
            storage = .empty
            if !isKnownUniquelyReferenced(&box) {
                box = box.copy()
            } else {
                box.clearCaches()
            }
            storage = .path(box)
            return box.cgPath
        }
    }

    /// Begins a new subpath at the specified point.
    public mutating func move(to p: CGPoint) {
        mutableCGPath().move(to: p)
    }

    /// Appends a straight line segment from the current point to the
    /// specified point.
    public mutating func addLine(to p: CGPoint) {
        mutableCGPath().addLine(to: p)
    }
    
    /// Adds a sequence of connected straight-line segments to the
    /// path.
    public mutating func addLines(_ lines: [CGPoint]) {
        guard !lines.isEmpty else {
            return
        }
        let cgpath = mutableCGPath()
        for (index, point) in lines.enumerated() {
            if index == 0 {
                cgpath.move(to: point)
            } else {
                cgpath.addLine(to: point)
            }
        }
    }

    /// Adds a quadratic Bézier curve to the path, with the
    /// specified end point and control point.
    public mutating func addQuadCurve(to p: CGPoint, control cp: CGPoint) {
        mutableCGPath().addQuadCurve(to: p, control: cp)
    }

    /// Adds a cubic Bézier curve to the path, with the
    /// specified end point and control points.
    public mutating func addCurve(to p: CGPoint, control1 cp1: CGPoint, control2 cp2: CGPoint) {
        mutableCGPath().addCurve(to: p, control1: cp1, control2: cp2)
    }

    /// Closes and completes the current subpath.
    public mutating func closeSubpath() {
        mutableCGPath().closeSubpath()
    }

    /// Adds a rectangular subpath to the path.
    public mutating func addRect(_ rect: CGRect, transform: CGAffineTransform = .identity) {
        guard !rect.isNull else {
            return
        }
        
        if storage == .empty && transform.isRectilinear {
            let transformedRect = rect.applying(transform)
            self.storage = .rect(transformedRect)
        } else {
            mutableCGPath().addRect(rect, transform: transform)
        }
    }

    /// Adds a rounded rectangle to the path.
    public mutating func addRoundedRect(in rect: CGRect, cornerSize: CGSize, style: RoundedCornerStyle = .circular, transform: CGAffineTransform = .identity) {
        guard !rect.isNull else {
            return
        }
        
        if storage == .empty && transform.isRectilinear {
            let transformedRect = rect.applying(transform)
            let transformedSize = cornerSize.applying(transform)
            self.storage = .roundedRect(.init(rect: transformedRect, cornerSize: transformedSize, style: style))
        } else {
            mutableCGPath().addRoundedRect(in: rect, cornerWidth: cornerSize.width, cornerHeight: cornerSize.height, transform: transform)
        }
    }

    /// Adds an ellipse to the path.
    public mutating func addEllipse(in rect: CGRect, transform: CGAffineTransform = .identity) {
        guard !rect.isNull else {
            return
        }
        
        if storage == .empty && transform.isRectilinear {
            let transformedRect = rect.applying(transform)
            self.storage = .ellipse(transformedRect)
        } else {
            mutableCGPath().addEllipse(in: rect, transform: transform)
        }
    }

    /// Adds a sequence of rectangular subpaths to the path.
    public mutating func addRects(_ rects: [CGRect], transform: CGAffineTransform = .identity) {
        guard !rects.isEmpty else {
            return
        }
        mutableCGPath().addRects(rects, transform: transform)
    }

    /// Adds an arc of a circle to the path, specified with a radius
    /// and a difference in angle.
    public mutating func addRelativeArc(center: CGPoint, radius: CGFloat, startAngle: Angle, delta: Angle, transform: CGAffineTransform = .identity) {
        mutableCGPath().addRelativeArc(center: center, radius: radius, startAngle: CGFloat(startAngle.radians), delta: CGFloat(delta.radians), transform: transform)
    }

    /// Adds an arc of a circle to the path, specified with a radius
    /// and angles.
    public mutating func addArc(center: CGPoint, radius: CGFloat, startAngle: Angle, endAngle: Angle, clockwise: Bool, transform: CGAffineTransform = .identity) {
        mutableCGPath().addArc(center: center, radius: radius, startAngle: CGFloat(startAngle.radians), endAngle: CGFloat(endAngle.radians), clockwise: clockwise, transform: transform)
    }

    /// Adds an arc of a circle to the path, specified with a radius
    /// and two tangent lines.
    public mutating func addArc(tangent1End p1: CGPoint, tangent2End p2: CGPoint, radius: CGFloat, transform: CGAffineTransform = .identity) {
        mutableCGPath().addArc(tangent1End: p1, tangent2End: p2, radius: radius, transform: transform)
    }

    /// Appends a copy of `path` to the path.
    public mutating func addPath(_ path: Path, transform: CGAffineTransform = .identity) {
        guard storage != .empty || !transform.isRectilinear || !transform.isIdentity else {
            self = path
            return
        }
        guard !path.isEmpty else {
            return
        }
        mutableCGPath().addPath(path.cgPath, transform: transform)
    }

    /// Returns the last point in the path, or nil if the path contains
    /// no points.
    public var currentPoint: CGPoint? {
        guard !isEmpty else {
            return nil
        }
        return cgPath.currentPoint
    }

    /// Returns a path constructed by applying `transform` to all
    /// points of `self`.
    public func applying(_ transform: CGAffineTransform) -> Path {
        
        typealias TransformHandler = (UnsafePointer<CGAffineTransform>) -> Path
        
        let transformHandler: TransformHandler = { transformValue -> Path in
            
            guard let copyPath = cgPath.copy(using: transformValue) else {
                return Path()
            }
            
            guard !copyPath.isEmpty else {
                return Path()
            }
            
            return Path(copyPath)
        }
        
        switch storage {
        case .rect(let rect):
            guard transform.isRectilinear else {
                return withUnsafePointer(to: transform) { transformHandler($0) }
            }
            
            let newRect = rect.applying(transform)
            
            guard !newRect.isNull else {
                return Path()
            }
            
            return Path(newRect)
        case .ellipse(let rect):
            guard transform.isRectilinear else {
                return withUnsafePointer(to: transform) { transformHandler($0) }
            }
            
            let newRect = rect.applying(transform)
            
            guard !newRect.isNull else {
                return Path()
            }
            
            return newRect.isInfinite ? Path(newRect) : Path(ellipseIn: newRect)
        case .roundedRect(let fixedRoundedRect):
            guard transform.isRectilinear else {
                return withUnsafePointer(to: transform) { transformHandler($0) }
            }
            
            let newRect = fixedRoundedRect.rect.applying(transform)
            let newCornerSize = fixedRoundedRect.cornerSize.applying(transform)
            
            guard !newRect.isNull else {
                return Path()
            }
            
            guard newCornerSize != .zero && !newRect.isInfinite else {
                return Path(newRect)
            }
            
            return Path(roundedRect: newRect, cornerSize: newCornerSize, style: fixedRoundedRect.style)
        case .path, .trimmed, .stroked:
            return withUnsafePointer(to: transform) { transformHandler($0) }
        case .empty:
            return Path()
        }
        
    }
    
    /// Returns a path constructed by translating `self` by `(dx, dy)`.
    public func offsetBy(dx: CGFloat, dy: CGFloat) -> Path {
        self.applying(.init(translationX: dx, y: dy))
    }
    
}
