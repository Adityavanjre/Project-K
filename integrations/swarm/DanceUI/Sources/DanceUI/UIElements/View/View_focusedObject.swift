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
extension FocusedValue {
    
    public init(_ objectType: Value.Type) where Value : AnyObject, Value : Observable {
        self.init(Value.focusedValueKey)
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    public func focusedValue<T>(_ object: T?) -> some View where T : AnyObject, T : Observable {
        focusedValue(T.focusedValueKey, object)
    }
    
}

@available(iOS 13.0, *)
extension Observable where Self: AnyObject {
    
    internal static var focusedValueKey: WritableKeyPath<FocusedValues, Self?> {
        \FocusedValues[FocusedObjectWrapper<Self>(id: ObjectIdentifier(self))]
    }
    
}

@available(iOS 13.0, *)
private struct FocusedObjectWrapper<A: AnyObject>: Hashable {
    
    fileprivate let id: ObjectIdentifier
    
}

@available(iOS 13.0, *)
extension FocusedValues {
    
    @inline(__always)
    fileprivate subscript<A: AnyObject>(store: FocusedObjectWrapper<A>) -> A? {
        get {
            self[FocusedObjectKey<A>.self]
        }
        set {
            self[FocusedObjectKey<A>.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct FocusedObjectKey<A: AnyObject>: FocusedValueKey {
    
    typealias Value = A
    
}
