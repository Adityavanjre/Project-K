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
internal struct DynamicContainer {

    internal static func makeContainer<Adaptor: DynamicContainerAdaptor>(adaptor: Adaptor, inputs: _ViewInputs) -> (Attribute<DynamicContainer.Info>, _ViewOutputs) {
        var visitor = AddCombinerVisitor(outputs: .init())
        for key in inputs.preferences.keys {
            key.visitKey(&visitor)
        }

        var outputs = visitor.outputs
        outputs.resetLayout()

        let asyncSignal = Attribute(value: ())
        let info = DynamicContainerInfo<Adaptor>(asyncSignal: asyncSignal, adaptor: adaptor, inputs: inputs, outputs: outputs)
        let infoAttribute = Attribute(info)
        infoAttribute.addInput(asyncSignal, options: .sentinel, token: 0)
        infoAttribute.flags = .active

        outputs.preferences.forEach { keyType, attribute in
            var visitor = AttachCombinerVisitor(combiner: attribute, container: infoAttribute)
            keyType.visitKey(&visitor)
        }

        return (infoAttribute, outputs)
    }

}

@available(iOS 13.0, *)
extension DynamicContainer {

    internal struct Info: Equatable {

        internal var items: [ItemInfo]

        internal var indexMap: [UInt32: Int]

        internal var displayMap: [UInt32]?

        internal var removedCount: Int

        internal var unusedCount: Int

        internal var allUnary: Bool

        internal var seed: UInt32

        @usableFromInline
        internal init() {
            items = []
            indexMap = [:]
            displayMap = nil
            removedCount = 0
            unusedCount = 0
            allUnary = true
            seed = 0
        }

        internal init(
            items: [ItemInfo],
            indexMap: [UInt32: Int],
            displayMap: [UInt32]?,
            removedCount: Int,
            unusedCount: Int,
            allUnary: Bool,
            seed: UInt32
        ) {
            self.items = items
            self.indexMap = indexMap
            self.displayMap = displayMap
            self.removedCount = removedCount
            self.unusedCount = unusedCount
            self.allUnary = allUnary
            self.seed = seed
        }

        internal static func == (lhs: Info, rhs: Info) -> Bool {
            lhs.seed == rhs.seed
        }
    }
}

@available(iOS 13.0, *)
extension DynamicContainer {

    internal class ItemInfo {

        internal let subgraph: DGSubgraphRef

        internal let uniqueId: UInt32

        internal let viewCount: Int32

        internal let outputs: _ViewOutputs

        internal let needsTransitions: Bool

        internal var listener: DynamicAnimationListener?

        internal var zIndex: Double

        internal var removalOrder: UInt32

        internal var precedingViewCount: Int32

        internal var resetSeed: UInt32

        internal var phase: TransitionPhase?

        internal var layoutPriority: Double? {
            _abstract(self)
        }

        internal init(subgraph: DGSubgraphRef,
                      uniqueId: UInt32,
                      viewCount: Int32,
                      outputs: _ViewOutputs,
                      needsTransitions: Bool,
                      listener: DynamicAnimationListener?,
                      zIndex: Double,
                      removalOrder: UInt32,
                      precedingViewCount: Int32,
                      resetSeed: UInt32,
                      phase: TransitionPhase?) {
            self.subgraph = subgraph
            self.uniqueId = uniqueId
            self.viewCount = viewCount
            self.outputs = outputs
            self.needsTransitions = needsTransitions
            self.listener = listener
            self.zIndex = zIndex
            self.removalOrder = removalOrder
            self.precedingViewCount = precedingViewCount
            self.resetSeed = resetSeed
            self.phase = phase
        }

        internal func destroy() {
            _intentionallyLeftBlank()
        }

        internal func `for`<A: DynamicContainerAdaptor>(_: A.Type) -> _ItemInfo<A> {
            unsafeDowncast(self, to: _ItemInfo<A>.self)
        }
    }
}

@available(iOS 13.0, *)
extension DynamicContainer {

    internal final class _ItemInfo<Adaptor: DynamicContainerAdaptor>: ItemInfo {

        internal var item: Adaptor.Item

        internal let itemLayout: Adaptor.ItemLayout

        internal override var layoutPriority: Double? {
            item.layoutPriority
        }

        internal init(item: Adaptor.Item,
                      itemLayout: Adaptor.ItemLayout,
                      subgraph: DGSubgraphRef,
                      uniqueId: UInt32,
                      viewCount: Int32,
                      phase: TransitionPhase,
                      needsTransitions: Bool,
                      outputs: _ViewOutputs) {
            self.item = item
            self.itemLayout = itemLayout

            super.init(subgraph: subgraph,
                       uniqueId: uniqueId,
                       viewCount: viewCount,
                       outputs: outputs,
                       needsTransitions: needsTransitions,
                       listener: nil,
                       zIndex: 0,
                       removalOrder: 0,
                       precedingViewCount: 0,
                       resetSeed: 0,
                       phase: phase)
        }

        internal override func destroy() {
            Adaptor.destroyItemLayout(itemLayout)
        }
    }
}

@available(iOS 13.0, *)
extension DynamicContainer {

    fileprivate struct AttachCombinerVisitor: PreferenceKeyVisitor {

        internal var combiner: DGAttribute

        internal var container: Attribute<DynamicContainer.Info>

        internal func visit<Key>(key: Key.Type) where Key : PreferenceKey {
            combiner.mutateBody(as: DynamicPreferenceCombiner<Key>.self, invalidating: true) { body in
                body.$info = container
            }
        }

    }

    fileprivate struct AddCombinerVisitor: PreferenceKeyVisitor {

        internal var outputs: _ViewOutputs

        internal mutating func visit<Key: PreferenceKey>(key: Key.Type) {
            outputs[key] = Attribute(DynamicPreferenceCombiner<Key>(info: .init(nil)))
        }

    }
}

@available(iOS 13.0, *)
private struct DynamicPreferenceCombiner<Key: PreferenceKey>: Rule {

    internal typealias Value = Key.Value

    @OptionalAttribute
    internal var info: DynamicContainer.Info?

    internal var value: Key.Value {
        let info = self.info!
        let inuseAndRemovedCount = info.items.count - info.unusedCount
        let inusedCount = inuseAndRemovedCount - info.removedCount

        let includesRemovedValues = info.removedCount > 0 && Key._includesRemovedValues
        let validateCount = includesRemovedValues ? inuseAndRemovedCount : inusedCount

        _danceuiPrecondition(validateCount >= 0)
        guard validateCount > 0 else {
            return Key.defaultValue
        }

        var value: Key.Value?
        for index in 0..<validateCount {
            var itemIndex = 0
            if let displayMap = info.displayMap {
                if includesRemovedValues {
                    itemIndex = Int(displayMap[inusedCount &+ index])
                } else {
                    itemIndex = Int(displayMap[index])
                }
            } else {
                itemIndex = index
                if includesRemovedValues {
                    itemIndex = itemIndex >= info.removedCount ? itemIndex - info.removedCount : inusedCount &+ index
                }
            }

            let item = info.items[itemIndex]
            guard let attribute = item.outputs[Key.self] else {
                continue
            }
            if value != nil {
                Key.reduce(value: &value!) {
                    attribute.value
                }
            } else {
                value = attribute.value
            }
        }
        return value ?? Key.defaultValue
    }
}
