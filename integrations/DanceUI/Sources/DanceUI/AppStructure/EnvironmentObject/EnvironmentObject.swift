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
import OpenCombine

/// A property wrapper type for an observable object supplied by a parent or
/// ancestor view.
///
/// An environment object invalidates the current view whenever the observable
/// object changes. If you declare a property as an environment object, be sure
/// to set a corresponding model object on an ancestor view by calling its
/// ``View/environmentObject(_:)`` modifier.
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct EnvironmentObject<ObjectType: ObservableObject>: DynamicProperty {
    
    /// A wrapper of the underlying environment object that can create bindings
    /// to its properties using dynamic member lookup.
    @dynamicMemberLookup
    @frozen
    public struct Wrapper {
        
        internal let root: ObjectType
        
        /// Returns a binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath: A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            Binding(root, keyPath: keyPath)
        }
        
    }
    
    /// The underlying value referenced by the environment object.
    ///
    /// This property provides primary access to the value's data. However, you
    /// don't access `wrappedValue` directly. Instead, you use the property
    /// variable created with the ``EnvironmentObject`` attribute.
    ///
    /// When a mutable value changes, the new value is immediately available.
    /// However, a view displaying the value is updated asynchronously and may
    /// not show the new value immediately.
    @inlinable
    public var wrappedValue: ObjectType {
        guard let store = _store else {
            error()
        }
        return store
    }
    
    @usableFromInline
    internal var _store: ObjectType?
    
    @usableFromInline
    internal var _seed: Int
    
    /// A projection of the environment object that creates bindings to its
    /// properties using dynamic member lookup.
    ///
    /// Use the projected value to pass an environment object down a view
    /// hierarchy.
    public var projectedValue: EnvironmentObject<ObjectType>.Wrapper {
        guard let store = _store else {
            error()
        }
        return Wrapper(root: store)
    }
    
    @usableFromInline
    internal func error() -> Never {
        _danceuiFatalError("No ObservableObject of type \(ObjectType.self) found. A View.environmentObject(_:) for \(ObjectType.self) may be missing as an ancestor of this view.")
    }
    
    /// Creates an environment object.
    public init() {
        _store = nil
        _seed = 0
    }
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        let signal = Attribute(value: Void())
#if DEBUG || DANCE_UI_INHOUSE
        signal.role = .signalForObservableObject
        signal.association = .defObservableObjectSignal(fieldName: name ?? "$UnknownField(offset=\(fieldOffset))", observableObjectType: ObjectType.self)
#endif
        
        let box = StoreBox<ObjectType>(host: GraphHost.currentHost,
                                       environment: inputs.environment,
                                       signal: WeakAttribute(signal))
        
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
}

@available(iOS 13.0, *)
private struct StoreBox<A: ObservableObject>: DynamicPropertyBox {
    
    fileprivate typealias Property = EnvironmentObject<A>
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    fileprivate let signal: WeakAttribute<Void>
    
    fileprivate let subscriber: AttributeInvalidatingSubscriber<A.ObjectWillChangePublisher>
    
    fileprivate let lifetime: SubscriptionLifetime<A.ObjectWillChangePublisher>
    
    fileprivate var seed: Int
    
    fileprivate init(host: GraphHost?, environment: Attribute<EnvironmentValues>, signal: WeakAttribute<Void>) {
        self._environment = environment
        self.signal = signal
        self.subscriber = AttributeInvalidatingSubscriber(host: host, attribute: signal)
        self.lifetime = SubscriptionLifetime()
        self.seed = 0
    }
    
    fileprivate mutating func update(property: inout EnvironmentObject<A>, phase: _GraphInputs.Phase) -> Bool {
        property._store = environment[keyPath: A.environmentStore]
        
        if let newStore = property._store {
            lifetime.subscribe(subscriber: subscriber, to: newStore.objectWillChange)
        }
        
        let changed: Bool
        
        if let signalAttr = signal.attribute {
            let signalChanged = signalAttr.changedValue().changed
            
            changed = signalChanged
            
            if signalChanged {
                seed &+= 1
            }
        } else {
            changed = false
        }
        
        property._seed = seed
        
        return changed
    }
    
}
