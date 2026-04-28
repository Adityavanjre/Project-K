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
import UIKit


/// A property wrapper type that can read and write a value that DanceUI updates
/// as the placement of focus within the scene changes.
///
/// Use this property wrapper in conjunction with ``View/focused(_:equals:)``
/// and ``View/focused(_:)`` to
/// describe views whose appearance and contents relate to the location of
/// focus in the scene. When focus enters the modified view, the wrapped value
/// of this property updates to match a given prototype value. Similarly, when
/// focus leaves, the wrapped value of this property resets to `nil`
/// or `false`. Setting the property's value programmatically has the reverse
/// effect, causing focus to move to the view associated with the
/// updated value.
///
/// In the following example of a simple login screen, when the user presses the
/// Sign In button and one of the fields is still empty, focus moves to that
/// field. Otherwise, the sign-in process proceeds.
///
///     struct LoginForm {
///         enum Field: Hashable {
///             case username
///             case password
///         }
///
///         @State private var username = ""
///         @State private var password = ""
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             Form {
///                 TextField("Username", text: $username)
///                     .focused($focusedField, equals: .username)
///
///                 SecureField("Password", text: $password)
///                     .focused($focusedField, equals: .password)
///
///                 Button("Sign In") {
///                     if username.isEmpty {
///                         focusedField = .username
///                     } else if password.isEmpty {
///                         focusedField = .password
///                     } else {
///                         handleLogin(username, password)
///                     }
///                 }
///             }
///         }
///     }
///
/// To allow for cases where focus is completely absent from a view tree, the
/// wrapped value must be either an optional or a Boolean. Set the focus binding
/// to `false` or `nil` as appropriate to remove focus from all bound fields.
/// You can also use this to remove focus from a ``TextField`` and thereby
/// dismiss the keyboard.
///
/// ### Avoid Ambiguous Focus Bindings
///
/// The same view can have multiple focus bindings. In the following example,
/// setting `focusedField` to either `name` or `fullName` causes the field
/// to receive focus:
///
///     struct ContentView: View {
///         enum Field: Hashable {
///             case name
///             case fullName
///         }
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             TextField("Full Name", ...)
///                 .focused($focusedField, equals: .name)
///                 .focused($focusedField, equals: .fullName)
///         }
///     }
///
/// On the other hand, binding the same value to two views is ambiguous. In
/// the following example, two separate fields bind focus to the `name` value:
///
///     struct ContentView: View {
///         enum Field: Hashable {
///             case name
///             case fullName
///         }
///         @FocusState private var focusedField: Field?
///
///         var body: some View {
///             TextField("Name", ...)
///                 .focused($focusedField, equals: .name)
///             TextField("Full Name", ...)
///                 .focused($focusedField, equals: .name) // incorrect re-use of .name
///         }
///     }
///
/// If the user moves focus to either field, the `focusedField` binding updates
/// to `name`. However, if the app programmatically sets the value to `name`,
/// DanceUI chooses the first candidate, which in this case is the "Name"
/// field. DanceUI also emits a runtime warning in this case, since the repeated
/// binding is likely a programmer error.
///
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct FocusState<Value: Hashable> : DynamicProperty {

    /// A property wrapper type that can read and write a value that indicates
    /// the current focus location.
    @frozen
    @propertyWrapper
    public struct Binding {
        
        @DanceUI.Binding
        private var binding: Value
        
        internal var propertyID: ObjectIdentifier {
            guard let loc = $binding.location as? FocusStoreLocation<Value> else {
                return ObjectIdentifier(unsafeBitCast(0, to: AnyObject.self))
            }
            
            return ObjectIdentifier(loc)
        }
        
        @inline(__always)
        internal init(binding: DanceUI.Binding<Value>) {
            _binding = binding
        }
        
        /// The underlying value referenced by the bound property.
        public var wrappedValue: Value {
            get {
                binding
            }
            nonmutating set {
                binding = newValue
            }
        }
        
        /// A projection of the binding value that returns a binding.
        ///
        /// Use the projected value to pass a binding value down a view
        /// hierarchy.
        public var projectedValue: Binding {
            self
        }
        
        @inline(__always)
        internal func makeWeak() -> WeakBinding {
            WeakBinding(binding: $binding.makeWeak())
        }
    }

    internal var value: Value

    internal var location: AnyLocation<Value>?

    internal var resetValue: Value
    
    /// The current state value, taking into account whatever bindings might be
    /// in effect due to the current location of focus.
    ///
    /// When focus is not in any view that is bound to this state, the wrapped
    /// value will be `nil` (for optional-typed state) or `false` (for `Bool`-
    /// typed state).
    public var wrappedValue: Value {
        get {
            getValue(forReading: true)
        }
        nonmutating set {
            guard let location = location else {
                return
            }
            
            location.set(newValue, transaction: Transaction())
        }
    }

    /// A projection of the focus state value that returns a binding.
    ///
    /// When focus is outside any view that is bound to this state, the wrapped
    /// value is `nil` for optional-typed state or `false` for Boolean state.
    ///
    /// In the following example of a simple navigation sidebar, when the user
    /// presses the Filter Sidebar Contents button, focus moves to the sidebar's
    /// filter text field. Conversely, if the user moves focus to the sidebar's
    /// filter manually, then the value of `isFiltering` automatically
    /// becomes `true`, and the sidebar view updates.
    ///
    ///     struct Sidebar: View {
    ///         @State private var filterText = ""
    ///         @FocusState private var isFiltering: Bool
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Button("Filter Sidebar Contents") {
    ///                     isFiltering = true
    ///                 }
    ///
    ///                 TextField("Filter", text: $filterText)
    ///                     .focused($isFiltering)
    ///             }
    ///         }
    ///     }
    public var projectedValue: Binding {
        let value = getValue(forReading: false)
        
        if let location = location {
            return Binding(binding: DanceUI.Binding(value: value, location: location, transaction: Transaction()))
        } else {
            // runtime issue.
            logger.debug("Accessing FocusState's value outside of the body of a View. This will result in a constant Binding of the initial value and will not update.")
            return Binding(binding: DanceUI.Binding.constant(value))
        }
    }
    
    private func getValue(forReading isReading: Bool) -> Value {
        guard let location = location else {
            return value
        }
        
        if GraphHost.isUpdating {
            if isReading {
                location.wasRead = true
            }
            return value
        } else {
            return location.get()
        }
    }

    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(Box(store: inputs.focusStore,
                          focusedItem: inputs.focusedItem.attribute!,
                          location: nil),
                      fieldOffset: fieldOffset)
    }
    
    /// Creates a focus state that binds to a Boolean.
    public init() where Value == Bool {
        value = false
        location = nil
        resetValue = false
    }

    /// Creates a focus state that binds to an optional type.
    public init<T: Hashable>() where Value == T? {
        value = nil
        location = nil
        resetValue = nil
    }
    
    internal struct Box: DynamicPropertyBox {

        internal typealias Property = FocusState<Value>

        @OptionalAttribute
        internal var store: FocusStore?

        @Attribute
        internal var focusedItem: FocusItem?

        internal var location: FocusStoreLocation<Value>?
        
        internal mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
            let focusStoreLocation: FocusStoreLocation<Value>
            
            let wasNoLocation = location == nil
            
            if wasNoLocation {
                if let location = property.location as? FocusStoreLocation<Value> {
                    focusStoreLocation = location
                } else {
                    focusStoreLocation = FocusStoreLocation(host: GraphHost.currentHost, resetValue: property.resetValue)
                }
                
                location = focusStoreLocation
            }
            
            let newStore = store ?? FocusStore()
            
            location!.store = newStore
            
            let focusedItem = focusedItem
            
            location!.focusSeed = focusedItem?.seed ?? .zero
            
            let (value, isUpdated) = location!.update()
            
            property.value = value
            property.location = location!
            
            weak var loc = self.location
            
            if store != nil {
                loc?.retryFailedAssignmentIfNecessary()
            }
            
            return isUpdated ? location!.wasRead || wasNoLocation : wasNoLocation
        }
        
        internal mutating func reset() {
            location = nil
        }
        
    }
}

@available(iOS 13.0, *)
extension View {

    /// Modifies this view by binding its focus state to the given state value.
    ///
    /// Use this modifier to cause the view to receive focus whenever the
    /// the `binding` equals the `value`. Typically, you create an enumeration
    /// of fields that may receive focus, bind an instance of this enumeration,
    /// and assign its cases to focusable views.
    ///
    /// The following example uses the cases of a `LoginForm` enumeration to
    /// bind the focus state of two ``TextField`` views. A sign-in button
    /// validates the fields and sets the bound `focusedField` value to
    /// any field that requires the user to correct a problem.
    ///
    ///     struct LoginForm {
    ///         enum Field: Hashable {
    ///             case usernameField
    ///             case passwordField
    ///         }
    ///
    ///         @State private var username = ""
    ///         @State private var password = ""
    ///         @FocusState private var focusedField: Field?
    ///
    ///         var body: some View {
    ///             Form {
    ///                 TextField("Username", text: $username)
    ///                     .focused($focusedField, equals: .usernameField)
    ///
    ///                 SecureField("Password", text: $password)
    ///                     .focused($focusedField, equals: .passwordField)
    ///
    ///                 Button("Sign In") {
    ///                     if username.isEmpty {
    ///                         focusedField = .usernameField
    ///                     } else if password.isEmpty {
    ///                         focusedField = .passwordField
    ///                     } else {
    ///                         handleLogin(username, password)
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus using a Boolean, use the ``View/focused(_:)`` method
    /// instead.
    ///
    /// - Parameters:
    ///   - binding: The state binding to register. When focus moves to the
    ///     modified view, the binding sets the bound value to the corresponding
    ///     match value. If a caller sets the state value programmatically to the
    ///     matching value, then focus moves to the modified view. When focus
    ///     leaves the modified view, the binding sets the bound value to
    ///     `nil`. If a caller sets the value to `nil`, DanceUI automatically
    ///     dismisses focus.
    ///   - value: The value to match against when determining whether the
    ///     binding should change.
    /// - Returns: The modified view.
    public func focused<Value>(_ binding: FocusState<Value>.Binding, equals value: Value) -> some View where Value : Hashable {
        self.modifier(FocusBindingModifier(binding: binding, prototype: value))
    }


    /// Modifies this view by binding its focus state to the given Boolean state
    /// value.
    ///
    /// Use this modifier to cause the view to receive focus whenever the
    /// the `condition` value is `true`. You can use this modifier to
    /// observe the focus state of a single view, or programmatically set and
    /// remove focus from the view.
    ///
    /// In the following example, a single ``TextField`` accepts a user's
    /// desired `username`. The text field binds its focus state to the
    /// Boolean value `usernameFieldIsFocused`. A "Submit" button's action
    /// verifies whether the name is available. If the name is unavailable, the
    /// button sets `usernameFieldIsFocused` to `true`, which causes focus to
    /// return to the text field, so the user can enter a different name.
    ///
    ///     @State private var username: String = ""
    ///     @FocusState private var usernameFieldIsFocused: Bool
    ///     @State private var showUsernameTaken = false
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField("Choose a username.", text: $username)
    ///                 .focused($usernameFieldIsFocused)
    ///             if showUsernameTaken {
    ///                 Text("That username is taken. Please choose another.")
    ///             }
    ///             Button("Submit") {
    ///                 showUsernameTaken = false
    ///                 if !isUserNameAvailable(username: username) {
    ///                     usernameFieldIsFocused = true
    ///                     showUsernameTaken = true
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus by matching a value, use the
    /// ``View/focused(_:equals:)`` method instead.
    ///
    /// - Parameter condition: The focus state to bind. When focus moves
    ///   to the view, the binding sets the bound value to `true`. If a caller
    ///   sets the value to  `true` programmatically, then focus moves to the
    ///   modified view. When focus leaves the modified view, the binding
    ///   sets the value to `false`. If a caller sets the value to `false`,
    ///   DanceUI automatically dismisses focus.
    ///
    /// - Returns: The modified view.
    public func focused(_ condition: FocusState<Bool>.Binding) -> some View {
        focused(condition, equals: true)
    }

}

@available(iOS 13.0, *)
fileprivate struct FocusBindingModifier<Value: Hashable>: ViewModifier {
    
    @FocusState.Binding
    fileprivate var binding: Value

    fileprivate var prototype: Value
    
    fileprivate init(binding: FocusState<Value>.Binding, prototype: Value) {
        self._binding = binding
        self.prototype = prototype
    }
    
    fileprivate func body(content: Content) -> some View {
        content.modifier(ResponderViewModifier<FocusStoreListModifier<Value>> { responder in
            FocusStoreListModifier(binding: _binding, prototype: prototype, responder: responder)
        })
    }
    
}

@available(iOS 13.0, *)
extension FocusState {

    /// A pure stored data that holds a weak binding and maintains the
    /// encapsulation of `FocusState.Binding`.
    internal struct WeakBinding {
        
        internal let binding: DanceUI.WeakBinding<Value>
        
        @inlinable
        internal func makeStrong() -> Binding? {
            guard let binding = binding.makeStrong() else {
                return nil
            }
            return Binding(binding: binding)
        }
        
    }
    
}
