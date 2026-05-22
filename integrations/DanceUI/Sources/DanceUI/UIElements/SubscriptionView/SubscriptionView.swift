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

/// A view that subscribes to a publisher with an action.
@frozen
@available(iOS 13.0, *)
public struct SubscriptionView<PublisherType: Publisher, Content: View>: View where PublisherType.Failure == Never {
    
    /// The content view.
    public var content: Content
    
    /// The `Publisher` that is being subscribed.
    public var publisher: PublisherType
    
    /// The `Action` executed when `publisher` emits an event.
    public var action: (PublisherType.Output) -> Void
    
    public var body: Never {
        _terminatedViewNode()
    }
    
    @inlinable
    public init(content: Content, publisher: PublisherType, action: @escaping (PublisherType.Output) -> Void) {
        self.content = content
        self.publisher = publisher
        self.action = action
    }
    
    public static func _makeView(view: _GraphValue<Self>,
                                 inputs: _ViewInputs) -> _ViewOutputs {
        let child = Attribute(ChildAttribute(view: view.value))
        child.flags = .active
        return Content.makeDebuggableView(value: _GraphValue(child), inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<SubscriptionView>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let child = Attribute(ChildAttribute(view: view.value))
        child.flags = .active
        return Content._makeViewList(view: _GraphValue(child), inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
    
    internal struct ChildAttribute: StatefulRule {
        
        internal typealias Value = Content
        
        @Attribute
        internal var view: SubscriptionView<PublisherType, Content>
        
        internal var subscriptionLifetime: SubscriptionLifetime<PublisherType>
        
        internal var actionBox: MutableBox<(PublisherType.Output) -> Void>
        
        @inlinable
        internal init(view: Attribute<SubscriptionView<PublisherType, Content>>) {
            _view = view
            subscriptionLifetime = .init()
            actionBox = MutableBox { _ in }
        }
        
        internal mutating func updateValue() {
            let subscriptionView = view
            
            actionBox.value = { output in
                Update.enqueueAction {
                    subscriptionView.action(output)
                }
            }
            
            let subscriber = ActionDispatcherSubscriber(actionBox: actionBox,
                                                        combineIdentifier: CombineIdentifier())
            
            subscriptionLifetime.subscribe(subscriber: subscriber,
                                           to: subscriptionView.publisher)
            
            value = subscriptionView.content
        }
    }
    
}
