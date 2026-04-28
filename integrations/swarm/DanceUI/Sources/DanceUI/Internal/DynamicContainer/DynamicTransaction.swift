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
internal struct DynamicTransaction: StatefulRule {

    internal typealias Value = Transaction

    @Attribute
    internal var info: DynamicContainer.Info

    @Attribute
    internal var transaction: Transaction

    internal let uniqueId: UInt32

    internal var wasRemoved: Bool

    internal mutating func updateValue() {
        let info = self.info
        guard let index = info.indexMap[uniqueId], let phase = info.items[index].phase else {
            self.value = Transaction()
            return
        }

        var transaction = self.transaction
        let preRemovedState = wasRemoved
        wasRemoved = false
        switch phase {
        case .willInsert:
            transaction.animation = nil
            transaction.disablesAnimations = false
        case .normal:
            break
        case .didRemove:
            if !preRemovedState, let listener = info.items[index].listener {
                if let transationListener = transaction.listener {
                    transaction.listener = ListenerPair(first: transationListener, second: listener)
                } else {
                    transaction.listener = listener
                }
            }
            wasRemoved = true
        }
        self.value = transaction
    }

}

@available(iOS 13.0, *)
internal final class ListenerPair: AnimationListener {

    internal let first: AnimationListener

    internal let second: AnimationListener

    internal init(first: AnimationListener, second: AnimationListener) {
        self.first = first
        self.second = second
    }

    internal func animationWasAdded() {
        first.animationWasAdded()
        second.animationWasAdded()
    }

    internal func animationWasRemoved() {
        first.animationWasRemoved()
        second.animationWasRemoved()
    }

    internal func checkDispatched() {
        first.checkDispatched()
        second.checkDispatched()
    }

}
