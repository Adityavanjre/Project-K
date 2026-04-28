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
///
/// An alignment position along the horizontal axis.
///
/// Use horizontal alignment guides to tell DanceUI how to position views
/// relative to one another horizontally, like when you place views vertically
/// in an ``VStack``. The following example demonstrates common built-in
/// horizontal alignments:
///
///
/// You can generate the example above by creating a series of columns
/// implemented as vertical stacks, where you configure each stack with a
/// different alignment guide:
///
///     private struct HorizontalAlignmentGallery: View {
///         var body: some View {
///             HStack(spacing: 30) {
///                 column(alignment: .leading, text: "Leading")
///                 column(alignment: .center, text: "Center")
///                 column(alignment: .trailing, text: "Trailing")
///             }
///             .frame(height: 150)
///         }
///
///         private func column(alignment: HorizontalAlignment, text: String) -> some View {
///             VStack(alignment: alignment, spacing: 0) {
///                 Color.red.frame(width: 1)
///                 Text(text).font(.title).border(.gray)
///                 Color.red.frame(width: 1)
///             }
///         }
///     }
///
/// During layout, DanceUI aligns the views inside each stack by bringing
/// together the specified guides of the affected views. DanceUI calculates
/// the position of a guide for a particular view based on the characteristics
/// of the view. For example, the ``HorizontalAlignment/center`` guide appears
/// at half the width of the view. You can override the guide calculation for a
/// particular view using the ``View/alignmentGuide(_:computeValue:)-9mdoh``
/// view modifier.
///
/// ### Layout direction
///
/// When a user configures their device to use a left-to-right language like
/// English, the system places the leading alignment on the left and the
/// trailing alignment on the right, as the example from the previous section
/// demonstrates. However, in a right-to-left language, the system reverses
/// these. You can see this by using the ``View/environment(_:_:)`` view
/// modifier to explicitly override the ``EnvironmentValues/layoutDirection``
/// environment value for the view defined above:
///
///     HorizontalAlignmentGallery()
///         .environment(\.layoutDirection, .rightToLeft)
///
///
/// This automatic layout adjustment makes it easier to localize your app,
/// but it's still important to test your app for the different locales that
/// you ship into. For more information about the localization process, see
/// [localization](https://developer.apple.com/documentation/Xcode/localization).
///
/// ### Custom alignment guides
///
/// You can create a custom horizontal alignment by creating a type that
/// conforms to the ``AlignmentID`` protocol, and then using that type to
/// initalize a new static property on `HorizontalAlignment`:
///
///     private struct OneQuarterAlignment: AlignmentID {
///         static func defaultValue(in context: ViewDimensions) -> CGFloat {
///             context.width / 4
///         }
///     }
///
///     extension HorizontalAlignment {
///         static let oneQuarter = HorizontalAlignment(OneQuarterAlignment.self)
///     }
///
/// You implement the ``AlignmentID/defaultValue(in:)`` method to calculate
/// a default value for the custom alignment guide. The method receives a
/// ``ViewDimensions`` instance that you can use to calculate an appropriate
/// value based on characteristics of the view. The example above places
/// the guide at one quarter of the width of the view, as measured from the
/// view's origin.
///
/// You can then use the custom alignment guide like any built-in guide. For
/// example, you can use it as the `alignment` parameter to a ``VStack``,
/// or you can change it for a specific view using the
/// ``View/alignmentGuide(_:computeValue:)-9mdoh`` view modifier.
/// Custom alignment guides also automatically reverse in a right-to-left
/// environment, just like built-in guides.
///
/// ### Composite alignment
///
/// Combine a ``VerticalAlignment`` with a `HorizontalAlignment` to create a
/// composite ``Alignment`` that indicates both vertical and horizontal
/// positioning in one value. For example, you could combine your custom
/// `oneQuarter` horizontal alignment from the previous section with a built-in
/// ``VerticalAlignment/center`` vertical alignment to use in a ``ZStack``:
///
///     struct LayeredVerticalStripes: View {
///         var body: some View {
///             ZStack(alignment: Alignment(horizontal: .oneQuarter, vertical: .center)) {
///                 verticalStripes(color: .blue)
///                     .frame(width: 300, height: 150)
///                 verticalStripes(color: .green)
///                     .frame(width: 180, height: 80)
///             }
///         }
///
///         private func verticalStripes(color: Color) -> some View {
///             HStack(spacing: 1) {
///                 ForEach(0..<4) { _ in color }
///             }
///         }
///     }
///
/// The example above uses widths and heights that generate two mismatched sets
/// of four vertical stripes. The ``ZStack`` centers the two sets vertically and
/// aligns them horizontally one quarter of the way from the leading edge of
/// each set. In a left-to-right locale, this aligns the right edges of the
/// left-most stripes of each set:
///
@frozen
@available(iOS 13.0, *)
public struct HorizontalAlignment : AlignmentGuide {

    
    @usableFromInline
    internal let key: AlignmentKey
    
    @usableFromInline
    var id: AlignmentID.Type {
        key.id
    }
    
    public init(_ id: AlignmentID.Type) {
        self.key = AlignmentKey(bits: .horizontal(id))
    }
 
    struct Leading : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            VerticalAlignment.Top.defaultValue(in: context)
        }
    }

    struct Center : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context.width / 2.0
        }
    }

    struct Trailing : FrameAlignment {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            context.width
        }
    }
}

@available(iOS 13.0, *)
extension HorizontalAlignment {

    /// A guide marking the leading edge of the view.
    public static let leading = HorizontalAlignment(Leading.self)

    /// A guide marking the horizontal center of the view.
    public static let center = HorizontalAlignment(Center.self)

    /// A guide marking the trailing edge of the view.
    public static let trailing = HorizontalAlignment(Trailing.self)
}
