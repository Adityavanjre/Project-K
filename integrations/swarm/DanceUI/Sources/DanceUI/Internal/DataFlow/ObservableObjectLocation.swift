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

@available(iOS 13.0, *)
internal struct ObservableObjectLocation<Base: ObservableObject, Member>: Location {
    
    internal typealias Value = Member
    
    internal var base: Base

    internal var keyPath: ReferenceWritableKeyPath<Base, Member>
    
    internal init(base: Base, keyPath: ReferenceWritableKeyPath<Base, Member>) {
        self.base = base
        self.keyPath = keyPath
    }
    
    internal var wasRead: Bool {
        get { true }
        set { }
    }
    
    internal func get() -> Value {
        base[keyPath: keyPath]
    }
    
    internal mutating func set(_ value: Value, transaction: Transaction) {
        let overridenTransaction = transaction.byOverriding(with: .current)
        withTransaction(overridenTransaction) {
            base[keyPath: keyPath] = value
        }
    }
    
}
