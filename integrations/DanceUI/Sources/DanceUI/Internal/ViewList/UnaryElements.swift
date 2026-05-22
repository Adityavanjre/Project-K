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
internal struct UnaryElements<Body: UnaryViewGenerator> : _ViewList_Elements {

    internal var body: Body

    internal var baseInputs: _GraphInputs

    @inlinable
    internal init(body: Body, baseInputs: _GraphInputs) {
        self.body = body
        self.baseInputs = baseInputs
    }

    @inlinable
    internal var count: Int {
        1
    }

    internal func makeElements(from index: inout Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool)) -> (_ViewOutputs?, Bool) {
        defer {
            index = max(index - 1, 0)
        }
        guard index == 0 else {
            return (nil, true)
        }

        let (outputs, shouldContinue) = body(inputs) { (internalInputs) -> _ViewOutputs in

            var reusable = self.baseInputs
            reusable.makeReusable(indirectMap: indirectMap)

            var mergedInputs = internalInputs
            mergedInputs.merge(inputs: reusable, ignoringPhase: false)
            return self.body.makeView(inputs: mergedInputs, indirectMap: indirectMap)
        }

        return (outputs, shouldContinue)
    }

    internal func tryToReuseElement(at index: Int, by elements: _ViewList_Elements, at elementsIndex: Int, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        guard let unaryElements = elements as? UnaryElements else {
            return false
        }
        guard body.tryToReuse(by: unaryElements.body, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        return baseInputs.tryToReuse(by: unaryElements.baseInputs, indirectMap: indirectMap, testOnly: testOnly)
    }

    internal func retain() -> _ViewList_Elements_ReleaseHandler {
        {

        }
    }
}
