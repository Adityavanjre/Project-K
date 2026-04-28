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
internal struct MergedElements : _ViewList_Elements {

    internal var outputs: [_ViewListOutputs]

    internal var count: Int {
        guard !outputs.isEmpty else {
            return 0
        }
        var totalCount: Int = 0
        for output in outputs {
            switch output.views {
                case .staticList(let elements):
                    totalCount = totalCount &+ elements.count
                case .dynamicList:
                    _danceuiFatalError()
            }
        }
        return totalCount
    }

    internal func makeElements(from index: inout Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool)) -> (_ViewOutputs?, Bool) {
        var viewOutputs: [_ViewOutputs] = []
        var shouldContinue = true
        OutputsMakeElements: for output in outputs {
            switch output.views {
                case .staticList(let elements):
                viewOutputs.reserveCapacity(viewOutputs.count + elements.count)
                    let (elementsOutputs, elementsShouldContinue) = elements.makeElements(from: &index, inputs: inputs, indirectMap: indirectMap, body: body)
                    if let elementsOutputs = elementsOutputs {
                        viewOutputs.append(elementsOutputs)
                    }
                    guard elementsShouldContinue else {
                        break OutputsMakeElements
                    }
                case .dynamicList:
                    _danceuiFatalError()
            }
        }
        guard !viewOutputs.isEmpty else {
            return (nil, shouldContinue)
        }

        let resultOutputs: _ViewOutputs
        if viewOutputs.count == 1, let singleResult = viewOutputs.first {
            resultOutputs = singleResult
            shouldContinue = false
        } else {
            if inputs.preferences.keys.isEmpty {
                resultOutputs = _ViewOutputs()
            } else {
                var visitor = MultiPreferenceCombinerVisitor(childOutputs: viewOutputs.map({$0.preferences}),
                                                             result: PreferencesOutputs())
                for keyType in inputs.preferences.keys {
                    keyType.visitKey(&visitor)
                }
                resultOutputs = _ViewOutputs(preferences: visitor.result)
            }
        }
        return (resultOutputs, shouldContinue)
    }

    @usableFromInline
    internal func tryToReuseElement(at index: Int, by elements: _ViewList_Elements, at elementsIndex: Int, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        guard let mergedElements = elements as? MergedElements else {
            return false
        }
        let parentElements: (elements: _ViewList_Elements, targetIndex: Int) = findElement(at: index)
        let childElements: (elements: _ViewList_Elements, targetIndex: Int) = mergedElements.findElement(at: elementsIndex)
        return childElements.elements.tryToReuseElement(at: parentElements.targetIndex, by: mergedElements, at: childElements.targetIndex, indirectMap: indirectMap, testOnly: testOnly)
    }

    @usableFromInline
    internal func findElement(at targetIndex: Int) -> (_ViewList_Elements, Int) {
        var totalCount: Int = 0
        for output in outputs {
            switch output.views {
                case .staticList(let elements):
                    let count: Int = elements.count
                    totalCount = totalCount &+ count
                    if targetIndex >= count && totalCount > targetIndex {
                        return (elements, targetIndex - count)
                    }
                case .dynamicList:
                    break
            }
        }
        _danceuiFatalError()
    }

    @usableFromInline
    internal func retain() -> _ViewList_Elements_ReleaseHandler {
        {}
    }
}
