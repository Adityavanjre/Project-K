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

/// A view's size and alignment guides in its own coordinate space.
///
/// This structure contains the size and alignment guides of a view.
/// You receive an instance of this structure to use in a variety of
/// layout calculations, like when you:
///
/// * Define a default value for a custom alignment guide;
///   see ``AlignmentID/defaultValue(in:)``.
/// * Modify an alignment guide on a view;
///   see ``View/alignmentGuide(_:computeValue:)-9mdoh``.
/// * Ask for the dimensions of a subview of a custom view layout;
///   see ``LayoutSubview/dimensions(in:)``.
///
/// ### Custom alignment guides
///
/// You receive an instance of this structure as the `context` parameter to
/// the ``AlignmentID/defaultValue(in:)`` method that you implement to produce
/// the default offset for an alignment guide, or as the first argument to the
/// closure you provide to the ``View/alignmentGuide(_:computeValue:)-6y3u2``
/// view modifier to override the default calculation for an alignment guide.
/// In both cases you can use the instance, if helpful, to calculate the
/// offset for the guide. For example, you could compute a default offset
/// for a custom ``VerticalAlignment`` as a fraction of the view's ``height``:
///
///     private struct FirstThirdAlignment: AlignmentID {
///         static func defaultValue(in context: ViewDimensions) -> CGFloat {
///             context.height / 3
///         }
///     }
///
///     extension VerticalAlignment {
///         static let firstThird = VerticalAlignment(FirstThirdAlignment.self)
///     }
///
/// As another example, you could use the view dimensions instance to look
/// up the offset of an existing guide and modify it:
///
///     struct ViewDimensionsOffset: View {
///         var body: some View {
///             VStack(alignment: .leading) {
///                 Text("Default")
///                 Text("Indented")
///                     .alignmentGuide(.leading) { context in
///                         context[.leading] - 10
///                     }
///             }
///         }
///     }
///
/// The example above indents the second text view because the subtraction
/// moves the second text view's leading guide in the negative x direction,
/// which is to the left in the view's coordinate space. As a result,
/// DanceUI moves the second text view to the right, relative to the first
/// text view, to keep their leading guides aligned:
///
///
/// ### Layout direction
///
/// The discussion above describes a left-to-right language environment,
/// but you don't change your guide calculation to operate in a right-to-left
/// environment. DanceUI moves the view's origin from the left to the right side
/// of the view and inverts the positive x direction. As a result,
/// the existing calculation produces the same effect, but in the opposite
/// direction.
///
/// You can see this if you use the ``View/environment(_:_:)``
/// modifier to set the ``EnvironmentValues/layoutDirection`` property for the
/// view that you defined above:
///
///     ViewDimensionsOffset()
///         .environment(\.layoutDirection, .rightToLeft)
///
/// With no change in your guide, this produces the desired effect ---
/// it indents the second text view's right side, relative to the
/// first text view's right side. The leading edge is now on the right,
/// and the direction of the offset is reversed:
///
@available(iOS 13.0, *)
public struct ViewDimensions: Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: ViewDimensions, rhs: ViewDimensions) -> Bool {
        lhs.guideComputer == rhs.guideComputer && lhs.size.value == rhs.size.value
    }

    internal let guideComputer: LayoutComputer

    internal var size: ViewSize
    
    internal init(guideComputer: LayoutComputer, size: ViewSize) {
        self.guideComputer = guideComputer
        self.size = size
    }
    
    static let invalidValue: ViewDimensions = ViewDimensions(guideComputer: .defaultValue, size: ViewSize(value: .invalidValue, _proposal: .invalidValue))
    
    static let zero: ViewDimensions = ViewDimensions(guideComputer: .defaultValue, size: ViewSize(value: .zero, _proposal: .zero))
    
    /// The view's width
    public var width: CGFloat {
        size.value.width
    }

    /// The view's height
    public var height: CGFloat {
        size.value.height
    }

    /// Gets the value of the given horizontal guide.
    ///
    /// Find the offset of a particular guide in the corresponding view by
    /// using that guide as an index to read from the context:
    ///
    ///     .alignmentGuide(.leading) { context in
    ///         context[.leading] - 10
    ///     }
    ///
    /// For information about using subscripts in Swift to access member
    /// elements of a collection, list, or, sequence, see
    /// [Subscripts](https://docs.swift.org/swift-book/LanguageGuide/Subscripts.html)
    /// in _The Swift Programming Language_.
    public subscript(guide: HorizontalAlignment) -> CGFloat {
        self[guide.key]
    }

    /// Gets the value of the given vertical guide.
    ///
    /// Find the offset of a particular guide in the corresponding view by
    /// using that guide as an index to read from the context:
    ///
    ///     .alignmentGuide(.top) { context in
    ///         context[.top] - 10
    ///     }
    ///
    /// For information about using subscripts in Swift to access member
    /// elements of a collection, list, or, sequence, see
    /// [Subscripts](https://docs.swift.org/swift-book/LanguageGuide/Subscripts.html)
    /// in _The Swift Programming Language_.
    public subscript(guide: VerticalAlignment) -> CGFloat {
        self[guide.key]
    }

    /// Gets the explicit value of the given horizontal alignment guide.
    ///
    /// Find the horizontal offset of a particular guide in the corresponding
    /// view by using that guide as an index to read from the context:
    ///
    ///     .alignmentGuide(.leading) { context in
    ///         context[.leading] - 10
    ///     }
    ///
    /// This subscript returns `nil` if no value exists for the guide.
    ///
    /// For information about using subscripts in Swift to access member
    /// elements of a collection, list, or, sequence, see
    /// [Subscripts](https://docs.swift.org/swift-book/LanguageGuide/Subscripts.html)
    /// in _The Swift Programming Language_.
    public subscript(explicit guide: HorizontalAlignment) -> CGFloat? {
        self[explicit: guide.key]
    }

    /// Gets the explicit value of the given vertical alignment guide
    ///
    /// Find the vertical offset of a particular guide in the corresponding
    /// view by using that guide as an index to read from the context:
    ///
    ///     .alignmentGuide(.top) { context in
    ///         context[.top] - 10
    ///     }
    ///
    /// This subscript returns `nil` if no value exists for the guide.
    ///
    /// For information about using subscripts in Swift to access member
    /// elements of a collection, list, or, sequence, see
    /// [Subscripts](https://docs.swift.org/swift-book/LanguageGuide/Subscripts.html)
    /// in _The Swift Programming Language_.
    public subscript(explicit guide: VerticalAlignment) -> CGFloat? {
        self[explicit: guide.key]
    }
    
    @inline(__always)
    internal subscript(explicit key: AlignmentKey) -> CGFloat? {
        explicitAlignment(key: key, size: size)
    }
    
    @inline(__always)
    internal subscript(key: AlignmentKey) -> CGFloat {
        alignment(key: key, size: size)
    }
    
    @inline(__always)
    private func alignment(key: AlignmentKey, size: ViewSize) -> CGFloat {
        explicitAlignment(key: key, size: size) ?? key.id.defaultValue(in: self)
    }
    
    @inline(__always)
    private func explicitAlignment(key: AlignmentKey, size: ViewSize) -> CGFloat? {
        guideComputer.engine.explicitAlignment(key, at: size)
    }
    
    internal static func dimension(min: CGFloat?, max: CGFloat?, childProposal: CGFloat?, childActual: CGFloat) -> CGFloat {
        if let min: CGFloat = min {
            if let max: CGFloat = max {
                _danceuiPrecondition(max >= min)
                if min > childActual {
                    return min
                } else {
                    return .minimum(max, childActual)
                }
            } else {
                return .maximum(min, .minimum(childProposal ?? .infinity, childActual))
            }
        } else {
            if let max: CGFloat = max {
                return .minimum(max, .maximum(childProposal ?? -.infinity, childActual))
            } else {
                return childActual
            }
        }
    }
}
