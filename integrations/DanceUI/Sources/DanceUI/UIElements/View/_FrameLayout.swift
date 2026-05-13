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
public struct _FrameLayout : UnaryLayout, Animatable, FrameLayoutCommon {
    
    public typealias Body = Never
    
    public typealias Content = Void
    
    typealias PlacementContextType = PlacementContext
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public var width: CGFloat?
    
    public var height: CGFloat?
    
    public var alignment: Alignment
    
    @usableFromInline
    init(width: CGFloat?, height: CGFloat?, alignment: Alignment) {
        
        let isInvalidWidth = width?.isInvalid ?? false || width?.isNegative ?? false
        let isInvalidHeight = height?.isInvalid ?? false || height?.isNegative ?? false
        let w = isInvalidWidth ? nil : width
        let h = isInvalidHeight ? nil : height
        
        if isInvalidWidth || isInvalidHeight {
            runtimeIssue(type: .error, "Invalid frame dimension (negative or non-finite)")
        }
        
        self.width = w
        self.height = h
        self.alignment = alignment
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContextType) -> _Placement {
        var proposedSize = context.proposedSize
        if let width = self.width {
            proposedSize.width = width
        }
        if let height = self.height {
            proposedSize.height = height
        }
        return commonPlacement(of: child, in: context, childProposal: proposedSize)
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        if let width: CGFloat = self.width, let height: CGFloat = self.height {
            return .init(width: width, height: height)
        } else {
            var proposal: _ProposedSize = proposedSize
            proposal.width = self.width ?? proposedSize.width
            proposal.height = self.height ?? proposedSize.height
            let fittingSize: CGSize = child.layoutComputer.engine.sizeThatFits(proposal)
            return .init(width: width ?? fittingSize.width, height: height ?? fittingSize.height)
        }
    }
    
    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        #warning("Semantics")
        let layoutComputer = child.layoutComputer
        guard !layoutComputer.engine.requiresSpacingProjection() else {
            return layoutComputer.engine.spacing()
        }
        var spacing = layoutComputer.engine.spacing()

        var edges = Edge.Set()
        if height != nil {
            edges.insert(.top)
            edges.insert(.bottom)
        }
        if width != nil {
            edges.insert(.leading)
            edges.insert(.trailing)
        }
        spacing.reset(edges)
        return spacing
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Positions this view within an invisible frame.
    ///
    /// Use ``DanceUI/View/frame(width:height:alignment:)`` or
    /// ``DanceUI/View/frame(minWidth:idealWidth:maxWidth:minHeight:idealHeight:maxHeight:alignment:)``
    /// instead.
    @inlinable
    @available(*, deprecated, message: "Please pass one or more parameters.")
    public func frame() -> some View {
        frame(width: nil, height: nil, alignment: .center)
    }
    
    /// Positions this view within an invisible frame with the specified size.
    ///
    /// Use this method to specify a fixed size for a view's width, height, or
    /// both. If you only specify one of the dimensions, the resulting view
    /// assumes this view's sizing behavior in the other dimension.
    ///
    /// For example, the following code lays out an ellipse in a fixed 200 by
    /// 100 frame. Because a shape always occupies the space offered to it by
    /// the layout system, the first ellipse is 200x100 points. The second
    /// ellipse is laid out in a frame with only a fixed height, so it occupies
    /// that height, and whatever width the layout system offers to its parent.
    ///
    ///     VStack {
    ///         Ellipse()
    ///             .fill(Color.purple)
    ///             .frame(width: 200, height: 100)
    ///         Ellipse()
    ///             .fill(Color.blue)
    ///             .frame(height: 100)
    ///     }
    ///
    ///
    /// `The alignment` parameter specifies this view's alignment within the
    /// frame.
    ///
    ///     Text("Hello world!")
    ///         .frame(width: 200, height: 30, alignment: .topLeading)
    ///         .border(Color.gray)
    ///
    /// In the example above, the text is positioned at the top, leading corner
    /// of the frame. If the text is taller than the frame, its bounds may
    /// extend beyond the bottom of the frame's bounds.
    ///
    ///
    /// - Parameters:
    ///   - width: A fixed width for the resulting view. If `width` is `nil`,
    ///     the resulting view assumes this view's sizing behavior.
    ///   - height: A fixed height for the resulting view. If `height` is `nil`,
    ///     the resulting view assumes this view's sizing behavior.
    ///   - alignment: The alignment of this view inside the resulting frame.
    ///     Note that most alignment values have no apparent effect when the
    ///     size of the frame happens to match that of this view.
    ///
    /// - Returns: A view with fixed dimensions of `width` and `height`, for the
    ///   parameters that are non-`nil`.
    @inlinable
    public func frame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View {
#if DEBUG || DANCE_UI_INHOUSE
        // DanceUI addition began
        if Self.self == Spacer.self {
            runtimeIssue(type: .warning, "Detected usage of frame on Spacer, which may cause some unpredictable layout issues. Please resolve spacing using .padding or specify the minimum length of the Spacer using the 'minLength:' parameter.")
        }
        // DanceUI addition ended
#endif
        return modifier(_FrameLayout(width: width, height: height, alignment: alignment))
    }
    
    /// Positions this view within an invisible frame having the specified size
    /// constraints.
    ///
    /// Always specify at least one size characteristic when calling this
    /// method. Pass `nil` or leave out a characteristic to indicate that the
    /// frame should adopt this view's sizing behavior, constrained by the other
    /// non-`nil` arguments.
    ///
    /// The size proposed to this view is the size proposed to the frame,
    /// limited by any constraints specified, and with any ideal dimensions
    /// specified replacing any corresponding unspecified dimensions in the
    /// proposal.
    ///
    /// If no minimum or maximum constraint is specified in a given dimension,
    /// the frame adopts the sizing behavior of its child in that dimension. If
    /// both constraints are specified in a dimension, the frame unconditionally
    /// adopts the size proposed for it, clamped to the constraints. Otherwise,
    /// the size of the frame in either dimension is:
    ///
    /// - If a minimum constraint is specified and the size proposed for the
    ///   frame by the parent is less than the size of this view, the proposed
    ///   size, clamped to that minimum.
    /// - If a maximum constraint is specified and the size proposed for the
    ///   frame by the parent is greater than the size of this view, the
    ///   proposed size, clamped to that maximum.
    /// - Otherwise, the size of this view.
    ///
    /// - Parameters:
    ///   - minWidth: The minimum width of the resulting frame.
    ///   - idealWidth: The ideal width of the resulting frame.
    ///   - maxWidth: The maximum width of the resulting frame.
    ///   - minHeight: The minimum height of the resulting frame.
    ///   - idealHeight: The ideal height of the resulting frame.
    ///   - maxHeight: The maximum height of the resulting frame.
    ///   - alignment: The alignment of this view inside the resulting frame.
    ///     Note that most alignment values have no apparent effect when the
    ///     size of the frame happens to match that of this view.
    ///
    /// - Returns: A view with flexible dimensions given by the call's non-`nil`
    ///   parameters.
    @inlinable
    public func frame(minWidth: CGFloat? = nil, idealWidth: CGFloat? = nil, maxWidth: CGFloat? = nil, minHeight: CGFloat? = nil, idealHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, alignment: Alignment = .center) -> some View {
          func areInNondecreasingOrder(
              _ min: CGFloat?, _ ideal: CGFloat?, _ max: CGFloat?
          ) -> Bool {
              let min = min ?? -.infinity
              let ideal = ideal ?? min
              let max = max ?? ideal
              return min <= ideal && ideal <= max
          }

          return modifier(
              _FlexFrameLayout(
                  minWidth: minWidth,
                  idealWidth: idealWidth, maxWidth: maxWidth,
                  minHeight: minHeight,
                  idealHeight: idealHeight, maxHeight: maxHeight,
                  alignment: alignment))
      }
}
