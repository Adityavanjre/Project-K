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
import MyShims

@available(iOS 13.0, *)
extension CGMutablePath {
    
    internal func addPath(_ path: Path, transform: CGAffineTransform = .identity) {
        switch path.storage {
        case .rect(let rect):
            self.addRect(rect, transform: transform)
        case .ellipse(let rect):
            self.addEllipse(in: rect, transform: transform)
        case .stroked, .trimmed, .roundedRect, .path(_):
            self.addPath(path.cgPath, transform: transform)
        case .empty:
            break
        }
    }
    
}


#if os(macOS)
@available(iOS 13.0, *)
extension NSCoder {

    
    public class func string(for point: CGPoint) -> String {
        NSStringFromPoint(point)
    }

    public class func string(for size: CGSize) -> String {
        NSStringFromSize(size)
    }

    public class func string(for rect: CGRect) -> String {
        NSStringFromRect(rect)
    }
    
    public class func cgPoint(for string: String) -> CGPoint {
        guard !string.isEmpty else {
            return .zero
        }
        guard string.first == "{" && string.last == "}" else {
            return .zero
        }
        let parts = string.dropFirst().dropLast().components(separatedBy: ",")
        guard parts.count == 2 else {
            return .zero
        }
        guard let part0 = parts.first,
            let part1 = parts.second else {
            return .zero
        }
        guard let d0 = Double(part0), let d1 = Double(part1) else {
            return .zero
        }
        return CGPoint(x: d0, y: d1)
    }

    public class func cgSize(for string: String) -> CGSize {
        guard !string.isEmpty else {
            return .zero
        }
        guard string.first == "{" && string.last == "}" else {
            return .zero
        }
        let parts = string.dropFirst().dropLast().components(separatedBy: ",")
        guard parts.count == 2 else {
            return .zero
        }
        guard let part0 = parts.first,
            let part1 = parts.second else {
            return .zero
        }
        guard let d0 = Double(part0), let d1 = Double(part1) else {
            return .zero
        }
        return CGSize(width: d0, height: d1)
    }

    public class func cgRect(for string: String) -> CGRect {
        guard !string.isEmpty else {
            return .zero
        }
        guard string.first == "{" && string.last == "}" else {
            return .zero
        }
        let parts = string.dropFirst().dropLast()
        // {x,y},{w,h}
        
    }
    
}
#endif
@available(iOS 13.0, *)

extension CGPoint: LosslessStringConvertible {
    public var description: String {
        NSCoder.string(for: self)
    }
    public init?(_ description: String) {
        self = NSCoder.cgPoint(for: description)
    }
}

@available(iOS 13.0, *)
extension CGSize: LosslessStringConvertible {
    public var description: String {
        NSCoder.string(for: self)
    }
    public init?(_ description: String) {
        self = NSCoder.cgSize(for: description)
    }
}

@available(iOS 13.0, *)
extension CGRect: LosslessStringConvertible {
    public var description: String { //BDCOV_EXCL_BLOCK 覆盖率抖动
        NSCoder.string(for: self)
    }
    public init?(_ description: String) {
        self = NSCoder.cgRect(for: description)
    }
}

@available(iOS 13.0, *)


internal extension CGPath {
    
    func rx_applyWithBlock(_ block: (_ elementPtr: UnsafePointer<CGPathElement>) -> Void) {
        #if os(iOS)
        if #available(iOS 11.0, *) {
            self.applyWithBlock { block($0) }
            return
        }
        #elseif os(OSX)
        if #available(OSX 10.13, *) {
            self.applyWithBlock { block($0) }
            return
        }
        #endif
                
        typealias Block = @convention(block) (UnsafePointer<CGPathElement>) -> Void
        let callback: @convention(c) (UnsafeMutableRawPointer, UnsafePointer<CGPathElement>) -> Void = { info, element in
            unsafeBitCast(info, to: Block.self)(element)
        }

        withoutActuallyEscaping(block) { block in
            let block = unsafeBitCast(block, to: UnsafeMutableRawPointer.self)
            apply(info: block, function: unsafeBitCast(callback, to: CGPathApplierFunction.self))
        }
    }
    
}

@available(iOS 13.0, *)
extension Array {
    
    @usableFromInline
    internal var second: Element? {
        dropFirst().first
    }
    
    @usableFromInline
    internal var third: Element? {
        dropFirst(2).first
    }
    
}

@available(iOS 13.0, *)
extension CGPoint {
    internal var pathEncodingString: String {
        "" + (x.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(x))" : "\(x)") + " "
        + (y.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(y))" : "\(y)")
    }
}

extension CGPath: DanceUICompatible {
    public typealias CompatibleType = CGPath
}

@available(iOS 13.0, *)
extension DanceUINamespace where Base: CGPath {
    /// Returns a new path with filled regions in either this path or the given path.
    /// - Parameters:
    ///   - other: The path to union.
    ///   - rule: The rule for determining which areas to treat as the interior of the paths.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The filled region of resulting path is the combination of the filled region of both paths added together.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed. The result of filling this
    /// path using either even-odd or non-zero fill rules is identical.
    @_spi(DanceUICompose)
    public func union(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {
        __MyCGPathCreateCopyByUnioningPath(base, other, rule == .evenOdd)
    }

    /// Returns a new path with filled regions common to both paths.
    /// - Parameters:
    ///   - other: The path to intersect.
    ///   - rule: The rule for determining which areas to treat as the interior of the paths.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the overlapping area of the filled region of both paths.
    /// This can be used to clip the fill of a path to a mask.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed. The result of filling this
    /// path using either even-odd or non-zero fill rules is identical.
    @_spi(DanceUICompose)
    public func intersection(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {
        __MyCGPathCreateCopyByIntersectingPath(base, other, rule == .evenOdd)
    }

    /// Returns a new path with filled regions from this path that are not in the given path.
    /// - Parameters:
    ///   - other: The path to subtract.
    ///   - rule: The rule for determining which areas to treat as the interior of the paths.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the filled region of this path with the filled
    /// region `other` removed from it.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed. The result of filling this
    /// path using either even-odd or non-zero fill rules is identical.
    @_spi(DanceUICompose)
    public func subtracting(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {
        __MyCGPathCreateCopyBySubtractingPath(base, other, rule == .evenOdd)
    }

    /// Returns a new path with filled regions either from this path or the given path, but not in both.
    /// - Parameters:
    ///   - other: The path to difference.
    ///   - rule: The rule for determining which areas to treat as the interior of the paths.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The filled region of the resulting path is the filled region contained in either this path
    /// or `other`, but not both.
    ///
    /// Any unclosed subpaths in either path are assumed to be closed. The result of filling this
    /// path using either even-odd or non-zero fill rules is identical.
    @_spi(DanceUICompose)
    public func symmetricDifference(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {
        __MyCGPathCreateCopyBySymmetricDifferenceOfPath(base, other, rule == .evenOdd)
    }

    /// Returns a new path with a line from this path that does not overlap the filled region of the given path.
    /// - Parameters:
    ///   - other: The path to subtract.
    ///   - rule: The rule for determining which areas to treat as the interior of `other`.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The line of the resulting path is the line of this path that does not overlap the filled region of `other`.
    ///
    /// Intersected subpaths that are clipped create open subpaths. Closed subpaths that do not
    /// intersect `other` remain closed.
//    public func lineSubtracting(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {
//        _notImplemented()
//    }

    /// Returns a new path with a line from this path that overlaps the filled regions of the given path.
    /// - Parameters:
    ///   - other: The path to intersect.
    ///   - rule: The rule for determining which areas to treat as the interior of `other`.
    ///     Defaults to the `CGPathFillRule.winding` rule if not specified.
    /// - Returns: A new path.
    ///
    /// The line of the resulting path is the line of this path that overlaps the filled region of `other`.
    ///
    /// Intersected subpaths that are clipped create open subpaths. Closed subpaths that do not
    /// intersect `other` remain closed.
//    public func lineIntersection(_ other: CGPath, using rule: CGPathFillRule = .winding) -> CGPath {

    internal func normalized(using rule: CGPathFillRule = .winding) -> CGPath {
        __MyCGPathCreateCopyByNormalizing(base, rule == .evenOdd)
    }



//    internal func componentsSeparated(using rule: CGPathFillRule = .winding) -> [CGPath] {
//        _notImplemented()
//    }
}

