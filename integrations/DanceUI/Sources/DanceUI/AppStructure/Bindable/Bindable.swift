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

import DanceUIObservation

@available(iOS 13.0, *)
@dynamicMemberLookup
@propertyWrapper
public struct Bindable<Value> {
    
    public var wrappedValue: Value
    
    public var projectedValue: Bindable<Value> {
        self
    }
    
    @available(*, unavailable, message: "The wrapped value must be an object that conforms to Observable")
    public init(wrappedValue: Value) {
        preconditionFailure("Unavailable method.")
    }
    
    @available(*, unavailable, message: "The wrapped value must be an object that conforms to Observable")
    public init(projectedValue: Bindable<Value>) {
        preconditionFailure("Unavailable method.")
    }
}

@available(iOS 13.0, *)
extension Bindable where Value : AnyObject {
    
    public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<Value, Subject>) -> Binding<Subject> {
        Binding {
            wrappedValue[keyPath: keyPath]
        } set: { newValue in
            wrappedValue[keyPath: keyPath] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension Bindable where Value : OpenCombine.ObservableObject {
    
    @available(*, unavailable, message: "@Bindable only works with Observable types. For ObservableObject types, use @ObservedObject instead.")
    public init(wrappedValue: Value) {
        preconditionFailure("Unavailable method.")
    }
    
}

@available(iOS 13.0, *)
extension Bindable where Value : AnyObject, Value : Observable {
    
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(_ wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    public init(projectedValue: Bindable<Value>) {
        self = projectedValue
    }
    
}

@available(iOS 13.0, *)
extension Bindable : Identifiable where Value : Identifiable {
    
    public var id: Value.ID {
        wrappedValue.id
    }
    
    public typealias ID = Value.ID
    
}


@available(iOS 13.0, *)
extension Bindable : Sendable where Value : Sendable { }
