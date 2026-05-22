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
@_silgen_name("__CGPathParseString")
@available(iOS 13.0, *)
internal func __CGPathParseString(_ path: CGMutablePath, _ utf8CString: UnsafePointer<CChar>, _ length: Int) -> Bool

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// The outline of a 2D shape.
@frozen
@available(iOS 13.0, *)
public struct Path: Equatable, Animatable, Shape, ViewTransformable, LosslessStringConvertible {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
        
    internal var storage: Storage
    
    /// Creates an empty path.
    public init() {
        storage = .empty
    }
    
    /// Creates a path from an immutable shape path.
    public init(_ path: CGPath) {
        storage = .path(.init(path))
    }
    
    /// Creates a path from a copy of a mutable shape path.
    public init(_ path: CGMutablePath) {
        storage = .path(.init(path))
    }
    
    /// Creates a path as the given rectangle.
    public init(_ rect: CGRect) {
        guard !rect.isNull else {
            storage = .empty
            return
        }
        storage = .rect(rect)
    }
    
    /// Creates a path as the given rounded rectangle.
    public init(roundedRect rect: CGRect, cornerSize: CGSize, style: RoundedCornerStyle = .circular) {
        
        guard !rect.isNull || !rect.isEmpty else {
            storage = .empty
            return
        }
        guard !rect.isInfinite && cornerSize != .zero else {
            storage = .rect(rect)
            return
        }
        storage = .roundedRect(.init(rect: rect, cornerSize: cornerSize, style: style))
    }
    
    /// Creates a path as the given rounded rectangle.
    public init(roundedRect rect: CGRect, cornerRadius: CGFloat, style: RoundedCornerStyle = .circular) {
        guard !rect.isNull || !rect.isEmpty else {
            storage = .empty
            return
        }
        guard !rect.isInfinite && cornerRadius != .zero else {
            storage = .rect(rect)
            return
        }
        storage = .roundedRect(.init(rect: rect, cornerSize: .init(width: cornerRadius, height: cornerRadius), style: style))
    }
    
    /// Creates a path as an ellipse inscribed within the given rectangle.
    public init(ellipseIn rect: CGRect) {
        guard !rect.isNull || !rect.isEmpty else {
            storage = .empty
            return
        }
        guard !rect.isInfinite else {
            storage = .rect(rect)
            return
        }
        storage = .ellipse(rect)
    }
    
    /// Creates an empty path, and then executes the closure to add the initial
    /// elements.
    public init(_ callback: (inout Path) -> ()) {
        storage = .empty
        callback(&self)
    }
    
    /// Initializes from the result of a previous call to
    /// `Path.stringRepresentation`. Fails if the `string` does not
    /// describe a valid path.
    public init?(_ string: String) {
        let nsString = (string as NSString)
        guard let ptr = nsString.utf8String else {
            return nil
        }
        
        let mutablePath = CGMutablePath.init()
        guard __CGPathParseString(mutablePath, ptr, nsString.length) else {
            return nil
        }
        storage = .path(PathBox(mutablePath))
    }
    
    private init(_ strokedPath: StrokedPath) {
        storage = .stroked(strokedPath)
    }
    
    private init(_ trimmedPath: TrimmedPath) {
        storage = .trimmed(trimmedPath)
    }
    
    /// A description of the path that may be used to recreate the path
    /// via `init?(_:)`.
    public var description: String {
        var result = ""
        var first = true
        self.forEach { (element) in
            if first {
                first.toggle()
                result.append("\(element)")
            } else {
                result.append(" \(element)")
            }
        }
        return result
    }
    
    /// An immutable path representing the elements in the path.
    public var cgPath: CGPath {
        storage.cgPath
    }
    
    /// A Boolean value indicating whether the path contains zero elements.
    public var isEmpty: Bool {
        storage.isEmpty
    }
    
    /// A rectangle containing all path segments.
    public var boundingRect: CGRect {
        storage.boundingRect
    }
        
    /// Returns true if the path contains a specified point.
    ///
    /// If `eoFill` is true, this method uses the even-odd rule to define which
    /// points are inside the path. Otherwise, it uses the non-zero rule.
    public func contains(_ p: CGPoint, eoFill: Bool = false) -> Bool {
        storage.contains(p, eoFill: eoFill)
    }
    
    /// Returns a stroked copy of the path using `style` to define how
    /// the stroked outline is created.
    public func strokedPath(_ style: StrokeStyle) -> Path {
        if isEmpty {
            return Path()
        }
        
        return .init(StrokedPath(path: self, style: style))
    }
    
    /// Returns a partial copy of the path, containing the region
    /// between `from` and `to`, both of which must be fractions
    /// between zero and one defining points linearly-interpolated
    /// along the path.
    public func trimmedPath(from: CGFloat, to: CGFloat) -> Path {
        if isEmpty {
            return Path()
        }
        
        if from < 0 && to > 1 {
            return self
        }
        
        let diff = to - from
        
        if diff <= 0 {
            return Path()
        }
        
        if case .trimmed(let trimmedPath) = self.storage {
            let newTrimmedPath = trimmedPath.trimmed(from: from, to: to)
            return Path(newTrimmedPath)
        } else {
            return Path(TrimmedPath(path: self, start: from, end: to))
        }
    }
    
    @inline(__always)
    private mutating func isRounededRectIntersected(_ roundedRect: FixedRoundedRect,
                                                    otherRoundedRect: FixedRoundedRect) -> Bool {
        if roundedRect.contains(otherRect: otherRoundedRect) {
            self.storage = .roundedRect(otherRoundedRect)
            return true
        } else if otherRoundedRect.contains(otherRect: roundedRect) {
            self.storage = .roundedRect(roundedRect)
            return true
        } else {
            return false
        }
    }
    
    @inline(__always)
    private mutating func isRectIntersected(_ rect: CGRect,
                                   otherRect: CGRect) -> Bool {
        let intersection = rect.intersection(otherRect)
        if intersection.isNull {
            self.storage = .empty
        } else {
            self.storage = .rect(intersection)
        }
        return true
    }
    
    internal mutating func intersect(_ path: Path) -> Bool {
        switch (self.storage, path.storage) {
            
        case (.rect(let rect), .rect(let otherRect)):
            return isRectIntersected(rect, otherRect: otherRect)
            
        case (.rect(let rect), .ellipse(let ellipseRect)):
            if ellipseRect.width != ellipseRect.height {
                return false
            }
            
            let radius = ellipseRect.width * 0.5
            let roundedRect = FixedRoundedRect(rect: rect, cornerSize: CGSize(width: 0, height: 0), style: .circular)
            let otherRoundedRect = FixedRoundedRect(rect: ellipseRect, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.rect(let rect), .roundedRect(let otherRoundedRect)):
            let roundedRect = FixedRoundedRect(rect: rect, cornerSize: CGSize.zero, style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.rect, .stroked),
             (.rect, .trimmed),
             (.rect, .path),
             (.rect, .empty):
            return false
            
            
        case (.ellipse(let ellipseRect), .rect(let rect)):
            if ellipseRect.width != ellipseRect.height {
                return false
            }
            
            let radius = ellipseRect.width * 0.5
            let roundedRect = FixedRoundedRect(rect: ellipseRect, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            let otherRoundedRect = FixedRoundedRect(rect: rect, cornerSize: CGSize.zero, style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.ellipse(let ellipseRect), .ellipse(let otherEllipseRect)):
            if ellipseRect.width != ellipseRect.height || otherEllipseRect.width != otherEllipseRect.height {
                return false
            }
            
            let radius = ellipseRect.width * 0.5
            let otherEllipseRadius = otherEllipseRect.width * 0.5
            let roundedRect = FixedRoundedRect(rect: ellipseRect, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            let otherRoundedRect = FixedRoundedRect(rect: otherEllipseRect, cornerSize: CGSize(width: otherEllipseRadius, height: otherEllipseRadius), style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.ellipse(let ellipseRect), .roundedRect(let otherRoundedRect)):
            if ellipseRect.width != ellipseRect.height {
                return false
            }
            
            let radius = ellipseRect.width * 0.5
            let roundedRect = FixedRoundedRect(rect: ellipseRect, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.ellipse, .stroked),
             (.ellipse, .trimmed),
             (.ellipse, .path),
             (.ellipse, .empty):
            return false
            
            
        case (.roundedRect(let roundedRect), .rect(let rect)):
            if roundedRect.cornerSize != .zero {
                let otherRoundedRect = FixedRoundedRect(rect: rect, cornerSize: CGSize.zero, style: .circular)
                return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            } else {
                return isRectIntersected(roundedRect.rect, otherRect: rect)
            }
            
        case (.roundedRect(let roundedRect), .ellipse(let otherEllipse)):
            if otherEllipse.width != otherEllipse.height {
                return false
            }
            
            let radius = otherEllipse.width * 0.5
            let otherRoundedRect = FixedRoundedRect(rect: otherEllipse, cornerSize: CGSize(width: radius, height: radius), style: .circular)
            return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            
        case (.roundedRect(let roundedRect), .roundedRect(let otherRoundedRect)):
            if roundedRect.cornerSize != .zero || otherRoundedRect.cornerSize != .zero {
                return isRounededRectIntersected(roundedRect, otherRoundedRect: otherRoundedRect)
            } else {
                return isRectIntersected(roundedRect.rect, otherRect: otherRoundedRect.rect)
            }
            
        case (.roundedRect, .stroked),
             (.roundedRect, .trimmed),
             (.roundedRect, .path),
             (.roundedRect, .empty):
            return false
            
            // Other
        case (.stroked, _),
             (.trimmed, _),
             (.path, _),
             (.empty, _):
            return false
        }
        
    }
    
    @inline(__always)
    internal mutating func convert(to: CoordinateSpace, transform: ViewTransform) {
        self = mapPoints { points in
            points.convert(to: to, transform: transform)
        }
    }
    
    @inline(__always)
    internal mutating func convert(from: CoordinateSpace, transform: ViewTransform) {
        self = mapPoints { points in
            points.convert(from: from, transform: transform)
        }
    }

    internal mutating func union(path: Path) {
        
        let currentStorage = self.storage
        
        let fromPathStorage = path.storage
        
        switch fromPathStorage {
        case .rect(let fromRect):
            if case .rect(let currentRect) = currentStorage {
                if !fromRect.contains(currentRect) && !currentRect.contains(fromRect) {
                    addPath(path)
                }
            } else {
                addPath(path)
            }
        case .ellipse, .roundedRect, .stroked, .trimmed, .path:
            addPath(path)
        case .empty:
            break
        }
    }
    
    internal func mapPoints(value: (inout [CGPoint]) -> ()) -> Path {
        
        switch self.storage {
        case .rect(let rect):
            
            var cornerPoints = rect.cornerPoints
            value(&cornerPoints)
            let exactCornerPointsRect = CGRect(exactCornerPoints: cornerPoints)
            
            if let newRect = exactCornerPointsRect {
                return newRect.isNull ? .init() : .init(newRect)
            } else {
                let mutablePath = CGMutablePath()
                var pathBox = PathBox(mutablePath)
                let firstPoint = cornerPoints[0]
                mutablePath.move(to: firstPoint)
                
                if cornerPoints.count <= 1 {
                    _danceuiFatalError("CornerPoints in mapPoints is less than one.")
                }
                
                cornerPoints.dropFirst().forEach { point in
                    
                    if !isKnownUniquelyReferenced(&pathBox) {
                        pathBox = pathBox.copy()
                    } else {
                        pathBox.clearCaches()
                    }
                    
                    pathBox.cgPath.addLine(to: point)
                }
                
                pathBox.cgPath.closeSubpath()
                return Path(pathBox.cgPath)
            }
        case .ellipse(_), .roundedRect(_), .stroked(_), .trimmed(_), .path(_):
            
            var points: [CGPoint] = []
            
            forEach { element in
                switch element {
                case .move(to: let point), .line(to: let point):
                    points.append(point)
                case .quadCurve(to: let to, control: let p1):
                    points.append(contentsOf: [to, p1])
                case .curve(to: let to, control1: let p1, control2: let p2):
                    points.append(contentsOf: [to, p1, p2])
                case .closeSubpath:
                    break
                }
            }
            
            value(&points)
            let mutablePath = CGMutablePath()
            var index = 0
            
            forEach { element in
                switch element {
                case .move(_):
                    if index < points.count {
                        let point = points[index]
                        mutablePath.move(to: point)
                        index += 1
                    }
                case .line(_):
                    if index < points.count {
                        let point = points[index]
                        mutablePath.addLine(to: point)
                        index += 1
                    }
                case .quadCurve(_, _):
                    if index < points.count
                        && index + 1 < points.count {
                        let to = points[index]
                        let controllPoint = points[index + 1]
                        mutablePath.addQuadCurve(to: to, control: controllPoint)
                        index += 2
                    }
                case .curve(_, _, _):
                    if index < points.count
                        && index + 1 < points.count
                        && index + 2 < points.count {
                        let to = points[index]
                        let controllPoint1 = points[index + 1]
                        let controllPoint2 = points[index + 2]
                        mutablePath.addCurve(to: to, control1: controllPoint1, control2: controllPoint2)
                        index += 3
                    }
                case .closeSubpath:
                    mutablePath.closeSubpath()
                }
            }
            
            return mutablePath.isEmpty ? Path() : Path(mutablePath)
            
        case .empty:
            return Path()
        }
    }
    
// MARK: Shape
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = _ShapeView<Self, ForegroundStyle>

    public var body: _ShapeView<Path, ForegroundStyle> {
        _ShapeView<Path, ForegroundStyle>(shape: self, style: ForegroundStyle())
    }
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        self
    }
}



@available(iOS 13.0, *)
extension Path {
    
    /// Returns a new path with filled regions common to both paths.
    ///
    /// - Parameters:
    ///   - other: The path to intersect.
    ///   - eoFill: Whether to use the even-odd rule for determining
    ///       which areas to treat as the interior of the paths (if true),
    ///       or the non-zero rule (if false).
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the overlapping area
    /// of the filled region of both paths.  This can be used to clip
    /// the fill of a path to a mask.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed.
    /// The result of filling this path using either even-odd or
    /// non-zero fill rules is identical.
    public func intersection(_ other: Path, eoFill: Bool = false) -> Path {
        let newPath = self.cgPath.danceui.intersection(other.cgPath, using: eoFill ? .evenOdd : .winding)
        return Path(newPath)
    }

    /// Returns a new path with filled regions in either this path or
    /// the given path.
    ///
    /// - Parameters:
    ///   - other: The path to union.
    ///   - eoFill: Whether to use the even-odd rule for determining
    ///       which areas to treat as the interior of the paths (if true),
    ///       or the non-zero rule (if false).
    /// - Returns: A new path.
    ///
    /// The filled region of resulting path is the combination of the
    /// filled region of both paths added together.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed.
    /// The result of filling this path using either even-odd or
    /// non-zero fill rules is identical.
    public func union(_ other: Path, eoFill: Bool = false) -> Path {
        let newPath = self.cgPath.danceui.union(other.cgPath, using: eoFill ? .evenOdd : .winding)
        return Path(newPath)
    }

    /// Returns a new path with filled regions from this path that are
    /// not in the given path.
    ///
    /// - Parameters:
    ///   - other: The path to subtract.
    ///   - eoFill: Whether to use the even-odd rule for determining
    ///       which areas to treat as the interior of the paths (if true),
    ///       or the non-zero rule (if false).
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the filled region of
    /// this path with the filled region `other` removed from it.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed.
    /// The result of filling this path using either even-odd or
    /// non-zero fill rules is identical.
    public func subtracting(_ other: Path, eoFill: Bool = false) -> Path {
        let newPath = self.cgPath.danceui.subtracting(other.cgPath, using: eoFill ? .evenOdd : .winding)
        return Path(newPath)
    }

    /// Returns a new path with filled regions either from this path or
    /// the given path, but not in both.
    ///
    /// - Parameters:
    ///   - other: The path to difference.
    ///   - eoFill: Whether to use the even-odd rule for determining
    ///       which areas to treat as the interior of the paths (if true),
    ///       or the non-zero rule (if false).
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the filled region
    /// contained in either this path or `other`, but not both.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed.
    /// The result of filling this path using either even-odd or
    /// non-zero fill rules is identical.
    public func symmetricDifference(_ other: Path, eoFill: Bool = false) -> Path {
        let newPath = self.cgPath.danceui.symmetricDifference(other.cgPath, using: eoFill ? .evenOdd : .winding)
        return Path(newPath)
    }
    
    /// Returns a new weakly-simple copy of this path.
    ///
    /// - Parameters:
    ///   - eoFill: Whether to use the even-odd rule for determining
    ///       which areas to treat as the interior of the paths (if true),
    ///       or the non-zero rule (if false).
    /// - Returns: A new path.
    ///
    /// The returned path is a weakly-simple path, has no
    /// self-intersections, and has a normalized orientation. The
    /// result of filling this path using either even-odd or non-zero
    /// fill rules is identical.
    public func normalized(eoFill: Bool = true) -> Path {
        let newPath = self.cgPath.danceui.normalized(using: eoFill ? .evenOdd : .winding)
        return Path(newPath)
    }
}
