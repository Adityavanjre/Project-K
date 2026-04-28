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

@available(iOS 13.0, *)
internal struct _LayoutEngine<LayoutType: _Layout>: LayoutEngine where LayoutType.PlacementContextType == PlacementContext {

    internal var layout: LayoutType

    internal var layoutContext: SizeAndSpacingContext

    internal var children: LayoutProxyCollection

    internal var dimensionsCache: Cache3<_ProposedSize, CGSize>

    internal var placementCache: Cache3<ViewSize, [_Placement]>

    internal init(layout: LayoutType,
                  layoutContext: SizeAndSpacingContext,
                  children: LayoutProxyCollection) {
        self.layout = layout
        self.layoutContext = layoutContext
        self.children = children
        self.dimensionsCache = .init()
        self.placementCache = .init()
    }

    internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {

        if let dimensions = dimensionsCache[size] {
            return dimensions
        }

        let fitSize = self.layout.sizeThatFits(in: size, context: layoutContext, children: children)
        dimensionsCache[size] = fitSize
        return fitSize
    }

    internal mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let childPlacement = self.childPlacement(at: size)
        guard !childPlacement.isEmpty else {
            return nil
        }

        var combineIndex: Int = 0
        var explicitAlignment: CGFloat? = nil
        for (index, placement) in childPlacement.enumerated() {
            let proxy = self.children[index]
            let layoutComputer = proxy.layoutComputer
            let fittingSize = layoutComputer.engine.sizeThatFits(placement.proposedSize_)
            let dimension = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: placement.proposedSize_))
            guard let alignment = dimension[explicit: key] else {
                continue
            }
            let childValue: CGFloat
            switch key.bits {
            case .horizontal:
                childValue = placement.anchorPosition.x - placement.anchor.x * fittingSize.width + alignment
            case .vertical:
                childValue = placement.anchorPosition.y - placement.anchor.y * fittingSize.height + alignment
            }
            key.id._combineExplicit(childValue: childValue, combineIndex, into: &explicitAlignment)
            combineIndex += 1
        }
        return explicitAlignment
    }

    internal func layoutPriority() -> Double {
        layout.layoutPriority(children: children)
    }

    internal mutating func childPlacement(at size: ViewSize) -> [_Placement] {
        if let placement = placementCache[size] {
            return placement
        }
        let context = PlacementContext(context: layoutContext, size: size)
        let placements = self.layout.placement(of: children, in: context)
        placementCache[size] = placements
        return placements
    }

    internal mutating func childGeometries(at size: ViewSize, origin: CGPoint) -> [ViewGeometry] {
        childPlacement(at: size).enumerated().map { (index, placement) in
            var geometry = children[index].finallyPlaced(at: placement, in: size.value, layoutDirection: layoutContext.environmentValue(\.layoutDirection))
            geometry.origin.apply(origin)
            return geometry
        }
    }

    internal func requiresSpacingProjection() -> Bool {
        false
    }
}
