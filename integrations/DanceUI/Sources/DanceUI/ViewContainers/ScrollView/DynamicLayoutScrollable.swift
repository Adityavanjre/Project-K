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
internal struct DynamicLayoutScrollable: ScrollableContainer {

    @WeakAttribute
    internal var list: ViewList?

    @WeakAttribute
    internal var container: DynamicContainer.Info?
    
    @WeakAttribute
    internal var childGeometries: [ViewGeometry]?

    @WeakAttribute
    internal var position: ViewOrigin?

    @WeakAttribute
    internal var transform: ViewTransform?

    @WeakAttribute
    internal var parent: Scrollable?

    @WeakAttribute
    internal var children: [Scrollable]?
    
    internal func makeTarget<ID: Hashable>(for identifier: ID, anchor: UnitPoint?) -> ContentOffsetTarget? {
        guard let listFirstOffset = list?.firstOffset(forID: identifier, style: .default) else {
            return nil
        }
        return { size, frame in
            guard let childGeometries = self.childGeometries, childGeometries.count > listFirstOffset else {
                return nil
            }

            guard let transform = self.transform, let position = self.position else {
                return nil
            }

            var newTransform = transform
            newTransform.appendViewOrigin(position)
            let geometry = childGeometries[listFirstOffset]

            let space = CoordinateSpace.named(ScrollableContentSpace())
            var rect = geometry.rect
            if !rect.isNull && !rect.isInfinite {
                var corner = rect.cornerPoints
                corner.convert(to: space, transform: newTransform)
                rect = CGRect(cornerPoints: corner[0..<4])
            }

            return ScrollViewUtilities.animationOffset(for: rect, anchor: anchor, bounds: frame, contentSize: size)
        }
    }
}
