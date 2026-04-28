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

/// An edge on the vertical axis.
@frozen 
@available(iOS 13.0, *)
public enum VerticalEdge: Int8, CaseIterable, Codable {

    /// The top edge.
    case top

    /// The bottom edge.
    case bottom

    /// An efficient set of `VerticalEdge`s.

    @frozen public struct Set: OptionSet {
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = VerticalEdge.Set

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

        /// A set containing only the top vertical edge.
        public static let top: VerticalEdge.Set = VerticalEdge.Set(rawValue: 1)

        /// A set containing only the bottom vertical edge.
        public static let bottom: VerticalEdge.Set = VerticalEdge.Set(rawValue: 2)

        /// A set containing the top and bottom vertical edges.
        public static let all: VerticalEdge.Set = VerticalEdge.Set(rawValue: 3)

        /// Creates an instance containing just `e`
        public init(_ e: VerticalEdge) {
            switch e {
            case .top:
                self = .top
            case .bottom:
                self = .bottom
            }
        }

        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = VerticalEdge.Set.Element

        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = Int8
    }

    /// A type that can represent a collection of all values of this type.
    public typealias AllCases = [VerticalEdge]


    /// A collection of all values of this type.
    public static var allCases: [VerticalEdge] {
        return [.top, .bottom]
    }
}

@available(iOS 13.0, *)
extension VerticalEdge: Hashable, RawRepresentable, Sendable {
}

@available(iOS 13.0, *)
extension VerticalEdge.Set : Sendable {
}

