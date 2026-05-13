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

import Foundation
internal import DanceUIGraph
internal import DanceUIRuntime
@_spi(DanceUI) import DanceUIObservation

@frozen
@available(iOS 13.0, *)
public struct _EnvironmentKeyTransformModifier<Value>: _GraphInputsModifier, PrimitiveViewModifier {
    
    public typealias Body = Never

    public var keyPath: WritableKeyPath<EnvironmentValues, Value>

    public var transform: (inout Value) -> ()
    
    public static func _makeInputs(modifier: _GraphValue<_EnvironmentKeyTransformModifier<Value>>, inputs: inout _GraphInputs) {
        @Attribute(ChildEnvironment(modifier: modifier.value, environment: inputs.environment))
        var childEnvironment: EnvironmentValues

        $childEnvironment.flags = .removable

        let cachedEnvironment = CachedEnvironment($childEnvironment)
        inputs.updateCachedEnvironment(MutableBox(cachedEnvironment))
    }

    @inlinable
    public init(keyPath: WritableKeyPath<EnvironmentValues, Value>, transform: @escaping (inout Value) -> Void) {
        self.keyPath = keyPath
        self.transform = transform
    }
}

@available(iOS 13.0, *)
private struct ChildEnvironment<Value>: StatefulRule, ObservationAttribute {
    
    internal typealias Value = EnvironmentValues


    @Attribute
    internal var modifier: _EnvironmentKeyTransformModifier<Value>


    @Attribute
    internal var environment: EnvironmentValues


    internal var oldValue: Value? = nil

    internal var oldKeyPath: WritableKeyPath<EnvironmentValues, Value>? = nil
    

    internal var previousObservationTrackings: [ObservationTracking]?
    

    internal var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    internal static var initialValue: EnvironmentValues? {
        nil
    }

    internal mutating func updateValue() {
        var (environmentValue, environmentChanged) = $environment.changedValue()

        let (modifier, isModifierChanged) = self.$modifier.changedValue()

        let keyPath = modifier.keyPath
        var result = environmentValue[keyPath: keyPath]
        withObservation(shouldCancelPrevious: isModifierChanged) {
            modifier.transform(&result)
        }
        
        guard !environmentChanged else {
            return _updateValue(environment: &environmentValue, value: result, keyPath: keyPath)
        }
        
        let valueEqual = self.oldValue.map { DGCompareValues(lhs: result, rhs: $0, options: .pod) }
        guard let equal = valueEqual, !equal else {
            return _updateValue(environment: &environmentValue, value: result, keyPath: keyPath)
        }
        
        let keyPathEqual = self.oldKeyPath.map { $0 == keyPath }
        guard let keyPathEqual = keyPathEqual, !keyPathEqual, self.hasValue else {
            return _updateValue(environment: &environmentValue, value: result, keyPath: keyPath)
        }
    }
    
    @inline(__always)
    private mutating func _updateValue(environment: inout EnvironmentValues,
                                       value: Value,
                                       keyPath: WritableKeyPath<EnvironmentValues, Value>) {
        environment[keyPath: keyPath] = value
        self.value = environment
        self.oldValue = value
        self.oldKeyPath = keyPath
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Transforms the environment value of the specified key path with the
    /// given function.
    @inlinable
    public func transformEnvironment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>,
                                        transform: @escaping (inout V) -> Void) -> some View {
        return modifier(_EnvironmentKeyTransformModifier(keyPath: keyPath,
                                                         transform: transform))
    }
    
    /// Adds a condition that controls whether users can interact with this
    /// view.
    ///
    /// The higher views in a view hierarchy can override the value you set on
    /// this view. In the following example, the button isn't interactive
    /// because the outer `disabled(_:)` modifier overrides the inner one:
    ///
    ///     HStack {
    ///         Button(Text("Press")) {}
    ///         .disabled(false)
    ///     }
    ///     .disabled(true)
    ///
    /// - Parameter disabled: A Boolean value that determines whether users can
    ///   interact with this view.
    ///
    /// - Returns: A view that controls whether users can interact with this
    ///   view.
    @inlinable
    public func disabled(_ disabled: Bool) -> some View {
        transformEnvironment(\.isEnabled) {
            $0 = ($0 && !disabled)
        }
    }
    
}
