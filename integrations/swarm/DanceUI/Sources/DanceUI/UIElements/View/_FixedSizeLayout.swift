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

@frozen
@available(iOS 13.0, *)
public struct _FixedSizeLayout: ViewModifier, UnaryLayout, Animatable  {
    
    public typealias Body = Never
    
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = PlacementContext
    
    @usableFromInline
    internal var horizontal: Bool
    
    @usableFromInline
    internal var vertical: Bool
    
    @inlinable
    public init(horizontal: Bool = true, vertical: Bool = true) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
        let childSize = context.size
        var proposal = context.proposedSize
        if horizontal {
            proposal.width = nil
        }
        if vertical {
            proposal.height = nil
        }
        return _Placement(proposedSize: proposal, anchor: .center, at: CGPoint(x: childSize.width * 0.5, y: childSize.height * 0.5))
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        let width = horizontal ? nil : proposedSize.width
        let height = vertical ? nil : proposedSize.height
        
        let layoutComputer = child.layoutComputer
        let proposal = _ProposedSize(width: width, height: height)
        var fittingSize = layoutComputer.engine.sizeThatFits(proposal)
        
        assert((horizontal && fittingSize.width < .infinity) || !horizontal)
        assert((vertical && fittingSize.height < .infinity) || !vertical)
        if horizontal && fittingSize.width >= .infinity {
            fittingSize.width = 0
        }
        if vertical && fittingSize.height >= .infinity {
            fittingSize.height = 0
        }
        
        return fittingSize
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Fixes this view at its ideal size in the specified dimensions.
    ///
    /// This function behaves like ``View/fixedSize()``, except with
    /// `fixedSize(horizontal:vertical:)` the fixing of the axes can be
    /// optionally specified in one or both dimensions. For example, if you
    /// horizontally fix a text view before wrapping it in the frame view,
    /// you're telling the text view to maintain its ideal _width_. The view
    /// calculates this to be the space needed to represent the entire string.
    ///
    ///     Text("A single line of text, too long to fit in a box.")
    ///         .fixedSize(horizontal: true, vertical: false)
    ///         .frame(width: 200, height: 200)
    ///         .border(Color.gray)
    ///
    /// This can result in the view exceeding the parent's bounds, which may or
    /// may not be the effect you want.
    ///
    ///
    /// - Parameters:
    ///   - horizontal: A Boolean value that indicates whether to fix the width
    ///     of the view.
    ///   - vertical: A Boolean value that indicates whether to fix the height
    ///     of the view.
    ///
    /// - Returns: A view that fixes this view at its ideal size in the
    ///   dimensions specified by `horizontal` and `vertical`.
    @inlinable
    public func fixedSize(horizontal: Bool = true, vertical: Bool = true) -> some View {
        let modifier = _FixedSizeLayout(horizontal: horizontal, vertical: vertical)
        return self.modifier(modifier)
    }
    
}
