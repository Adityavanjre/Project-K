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

/// A container view that arranges its child views in a grid that
/// grows horizontally, creating items only as needed.
///
/// Use a lazy horizontal grid when you want to display a large, horizontally
/// scrollable collection of views arranged in a two dimensional layout. The
/// first view that you provide to the grid's `content` closure appears in the
/// top row of the column that's on the grid's leading edge. Additional views
/// occupy successive cells in the grid, filling the first column from top to
/// bottom, then the second column, and so on. The number of columns can grow
/// unbounded, but you specify the number of rows by providing a
/// corresponding number of ``GridItem`` instances to the grid's initializer.
///
/// The grid in the following example defines two rows and uses a ``ForEach``
/// structure to repeatedly generate a pair of ``Text`` views for the rows
/// in each column:
///
///     struct HorizontalSmileys: View {
///         let rows = [GridItem(.fixed(30)), GridItem(.fixed(30))]
///
///         var body: some View {
///             ScrollView(.horizontal) {
///                 LazyHGrid(rows: rows) {
///                     ForEach(0x1f600...0x1f679, id: \.self) { value in
///                         Text(String(format: "%x", value))
///                         Text(emoji(value))
///                             .font(.largeTitle)
///                     }
///                 }
///             }
///         }
///
///         private func emoji(_ value: Int) -> String {
///             guard let scalar = UnicodeScalar(value) else { return "?" }
///             return String(Character(scalar))
///         }
///     }
///
/// For each column in the grid, the top row shows a Unicode code point from
/// the "Smileys" group, and the bottom shows its corresponding emoji:
///
///
/// You can achieve a similar layout using a ``Grid`` container. Unlike a lazy
/// grid, which creates child views only when DanceUI needs to display
/// them, a regular grid creates all of its child views right away. This
/// enables the grid to provide better support for cell spacing and alignment.
/// Only use a lazy grid if profiling your app shows that a ``Grid`` view
/// performs poorly because it tries to load too many views at once.
@available(iOS 13.0, *)
public struct LazyHGrid<Content: View> : View, UnaryView, PrimitiveView {
    
    internal var tree: _VariadicView.Tree<LazyHGridLayout, Content>

    /// Creates a grid that grows horizontally, given the provided properties.
    ///
    /// - Parameters:
    ///   - rows: An array of grid items to size and position each column of
    ///    the grid.
    ///   - alignment: The alignment of the grid within its parent view.
    ///   - spacing: The spacing between the grid and the next item in its
    ///   parent view.
    ///   - pinnedViews: Views to pin to the bounds of a parent scroll view.
    ///   - content: The content of the grid.
    public init(rows: [GridItem], alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        let layout = LazyHGridLayout(rows: rows, alignment: alignment, spacing: spacing, pinnedViews: pinnedViews)
        tree = .init(layout, content: content)
    }

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Tree = _VariadicView.Tree<LazyHGridLayout, Content>
        return Tree._makeView(view: view[{.of(&$0.tree)}], inputs: inputs)
    }
}

/// A description of a row or a column in a lazy grid.
///
/// Use an array of `GridItem` instances to configure the layout of items in
/// a lazy grid. Each grid item in the array specifies layout properties like
/// size and spacing for the rows of a ``LazyHGrid`` or the columns of
/// a ``LazyVGrid``. The following example defines four rows for a
/// horizontal grid, each with different characteristics:
///
///     struct GridItemDemo: View {
///         let rows = [
///             GridItem(.fixed(30), spacing: 1),
///             GridItem(.fixed(60), spacing: 10),
///             GridItem(.fixed(90), spacing: 20),
///             GridItem(.fixed(10), spacing: 50)
///         ]
///
///         var body: some View {
///             ScrollView(.horizontal) {
///                 LazyHGrid(rows: rows, spacing: 5) {
///                     ForEach(0...300, id: \.self) { _ in
///                         Color.red.frame(width: 30)
///                         Color.green.frame(width: 30)
///                         Color.blue.frame(width: 30)
///                         Color.yellow.frame(width: 30)
///                     }
///                 }
///             }
///         }
///     }
///
/// A lazy horizontal grid sets the width of each column based on the widest
/// cell in the column. It can do this because it has access to all of the views
/// in a given column at once. In the example above, the ``Color`` views always
/// have the same fixed width, resulting in a uniform column width across the
/// whole grid.
///
/// However, a lazy horizontal grid doesn't generally have access to all the
/// views in a row, because it generates new cells as people scroll through
/// information in your app. Instead, it relies on a grid item for information
/// about each row. The example above indicates a different fixed height for
/// each row, and sets a different amount of spacing to appear after each row:
///
@available(iOS 13.0, *)
public struct GridItem {

    /// The size in the minor axis of one or more rows or columns in a grid
    /// layout.
    public enum Size {

        /// A single item with the specified fixed size.
        case fixed(_: CGFloat)

        /// A single flexible item.
        ///
        /// The size of this item is the size of the grid with spacing and
        /// inflexible items removed, divided by the number of flexible items,
        /// clamped to the provided bounds.
        case flexible(minimum: CGFloat = 10, maximum: CGFloat = .infinity)

        /// Multiple items in the space of a single flexible item.
        ///
        /// This size case places one or more items into the space assigned to
        /// a single `flexible` item, using the provided bounds and
        /// spacing to decide exactly how many items fit. This approach prefers
        /// to insert as many items of the `minimum` size as possible
        /// but lets them increase to the `maximum` size.
        case adaptive(minimum: CGFloat, maximum: CGFloat = .infinity)
    }

    /// The size of the item, which is the width of a column item or the
    /// height of a row item.
    public var size: GridItem.Size

    /// The spacing to the next item.
    ///
    /// If this value is `nil`, the item uses a reasonable default for the
    /// current platform.
    // 0x18
    public var spacing: CGFloat?

    /// The alignment to use when placing each view.
    ///
    /// Use this property to anchor the view's relative position to the same
    /// relative position in the view's assigned grid space.
    // 0x28
    public var alignment: Alignment?

    /// Creates a grid item with the provided size, spacing, and alignment
    /// properties.
    ///
    /// - Parameters:
    ///   - size: The size of the grid item.
    ///   - spacing: The spacing to use between this and the next item.
    ///   - alignment: The alignment to use for this grid item.
    public init(_ size: GridItem.Size = .flexible(), spacing: CGFloat? = nil, alignment: Alignment? = nil) {
        self.size = size
        self.spacing = spacing
        self.alignment = alignment
    }
}

@available(iOS 13.0, *)
internal struct LazyHGridLayout: _VariadicView_UnaryViewRoot, Animatable, HVGrid {
    
    internal typealias AnimatableData = EmptyAnimatableData
    
    internal typealias State = _IncrementalStack_State<Self>
    
    internal static var majorAxis: Axis {
        .horizontal
    }
    
    internal var items: [GridItem] {
        rows
    }
    
    internal var alignmentFraction: CGFloat {
        alignment.fraction
    }
    
    internal var alignmentID: AlignmentID.Type {
        alignment.id
    }

    internal var rows: [GridItem]

    internal var alignment: VerticalAlignment

    internal var spacing: CGFloat?

    internal var pinnedViews: PinnedScrollableViews
}

