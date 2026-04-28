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
/// grows vertically, creating items only as needed.
///
/// Use a lazy vertical grid when you want to display a large, vertically
/// scrollable collection of views arranged in a two dimensional layout. The
/// first view that you provide to the grid's `content` closure appears in the
/// top row of the column that's on the grid's leading edge. Additional views
/// occupy successive cells in the grid, filling the first row from leading to
/// trailing edges, then the second row, and so on. The number of rows can grow
/// unbounded, but you specify the number of columns by providing a
/// corresponding number of ``GridItem`` instances to the grid's initializer.
///
/// The grid in the following example defines two columns and uses a
/// ``ForEach`` structure to repeatedly generate a pair of ``Text`` views for
/// the columns in each row:
///
///     struct VerticalSmileys: View {
///         let columns = [GridItem(.flexible()), GridItem(.flexible())]
///
///         var body: some View {
///              ScrollView {
///                  LazyVGrid(columns: columns) {
///                      ForEach(0x1f600...0x1f679, id: \.self) { value in
///                          Text(String(format: "%x", value))
///                          Text(emoji(value))
///                              .font(.largeTitle)
///                      }
///                  }
///              }
///         }
///
///         private func emoji(_ value: Int) -> String {
///             guard let scalar = UnicodeScalar(value) else { return "?" }
///             return String(Character(scalar))
///         }
///     }
///
/// For each row in the grid, the first column shows a Unicode code point from
/// the "Smileys" group, and the second shows its corresponding emoji:
///
///
/// You can achieve a similar layout using a ``Grid`` container. Unlike a lazy
/// grid, which creates child views only when DanceUI needs to display
/// them, a regular grid creates all of its child views right away. This
/// enables the grid to provide better support for cell spacing and alignment.
/// Only use a lazy grid if profiling your app shows that a ``Grid`` view
/// performs poorly because it tries to load too many views at once.
@available(iOS 13.0, *)
public struct LazyVGrid<Content: View>: View, UnaryView, PrimitiveView {
    
    internal var tree: _VariadicView.Tree<LazyVGridLayout, Content>

    /// Creates a grid that grows vertically, given the provided properties.
    ///
    /// - Parameters:
    ///   - columns: An array of grid items to size and position each row of
    ///    the grid.
    ///   - alignment: The alignment of the grid within its parent view.
    ///   - spacing: The spacing between the grid and the next item in its
    ///   parent view.
    ///   - pinnedViews: Views to pin to the bounds of a parent scroll view.
    ///   - content: The content of the grid.
    public init(columns: [GridItem], alignment: HorizontalAlignment = .center, spacing: CGFloat? = nil, pinnedViews: PinnedScrollableViews = .init(), @ViewBuilder content: () -> Content) {
        let layout = LazyVGridLayout(columns: columns, alignment: alignment, spacing: spacing, pinnedViews: pinnedViews)
        tree = .init(layout, content: content)
    }

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        typealias Tree = _VariadicView.Tree<LazyVGridLayout, Content>
        return Tree._makeView(view: view[{.of(&$0.tree)}], inputs: inputs)
    }
}

@available(iOS 13.0, *)
internal struct LazyVGridLayout: _VariadicView_UnaryViewRoot, Animatable, HVGrid {
    
    internal typealias AnimatableData = EmptyAnimatableData
    
    internal typealias State = _IncrementalStack_State<Self>
    
    internal static var majorAxis: Axis {
        .vertical
    }
    
    internal var items: [GridItem] {
        columns
    }
    
    internal var alignmentFraction: CGFloat {
        alignment.fraction
    }
    
    internal var alignmentID: AlignmentID.Type {
        alignment.id
    }

    internal var columns: [GridItem]

    internal var alignment: HorizontalAlignment

    internal var spacing: CGFloat?

    internal var pinnedViews: PinnedScrollableViews

}
