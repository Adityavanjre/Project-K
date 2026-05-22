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

/// The horizontal or vertical dimension in a 2D coordinate system.
@frozen
@available(iOS 13.0, *)
public enum Axis: UInt8 {

    /// The horizontal dimension.
    case horizontal

    /// The vertical dimension.
    case vertical

    @inlinable
    public var minor: Axis {
        switch self {
            case .horizontal:
                return .vertical
            case .vertical:
                return .horizontal
        }
    }

    internal var scrollableEdges: Edge.Set {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }

}

@available(iOS 13.0, *)
extension Axis {

    /// An efficient set of axes.
    @frozen
    public struct Set: OptionSet, SetAlgebra, RawRepresentable, Equatable {

        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = Axis.Set

        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = Axis.Set.Element

        /// The corresponding value of the raw type.
        ///
        /// A new instance initialized with `rawValue` will be equivalent to this
        /// instance. For example:
        ///
        ///     enum PaperSize: String {
        ///         case A4, A5, Letter, Legal
        ///     }
        ///
        ///     let selectedSize = PaperSize.Letter
        ///     print(selectedSize.rawValue)
        ///     // Prints "Letter"
        ///
        ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
        ///     // Prints "true"
        public let rawValue: Int8

        internal static let empty: Set = Set()

        public static let horizontal: Set = .init(rawValue: 0x1 << 0)

        public static let vertical: Set = .init(rawValue: 0x1 << 1)

        internal static let all: Set = [.horizontal, .vertical]

        internal static let maxValue: Set = .init(rawValue: .max)

        /// Creates a new option set from the given raw value.
        ///
        /// This initializer always succeeds, even if the value passed as `rawValue`
        /// exceeds the static properties declared as part of the option set. This
        /// example creates an instance of `ShippingOptions` with a raw value beyond
        /// the highest element, with a bit mask that effectively contains all the
        /// declared static members.
        ///
        ///     let extraOptions = ShippingOptions(rawValue: 255)
        ///     print(extraOptions.isStrictSuperset(of: .all))
        ///     // Prints "true"
        ///
        /// - Parameter rawValue: The raw value of the option set to create. Each bit
        ///   of `rawValue` potentially represents an element of the option set,
        ///   though raw values may include bits that are not defined as distinct
        ///   values of the `OptionSet` type.
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }

        public init(axis: Axis) {
            switch axis {
            case .horizontal:
                self = .horizontal
            case .vertical:
                self = .vertical
            }
        }

        internal var first: Axis? {
            switch self {
            case .horizontal:
                return .horizontal
            case .vertical:
                return .vertical
            case .all:
                return .horizontal
            default:
                return nil
            }
        }

    }
}

@available(iOS 13.0, *)
extension CGSize {

    @inlinable
    internal init(axis: Axis, main: CGFloat, sub: CGFloat) {
        switch axis {
        case .horizontal:
            self.init(width: main, height: sub)
        case .vertical:
            self.init(width: sub, height: main)
        }
    }

    @inline(__always)
    internal static func size(for axis: Axis, _ width: CGFloat, _ height: CGFloat) -> CGSize {
        switch axis {
        case .horizontal:
            return CGSize(width: width, height: height)
        default:
            return CGSize(width: height, height: width)
        }
    }

    @inline(__always)
    internal func value(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return width
            case .vertical:
                return height
        }
    }

    @inline(__always)
    internal mutating func setValue(_ value: CGFloat, for axis: Axis) {
        switch axis {
            case .horizontal:
                width = value
            case .vertical:
                height = value
        }
    }
}

@available(iOS 13.0, *)
extension CGPoint {

    @inlinable
    internal init(axis: Axis, main: CGFloat, sub: CGFloat) {
        switch axis {
        case .horizontal:
            self.init(x: main, y: sub)
        case .vertical:
            self.init(x: sub, y: main)
        }
    }

    @inline(__always)
    internal static func point(for axis: Axis, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
        switch axis {
        case .horizontal:
            return CGPoint(x: x, y: y)
        default:
            return CGPoint(x: y, y: x)
        }
    }

    @inline(__always)
    internal func value(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return x
            case .vertical:
                return y
        }
    }

    @inline(__always)
    internal mutating func setValue(_ value: CGFloat, for axis: Axis) {
        switch axis {
            case .horizontal:
                x = value
            case .vertical:
                y = value
        }
    }
}

@available(iOS 13.0, *)
extension CGRect {

    @inline(__always)
    internal subscript(_ axis: Axis) -> ClosedRange<CGFloat> {
        get {
            let minValue = minOriginValue(for: axis)
            guard minValue < .infinity else {
                return .init(uncheckedBounds: (minValue, .infinity))
            }
            let maxValue = maxOriginValue(for: axis)
            _danceuiPrecondition(minValue <= maxValue)
            return .init(uncheckedBounds: (minValue, maxValue))
        }
    }

    @inline(__always)
    internal func maxOriginValue(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return maxX
            case .vertical:
                return maxY
        }
    }

    @inline(__always)
    internal func minOriginValue(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return minX
            case .vertical:
                return minY
        }
    }

    @inline(__always)
    internal func sizeValue(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return size.width
            case .vertical:
                return size.height
        }
    }

    @inline(__always)
    internal func onTheOutside(of other: CGRect, axis: Set<Axis>) -> Bool {
        (axis.contains(.horizontal) && onTheOutside(of: other, axis: .horizontal)) ||
        (axis.contains(.vertical) && onTheOutside(of: other, axis: .vertical))
    }

    @inline(__always)
    internal func onTheOutside(of other: CGRect, axis: Axis) -> Bool {
        minOriginValue(for: axis) < other.minOriginValue(for: axis) ||
        other.maxOriginValue(for: axis) < minOriginValue(for: axis)
    }

}

@available(iOS 13.0, *)
extension _ProposedSize {

    @inline(__always)
    internal func value(for axis: Axis) -> CGFloat? {
        switch axis {
            case .horizontal:
                return width
            case .vertical:
                return height
        }
    }

    @inline(__always)
    internal mutating func setValue(_ value: CGFloat?, for axis: Axis) {
        switch axis {
            case .horizontal:
                width = value
            case .vertical:
                height = value
        }
    }

    @inline(__always)
    internal func hasRequiredValue(for axis: Axis) -> Bool {
        switch axis {
            case .horizontal:
                return width != nil
            case .vertical:
                return height != nil
        }
    }
}

@available(iOS 13.0, *)
extension ViewGeometry {

    @usableFromInline
    internal func sizeValue(for axis: Axis) -> CGFloat {
        dimensions.size.value.value(for: axis)
    }

    @usableFromInline
    internal func originValue(for axis: Axis) -> CGFloat {
        origin.value.value(for: axis)
    }

    @usableFromInline
    internal mutating func setOriginValue(_ value: CGFloat, for axis: Axis) {
        origin.value.setValue(value, for: axis)
    }
}

@available(iOS 13.0, *)
extension UnitPoint {

    @usableFromInline
    internal static func point(with x: CGFloat, y: CGFloat, axis: Axis) -> UnitPoint {
        switch axis {
        case .horizontal:
            return .init(x: x, y: y)
        default:
            return .init(x: y, y: x)
        }
    }

    @usableFromInline
    internal func value(for axis: Axis) -> CGFloat {
        switch axis {
            case .horizontal:
                return x
            case .vertical:
                return y
        }
    }

    @usableFromInline
    mutating func setValue(_ value: CGFloat, for axis: Axis) {
        switch axis {
            case .horizontal:
                x = value
            case .vertical:
                y = value
        }
    }

}

