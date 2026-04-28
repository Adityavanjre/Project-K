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
public struct _ZStackLayout: _VariadicView_UnaryViewRoot, _Layout, Animatable, Layout, _VariadicView_ImplicitRoot {
    
    internal static var implicitRoot: _ZStackLayout {
        .init(alignment: .center)
    }
    internal typealias PlacementContextType = PlacementContext
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public typealias Body = Never
    
    public var alignment: Alignment
    
    public static let isIdentityUnaryLayout: Bool = true
    
    @inlinable
    public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }
    
    static var majorAxis: Axis? {
        nil
    }
    
    internal func placement(of collection: LayoutProxyCollection, in context: PlacementContext) -> [_Placement] {
        guard !collection.isEmpty else {
            return []
        }
        let bounds = CGRect(origin: .zero, size: context.size)
        let subviews = LayoutSubviews(layoutDirection: context.environmentValue(\.layoutDirection), storage: .direct(collection.attributes), context: context.context)
        let size = context.size
        let viewSize = ViewSize(value: size, _proposal: size)
        return withLayoutData(LayoutData(at: viewSize, origin: bounds.origin, subviews: subviews)) {
            var cache: () = ()
            self.placeSubviews(in: CGRect(origin: .zero, size: context.size), proposal: ProposedViewSize(context.size), subviews: LayoutSubviews(layoutDirection: context.environmentValue(\.layoutDirection), storage: .direct(collection.attributes), context: context.context), cache: &cache)
            return LayoutData.current.placement
        }
    }
    
    internal func sizeThatFits(in size: _ProposedSize, context: SizeAndSpacingContext, children: LayoutProxyCollection) -> CGSize {
        var cache: () = ()
        return sizeThatFits(proposal: ProposedViewSize(size), subviews: LayoutSubviews(layoutDirection: context.environmentValue(\.layoutDirection), storage: .direct(children.attributes), context: context.context), cache: &cache)
    }
    
    
    // MARK: Layout
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else {
            return .zero
        }
        
        let maxPriority: Double = subviews.reduce(0, { .maximum($0, $1.priority)})
        
        var fittingWidth: CGFloat = -.infinity
        var fittingHeight: CGFloat = -.infinity
        var maxHAlignmentValue: CGFloat = -.infinity
        var maxVAlignmentValue: CGFloat = -.infinity
        
        for subview in subviews {
            guard subview.priority == maxPriority else {
                continue
            }
            let layoutComputer: LayoutComputer = subview.proxy.layoutComputer
            let fittingSize = layoutComputer.engine.sizeThatFits(proposal.proposal)
            let viewDimension = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: proposal.proposal))
            let hAlignment: CGFloat = viewDimension[self.alignment.horizontal]
            let vAlignment: CGFloat = viewDimension[self.alignment.vertical]
            
            let hAliamentDimension = viewDimension.size.value.width < .infinity ? hAlignment : 0
            let vAliamentDimension = viewDimension.size.value.height < .infinity ? vAlignment : 0
            fittingWidth = .maximum(fittingWidth, hAlignment)
            fittingHeight = .maximum(fittingHeight, vAlignment)
            maxHAlignmentValue = .maximum(viewDimension.size.value.width - hAliamentDimension, maxHAlignmentValue)
            maxVAlignmentValue = .maximum(viewDimension.size.value.height - vAliamentDimension, maxVAlignmentValue)
        }
        return CGSize(width: fittingWidth + maxHAlignmentValue, height: fittingHeight + maxVAlignmentValue)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        
        let maxPriority: Double = subviews.reduce(0, { .maximum($0, $1.priority)})
        
        var maxHAlignment: CGFloat = -.infinity
        var maxVAlignment: CGFloat = -.infinity
        
        for subview in subviews {
            guard subview.priority == maxPriority else {
                continue
            }
            let layoutComputer: LayoutComputer = subview.proxy.layoutComputer
            let fittingSize = subview.sizeThatFits(proposal)
            let viewDimension = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: proposal.proposal))
            let hAlignment: CGFloat = viewDimension[self.alignment.horizontal]
            maxHAlignment = .maximum(maxHAlignment, hAlignment)
            
            let vAlignment: CGFloat = viewDimension[self.alignment.vertical]
            maxVAlignment = .maximum(maxVAlignment, vAlignment)
        }
        
        for subview in subviews {
            let layoutComputer = subview.proxy.layoutComputer
            let fittingSize: CGSize = subview.sizeThatFits(proposal)
            let viewDimension = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: proposal.proposal))
            let hAlignment: CGFloat = viewDimension[self.alignment.horizontal]
            let vAlignment: CGFloat = viewDimension[self.alignment.vertical]
            
            var anchorPosition = CGPoint(x: maxHAlignment - hAlignment, y: maxVAlignment - vAlignment)
            anchorPosition.apply(CGSize(width: bounds.origin.x, height: bounds.origin.y))
            subview.place(at: anchorPosition, anchor: .topLeading, proposal: proposal)
        }
    }
}
