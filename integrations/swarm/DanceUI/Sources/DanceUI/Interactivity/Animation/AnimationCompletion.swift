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
extension Transaction {

    /// Adds a completion to run when the animations created with this
    /// transaction are all complete.
    ///
    /// The completion callback will always be fired exactly one time. If no
    /// animations are created by the changes in `body`, then the callback will
    /// be called immediately after `body`.
    public mutating func addAnimationCompletion(criteria: AnimationCompletionCriteria = .logicallyComplete,
                                                _ completion: @escaping () -> Void) {
        switch criteria.storage {
        case .logicallyComplete:
            addAnimationLogicalListener { info in
                Update.enqueueAction {
                    completion()
                }
            }
        case .removed:
            addAnimationListener { info in
                Update.enqueueAction {
                    completion()
                }
            }
        }
    }
    
    internal mutating func addAnimationLogicalListener(allFinished: @escaping (AnimationCompletionInfo) -> Void) {
        let listener = AllFinishedListener(allFinished: allFinished,
                                           count: 0,
                                           maxCount: 0,
                                           dispatched: false)
        guard let transitionListener = self.logicalListener else {
            self.logicalListener = listener
            return
        }
        self.logicalListener = ListenerPair(first: transitionListener, second: listener)
    }
    
    internal mutating func addAnimationListener(allFinished: @escaping (AnimationCompletionInfo) -> Void) {
        let listener = AllFinishedListener(allFinished: allFinished,
                                           count: 0,
                                           maxCount: 0,
                                           dispatched: false)
        guard let transitionListener = self.listener else {
            self.listener = listener
            return
        }
        self.listener = ListenerPair(first: transitionListener, second: listener)
    }
    
    @inline(__always)
    internal var logicalListener: AnimationListener? {
        get {
            self[Transaction.AnimationLogicalListenerKey.self]
        }
        
        set {
            self[Transaction.AnimationLogicalListenerKey.self] = newValue
        }
    }
    
    fileprivate struct AnimationLogicalListenerKey: TransactionKey {
        
        internal typealias Value = AnimationListener?
        
        @inline(__always)
        internal static var defaultValue: AnimationListener? { nil }

    }
    
}

@available(iOS 13.0, *)
internal struct AnimationCompletionInfo {
    internal var completedCount: Int
}

@available(iOS 13.0, *)
private final class AllFinishedListener: AnimationListener {

    private let allFinished: (AnimationCompletionInfo) -> Void

    private var count: Int

    private var maxCount: Int

    private var dispatched: Bool
    
    deinit {
        dispatchIfNeeded()
    }
    
    internal init(allFinished: @escaping (AnimationCompletionInfo) -> Void,
                  count: Int,
                  maxCount: Int,
                  dispatched: Bool) {
        self.allFinished = allFinished
        self.count = count
        self.maxCount = maxCount
        self.dispatched = dispatched
    }
    
    fileprivate func animationWasAdded() {
        count &+= 1
        maxCount &+= 1
    }
    
    fileprivate func animationWasRemoved() {
        count &-= 1
        checkDispatched()
    }
    
    fileprivate func checkDispatched() {
        guard count == 0 else {
            return
        }
        dispatchIfNeeded()
    }
    
    @inline(__always)
    private func dispatchIfNeeded() {
        guard !dispatched else {
            return
        }
        allFinished(.init(completedCount: maxCount))
        dispatched = true
    }
}
