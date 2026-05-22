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
internal struct MakeChildTransition: TransitionVisitor {

    @Attribute
    internal var state: ViewCacheItem.State

    internal var inputs: _ViewInputs

    internal var id: _ViewList_ID

    internal var makeElt: (_ViewInputs) -> _ViewOutputs

    internal var outputs: _ViewOutputs?

    internal var transition: DGAttribute?

    internal var transitionType: Any.Type?

    internal mutating func visit<T>(_ transition: T) where T : Transition {
        let attribute = Attribute(IncrementalTransition(state: _state, item: nil, lastValue: transition))

        let graphValue = _GraphValue(attribute)
        let makeElement = makeElt
        self.outputs = T.TransitionModifier._makeView(modifier: graphValue, inputs: inputs) { (_graph, inputs) in
            makeElement(inputs)
        }
        self.transition = attribute.identifier
        self.transitionType = T.self
    }
}

@available(iOS 13.0, *)
internal struct IncrementalTransition<T: Transition>: StatefulRule {

    internal typealias Value = T.TransitionModifier

    @Attribute
    internal var state: ViewCacheItem.State

    internal var item: ViewCacheItem?

    internal var lastValue: T

    internal mutating func updateValue() {
        let traits = item!.list?.traits ?? .init()
        let traitValue = traits.value(for: TransitionTraitKey.self, defaultValue: .opacity)
        if let base = traitValue.base(as: T.self) {
            lastValue = base
        }
        let itemState = self.state
        let phase: TransitionPhase = itemState.enableTransitions ? itemState.phase : .normal
        self.value = lastValue.transitionModifier(phase: phase)
    }

}
