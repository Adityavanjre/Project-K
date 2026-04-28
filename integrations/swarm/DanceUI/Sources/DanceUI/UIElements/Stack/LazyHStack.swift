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

/// A view that arranges its children in a line that grows horizontally,
/// creating items only as needed.
///
/// The stack is "lazy," in that the stack view doesn't create items until
/// it needs to render them onscreen.
///
/// In the following example, a ``ScrollView`` contains a `LazyHStack` that
/// consists of a horizontal row of text views. The stack aligns to the top
/// of the scroll view and uses 10-point spacing between each text view.
///
///     ScrollView(.horizontal) {
///         LazyHStack(alignment: .top, spacing: 10) {
///             ForEach(1...100, id: \.self) {
///                 Text("Column \($0)")
///             }
///         }
///     }
@available(iOS 13.0, *)
public struct LazyHStack<Content: View> : View, PrimitiveView, UnaryView {
    
    internal var tree: _VariadicView.Tree<LazyHStackLayout, Content>
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required `body` property.
    public typealias Body = Never
    
    /// Creates a lazy horizontal stack view with the given spacing,
    /// vertical alignment, pinning behavior, and content.
    ///
    /// - Parameters:
    ///     - alignment: The guide for aligning the subviews in this stack. All
    ///       child views have the same vertical screen coordinate.
    ///     - spacing: The distance between adjacent subviews, or `nil` if you
    ///       want the stack to choose a default distance for each pair of
    ///       subviews.
    ///     - pinnedViews: The kinds of child views that will be pinned.
    ///     - content: A view builder that creates the content of this stack.
    public init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        let layout = LazyHStackLayout(base: .init(alignment: alignment, spacing: spacing), pinnedViews: pinnedViews)
        tree = .init(layout, content: content)
    }
    
    public static func _makeView(view: _GraphValue<LazyHStack<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Tree = _VariadicView.Tree<LazyHStackLayout, Content>
        return Tree._makeView(view: view[{.of(&$0.tree)}], inputs: inputs)
    }
}

/// A set of view types that may be pinned to the bounds of a scroll view.
@available(iOS 13.0, *)
public struct PinnedScrollableViews: OptionSet {
    
    // The corresponding value of the raw type.
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
    public let rawValue: UInt32
    
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
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    /// The header view of each `Section` will be pinned.
    public static let sectionHeaders: PinnedScrollableViews = .init(rawValue: 0x1)

    /// The footer view of each `Section` will be pinned.
    public static let sectionFooters: PinnedScrollableViews = .init(rawValue: 0x2)

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = PinnedScrollableViews

    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias Element = PinnedScrollableViews

    /// The raw type that can be used to represent all values of the conforming
    /// type.
    ///
    /// Every distinct value of the conforming type has a corresponding unique
    /// value of the `RawValue` type, but there may be values of the `RawValue`
    /// type that don't have a corresponding value of the conforming type.
    public typealias RawValue = UInt32
    
    public var isEmpty: Bool {
        rawValue == 0
    }
}
