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

internal typealias _ViewList_Elements_ReleaseHandler = () -> Void
@available(iOS 13.0, *)
internal protocol _ViewList_Elements {

    var count: Int { get }

    func makeElements(from index: inout Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool)) -> (_ViewOutputs?, Bool)

    func makeAllElements(inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> _ViewOutputs?) -> _ViewOutputs?

    func tryToReuseElement(at index: Int, by elements: _ViewList_Elements, at elementsIndex: Int, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool

    func retain() -> _ViewList_Elements_ReleaseHandler
}

@available(iOS 13.0, *)
extension _ViewList_Elements {

    @usableFromInline
    internal func makeAllElements(inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> _ViewOutputs?) -> _ViewOutputs? {
        withoutActuallyEscaping(body) { (body) -> _ViewOutputs? in
            let bodyWrapper: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool) = { (inputs, makeOutputs) in
                (body(inputs, makeOutputs), true)
            }
            var beginIndex = 0
            return self.makeElements(from: &beginIndex, inputs: inputs, indirectMap: indirectMap, body: bodyWrapper).0
        }
    }

    @usableFromInline
    internal func makeOneElement(at index: Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> _ViewOutputs?) -> _ViewOutputs?
    {
        withoutActuallyEscaping(body) { (body) -> _ViewOutputs? in
            let bodyWrapper: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool) = { (inputs, makeOutputs) in
                (body(inputs, makeOutputs), false)
            }

            var beginIndex = index
            return self.makeElements(from: &beginIndex, inputs: inputs, indirectMap: indirectMap, body: bodyWrapper).0
        }
    }
}
