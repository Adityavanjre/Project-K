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

@frozen
@available(iOS 13.0, *)
public struct _EnvironmentKeyWritingModifier<Value>: PrimitiveViewModifier, _GraphInputsModifier {
    
    public var keyPath: WritableKeyPath<EnvironmentValues, Value>
    
    public var value: Value
    
    public typealias Content = Void
    
    public typealias Body = Never
    
    @inlinable
    public init(keyPath: WritableKeyPath<EnvironmentValues, Value>, value: Value) {
        self.keyPath = keyPath
        self.value = value
    }
    
    public static func _makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs) {
        let childEnvironment = Attribute(ChildEnvironment<Value>(modifier: modifier.value, env: inputs.environment))
#if DEBUG || DANCE_UI_INHOUSE
        childEnvironment.addRole(.environmental)
#endif
        inputs.updateCachedEnvironment(MutableBox(CachedEnvironment(childEnvironment)))
    }
    
}

@available(iOS 13.0, *)
private struct ChildEnvironment<Value>: StatefulRule {
    
    internal typealias Value = EnvironmentValues
    
    @Attribute
    internal var modifier: _EnvironmentKeyWritingModifier<Value>
    
    @Attribute
    internal var env: EnvironmentValues
    
    internal var oldModifier: _EnvironmentKeyWritingModifier<Value>?
    
    internal mutating func updateValue() {
        let env = $env.changedValue(options: DGInputOptions())
        let modifier = $modifier.changedValue(options: DGInputOptions())
        if !env.changed, modifier.changed {
            let notEqual: Bool? = oldModifier.map { (oldValue) -> Bool in
                if oldValue.keyPath == modifier.value.keyPath {
                    return !DGCompareValues(lhs: oldValue.value, rhs: modifier.value.value)
                } else {
                    return true
                }
            }
            guard notEqual == true || !context.hasValue else {
                return
            }
        }
        var environmentValues: EnvironmentValues = env.value
        environmentValues[keyPath: modifier.value.keyPath] = modifier.value.value
        self.value = environmentValues
        oldModifier = modifier.value
    }
}
