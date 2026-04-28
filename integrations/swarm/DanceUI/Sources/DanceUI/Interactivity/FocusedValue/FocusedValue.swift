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
internal import DanceUIRuntime

/// A property wrapper for observing values from the focused view or one of its
/// ancestors.
///
/// If multiple views publish values using the same key, the wrapped property
///  will reflect the value from the view closest to focus.
@propertyWrapper
@available(iOS 13.0, *)
public struct FocusedValue<Value> : DynamicProperty {

    @usableFromInline
    @frozen
    internal enum Content {
        
        case keyPath(KeyPath<FocusedValues, Value?>)
        
        case value(Value?)
        
    }
    
    @usableFromInline
    internal var content: Content
    
    /// A new property wrapper for the given key path.
    ///
    /// The value of the property wrapper is updated dynamically as focus
    /// changes and different published values go in and out of scope.
    ///
    /// - Parameter keyPath: The key path for the focus value to read.
    public init(_ keyPath: KeyPath<FocusedValues, Value?>) {
        content = .keyPath(keyPath)
    }

    /// The value for the focus key given the current scope and state of the
    /// focused view hierarchy.
    ///
    /// Returns `nil` when nothing in the focused view hierarchy exports a
    /// value.
    @inlinable
    public var wrappedValue: Value? {
        if case .value(let value) = content {
            return value
        } else {
            return nil
        }
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        let box = FocusedValueBox<Value>(environment: inputs.environment, focusedValues: inputs.focusedValues)
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
}


/// A convenience property wrapper for observing and automatically unwrapping
/// state bindings from the focused view or one of its ancestors.
///
/// If multiple views publish bindings using the same key, the wrapped property
/// will reflect the value of the binding from the view closest to focus.
@propertyWrapper
@available(iOS 13.0, *)
public struct FocusedBinding<Value> : DynamicProperty {
    
    @usableFromInline
    @frozen
    internal enum Content {
        
        case keyPath(KeyPath<FocusedValues, Binding<Value>?>)
        
        case value(Binding<Value>?)
        
    }
    
    @usableFromInline
    internal var content: FocusedBinding<Value>.Content
    
    /// A new property wrapper for the given key path.
    ///
    /// The value of the property wrapper is updated dynamically as focus
    /// changes and different published bindings go in and out of scope.
    ///
    /// - Parameter keyPath: The key path for the focus value to read.
    public init(_ keyPath: KeyPath<FocusedValues, Binding<Value>?>) {
        self.content = .keyPath(keyPath)
    }
    
    /// The unwrapped value for the focus key given the current scope and state
    /// of the focused view hierarchy.
    @inlinable
    public var wrappedValue: Value? {
        get {
            if case .value(let value) = content {
                return value?.wrappedValue
            } else {
                return nil
            }
        }
        nonmutating set {
            if case .value(let value) = content, let newValue = newValue {
                value?.wrappedValue = newValue
            }
        }
    }
    
    /// A binding to the optional value.
    ///
    /// The unwrapped value is `nil` when no focused view hierarchy has
    /// published a corresponding binding.
    public var projectedValue: Binding<Value?> {
        switch content {
        case .value(let .some(value)):
            return Binding(value)
        default:
            return Binding.constant(nil)
        }
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        let box = FocusedValueBox<Binding<Value>>(environment: inputs.environment, focusedValues: inputs.focusedValues)
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct FocusedValueBox<Value>: DynamicPropertyBox {
    
    fileprivate typealias Property = FocusedValue<Value>
    
    @Attribute
    fileprivate var environment: EnvironmentValues

    @OptionalAttribute
    fileprivate var focusedValues: FocusedValues?

    fileprivate var keyPath: KeyPath<FocusedValues, Value?>?

    fileprivate var value: Value?
    
    fileprivate init(environment: Attribute<EnvironmentValues>, focusedValues: OptionalAttribute<FocusedValues>) {
        _environment = environment
        _focusedValues = focusedValues
    }
    
    fileprivate mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
        guard case .keyPath(let keyPath) = property.content else {
            return false
        }
        
        let (focusedValues, isFocusedValuesChanged) = $focusedValues?.changedValue() ?? (FocusedValues(), false)
        
        let (_, isEnvironmentChanged) = $environment.changedValue()
        
        let needsUpdateKeyPath = self.keyPath != keyPath
        
        if needsUpdateKeyPath {
            self.keyPath = keyPath
        }
        
        let isUpdated: Bool
        
        if needsUpdateKeyPath || isEnvironmentChanged || isFocusedValuesChanged {
            let focusedValue: Value? = focusedValues[keyPath: keyPath]
            if focusedValue == nil || !DGCompareValues(lhs: value, rhs: focusedValue) {
                value = focusedValue
                property.content = .value(focusedValue)
                isUpdated = true
            } else {
                isUpdated = false
            }
        } else {
            isUpdated = false
        }
        
        property.content = .value(value)
        
        return isUpdated
    }
    
    fileprivate func destroy() {
        
    }
    
    fileprivate func reset() {
        
    }
    
}

@available(iOS 13.0, *)


internal struct FocusedValueScope: Equatable, Identifiable {

    internal let id: ViewIdentity
    
    internal let name: String
    
    internal static let scene = FocusedValueScope(id: .make(), name: "Scene")
    
    internal static let view = FocusedValueScope(id: .make(), name: "View")

}

@available(iOS 13.0, *)
internal struct FocusedValueList {

    internal var items: [Item]
    
    @inlinable
    internal init() {
        items = []
    }
    
    @inlinable
    internal init(item: Item) {
        items = [item]
    }
    
    @inlinable
    internal init(items: [Item]) {
        self.items = items
    }
    
    @inlinable
    internal mutating func append(contentsOf another: FocusedValueList) {
        self.items.append(contentsOf: another.items)
    }
    
    @inlinable
    internal func forEach(_ body: (Item) -> Void) {
        items.forEach(body)
    }
    
    @inlinable
    internal var version: DisplayList.Version {
        items.reduce(.zero) { partialResult, item in
            max(partialResult, item.version)
        }
    }

    internal struct Key: HostPreferenceKey {
        
        internal typealias Value = FocusedValueList
        
        internal static var defaultValue: Value {
            FocusedValueList()
        }
        
        internal static func reduce(value: inout FocusedValueList, nextValue: () -> FocusedValueList) {
            value.append(contentsOf: nextValue())
        }
        
    }
    
    internal struct Item {
        
        internal var version: DisplayList.Version
        
        internal var isFocused: Bool
        
        internal var update: (inout FocusedValues) -> Void
        
        @inlinable
        internal init(isFocused: Bool, update: @escaping (inout FocusedValues) -> Void) {
            self.version = .make()
            self.isFocused = isFocused
            self.update = update
        }
        
    }

}
