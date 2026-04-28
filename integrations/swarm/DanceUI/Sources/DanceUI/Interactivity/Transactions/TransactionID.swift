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
internal struct TransactionID: Comparable {
    
    internal private(set) var id: Int
    
    internal init() {
        self.id = 0
    }
    
    @inline(__always)
    fileprivate init(graph: DGGraphRef) {
        self.id = graph.transactionCounter
    }
    
    internal init<A>(context: RuleContext<A>) {
        self.init(graph: context.attribute.graph)
    }
    
    internal static func < (lhs: TransactionID, rhs: TransactionID) -> Bool {
        lhs.id < rhs.id
    }
    
}

@available(iOS 13.0, *)
extension GraphHost {
    
    internal var transactionID: TransactionID {
        TransactionID(graph: graph)
    }
    
}
