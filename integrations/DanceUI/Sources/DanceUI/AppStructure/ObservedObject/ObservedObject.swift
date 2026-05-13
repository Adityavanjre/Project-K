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

/// A property wrapper type that subscribes to an observable object and
/// invalidates a view whenever the observable object changes.
@propertyWrapper
@frozen
@available(iOS 13.0, *)
public struct ObservedObject<ObjectType: ObservableObject> : DynamicProperty {
    
    /// A wrapper of the underlying observable object that can create bindings to
    /// its properties using dynamic member lookup.
    @dynamicMemberLookup
    @frozen
    public struct Wrapper {
        
        internal let root: ObjectType
        
        /// Returns a binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<ObjectType, Subject>) -> Binding<Subject> {
            Binding(root, keyPath: keyPath)
        }
        
    }
    
    internal var _seed: Int = 0
    
    /// The underlying value referenced by the observed object.
    ///
    /// This property provides primary access to the value's data. However, you
    /// don't access `wrappedValue` directly. Instead, you use the property
    /// variable created with the `@ObservedObject` attribute.
    ///
    /// When a mutable value changes, the new value is immediately available.
    /// However, a view displaying the value is updated asynchronously and may
    /// not show the new value immediately.
    public var wrappedValue: ObjectType
    
    /// Creates an observed object with an initial value.
    ///
    /// - Parameter initialValue: An initial value.
    public init(initialValue: ObjectType) {
        self.init(wrappedValue: initialValue)
    }
    
    /// Creates an observed object with an initial wrapped value.
    ///
    /// You don't call this initializer directly. Instead, declare a property
    /// with the `@ObservedObject` attribute, and provide an initial value.
    ///
    /// - Parameter wrappedValue: An initial value.
    public init(wrappedValue: ObjectType) {
        _seed = 0
        self.wrappedValue = wrappedValue
    }
    
    /// A projection of the observed object that creates bindings to its
    /// properties using dynamic member lookup.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the `projectedValue`, prefix the property variable with `$`.
    public var projectedValue: Wrapper {
        return Wrapper(root: wrappedValue)
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        let graphHost = GraphHost.currentHost
        
        let signal = Attribute(value: Void())
#if DEBUG || DANCE_UI_INHOUSE
        signal.role = .signalForObservableObject
        signal.association = .defObservableObjectSignal(fieldName: name ?? "$UnknownField(offset=\(fieldOffset))", observableObjectType: ObjectType.self)
#endif
        
        let weakSignal = WeakAttribute(signal)
        
        let box = ObservedObjectPropertyBox<ObjectType>(host: graphHost, invalidation: weakSignal)
        
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
    public static var _propertyBehaviors: UInt32 {
        0x2
    }
    
}

@available(iOS 13.0, *)
fileprivate struct ObservedObjectPropertyBox<ObjectType: ObservableObject>: DynamicPropertyBox {

    fileprivate typealias Property = ObservedObject<ObjectType>

    fileprivate let subscriber: AttributeInvalidatingSubscriber<ObjectType.ObjectWillChangePublisher>

    fileprivate let lifetime: SubscriptionLifetime<ObjectType.ObjectWillChangePublisher>
    
    fileprivate var seed: Int
    
    fileprivate init(host: GraphHost?, invalidation: WeakAttribute<Void>) {
        subscriber = .init(host: host, attribute: invalidation)
        lifetime = .init()
        seed = 0
    }
    
    fileprivate mutating func update(property: inout ObservedObject<ObjectType>, phase: _GraphInputs.Phase) -> Bool {
        lifetime.subscribe(subscriber: subscriber, to: property.wrappedValue.objectWillChange)
        
        guard let signal = subscriber.attribute.attribute else {
            return false
        }
        
        guard signal.changedValue().changed else {
            return false
        }
        
        seed &+= 1
        
        property._seed = seed
        
        return true
    }
    
}
