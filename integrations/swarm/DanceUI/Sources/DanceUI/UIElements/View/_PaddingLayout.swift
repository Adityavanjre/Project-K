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

@frozen
@available(iOS 13.0, *)
public struct _PaddingLayout : UnaryLayout {
    
    public typealias Body = Never
    
    public typealias Content = Void
    
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = PlacementContext
    
    public let edges: Edge.Set
    
    public let insets: EdgeInsets?
    
    @usableFromInline init(edges: Edge.Set, insets: EdgeInsets? = nil) {
        self.edges = edges
        self.insets = insets
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
        let insets = effectiveInsets(in: SizeAndSpacingContext(context.context, environment: context.$environment))
        let size = context.size.inset(by: insets)
        return _Placement(proposedSize: size, anchor: .topLeading, at: .init(x: insets.leading, y: insets.top))
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        let insets: EdgeInsets = effectiveInsets(in: context)
        var newProposedSize = proposedSize
        if let width: CGFloat = proposedSize.width {
            var remaingWidth: CGFloat = width
            remaingWidth -= (insets.leading + insets.trailing)
            if remaingWidth < 0 {
                remaingWidth = 0
            }
            newProposedSize.width = remaingWidth
        }
        
        if let height: CGFloat = proposedSize.height {
            var remaingHeight: CGFloat = height
            remaingHeight -= (insets.top + insets.bottom)
            if remaingHeight < 0 {
                remaingHeight = 0
            }
            newProposedSize.height = remaingHeight
        }
        
        let fittingSize: CGSize = child.layoutComputer.engine.sizeThatFits(newProposedSize)
        
        return fittingSize.inset(by: -insets)
    }
    
    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        #warning("Semantics")
        var spacing = child.layoutComputer.engine.spacing()
        let insets: EdgeInsets = effectiveInsets(in: context)
        var set = Edge.Set()
        if insets.top != 0 {
            set.insert(.top)
        }
        if insets.bottom != 0 {
            set.insert(.bottom)
        }
        if insets.leading != 0 {
            set.insert(.leading)
        }
        if insets.trailing != 0 {
            set.insert(.trailing)
        }
        spacing.clear(set)
        return spacing
    }
    
    private func effectiveInsets(in context: SizeAndSpacingContext) -> EdgeInsets {
        var paddingInsets: EdgeInsets
        if let insets = insets {
            paddingInsets = insets
        } else {
            paddingInsets = context.environmentValue(\.defaultPadding)
        }
        paddingInsets.top = edges.contains(.top) ? paddingInsets.top : 0
        paddingInsets.leading = edges.contains(.leading) ? paddingInsets.leading : 0
        paddingInsets.trailing = edges.contains(.trailing) ? paddingInsets.trailing : 0
        paddingInsets.bottom = edges.contains(.bottom) ? paddingInsets.bottom : 0
        return paddingInsets
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Adds a specific padding amount to each edge of this view.
    ///
    /// Use this modifier to add padding all the way around a view.
    ///
    ///     VStack {
    ///         Text("Text padded by 10 points on each edge.")
    ///             .padding(10)
    ///             .border(.gray)
    ///         Text("Unpadded text for comparison.")
    ///             .border(.yellow)
    ///     }
    ///
    /// The order in which you apply modifiers matters. The example above
    /// applies the padding before applying the border to ensure that the
    /// border encompasses the padded region:
    ///
    ///
    /// To independently control the amount of padding for each edge, use
    /// ``View/padding(_:)-25zli``. To pad a select set of edges by the
    /// same amount, use ``View/padding(_:_:)``.
    ///
    /// - Parameter length: The amount, given in points, to pad this view on all
    ///   edges.
    ///
    /// - Returns: A view that's padded by the amount you specify.
    @inlinable
    public func padding(_ length: CGFloat) -> some View {
        self.padding(.all, length)
    }
    
    /// Adds a different padding amount to each edge of this view.
    ///
    /// Use this modifier to add a different amount of padding on each edge
    /// of a view:
    ///
    ///     VStack {
    ///         Text("Text padded by different amounts on each edge.")
    ///             .padding(EdgeInsets(top: 10, leading: 20, bottom: 40, trailing: 0))
    ///             .border(.gray)
    ///         Text("Unpadded text for comparison.")
    ///             .border(.yellow)
    ///     }
    ///
    /// The order in which you apply modifiers matters. The example above
    /// applies the padding before applying the border to ensure that the
    /// border encompasses the padded region:
    ///
    ///
    /// To pad a view on specific edges with equal padding for all padded
    /// edges, use ``View/padding(_:_:)``. To pad all edges of a view
    /// equally, use ``View/padding(_:)-1o8t0``.
    ///
    /// - Parameter insets: An ``EdgeInsets`` instance that contains
    ///   padding amounts for each edge.
    ///
    /// - Returns: A view that's padded by different amounts on each edge.
    @inlinable
    public func padding(_ insets: EdgeInsets) -> some View {
        self.modifier(_PaddingLayout(edges: .all, insets: insets))
    }
    
    /// Adds an equal padding amount to specific edges of this view.
    ///
    /// Use this modifier to add a specified amount of padding to one or more
    /// edges of the view. Indicate the edges to pad by naming either a single
    /// value from ``Edge/Set``, or by specifying an
    /// <https://developer.apple.com/documentation/Swift/OptionSet>
    /// that contains edge values:
    ///
    ///     VStack {
    ///         Text("Text padded by 20 points on the bottom and trailing edges.")
    ///             .padding([.bottom, .trailing], 20)
    ///             .border(.gray)
    ///         Text("Unpadded text for comparison.")
    ///             .border(.yellow)
    ///     }
    ///
    /// The order in which you apply modifiers matters. The example above
    /// applies the padding before applying the border to ensure that the
    /// border encompasses the padded region:
    ///
    ///
    /// You can omit either or both of the parameters. If you omit the `length`,
    /// DanceUI uses a default amount of padding. If you
    /// omit the `edges`, DanceUI applies the padding to all edges. Omit both
    /// to add a default padding all the way around a view. DanceUI chooses a
    /// default amount of padding that's appropriate for the platform and
    /// the presentation context.
    ///
    ///     VStack {
    ///         Text("Text with default padding.")
    ///             .padding()
    ///             .border(.gray)
    ///         Text("Unpadded text for comparison.")
    ///             .border(.yellow)
    ///     }
    ///
    /// The example above looks like this in iOS under typical conditions:
    ///
    ///
    /// To control the amount of padding independently for each edge, use
    /// ``View/padding(_:)-25zli``. To pad all outside edges of a view by a
    /// specified amount, use ``View/padding(_:)-1o8t0``.
    ///
    /// - Parameters:
    ///   - edges: The set of edges to pad for this view. The default
    ///     is ``Edge/Set/all``.
    ///   - length: An amount, given in points, to pad this view on the
    ///     specified edges. If you set the value to `nil`, DanceUI uses
    ///     a platform-specific default amount. The default value of this
    ///     parameter is `nil`.
    ///
    /// - Returns: A view that's padded by the specified amount on the
    ///   specified edges.
    @inlinable
    public func padding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
        let insets = length.map { EdgeInsets(top: $0, leading: $0, bottom: $0, trailing: $0) }
        return modifier(_PaddingLayout(edges: edges, insets: insets))
    }
}
