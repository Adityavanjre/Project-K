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

import CoreGraphics

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
///
@frozen
@available(iOS 13.0, *)
public struct VerticalAlignment : AlignmentGuide {

    @usableFromInline
    internal let key: AlignmentKey
    
    @usableFromInline
    var id: AlignmentID.Type {
        key.id
    }
    
    /// Creates an instance with the given ID.
    ///
    /// Note: each instance should have a unique ID.
    public init(_ id: AlignmentID.Type) {
        self.key = AlignmentKey(bits: .vertical(id))
    }
    
    struct Top : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            0
        }
    }

    struct Center : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context.height / 2.0
        }
    }

    struct Bottom : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            LastTextBaseline.defaultValue(in: context)
        }
    }
    
    struct FirstTextBaseline: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            LastTextBaseline.defaultValue(in: context)
        }
        
        static func _combineExplicit(childValue: CGFloat, _: Int, into alignment: inout CGFloat?) {
            let tempAlignment = alignment ?? CGFloat.infinity
            alignment = min(tempAlignment, childValue)
        }
    }
    
    struct LastTextBaseline: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context.height
        }
        
        static func _combineExplicit(childValue: CGFloat, _: Int, into alignment: inout CGFloat?) {
            alignment = max(alignment ?? -.infinity, childValue)
        }
    }
    
    struct FirstTextLineCenter: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context[VerticalAlignment.center.key]
        }
    }
}

@available(iOS 13.0, *)
extension VerticalAlignment {

    /// A guide marking the top edge of the view.
    public static let top = VerticalAlignment(Top.self)

    /// A guide marking the vertical center of the view.
    public static let center = VerticalAlignment(Center.self)

    /// A guide marking the bottom edge of the view.
    public static let bottom = VerticalAlignment(Bottom.self)

    /// A guide marking the topmost text baseline view.
    public static let firstTextBaseline = VerticalAlignment(FirstTextBaseline.self)

    /// A guide marking the bottom-most text baseline in a view.
    public static let lastTextBaseline = VerticalAlignment(LastTextBaseline.self)
}

@available(iOS 13.0, *)

extension VerticalAlignment {
    
    static let firstTextLineCenter = VerticalAlignment(FirstTextLineCenter.self)
    
}
