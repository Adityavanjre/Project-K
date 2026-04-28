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
internal struct DynamicViewListItem: DynamicContainerItem {

    internal var id: _ViewList_ID

    internal var elements: _ViewList_Elements

    internal var traits: ViewTraitCollection

    internal var list: Attribute<ViewList>?

    internal var count: Int {
        elements.count
    }

    internal var layoutPriority: Double? {

        let layoutPriority = traits.value(for: LayoutPriorityTraitKey.self, defaultValue: .nan)
        return layoutPriority.isNaN ? nil : layoutPriority
    }

    internal var needsTransitions: Bool {
        let canTransition = traits.value(for: CanTransitionTraitKey.self, defaultValue: false)

        if canTransition {
            let transition = traits.value(for: TransitionTraitKey.self, defaultValue: AnyTransition.opacity)
            return !transition.box.isIdentity
        }

        return false
    }

    internal var zIndex: Double {
        traits.value(for: ZIndexTraitKey.self, defaultValue: .zero)
    }

    internal func matchesIdentity(of item: DynamicViewListItem) -> Bool {
        list == item.list && id == item.id
    }

}
