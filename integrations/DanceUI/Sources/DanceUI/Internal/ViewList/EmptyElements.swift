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
internal struct EmptyViewListElements: _ViewList_Elements {

    @usableFromInline
    internal var count: Int {
        0
    }

    @usableFromInline
    internal func makeElements(from index: inout Int, inputs: _ViewInputs, indirectMap: _ViewList_IndirectMap?, body: (_ViewInputs, @escaping (_ViewInputs) -> _ViewOutputs) -> (_ViewOutputs?, Bool)) -> (_ViewOutputs?, Bool) {
        (nil, true)
    }

    @usableFromInline
    internal func tryToReuseElement(at index: Int, by elements: _ViewList_Elements, at elementsIndex: Int, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        elements is EmptyViewListElements
    }

    @usableFromInline
    internal func retain() -> _ViewList_Elements_ReleaseHandler {
        {}
    }
}
