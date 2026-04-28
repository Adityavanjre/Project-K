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
internal class _ViewList_Subgraph {

    internal let subgraph: DGSubgraphRef

    private var refcount: UInt32

    internal var isValid: Bool {
        guard refcount > 0 else {
            return false
        }
        return subgraph.isValid
    }

    internal init(subgraph: DGSubgraphRef) {
        self.subgraph = subgraph
        self.refcount = 1
    }

    internal func invalidate() {
        _intentionallyLeftBlank()
    }

    internal func retain() {
        refcount &+= 1
    }

    internal func release(isInserted: Bool) {
        refcount &-= 1

        guard refcount == 0 else {
            return
        }

        invalidate()

        guard subgraph.isValid else {
            return
        }

        if isInserted {
            subgraph.willRemove()
        }

        subgraph.invalidate()
    }

    @inline(__always)
    internal func wrapping(_ elements: _ViewList_Elements) -> _ViewList_Elements {
        SubgraphElements(base: elements, subgraph: self)
    }

}
