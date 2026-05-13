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

@frozen
@available(iOS 13.0, *)
public struct _FlexFrameLayout: UnaryLayout, Animatable, FrameLayoutCommon {
    
    public typealias Body = Never
    
    public typealias Content = Void
    
    typealias PlacementContextType = PlacementContext
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public var minWidth: CGFloat?
    
    public var idealWidth: CGFloat?
    
    public var maxWidth: CGFloat?
    
    public var minHeight: CGFloat?
    
    public var idealHeight: CGFloat?
    
    public var maxHeight: CGFloat?
    
    public var alignment: Alignment
    
    @usableFromInline
    internal init(minWidth: CGFloat?, idealWidth: CGFloat? = nil,
         maxWidth: CGFloat? = nil, minHeight: CGFloat?,
         idealHeight: CGFloat? = nil, maxHeight: CGFloat?,
         alignment: Alignment = .center) {
        self.minWidth = minWidth
        self.idealWidth = idealWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.idealHeight = idealHeight
        self.maxHeight = maxHeight
        self.alignment = alignment
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContextType) -> _Placement {
        let childProposal = childPlacementProposal(of: child, context: context)
        return commonPlacement(of: child, in: context, childProposal: childProposal)
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        var fitWidth: CGFloat? = idealWidth
        if let proposedWidth: CGFloat = proposedSize.width {
            if let minWidth: CGFloat = self.minWidth, let maxWidth: CGFloat = self.maxWidth {
                _danceuiPrecondition(maxWidth >= minWidth)
                fitWidth = max(min(proposedWidth, maxWidth), minWidth)
            } else {
                fitWidth = nil
            }
        }
        
        var fitHeight: CGFloat? = idealHeight
        if let proposedHeight: CGFloat = proposedSize.height {
            if let minHeight: CGFloat = self.minHeight,
               let maxHeight: CGFloat = self.maxHeight {
                _danceuiPrecondition(maxHeight >= minHeight)
                fitHeight = max(min(proposedHeight, maxHeight), minHeight)
            } else {
                fitHeight = nil
            }
        }
        
        if let width = fitWidth, let height = fitHeight {
            return .init(width: width, height: height)
        }
        
        var childProposedWidth: CGFloat? = nil
        if idealWidth != nil || proposedSize.width != nil {
            childProposedWidth = proposedSize.width ?? idealWidth
            childProposedWidth = max(minWidth ?? -.infinity, childProposedWidth!)
            childProposedWidth = min(maxWidth ?? .infinity, childProposedWidth!)
        }
        
        var childProposedHeight: CGFloat? = nil
        if idealHeight != nil || proposedSize.height != nil {
            childProposedHeight = proposedSize.height ?? idealHeight
            childProposedHeight = max(minHeight ?? -.infinity, childProposedHeight!)
            childProposedHeight = min(maxHeight ?? .infinity, childProposedHeight!)
        }
        
        let childProposedSize: _ProposedSize = .init(width: childProposedWidth, height: childProposedHeight)
        let fittingSize: CGSize = child.layoutComputer.engine.sizeThatFits(childProposedSize)
        
        let finalWidth: CGFloat
        if let fitWidth = fitWidth {
            finalWidth = fitWidth
        } else {
            finalWidth = ViewDimensions.dimension(min: minWidth, max: maxWidth, childProposal: childProposedWidth, childActual: fittingSize.width)
        }
        
        let finalHeight: CGFloat
        if let fitHeight = fitHeight {
            finalHeight = fitHeight
        } else {
            finalHeight = ViewDimensions.dimension(min: minHeight, max: maxHeight, childProposal: childProposedHeight, childActual: fittingSize.height)
        }
        
        return .init(width: finalWidth, height: finalHeight)
    }
    
    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        let childLayoutComputer = child.layoutComputer
        var spacing = childLayoutComputer.engine.spacing()
        guard !childLayoutComputer.engine.requiresSpacingProjection() else {
            return spacing
        }
        var edges = Edge.Set()
        if maxHeight != nil ||
            minHeight != nil ||
            idealHeight != nil {
            edges = .vertical
        }
        if maxWidth != nil ||
            minWidth != nil ||
            idealWidth != nil {
            edges.insert(.horizontal)
        }
        spacing.reset(edges)
        return spacing
    }
    
    fileprivate func childPlacementProposal(of child: LayoutProxy, context: PlacementContext) -> _ProposedSize {
        func proposedDimension(_ axis: Axis, min: CGFloat?, ideal: CGFloat?, max: CGFloat?) -> CGFloat? {
            let proposedDimension = context.size.value(for: axis)
            guard ideal == nil else {
                return proposedDimension
            }
            guard context.proposedSize.value(for: axis) == nil else {
                return proposedDimension
            }
            let min = min ?? -.infinity
            let max = max ?? .infinity
            guard proposedDimension >= max || proposedDimension <= min else {
                return nil
            }
            return proposedDimension
        }
        let proposedWidth = proposedDimension(.horizontal, min: self.minWidth, ideal: self.idealWidth, max: self.maxWidth)
        let proposedHeight = proposedDimension(.vertical, min: self.minWidth, ideal: self.idealHeight, max: self.maxHeight)
        return _ProposedSize(width: proposedWidth, height: proposedHeight)
    }
}
