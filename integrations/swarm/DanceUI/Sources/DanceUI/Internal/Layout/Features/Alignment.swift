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

/// An alignment in both axes.
///
/// An `Alignment` contains a ``HorizontalAlignment`` guide and a
/// ``VerticalAlignment`` guide. Specify an alignment to direct the behavior of
/// certain layout containers and modifiers, like when you place views in a
/// ``ZStack``, or layer a view in front of or behind another view using
/// ``View/overlay(alignment:content:)`` or
/// ``View/background(alignment:content:)``, respectively. During layout,
/// DanceUI brings the specified guides of the affected views together,
/// aligning the views.
///
/// DanceUI provides a set of built-in alignments that represent common
/// combinations of the built-in horizontal and vertical alignment guides.
/// The blue boxes in the following diagram demonstrate the alignment named
/// by each box's label, relative to the background view:
///
///
/// The following code generates the diagram above, where each blue box appears
/// in an overlay that's configured with a different alignment:
///
///     struct AlignmentGallery: View {
///         var body: some View {
///             BackgroundView()
///                 .overlay(alignment: .topLeading) { box(".topLeading") }
///                 .overlay(alignment: .top) { box(".top") }
///                 .overlay(alignment: .topTrailing) { box(".topTrailing") }
///                 .overlay(alignment: .leading) { box(".leading") }
///                 .overlay(alignment: .center) { box(".center") }
///                 .overlay(alignment: .trailing) { box(".trailing") }
///                 .overlay(alignment: .bottomLeading) { box(".bottomLeading") }
///                 .overlay(alignment: .bottom) { box(".bottom") }
///                 .overlay(alignment: .bottomTrailing) { box(".bottomTrailing") }
///                 .overlay(alignment: .leadingLastTextBaseline) { box(".leadingLastTextBaseline") }
///                 .overlay(alignment: .trailingFirstTextBaseline) { box(".trailingFirstTextBaseline") }
///         }
///
///         private func box(_ name: String) -> some View {
///             Text(name)
///                 .font(.system(.caption, design: .monospaced))
///                 .padding(2)
///                 .foregroundColor(.white)
///                 .background(.blue.opacity(0.8), in: Rectangle())
///         }
///     }
///
///     private struct BackgroundView: View {
///         var body: some View {
///             Grid(horizontalSpacing: 0, verticalSpacing: 0) {
///                 GridRow {
///                     Text("Some text in an upper quadrant")
///                     Color.gray.opacity(0.3)
///                 }
///                 GridRow {
///                     Color.gray.opacity(0.3)
///                     Text("More text in a lower quadrant")
///                 }
///             }
///             .aspectRatio(1, contentMode: .fit)
///             .foregroundColor(.secondary)
///             .border(.gray)
///         }
///     }
///
/// To avoid crowding, the alignment diagram shows only two of the available
/// text baseline alignments. The others align as their names imply. Notice that
/// the first text baseline alignment aligns with the top-most line of text in
/// the background view, while the last text baseline aligns with the
/// bottom-most line. For more information about text baseline alignment, see
/// ``VerticalAlignment``.
///
/// In a left-to-right language like English, the leading and trailing
/// alignments appear on the left and right edges, respectively. DanceUI
/// reverses these in right-to-left language environments. For more
/// information, see ``HorizontalAlignment``.
///
/// ### Custom alignment
///
/// You can create custom alignments --- which you typically do to make use
/// of custom horizontal or vertical guides --- by using the
/// ``init(horizontal:vertical:)`` initializer. For example, you can combine
/// a custom vertical guide called `firstThird` with the built-in horizontal
/// ``HorizontalAlignment/center`` guide, and use it to configure a ``ZStack``:
///
///     ZStack(alignment: Alignment(horizontal: .center, vertical: .firstThird)) {
///         // ...
///     }
///
/// For more information about creating custom guides, including the code
/// that creates the custom `firstThird` alignment in the example above,
/// see ``AlignmentID``.
@frozen
@available(iOS 13.0, *)
public struct Alignment : Equatable {
    
    /// The alignment on the horizontal axis.
    ///
    /// Set this value when you initialize an alignment using the
    /// ``init(horizontal:vertical:)`` method. Use one of the built-in
    /// ``HorizontalAlignment`` guides, like ``HorizontalAlignment/center``,
    /// or a custom guide that you create.
    ///
    /// For information about creating custom guides, see ``AlignmentID``.
    public var horizontal: HorizontalAlignment
    
    /// The alignment on the vertical axis.
    ///
    /// Set this value when you initialize an alignment using the
    /// ``init(horizontal:vertical:)`` method. Use one of the built-in
    /// ``VerticalAlignment`` guides, like ``VerticalAlignment/center``,
    /// or a custom guide that you create.
    ///
    /// For information about creating custom guides, see ``AlignmentID``.
    public var vertical: VerticalAlignment
    
    /// Creates a custom alignment value with the specified horizontal
    /// and vertical alignment guides.
    ///
    /// DanceUI provides a variety of built-in alignments that combine built-in
    /// ``HorizontalAlignment`` and ``VerticalAlignment`` guides. Use this
    /// initializer to create a custom alignment that makes use
    /// of a custom horizontal or vertical guide, or both.
    ///
    /// For example, you can combine a custom vertical guide called
    /// `firstThird` with the built-in ``HorizontalAlignment/center``
    /// guide, and use it to configure a ``ZStack``:
    ///
    ///     ZStack(alignment: Alignment(horizontal: .center, vertical: .firstThird)) {
    ///         // ...
    ///     }
    ///
    /// For more information about creating custom guides, including the code
    /// that creates the custom `firstThird` alignment in the example above,
    /// see ``AlignmentID``.
    ///
    /// - Parameters:
    ///   - horizontal: The alignment on the horizontal axis.
    ///   - vertical: The alignment on the vertical axis.
    @inlinable
    public init(horizontal: HorizontalAlignment,
                vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    /// A guide that marks the center of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/center``
    /// horizontal guide and the ``VerticalAlignment/center``
    /// vertical guide:
    ///
    public static let center = Alignment(horizontal: .center, vertical: .center)
    
    /// A guide that marks the leading edge of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/leading``
    /// horizontal guide and the ``VerticalAlignment/center``
    /// vertical guide:
    ///
    public static let leading = Alignment(horizontal: .leading, vertical: .center)
    
    /// A guide that marks the trailing edge of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/trailing``
    /// horizontal guide and the ``VerticalAlignment/center``
    /// vertical guide:
    ///
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)
    
    /// A guide that marks the top edge of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/center``
    /// horizontal guide and the ``VerticalAlignment/top``
    /// vertical guide:
    ///
    public static let top = Alignment(horizontal: .center, vertical: .top)
    
    /// A guide that marks the bottom edge of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/center``
    /// horizontal guide and the ``VerticalAlignment/bottom``
    /// vertical guide:
    ///
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)
    
    /// A guide that marks the top and leading edges of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/leading``
    /// horizontal guide and the ``VerticalAlignment/top``
    /// vertical guide:
    ///
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
    
    /// A guide that marks the top and trailing edges of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/trailing``
    /// horizontal guide and the ``VerticalAlignment/top``
    /// vertical guide:
    ///
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)
    
    /// A guide that marks the bottom and leading edges of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/leading``
    /// horizontal guide and the ``VerticalAlignment/bottom``
    /// vertical guide:
    ///
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
    
    /// A guide that marks the bottom and trailing edges of the view.
    ///
    /// This alignment combines the ``HorizontalAlignment/trailing``
    /// horizontal guide and the ``VerticalAlignment/bottom``
    /// vertical guide:
    ///
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)
    
}

@available(iOS 13.0, *)
extension Alignment {

    /// A guide that marks the top-most text baseline in a view.
    ///
    /// This alignment combines the ``HorizontalAlignment/center``
    /// horizontal guide and the ``VerticalAlignment/firstTextBaseline``
    /// vertical guide:
    ///
    public static var centerFirstTextBaseline: Alignment {
        .init(horizontal: .center, vertical: .firstTextBaseline)
    }

    /// A guide that marks the bottom-most text baseline in a view.
    ///
    /// This alignment combines the ``HorizontalAlignment/center``
    /// horizontal guide and the ``VerticalAlignment/lastTextBaseline``
    /// vertical guide:
    ///
    public static var centerLastTextBaseline: Alignment {
        .init(horizontal: .center, vertical: .lastTextBaseline)
    }

    /// A guide that marks the leading edge and top-most text baseline in a
    /// view.
    ///
    /// This alignment combines the ``HorizontalAlignment/leading``
    /// horizontal guide and the ``VerticalAlignment/firstTextBaseline``
    /// vertical guide:
    ///
    public static var leadingFirstTextBaseline: Alignment {
        .init(horizontal: .leading, vertical: .firstTextBaseline)
    }

    /// A guide that marks the leading edge and bottom-most text baseline
    /// in a view.
    ///
    /// This alignment combines the ``HorizontalAlignment/leading``
    /// horizontal guide and the ``VerticalAlignment/lastTextBaseline``
    /// vertical guide:
    ///
    public static var leadingLastTextBaseline: Alignment {
        .init(horizontal: .leading, vertical: .lastTextBaseline)
    }

    /// A guide that marks the trailing edge and top-most text baseline in
    /// a view.
    ///
    /// This alignment combines the ``HorizontalAlignment/trailing``
    /// horizontal guide and the ``VerticalAlignment/firstTextBaseline``
    /// vertical guide:
    ///
    public static var trailingFirstTextBaseline: Alignment {
        .init(horizontal: .trailing, vertical: .firstTextBaseline)
    }

    /// A guide that marks the trailing edge and bottom-most text baseline
    /// in a view.
    ///
    /// This alignment combines the ``HorizontalAlignment/trailing``
    /// horizontal guide and the ``VerticalAlignment/lastTextBaseline``
    /// vertical guide:
    ///
    public static var trailingLastTextBaseline: Alignment {
        .init(horizontal: .trailing, vertical: .lastTextBaseline)
    }
}
