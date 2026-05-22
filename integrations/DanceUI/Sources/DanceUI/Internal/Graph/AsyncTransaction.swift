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

@available(iOS 13.0, *)
internal final class AsyncTransaction {

    internal var transaction: Transaction

    internal var mutations: [GraphMutation] = []
    
    internal init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    internal func apply() {
        withTransaction(transaction) {
            for var eachMutation in mutations {
                eachMutation.traceApply()

                eachMutation.apply()
            }
        }
    }
    
    internal func append<Mutation: GraphMutation>(_ mutation: Mutation) {
        // ``GraphMutation/combine`` is mutating function
        // So we use ``Array.subscript/_modify`` instead of ``Array.last/getter`` to mutate inline
        if !mutations.isEmpty, mutations[mutations.count-1].combine(with: mutation) {
            return
        }
        mutations.append(mutation)
    }
    
    @inline(__always)
    internal func canAppendAsyncTransaction(with transaction: Transaction) -> Bool {
        return transaction.mayConcatenate(with: self.transaction)
    }
    
}
