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
internal struct UnaryLayoutEngine<Layout: UnaryLayout>: LayoutEngine where Layout.PlacementContextType == PlacementContext {

    internal var layout: Layout

    internal var layoutContext: SizeAndSpacingContext

    internal var child: LayoutProxy

    internal var dimensionsCache: Cache3<_ProposedSize, CGSize>

    internal var placementCache: Cache3<ViewSize, _Placement>

    internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        if let value = dimensionsCache[size] {
            return value
        } else {
            let fitSize: CGSize = layout.sizeThatFits(in: size, context: layoutContext, child: child)
            dimensionsCache[size] = fitSize
            return fitSize
        }
    }

    internal mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let placement: _Placement = childPlacement(at: size)
        let computer: LayoutComputer = child.layoutComputer
        let proposal = placement.proposedSize_
        let fittingSize: CGSize = computer.engine.sizeThatFits(proposal)
        let dimension = ViewDimensions(guideComputer: computer, size: ViewSize(value: fittingSize, proposal: proposal))
        if var explicitAlignment = dimension[explicit: key] {
            var result: CGFloat = 0
            switch key.bits {
                case .horizontal:
                    result = placement.anchor.x * fittingSize.width
                    result = placement.anchorPosition.x - result
                case .vertical:
                    result = placement.anchor.y * fittingSize.height
                    result = placement.anchorPosition.y - result
            }
            explicitAlignment += result
            return explicitAlignment
        } else {
            return nil
        }
    }

    @usableFromInline
    internal func layoutPriority() -> Double {
        layout.layoutPriority(child: child)
    }

    internal mutating func childPlacement(at size: ViewSize) -> _Placement {
        if let value = placementCache[size] {
            return value
        } else {
            let placement = layout.placement(of: child, in: PlacementContext(context: layoutContext, size: size))
            placementCache[size] = placement
            return placement
        }
    }

    internal func spacing() -> Spacing {
        layout.spacing(in: layoutContext, child: child)
    }

    internal func ignoresAutomaticPadding() -> Bool {
        layout.ignoresAutomaticPadding(child: child)
    }
}
