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
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal final class SubscriptionLifetime<A: Publisher>: Cancellable {
    
    internal var subscriptionID: UniqueSeedGenerator

    internal var state: SubscriptionLifetime<A>.StateType
    
    internal init() {
        subscriptionID = UniqueSeedGenerator()
        state = .uninitialized
    }
    
    deinit {
        cancel()
    }
    
    internal func subscribe<A1: Cancellable & Subscriber>(subscriber: A1, to publisher: A) where A.Failure == A1.Failure, A.Output == A1.Input {
        let needsSubscribe: Bool
        
        if case let .subscribed(to: oldPublisher, subscriber: oldSubscriber, subscription: oldSubscription, _) = state {
            let isIdenticalPublisher = DGCompareValues(lhs: oldPublisher, rhs: publisher)
            
            if !isIdenticalPublisher {
                oldSubscriber.cancel()
                oldSubscription.cancel()
                needsSubscribe = true
            } else {
                needsSubscribe = false
            }
            
            
        } else {
            needsSubscribe = true
        }
        
        if needsSubscribe {
            let nextID = subscriptionID.generateNextID()
            
            let connection = Connection(parent: self, downstream: subscriber, subscriptionID: nextID)
            
            state = .requestedSubscription(to: publisher, subscriber: AnyCancellable(subscriber), subscriptionID: nextID)
            
            publisher.subscribe(connection)
        }
    }
    
    internal func shouldAcceptSubscription(_ subscription: Subscription, for subscriptionID: Int) -> Bool {
        if case let .requestedSubscription(to: oldPublisher, subscriber: oldSubscriber, subscriptionID: oldSubscriptionID) = state {
            if oldSubscriptionID != subscriptionID {
                subscription.cancel()
                
                return false
            } else {
                
                self.state = .subscribed(to: oldPublisher, subscriber: oldSubscriber, subscription: subscription, subscriptionID: subscriptionID)
                
                return true
            }
        } else {
            subscription.cancel()
            
            return false
        }
    }
    
    internal func shouldAcceptValue(for subscriptionID: Int) -> Bool {
        if case .subscribed = state {
            return true
        }
        
        return false
    }
    
    internal func shouldAcceptCompletion(for subscriptionID: Int) -> Bool {
        if case let .subscribed(_, _, _, subscriptionID: oldSubscriptionID) = state {
            if  oldSubscriptionID == subscriptionID {
                
                self.state = .uninitialized
                
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }

    // MARK: Cancellable
    
    internal func cancel() {
        
        guard case let .subscribed(_, subscriber: subscriber, subscription: subscription, _) = state else {
            return
        }
        
        subscriber.cancel()
        subscription.cancel()
        
        state = .uninitialized
        
    }
    
    internal enum StateType {
        
        case requestedSubscription(to: A, subscriber: AnyCancellable, subscriptionID: Int)
        
        case subscribed(to: A, subscriber: AnyCancellable, subscription: Subscription, subscriptionID: Int)
        
        case uninitialized
        
    }
    
    fileprivate struct Connection<A1: Subscriber>: Subscriber where A.Output == A1.Input {
        
        fileprivate typealias Input = A1.Input
        
        fileprivate typealias Failure = A1.Failure
        
        fileprivate var combineIdentifier: CombineIdentifier
        
        fileprivate weak var parent: SubscriptionLifetime<A>?
        
        fileprivate var downstream: A1
        
        fileprivate var subscriptionID: Int
        
        fileprivate init(parent: SubscriptionLifetime<A>, downstream: A1, subscriptionID: Int) {
            self.combineIdentifier = .init()
            self.parent = parent
            self.downstream = downstream
            self.subscriptionID = subscriptionID
        }
        
        fileprivate func receive(subscription: Subscription) {
            guard let parent = parent,
                parent.shouldAcceptSubscription(subscription, for: subscriptionID) else {
                return
            }
            
            downstream.receive(subscription: subscription)
            
            subscription.request(.unlimited)
        }
        
        fileprivate func receive(_ output: A.Output) -> Subscribers.Demand {
            guard let parent = parent,
                parent.shouldAcceptValue(for: subscriptionID) else {
                return .none
            }
            
            _ = self.downstream.receive(output)
            
            return .none
        }
        
        fileprivate func receive(completion: Subscribers.Completion<A1.Failure>) {
            guard let parent = parent,
                parent.shouldAcceptCompletion(for: subscriptionID) else {
                return
            }
            
            downstream.receive(completion: completion)
        }
    }
}
