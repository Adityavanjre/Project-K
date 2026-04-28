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
internal struct DynamicLayoutViewAdaptor: DynamicContainerAdaptor {

    internal typealias Item = DynamicViewListItem

    internal typealias Items = ViewList

    @Attribute
    internal var item: ViewList

    @OptionalAttribute
    internal var childGeometries: [ViewGeometry]?

    internal var mutateLayoutComputerMap: ((inout DynamicLayoutMap) -> ()) -> ()

    internal func updatedItems() -> ViewList? {
        let (item, isItemChanged) = _item.changedValue()
        return isItemChanged ? item : nil
    }

    internal static func containsItem(_ viewlist: ViewList, _ item: DynamicViewListItem) -> Bool {
        var index = 0
        return viewlist.applySublists(from: &index, list: nil) { sublist in
            sublist.id == item.id
        }
    }

    internal func foreachItem(_ viewlist: ViewList, _ body: (DynamicViewListItem) -> ()) {
        var index = 0
        _ = viewlist.applySublists(from: &index, list: _GraphValue(_item)) { sublist in
            body(DynamicViewListItem(id: sublist.id, elements: sublist.elements, traits: sublist.traits, list: sublist.list))
            return true
        }
    }

    internal static func destroyItemLayout(_ itemLayout: ItemLayout) -> () {
        itemLayout.release()
    }

    internal func makeItemLayout(item: DynamicViewListItem, uniqueId: UInt32, inputs: _ViewInputs, containerInfo: Attribute<DynamicContainer.Info>, containerInputs: (inout _ViewInputs) -> Void) -> (_ViewOutputs, ItemLayout) {
        var transition = item.traits.optionalTransition

        if let t = item.traits.optionalTransition {
            let fadeTransitions = DGGraphRef.withoutUpdate {
                inputs.environment.value.accessibilityPrefersCrossFadeTransitions
            }
            if (t.box.hasMotion && fadeTransitions) {
                transition = .opacity
            }
        }

        var containerID = DynamicContainerID(uniqueId: uniqueId, viewIndex: 0)
        let outputs = item.elements.makeAllElements(inputs: inputs, indirectMap: nil) { internalInputs, makeOutputs in
            let childGeometry = Attribute(DynamicLayoutViewChildGeometry(containerInfo: containerInfo, childGeometries: _childGeometries.attribute!, id: containerID))
            var newInputs = internalInputs
            containerInputs(&newInputs)
            newInputs.size = childGeometry.size()
            newInputs.position = childGeometry.origin()
            newInputs.enableLayouts = true
            let viewOutputs: _ViewOutputs
            if let transition = transition {
                var makeTransition = MakeTransition(containerInfo: containerInfo, uniqueId: uniqueId, list: item.list, id: item.id, inputs: newInputs, makeElt: makeOutputs, outputs: nil)
                transition.box.visitBase(applying: &makeTransition)
                viewOutputs = makeTransition.outputs!
            } else {
                viewOutputs = makeOutputs(newInputs)
            }
            if let outputLayout = viewOutputs.layout.attribute {
                mutateLayoutComputerMap({ map in
                    map[containerID] = LayoutProxyAttributes(_layoutComputer: .init(outputLayout), _traitsList: .init(item.list))
                })
            }
            containerID.viewIndex &+= 1
            return viewOutputs
        }
        return (outputs ?? .init(), .init(release: item.elements.retain()))
    }

    internal func removeItemLayout(uniqueId: UInt32, itemLayout: ItemLayout) {
        mutateLayoutComputerMap({ map in
            map.remove(uniqueId: uniqueId)
        })
        itemLayout.release()
    }

}

@available(iOS 13.0, *)
extension DynamicLayoutViewAdaptor {

    internal struct ItemLayout {

        internal var release: _ViewList_Elements_ReleaseHandler
    }
}

@available(iOS 13.0, *)
extension DynamicLayoutViewAdaptor {

    internal struct ViewListTransition<T: Transition>: StatefulRule {

        internal typealias Value = T.TransitionModifier

        @OptionalAttribute
        internal var list: ViewList?

        @Attribute
        internal var info: DynamicContainer.Info

        internal let uniqueId: UInt32

        internal var lastValue: T

        internal var lastPhase: TransitionPhase

        internal mutating func updateValue() {
            let info = self.info
            var needs: Bool = false
            if let index = info.indexMap[uniqueId], let phase = info.items[index].phase {
                needs = phase != lastPhase
                lastPhase = phase
            }

            let trait = list?.traits ?? ViewTraitCollection()
            let transition = trait.value(for: TransitionTraitKey.self, defaultValue: AnyTransition.opacity)
            let base = transition.base(as: T.self)

            base.map({ value in
                self.lastValue = value
                needs = true
            })
            guard needs || !hasValue else {
                return
            }
            self.value = lastValue.transitionModifier(phase: lastPhase)
        }
    }
}

@available(iOS 13.0, *)
extension DynamicLayoutViewAdaptor {

    fileprivate struct MakeTransition: TransitionVisitor {
        internal var containerInfo: Attribute<DynamicContainer.Info>
        internal var uniqueId: UInt32
        internal var list: Attribute<ViewList>?

        #warning("unused")
        internal var id: _ViewList_ID

        internal var inputs: _ViewInputs

        internal var makeElt: (_ViewInputs) -> _ViewOutputs

        internal var outputs: _ViewOutputs?

        internal mutating func visit<T: Transition>(_ transition: T) {
            let viewListTransition = ViewListTransition(list: OptionalAttribute(list), info: containerInfo, uniqueId: uniqueId, lastValue: transition, lastPhase: .normal)

            let transitionAtt = Attribute(viewListTransition)
            let makeElt = self.makeElt
            outputs = T.TransitionModifier._makeView(modifier: _GraphValue(transitionAtt), inputs: inputs, body: { _, inputs in
                makeElt(inputs)
            })

        }
    }
}
