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

@frozen
@available(iOS 13.0, *)
public enum HorizontalEdge: Int8, CaseIterable, Codable {

    /// The leading edge.
    case leading

    /// The trailing edge.
    case trailing

    /// An efficient set of `HorizontalEdge`s.

    @frozen public struct Set: OptionSet {
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = HorizontalEdge.Set
        
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

        /// A set containing only the leading horizontal edge.
        public static let leading: HorizontalEdge.Set = HorizontalEdge.Set(rawValue: 1)

        /// A set containing only the trailing horizontal edge.
        public static let trailing: HorizontalEdge.Set = HorizontalEdge.Set(rawValue: 2)

        /// A set containing the leading and trailing horizontal edges.
        public static let all: HorizontalEdge.Set = HorizontalEdge.Set(rawValue: 3)

        /// Creates an instance containing just `e`.
        public init(_ e: HorizontalEdge) {
            switch e {
            case .leading:
                self = .leading
            case .trailing:
                self = .trailing
            }
        }

        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = HorizontalEdge.Set.Element

    }

    /// A type that can represent a collection of all values of this type.
    public typealias AllCases = [HorizontalEdge]


    /// A collection of all values of this type.
    public static var allCases: [HorizontalEdge] {
        return [.leading, .trailing]
    }
}

@available(iOS 13.0, *)
extension HorizontalEdge: Hashable, RawRepresentable, Sendable {
}

@available(iOS 13.0, *)
extension HorizontalEdge.Set: Sendable {
}
