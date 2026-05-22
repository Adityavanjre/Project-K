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

@available(iOS 13.0, *)
internal struct ModifiedElements<Modifier: ViewModifier> : _ViewList_Elements {

    internal let base: _ViewList_Elements

    internal let modifier: _GraphValue<Modifier>

    internal let baseInputs: _GraphInputs

    @inlinable
    internal init(base: _ViewList_Elements, modifier: _GraphValue<Modifier>, baseInputs: _GraphInputs) {
        self.base = base
        self.modifier = modifier
        self.baseInputs = baseInputs
    }

    @inlinable
    internal var count: Int {
        base.count
    }

    internal func makeElements(from index: inout Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool)) -> (_ViewOutputs?, Bool) {
        withoutActuallyEscaping(body) { (body) -> (_ViewOutputs?, Bool) in
            self.base.makeElements(from: &index, inputs: inputs, indirectMap: indirectMap) { (inputs, makeViewOutputs) in
                return body(inputs, { internalInputs in
                    var reusableInputs = self.baseInputs
                    reusableInputs.makeReusable(indirectMap: indirectMap)

                    var mergedInputs = internalInputs
                    mergedInputs.merge(inputs: reusableInputs, ignoringPhase: false)

                    var reusableModifier = self.modifier
                    reusableModifier.makeReusable(indirectMap: indirectMap)

                    let outputs = Modifier.makeDebuggableViewModifier(value: reusableModifier, inputs: mergedInputs) { _, inputs in
                        makeViewOutputs(inputs)
                    }
                    return outputs
                })
            }
        }
    }

    internal func tryToReuseElement(at index: Int, by elements: _ViewList_Elements, at elementsIndex: Int, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        guard let modifiedElements = elements as? ModifiedElements else {
            return false
        }
        guard modifier.tryToReuse(by: modifiedElements.modifier, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        guard baseInputs.tryToReuse(by: modifiedElements.baseInputs, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        return base.tryToReuseElement(at: index, by: modifiedElements.base, at: elementsIndex, indirectMap: indirectMap, testOnly: testOnly)
    }

    @inlinable
    internal func retain() -> _ViewList_Elements_ReleaseHandler {
        base.retain()
    }

}
