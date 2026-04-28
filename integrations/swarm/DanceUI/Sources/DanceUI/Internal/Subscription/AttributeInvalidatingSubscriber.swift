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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal final class AttributeInvalidatingSubscriber<A: Publisher>:
    Subscriber,
    Cancellable,
    CustomCombineIdentifierConvertible
{
    
    internal typealias Input = A.Output
    
    internal typealias Failure = A.Failure
    
    internal weak var host: GraphHost?

    internal let attribute: WeakAttribute<Void>

    internal var state: StateType
    
    internal init(host: GraphHost?, attribute: WeakAttribute<Void>) {
        self.host = host
        self.attribute = attribute
        self.state = .unsubscribed
    }
    
    internal func cancel() {
        if case let .subscribed(sub) = state {
            sub.cancel()
        }
        
        state = .unsubscribed
    }
    
    internal func receive(subscription: Subscription) {
        switch state {
        case .unsubscribed:
            state = .subscribed(subscription)
            subscription.request(.unlimited)
        default:
            subscription.cancel()
        }
    }
    
    internal func receive(_ input: A.Output) -> Subscribers.Demand {
        if case .subscribed = state {
            invalidateAttribute()
        }
        
        return .none
    }
    
    internal func receive(completion: Subscribers.Completion<A.Failure>) {
        if case .subscribed = state {
            state = .complete
            invalidateAttribute()
        }
    }
    
    internal /* fileprivate */ func invalidateAttribute() {
#if DEBUG || DANCE_UI_INHOUSE
        if !isMainThread {
            runtimeIssue(type: .error, "Publishing changes from background threads is not allowed; make sure to publish values from the main thread (via operators like receive(on:)) on model updates.")
        }
#endif
        Update.ensure {
            // Get the identifier with ` self.attribute.base.__attribute`
            // to avoid live-ness testing.
            let mutation = InvalidatingGraphMutation(attribute: self.attribute)
#if DEBUG || DANCE_UI_INHOUSE
            Signpost.viewInfoTrace.traceEvent(
                "will schedule invalidating graph mutation: attribute = %{public}d; seed = %{public}d",
                [self.attribute.base.__attribute.rawValue, mutation.seed.value]
            )
#endif // DEBUG || DANCE_UI_INHOUSE
            self.host?.asyncTransaction(Transaction.current,
                                        mutation: mutation,
                                        style: .ignoresFlushWhenUpdating,
                                        mayDeferUpdate: true)
        }
    }
    
    internal enum StateType {
        case subscribed(Subscription)

        case unsubscribed

        case complete

    }
}
