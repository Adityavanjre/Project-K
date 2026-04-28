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
internal struct IncrementalTransaction: StatefulRule {

    internal typealias Value = Transaction

    @Attribute
    internal var transaction: Transaction

    @Attribute
    internal var state: ViewCacheItem.State

    internal var item: ViewCacheItem?

    internal var lastPhase: TransitionPhase?

    internal mutating func updateValue() {
        var transaction = transaction
        let state = state

        switch state.phase {
        case .willInsert:
            transaction.animation = nil
            transaction.disablesAnimations = true
        case .normal:
            break
        case .didRemove:
            guard lastPhase != .didRemove else {
                break
            }
            if let listener = transaction.listener {
                transaction.listener = ListenerPair(first: listener, second: item!)
            } else {
                transaction.listener = item!
            }
        }
        lastPhase = state.phase
        self.value = transaction
    }

}
