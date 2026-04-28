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
internal struct IncrementalChildPlacements<Layout: IncrementalLayout>: StatefulRule, ObservedAttribute {

    internal typealias Value = [_IncrementalLayout_PlacedChild]

    @Attribute
    internal var layout: Layout

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @Attribute
    internal var environment: EnvironmentValues

    @WeakAttribute
    internal var parent: Scrollable?

    internal var layoutComputer: OptionalAttribute<LayoutComputer>

    internal var cache: ViewCache?

    internal var validRect: CGRect

    internal var placedChildren: [_IncrementalLayout_PlacedChild]

    internal var resetSeed: UInt32

    internal func destroy() {
        cache!.invalidate()
    }

    internal mutating func updateValue() {
        let phase = cache!.inputs.phase.value
        if phase.seed != resetSeed {
            resetSeed = phase.seed
            validRect = .null
            placedChildren = []
        }
        let layout = self.layout
        let position = self.position
        let placementContext = _IncrementalLayout_PlacementContext(
            placedChildren: context.attribute,
            environment: $environment,
            size: $size,
            position: $position,
            transform: $transform,
            pinnedViews: layout.pinnedViews,
            accessibilityEnabled: cache!.$accessibilityEnabled
        )
        func validRectChanged() -> Bool {
            var scrolledVisibleRect = placementContext.scrolledGeometry.visibleRect
            scrolledVisibleRect.origin.x = .maximum(scrolledVisibleRect.origin.x, 0)
            scrolledVisibleRect.origin.y = .maximum(scrolledVisibleRect.origin.y, 0)
            return !validRect.contains(scrolledVisibleRect)
        }
        if self.cache != nil && (validRect.isEmpty ||
            [_position.identifier, _transform.identifier].anyOtherInputsChanged ||
            validRectChanged()) {

            cache?.placementSeed &+= 1
            var newPlacements = _IncrementalLayout_Placements()

            swap(&self.placedChildren, &newPlacements.placedChildren)
            newPlacements.placedChildren.removeAll(keepingCapacity: true)

            cache?.withMutableState(type: Layout.State.self, { (state) in
                let children = cache!.children(context: DanceUIGraph.AnyRuleContext(context.attribute.identifier))
                layout.place(children: children, context: placementContext, state: &state, in: &newPlacements)
            })

            if newPlacements.rect == nil, cache!.mayInvalidate(), let layoutComputerAttribute = layoutComputer.attribute {
                let weakLayoutComputer = WeakAttribute(layoutComputerAttribute)
                Update.enqueueAction {
                    guard let attribute = weakLayoutComputer.attribute else {
                        return
                    }
                    attribute.invalidateValue()
                    attribute.graph.graphHost().graphDelegate?.graphDidChange()
                }
            }
            if (newPlacements.offset.width != 0 || newPlacements.offset.height != 0),
               let parent = self.parent {
                _ = parent.adjustContentOffset(by: newPlacements.offset)
            }
            validRect = newPlacements.rect ?? .zero
            self.placedChildren = newPlacements.placedChildren
        }
        var from = [_IncrementalLayout_PlacedChild]()
        if var value = self.optionalValue {
            swap(&value, &from)
            self.value = value
        }
        var placedChildren = self.placedChildren
        cache!.commitPlacedChildren(from: &from, to: &placedChildren)
        guard cache?.hasSections == true, !layout.pinnedAxes.isEmpty, !layout.pinnedViews.isEmpty else {
            self.value = placedChildren
            return
        }
        var transform = self.transform
        var translation = position.value

        translation.x -= transform.positionAdjustment.width
        translation.y -= transform.positionAdjustment.height

        if translation != .zero {
            transform.appendTranslation(.init(width: -translation.x, height: -translation.y))
        }

        let scrollLayout: _ScrollLayout
        if let layout = transform.containingScrollLayout {
            scrollLayout = layout
        } else {
            let size = self.size.value
            scrollLayout = .init(contentOffset: .zero, size: size, visibleRect: .init(origin: .zero, size: size))
        }
        let pinnedViews = layout.pinnedViews
        let pinnedAxes = layout.pinnedAxes
        let headerAxes = pinnedViews.contains(.sectionHeaders) ? pinnedAxes : []
        let footerAxes = pinnedViews.contains(.sectionFooters) ? pinnedAxes : []
        placedChildren.pinSectionHeadersAndFooters(in: scrollLayout, headerAxes: headerAxes, footerAxes: footerAxes)
        self.value = placedChildren
    }
}
