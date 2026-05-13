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
public struct _SafeAreaRegionsIgnoringLayout: UnaryLayout {
    
    internal typealias PlacementContextType = _PositionAwarePlacementContext
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public typealias Body = Never
    
    public var regions: SafeAreaRegions
    
    public var edges: Edge.Set
    
    @inlinable
    internal init(regions: SafeAreaRegions, edges: Edge.Set) {
        self.regions = regions
        self.edges = edges
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContextType) -> _Placement {
        let matchedSafeAreaInsets = context.safeAreaInsets(matching: regions)
        let safeAreaInsets = matchedSafeAreaInsets.in(edges)
        let size = context.proposedSize.inset(by: safeAreaInsets)
        return _Placement(proposedSize: size,
                          anchor: .topLeading,
                          at: CGPoint(x: -safeAreaInsets.leading, y: -safeAreaInsets.top))
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        child.layoutComputer.engine.sizeThatFits(proposedSize)
    }
    
    internal func ignoresAutomaticPadding(child: LayoutProxy) -> Bool {
        true
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Expands the view out of its safe area.
    ///
    /// - Parameters:
    ///   - regions: the kinds of rectangles removed from the safe area
    ///     that should be ignored (i.e. added back to the safe area
    ///     of the new child view).
    ///   - edges: the edges of the view that may be outset, any edges
    ///     not in this set will be unchanged, even if that edge is
    ///     abutting a safe area listed in `regions`.
    ///
    /// - Returns: a new view with its safe area expanded.
    ///
    @inlinable
    public func ignoresSafeArea(_ regions: SafeAreaRegions = .all, edges: Edge.Set = .all) -> some View {
        modifier(_SafeAreaRegionsIgnoringLayout(
            regions: regions, edges: edges))
    }
    
}
