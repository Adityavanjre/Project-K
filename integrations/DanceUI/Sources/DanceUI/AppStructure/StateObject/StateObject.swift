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

/// A property wrapper type that instantiates an observable object.
///
/// Create a state object in a ``DanceUI/View``, ``DanceUI/App``, or
/// ``DanceUI/Scene`` by applying the `@StateObject` attribute to a property
/// declaration and providing an initial value that conforms to the
/// <https://developer.apple.com/documentation/Combine/ObservableObject>
/// protocol:
///
///     @StateObject var model = DataModel()
///
/// DanceUI creates a new instance of the object only once for each instance of
/// the structure that declares the object. When published properties of the
/// observable object change, DanceUI updates the parts of any view that depend
/// on those properties:
///
///     Text(model.title) // Updates the view any time `title` changes.
///
/// You can pass the state object into a property that has the
/// ``DanceUI/ObservedObject`` attribute. You can alternatively add the object
/// to the environment of a view hierarchy by applying the
/// ``DanceUI/View/environmentObject(_:)`` modifier:
///
///     ContentView()
///         .environmentObject(model)
///
/// If you create an environment object as shown in the code above, you can
/// read the object inside `ContentView` or any of its descendants
/// using the ``DanceUI/EnvironmentObject`` attribute:
///
///     @EnvironmentObject var model: DataModel
///
/// Get a ``DanceUI/Binding`` to one of the state object's properties using the
/// `$` operator. Use a binding when you want to create a two-way connection to
/// one of the object's properties. For example, you can let a
/// ``DanceUI/Toggle`` control a Boolean value called `isEnabled` stored in the
/// model:
///
///     Toggle("Enabled", isOn: $model.isEnabled)
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct StateObject<ObjectType: ObservableObject> : DynamicProperty {
    
    @usableFromInline
    @frozen
    internal enum Storage {
        
        case initially(() -> ObjectType)
        
        case object(ObservedObject<ObjectType>)
        
    }
    
    @usableFromInline
    internal var storage: StateObject<ObjectType>.Storage
    
    internal var objectValue: ObservedObject<ObjectType> {
        switch storage {
        case let .object(value):
            return value
        case let .initially(thunk):
            runtimeIssue(type: .warning, "Accessing StateObject's object without being installed on a View. This will create a new instance each time.")
            return ObservedObject(wrappedValue: thunk())
        }
    }
    
    /// Creates a new state object with an initial wrapped value.
    ///
    /// You don’t call this initializer directly. Instead, declare a property
    /// with the `@StateObject` attribute in a ``DanceUI/View``,
    /// ``DanceUI/App``, or ``DanceUI/Scene``, and provide an initial value:
    ///
    ///     struct MyView: View {
    ///         @StateObject var model = DataModel()
    ///
    ///         // ...
    ///     }
    ///
    /// DanceUI creates only one instance of the state object for each
    /// container instance that you declare. In the code above, DanceUI
    /// creates `model` only the first time it initializes a particular instance
    /// of `MyView`. On the other hand, each different instance of `MyView`
    /// receives a distinct copy of the data model.
    ///
    /// - Parameter thunk: An initial value for the state object.
    @inlinable
    public init(wrappedValue thunk: @autoclosure @escaping () -> ObjectType) {
        storage = .initially(thunk)
    }
    
    /// The underlying value referenced by the state object.
    ///
    /// The wrapped value property provides primary access to the value's data.
    /// However, you don't access `wrappedValue` directly. Instead, use the
    /// property variable created with the `@StateObject` attribute:
    ///
    ///     @StateObject var contact = Contact()
    ///
    ///     var body: some View {
    ///         Text(contact.name) // Accesses contact's wrapped value.
    ///     }
    ///
    /// When you change a property of the wrapped value, you can access the new
    /// value immediately. However, DanceUI updates views displaying the value
    /// asynchronously, so the user interface might not update immediately.
    public var wrappedValue: ObjectType {
        objectValue.wrappedValue
    }
    
    /// A projection of the state object that creates bindings to its
    /// properties.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the projected value, prefix the property variable with `$`. For
    /// example, you can get a binding to a model's `isEnabled` Boolean so that
    /// a ``DanceUI/Toggle`` view can control the value:
    ///
    ///     struct MyView: View {
    ///         @StateObject var model = DataModel()
    ///
    ///         var body: some View {
    ///             Toggle("Enabled", isOn: $model.isEnabled)
    ///         }
    ///     }
    public var projectedValue: ObservedObject<ObjectType>.Wrapper {
        objectValue.projectedValue
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer,
                                        container: _GraphValue<V>,
                                        fieldOffset: Int,
                                        name: String?,
                                        inputs: inout _GraphInputs) {
        var links = _DynamicPropertyBuffer()
        ObservedObject<ObjectType>._makeProperty(in: &links,
                                                 container: container,
                                                 fieldOffset: 0 /* exactly */,
                                                 name: name,
                                                 inputs: &inputs)
        let box = Box(links: links, object: nil)
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
    private struct Box: DynamicPropertyBox {
        
        internal typealias Property = StateObject<ObjectType>
        
        internal var links: _DynamicPropertyBuffer
        
        internal var object: ObservedObject<ObjectType>?
        
        internal mutating func destroy() {
            links.destroy()
        }
        
        internal mutating func reset() {
            links.reset()
            object = nil
        }
        
        internal mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
            let isNewlyCreated: Bool
            
            if object == nil {
                let object: ObservedObject<ObjectType>
                switch property.storage {
                case let .initially(thunk):
                    object = ObservedObject(wrappedValue: thunk())
                case let .object(value):
                    object = value
                }
                self.object = object
                isNewlyCreated = true
            } else {
                isNewlyCreated = false
            }
            
            var object = self.object!
            let wereLinksUpdated = withUnsafeMutablePointer(to: &object) { object in
                links.update(container: object, phase: phase)
            }
            property.storage = .object(object)
            
            return wereLinksUpdated || isNewlyCreated
        }
        
    }
    
    public static var _propertyBehaviors: UInt32 {
        0x2
    }
    
}
