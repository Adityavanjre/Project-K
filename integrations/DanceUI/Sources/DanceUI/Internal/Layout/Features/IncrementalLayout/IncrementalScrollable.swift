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
internal struct IncrementalScrollable<Layout: IncrementalLayout>: Scrollable, ScrollableContainer, ScrollableCollection {

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @WeakAttribute
    internal var parent: Scrollable?

    @OptionalAttribute
    internal var children: [Scrollable]?

    internal var cache: _ViewCache<Layout>

    internal func makeTarget<ID: Hashable>(for id: ID, anchor: UnitPoint?) -> ContentOffsetTarget? {
        let indexOrNil = cache.withPlacementData { (layout, context) -> Int? in
            let children = cache.children(context: .init(.nil))
            return layout.firstIndex(of: id, children: children, context: context)
        }

        guard let index = indexOrNil else {
            return nil
        }

        return makeTarget(at: index, anchor: anchor)
    }

    internal func makeTarget(at index: Int, anchor: UnitPoint?) -> ContentOffsetTarget? {
        { [weak cache] (contentSize, bounds) -> CGPoint? in
            guard let cache = cache else {
                return nil
            }

            let targetRectOrNil = cache.withPlacementData { (layout, context) -> CGRect? in
                cache.withMutableState(type: Layout.State.self) { (state) -> CGRect? in
                    let children = cache.children(context: .init(.nil))
                    return layout.boundingRect(at: index, children: children, context: context, state: &state)
                }
            }

            guard let targetRect = targetRectOrNil else {
                return nil
            }

            var newTransform = self.transform
            let position = self.position

            if newTransform.positionAdjustment.width != position.value.x || newTransform.positionAdjustment.height != position.value.y {
                let difference = CGSize(
                    width: -(position.value.x - newTransform.positionAdjustment.width),
                    height: -(position.value.y - newTransform.positionAdjustment.height)
                )
                newTransform.appendTranslation(difference)
            }

            let contentSpace = AnyHashable(ScrollableContentSpace())

            let safeTargetRect: CGRect

            if targetRect.isNull || targetRect.isInfinite {
                safeTargetRect = CGRect(x: targetRect.origin.y, y: targetRect.origin.y, width: targetRect.height, height: targetRect.height)
            } else {
                var cornerPoints = targetRect.cornerPoints
                cornerPoints.convert(to: .named(contentSpace), transform: newTransform)
                safeTargetRect = CGRect(cornerPoints: cornerPoints[0..<4])
            }

            return ScrollViewUtilities.animationOffset(
                for: safeTargetRect,
                anchor: anchor,
                bounds: bounds,
                contentSize: contentSize
            )
        }
    }

    internal static func hasMultipleViewsInAxis(_ axis: Axis) -> Bool {
        Layout.hasMultipleViewsInAxis(axis)
    }

    internal func collectionViewID(for subgraph: DGSubgraphRef) -> _ViewList_ID.Canonical? {
        guard let item = cache.item(for: subgraph) else {
            return nil
        }

        return _ViewList_ID.Canonical(id: item.id)
    }

    internal func scroll(toCollectionViewID id: _ViewList_ID.Canonical, anchor: UnitPoint?) -> Bool {
        let children = cache.children(context: .init(.nil))

        guard let index = children.firstIndex(of: id, style: .default) ,
              let target = makeTarget(at: index, anchor: anchor) else {
            return false
        }

        return setContentOffset(target: target)
    }
}
