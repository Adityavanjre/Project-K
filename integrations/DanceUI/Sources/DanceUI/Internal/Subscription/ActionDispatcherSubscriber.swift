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

import OpenCombine
import Darwin
internal import Dispatch
internal import os.log

@available(iOS 13.0, *)
internal struct ActionDispatcherSubscriber<Input>: Cancellable, Subscriber {
    
    internal typealias Failure = Never
    
    internal var actionBox: MutableBox<(Input) -> Void>
    
    internal var combineIdentifier: CombineIdentifier
    
    internal init(actionBox: MutableBox<(Input) -> Void>, combineIdentifier: CombineIdentifier) {
        self.actionBox = actionBox
        self.combineIdentifier = combineIdentifier
    }
    
    internal func cancel() {
        _intentionallyLeftBlank()
    }
    
    internal func receive(completion: Subscribers.Completion<Never>) {
        _intentionallyLeftBlank()
    }
    
    internal func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }
    
    internal func receive(_ input: Input) -> Subscribers.Demand {
        respond(to: input)
        
        return .none
    }
    
    internal func respond(to input: Input) {
#if DEBUG || DANCE_UI_INHOUSE
        if !isMainThread {
            runtimeIssue(type: .error, "Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates.")
        }
#endif
        performOnMainThread {
            self.actionBox.value(input)
        }
    }
}
