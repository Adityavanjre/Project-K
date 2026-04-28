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

/// An enumeration to indicate one edge of a rectangle.
@frozen
@available(iOS 13.0, *)
public enum Edge: Int8, CaseIterable, Hashable, RawRepresentable {
    
    /// The raw type that can be used to represent all values of the conforming
    /// type.
    ///
    /// Every distinct value of the conforming type has a corresponding unique
    /// value of the `RawValue` type, but there may be values of the `RawValue`
    /// type that don't have a corresponding value of the conforming type.
    public typealias RawValue = Int8
    

    case top
    

    case leading
    

    case bottom
    

    case trailing
    
    internal init(_ accessibilityScrollDirection: UIAccessibilityScrollDirection) {
        switch accessibilityScrollDirection {
        case .right:
            self = .trailing
        case .left:
            self = .leading
        case .up:
            self = .top
        case .down:
            self = .bottom
        case .next:
            self = .trailing
        case .previous:
            self = .leading
        @unknown default:
            _danceuiFatalError()
        }
    }
    
    internal enum Alignment {
        
        case topLeading
        
        case bottomTrailing
        
    }
    
    internal init(axis: Axis, alignment: Alignment) {
        switch (axis, alignment) {
        case (.vertical, .topLeading):
            self = .top
        case (.vertical, .bottomTrailing):
            self = .bottom
        case (.horizontal, .topLeading):
            self = .leading
        case (.horizontal, .bottomTrailing):
            self = .trailing
        }
    }
    
    /// An efficient set of `Edge`s.
    @frozen
    public struct Set: OptionSet {
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = Edge.Set
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = Edge.Set.Element
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = Int8
        
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
        
        public static let top = Set(rawValue: 0x1 << Edge.top.rawValue)
        public static let leading = Set(rawValue: 0x1 << Edge.leading.rawValue)
        public static let bottom = Set(rawValue: 0x1 << Edge.bottom.rawValue)
        public static let trailing = Set(rawValue: 0x1 << Edge.trailing.rawValue)
        public static let horizontal = Set([Set.leading, Set.trailing])
        public static let vertical = Set([Set.top, Set.bottom])
        
        public static let all = Edge.Set([Set.top, Set.leading, Set.bottom, Set.trailing])
        
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
        @inlinable
        public init(rawValue: Int8) {
            self.rawValue = rawValue
        }
        
        /// Creates an instance containing just `e`
        @inlinable
        public init(_ e: Edge) {
            self.init(rawValue: 0x1 << e.rawValue)
        }
        
        @inlinable
        public func contains(_ edge: Edge) -> Bool {
            self.contains(.init(edge))
        }
    }
}
