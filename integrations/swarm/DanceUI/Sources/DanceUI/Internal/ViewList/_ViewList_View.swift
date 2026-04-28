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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct _ViewList_View: PrimitiveView, UnaryView {

    internal typealias Body = Never

    internal var elements: _ViewList_Elements

    internal var id: _ViewList_ID

    internal var index: Int

    internal var count: Int

    internal var contentSubgraph: DGSubgraphRef

    private var canonicalID: AnyHashable {
        guard count != 1 || id.implicitID >= 0 else {
            fatalError("get viewID error, count: \(self.count), implicitID: \(id.implicitID)")
        }
        var canonical = _ViewList_ID.Canonical(id: id)
        canonical._index = numericCast(self.index)
        return AnyHashable(canonical)
    }

    internal var viewID: AnyHashable {
        if id.explicitIDs.isEmpty {
            return canonicalID
        } else {
            switch id.explicitIDs.storage {
            case .one(let element):
                guard count == 1,
                      element.isUnary else {
                    return canonicalID
                }
                return element.id
            case .two(let element, _):
                guard count == 1,
                      element.isUnary else {
                    return canonicalID
                }
                return element.id
            case .many(let elements):
                guard count == 1,
                      let first = elements.first,
                      first.isUnary else {
                    return canonicalID
                }
                return elements.first!.id
            case .empty:
                return canonicalID
            }
        }
    }

    internal static func _makeView(view: _GraphValue<_ViewList_View>, inputs: _ViewInputs) -> _ViewOutputs {
        let outputs = inputs.makeIndirectOutputs()
        let current = DGSubgraphRef.current!
        let placeholderInfo = Attribute(PlaceholderInfo(placeholder: view.value, inputs: inputs, outputs: outputs, parentSubgraph: current, lastSubgraph: nil, lastRelease: nil, secondaryRelease: nil, lastElements: nil, lastMap: nil, lastPhase: nil))
        placeholderInfo.setFlags(.active, mask: .reserved)
        outputs.preferences.forEach { type, attribute in
            attribute.indirectDependency = placeholderInfo.identifier
        }
        outputs.layout.attribute?.identifier.indirectDependency = placeholderInfo.identifier
        return outputs
    }

}

@available(iOS 13.0, *)
private struct PlaceholderInfo : StatefulRule {

    @Attribute
    fileprivate var placeholder: _ViewList_View

    fileprivate let inputs: _ViewInputs

    fileprivate let outputs: _ViewOutputs

    fileprivate let parentSubgraph: DGSubgraphRef

    fileprivate var lastSubgraph: DGSubgraphRef?

    fileprivate var lastRelease: (() -> ())?

    fileprivate var secondaryRelease: (() -> ())?

    fileprivate var lastElements: _ViewList_Elements?

    fileprivate var lastMap: _ViewList_IndirectMap?

    fileprivate var lastPhase: Attribute<_GraphInputs.Phase>?

    fileprivate struct Value {

        fileprivate var id: _ViewList_ID

        fileprivate var seed: UInt32

        fileprivate var index: Int

    }

    fileprivate mutating func updateValue() {
        var seed: UInt32 = 0
        if hasValue {
            let oldValue = value
            guard oldValue.index != placeholder.index || oldValue.id != placeholder.id else {
                return
            }
            var previousValue = value
            if reuseItem(info: &previousValue, placeholder: placeholder) {
                self.value = previousValue
                return
            }
            seed = value.seed &+ 1
        }

        if lastSubgraph != nil {
            eraseItem(info: value)
        }
        if placeholder.contentSubgraph.isValid {
            let subgraph = DGSubgraphCreate(parentSubgraph.graph)
            parentSubgraph.add(child: subgraph)
            placeholder.contentSubgraph.add(child: subgraph)
            subgraph.apply {
                let map = _ViewList_IndirectMap(subgraph)
                if let outputs = placeholder.elements.makeOneElement(at: placeholder.index, inputs: inputs, indirectMap: map, body: { inputs, body in
                    self.lastPhase = Attribute(PlaceholderViewPhase(phase1: inputs.phase, phase2: self.inputs.phase, resetDelta: 0))
                    var newInputs = inputs
                    newInputs.merge(inputs: self.inputs.base, ignoringPhase: true)
                    newInputs.merge(phase: self.lastPhase!)
                    return body(newInputs)
                }) {
                    self.outputs.attachIndirectOutputs(to: outputs)
                }
                lastSubgraph = subgraph
                lastRelease = placeholder.elements.retain()
                lastElements = placeholder.elements
                lastMap = map
            }
            self.value = Value(id: placeholder.id, seed: seed, index: placeholder.index)
        } else {
            self.value = Value(id: _ViewList_ID(implicitID: 0), seed: seed, index: 0)
        }
    }

    fileprivate mutating func reuseItem(info: inout Value, placeholder: _ViewList_View) -> Bool {
        guard lastElements!.tryToReuseElement(at: info.index, by: placeholder.elements, at: placeholder.index, indirectMap: lastMap!, testOnly: false) else {
            return false
        }

        lastPhase!.mutateBody(as: PlaceholderViewPhase.self, invalidating: true) { body in
            body.resetDelta &+= 1
        }

        secondaryRelease?()
        secondaryRelease = placeholder.elements.retain()
        info.id = placeholder.id
        info.index = placeholder.index
        return true
    }

    fileprivate mutating func eraseItem(info: Value) {
        outputs.detachIndirectOutputs()
        if let lastSubgraph = lastSubgraph {
            lastSubgraph.willRemove()
            lastSubgraph.invalidate()
            self.lastSubgraph = nil
        }
        lastRelease?()
        lastRelease = nil
        secondaryRelease?()
        secondaryRelease = nil
        lastElements = nil
        lastMap = nil
        lastPhase = nil
    }

    fileprivate func destroy() {
        lastRelease?()
        secondaryRelease?()
    }
}

@available(iOS 13.0, *)
private struct PlaceholderViewPhase : Rule {

    fileprivate typealias Value = _GraphInputs.Phase

    @Attribute
    fileprivate var phase1: _GraphInputs.Phase

    @Attribute
    fileprivate var phase2: _GraphInputs.Phase

    fileprivate var resetDelta: UInt32

    fileprivate var value: _GraphInputs.Phase {
        var newPhase = phase1.merge(rhs: phase2)
        newPhase.seed &+= resetDelta
        return newPhase
    }
}
