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

/// A property wrapper that reads a value from a view's environment.
///
/// Use the `Environment` property wrapper to read a value
/// stored in a view's environment. Indicate the value to read using an
/// ``EnvironmentValues`` key path in the property declaration. For example, you
/// can create a property that reads the color scheme of the current
/// view using the key path of the ``EnvironmentValues/colorScheme``
/// property:
///
///     @Environment(\.colorScheme) var colorScheme: ColorScheme
///
/// You can condition a view's content on the associated value, which
/// you read from the declared property's ``wrappedValue``. As with any property
/// wrapper, you access the wrapped value by directly referring to the property:
///
///     if colorScheme == .dark { // Checks the wrapped value.
///         DarkContent()
///     } else {
///         LightContent()
///     }
///
/// If the value changes, DanceUI updates any parts of your view that depend on
/// the value. For example, that might happen in the above example if the user
/// changes the Appearance settings.
///
/// You can use this property wrapper to read --- but not set --- an environment
/// value. DanceUI updates some environment values automatically based on system
/// settings and provides reasonable defaults for others. You can override some
/// of these, as well as set custom environment values that you define,
/// using the ``View/environment(_:_:)`` view modifier.
///
/// For the complete list of environment values provided by DanceUI, see the
/// properties of the ``EnvironmentValues`` structure. For information about
/// creating custom environment values, see the ``EnvironmentKey`` protocol.
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct Environment<Value>: DynamicProperty {
    
    @frozen
    @usableFromInline
    internal enum Content {
        
        case keyPath(KeyPath<EnvironmentValues, Value>)
        
        case value(Value)
        
    }
    
    @usableFromInline
    internal var content: Content
    
    /// The current value of the environment property.
    ///
    /// The wrapped value property provides primary access to the value's data.
    /// However, you don't access `wrappedValue` directly. Instead, you read the
    /// property variable created with the ``Environment`` property wrapper:
    ///
    ///     @Environment(\.colorScheme) var colorScheme: ColorScheme
    ///
    ///     var body: some View {
    ///         if colorScheme == .dark {
    ///             DarkContent()
    ///         } else {
    ///             LightContent()
    ///         }
    ///     }
    ///
    @inlinable
    public var wrappedValue: Value {
        // swift-format-ignore: UseLetInEveryBoundCaseVariable
        switch content {
        case let .value(value):
            return value
        case let .keyPath(keyPath):
            // not bound to a view, return the default value.
            return EnvironmentValues()[keyPath: keyPath]
        }
    }
    
    /// Creates an environment property to read the specified key path.
    ///
    /// Don’t call this initializer directly. Instead, declare a property
    /// with the ``Environment`` property wrapper, and provide the key path of
    /// the environment value that the property should reflect:
    ///
    ///     struct MyView: View {
    ///         @Environment(\.colorScheme) var colorScheme: ColorScheme
    ///
    ///         // ...
    ///     }
    ///
    /// DanceUI automatically updates any parts of `MyView` that depend on
    /// the property when the associated environment value changes.
    /// You can't modify the environment value using a property like this.
    /// Instead, use the ``View/environment(_:_:)`` view modifier on a view to
    /// set a value for a view hierarchy.
    ///
    /// - Parameter keyPath: A key path to a specific resulting value.
    @inlinable
    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.content = .keyPath(keyPath)
    }
    
    @usableFromInline
    internal func error() -> Never {
        _danceuiFatalError("Reading Environment<\(Value.self)>")
    }
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<Container>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(EnvironmentBox<Value>(environment: inputs.environment),
                      fieldOffset: fieldOffset)
    }
    
}
