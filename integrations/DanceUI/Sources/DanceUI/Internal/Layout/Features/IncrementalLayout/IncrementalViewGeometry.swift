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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct IncrementalViewGeometry: Rule {

    internal typealias Value = ViewGeometry

    @Attribute
    internal var children: [_IncrementalLayout_PlacedChild]

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var parentPosition: ViewOrigin

    @Attribute
    internal var layoutDirection: LayoutDirection

    internal var cache: ViewCache

    internal var item: ViewCacheItem?

    internal var value: ViewGeometry {
        guard let placement = cache.placement(of: item!, in: children) else {
            return .zero
        }
        let layoutComputer = item?.outputs.layout.value ?? .defaultValue
        let fittingSize = layoutComputer.engine.sizeThatFits(placement.proposedSize_)
        let originOffset = CGSize(width: fittingSize.width * placement.anchor.x, height: fittingSize.height * placement.anchor.y)
        let origin = CGPoint(x: placement.anchorPosition.x - originOffset.width, y: placement.anchorPosition.y - originOffset.height)
        var geometry = ViewGeometry(origin: ViewOrigin(value: origin), dimensions: ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: placement.proposedSize_)))
        if layoutDirection == .rightToLeft {
            let rect: CGRect = CGRect(origin: geometry.origin.value, size: geometry.dimensions.size.value)
            let maxX: CGFloat = rect.maxX
            geometry.origin.value.x = size.value.width - maxX
        }
        let position = self.parentPosition
        geometry.origin.value.x += position.value.x
        geometry.origin.value.y += position.value.y
        return geometry
    }

}
