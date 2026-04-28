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

/// A type that you use to create custom alignment guides.
///
/// Every built-in alignment guide that ``VerticalAlignment`` or
/// ``HorizontalAlignment`` defines as a static property, like
/// ``VerticalAlignment/top`` or ``HorizontalAlignment/leading``, has a
/// unique alignment identifier type that produces the default offset for
/// that guide. To create a custom alignment guide, define your own alignment
/// identifier as a type that conforms to the `AlignmentID` protocol, and
/// implement the required ``AlignmentID/defaultValue(in:)`` method:
///
///     private struct FirstThirdAlignment: AlignmentID {
///         static func defaultValue(in context: ViewDimensions) -> CGFloat {
///             context.height / 3
///         }
///     }
///
/// When implementing the method, calculate the guide's default offset
/// from the view's origin. If it's helpful, you can use information from the
/// ``ViewDimensions`` input in the calculation. This parameter provides context
/// about the specific view that's using the guide. The above example creates an
/// identifier called `FirstThirdAlignment` and calculates a default value
/// that's one-third of the height of the aligned view.
///
/// Use the identifier's type to create a static property in an extension of
/// one of the alignment guide types, like ``VerticalAlignment``:
///
///     extension VerticalAlignment {
///         static let firstThird = VerticalAlignment(FirstThirdAlignment.self)
///     }
///
/// You can apply your custom guide like any of the built-in guides. For
/// example, you can use an ``HStack`` to align its views at one-third
/// of their height using the guide defined above:
///
///     struct StripesGroup: View {
///         var body: some View {
///             HStack(alignment: .firstThird, spacing: 1) {
///                 HorizontalStripes().frame(height: 60)
///                 HorizontalStripes().frame(height: 120)
///                 HorizontalStripes().frame(height: 90)
///             }
///         }
///     }
///
///     struct HorizontalStripes: View {
///         var body: some View {
///             VStack(spacing: 1) {
///                 ForEach(0..<3) { _ in Color.blue }
///             }
///         }
///     }
///
/// Because each set of stripes has three equal, vertically stacked
/// rectangles, they align at the bottom edge of the top rectangle. This
/// corresponds in each case to a third of the overall height, as
/// measured from the origin at the top of each set of stripes:
///
///
/// You can also use the ``View/alignmentGuide(_:computeValue:)-3t36q`` view
/// modifier to alter the behavior of your custom guide for a view, as you
/// might alter a built-in guide. For example, you can change
/// one of the stacks of stripes from the previous example to align its
/// `firstThird` guide at two thirds of the height instead:
///
///     struct StripesGroupModified: View {
///         var body: some View {
///             HStack(alignment: .firstThird, spacing: 1) {
///                 HorizontalStripes().frame(height: 60)
///                 HorizontalStripes().frame(height: 120)
///                 HorizontalStripes().frame(height: 90)
///                     .alignmentGuide(.firstThird) { context in
///                         2 * context.height / 3
///                     }
///             }
///         }
///     }
///
/// The modified guide calculation causes the affected view to place the
/// bottom edge of its middle rectangle on the `firstThird` guide, which aligns
/// with the bottom edge of the top rectangle in the other two groups:
///
///
@available(iOS 13.0, *)
public protocol AlignmentID {

    /// Calculates a default value for the corresponding guide in the specified
    /// context.
    ///
    /// Implement this method when you create a type that conforms to the
    /// ``AlignmentID`` protocol. Use the method to calculate the default
    /// offset of the corresponding alignment guide. DanceUI interprets the
    /// value that you return as an offset in the coordinate space of the
    /// view that's being laid out. For example, you can use the context to
    /// return a value that's one-third of the height of the view:
    ///
    ///     private struct FirstThirdAlignment: AlignmentID {
    ///         static func defaultValue(in context: ViewDimensions) -> CGFloat {
    ///             context.height / 3
    ///         }
    ///     }
    ///
    /// You can override the default value that this method returns for a
    /// particular guide by adding the
    /// ``View/alignmentGuide(_:computeValue:)-6bhhk`` view modifier to a
    /// particular view.
    ///
    /// - Parameter context: The context of the view that you apply
    ///   the alignment guide to. The context gives you the view's dimensions,
    ///   as well as the values of other alignment guides that apply to the
    ///   view, including both built-in and custom guides. You can use any of
    ///   these values, if helpful, to calculate the value for your custom
    ///   guide.
    ///
    /// - Returns: The offset of the guide from the origin in the
    ///   view's coordinate space.
    static func defaultValue(in context: ViewDimensions) -> CGFloat
    
    static func _combineExplicit(childValue: CGFloat, _: Int, into: inout CGFloat?)
}

@available(iOS 13.0, *)
extension AlignmentID {
    
    public static func _combineExplicit(childValue: CGFloat, _ n: Int, into parentValue: inout CGFloat?) {
        if n != 0 {
            assert(parentValue != nil)
        } else {
            parentValue = childValue
        }
        
        var alignmentValue: CGFloat = parentValue!
        alignmentValue *= CGFloat(n)
        alignmentValue += childValue
        
        let seedValue: CGFloat = CGFloat(n) + 1
        alignmentValue /= seedValue
        
        parentValue = alignmentValue
    }
}
