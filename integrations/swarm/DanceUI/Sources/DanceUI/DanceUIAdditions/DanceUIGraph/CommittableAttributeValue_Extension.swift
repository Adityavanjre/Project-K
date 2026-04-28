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
internal protocol CommittableAttributeValue {
    
}

@available(iOS 13.0, *)
extension CommittableAttributeValue {
    
    internal func commit(to attribute: WeakAttribute<Self>) {
        guard let stateAttribute = attribute.attribute else {
            return
        }
        
        let graph = stateAttribute.graph.graphHost()
        let transaction = Transaction()
        let mutation = ValueCommitMutation(attribute: attribute, value: self)
        graph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
        Update.enqueueAction {
            graph.flushTransactions()
        }
    }
    
}

@available(iOS 13.0, *)
extension Optional: CommittableAttributeValue where Wrapped: CommittableAttributeValue {
    
}

@available(iOS 13.0, *)
internal struct ValueCommitMutation<Value>: GraphMutation {
    
    private let attribute: WeakAttribute<Value>
    
    private var value: Value
    
#if DEBUG || DANCE_UI_INHOUSE
    internal let file: StaticString
    
    internal let line: UInt
    
    internal let function: StaticString
    
    internal init(attribute: WeakAttribute<Value>, value: Value, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
        self.attribute = attribute
        self.value = value
        self.file = file
        self.line = line
        self.function = function
    }
#else
    internal init(attribute: WeakAttribute<Value>, value: Value) {
        self.attribute = attribute
        self.value = value
    }
#endif
    
    internal func apply() {
        _ = attribute.attribute?.setValue(value)
    }
    
    internal mutating func combine<T: GraphMutation>(with mutation: T) -> Bool {
        guard let commitMutation = mutation as? ValueCommitMutation,
              attribute == commitMutation.attribute else {
            return false
        }
        value = commitMutation.value
        return true
    }
    
}

@available(iOS 13.0, *)
extension ViewGraph {
    
    internal static func setNeedUpdateWithNewValue<Value>(_ value: Value, of weakAttribute: WeakAttribute<Value>, graphWillFlushTransactions: (() -> Void)? = nil) {
        guard let attribute = weakAttribute.attribute else {
            return
        }
        let graph = attribute.graph.graphHost()
        let transaction = Transaction()
        let mutation = ValueCommitMutation(attribute: weakAttribute, value: value)
        graph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
        Update.enqueueAction {
            graphWillFlushTransactions?()
            graph.flushTransactions()
        }
    }
    
    internal static func asyncWithNewValue<Value>(_ value: Value, 
                                                  of weakAttribute: WeakAttribute<Value>,
                                                  transaction: Transaction,
                                                  mayDeferUpdate: Bool = true) {
        guard let attribute = weakAttribute.attribute else {
            return
        }
        let graphHost = attribute.graph.graphHost()
        let mutation = ValueCommitMutation(attribute: weakAttribute, value: value)
        let newTransaction = Transaction.current.byOverriding(with: transaction)
        graphHost.asyncTransaction(newTransaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: mayDeferUpdate)
        Update.enqueueAction {
            graphHost.flushTransactions()
        }
    }
}
