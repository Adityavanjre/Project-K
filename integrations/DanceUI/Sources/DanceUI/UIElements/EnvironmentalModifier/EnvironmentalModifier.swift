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

/// A modifier that must resolve to a concrete modifier in an environment before
/// use.
@available(iOS 13.0, *)
public protocol EnvironmentalModifier : ViewModifier where Self.Body == Never {

    /// The type of modifier to use after being resolved.
    associatedtype ResolvedModifier : ViewModifier

    func resolve(in environment: EnvironmentValues) -> Self.ResolvedModifier
}

@available(iOS 13.0, *)
extension EnvironmentalModifier {
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let effectChild = EnvironmentalEffectChild<Self>(modifier: modifier.value, environment: inputs.base.environment)
        
        let attribute = Attribute(effectChild)
        
        let graphValue = _GraphValue<EnvironmentalEffectChild<Self>.Value>(attribute)
        
        let outputs = ResolvedModifier.makeDebuggableViewModifier(value: graphValue, inputs: inputs, body: body)
        
        return outputs
    }
    
    public static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        
        let effectChild = EnvironmentalEffectChild<Self>(modifier: modifier.value, environment: inputs.base.environment)
        
        let attribute = Attribute(effectChild)
        
        let graphValue = _GraphValue<EnvironmentalEffectChild<Self>.Value>(attribute)
        
        var outputs = body(_Graph(), inputs)
        
        outputs.multiModifier(graphValue, inputs: inputs)
        
        return outputs
    }
}

@available(iOS 13.0, *)
private struct EnvironmentalEffectChild<ModifierType: EnvironmentalModifier>: StatefulRule {
    
    fileprivate typealias Value = ModifierType.ResolvedModifier
    
    @Attribute
    fileprivate var modifier: ModifierType
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    fileprivate let tracker: PropertyList.Tracker = .init()
    
    fileprivate mutating func updateValue() {
        
        let (modifierValue, isValueChanged) = _modifier.changedValue()
        
        let (environmentValues, isEnvironmentValueChanged) = _environment.changedValue()
        
        if isValueChanged || (isEnvironmentValueChanged && environmentValues.hasDifferentUsedValues(with: tracker)) || !hasValue {
            let trackedEnvironment = environmentValues.withTracker(tracker)
            let newValue = modifierValue.resolve(in: trackedEnvironment)
            self.value = newValue
        }
    }
}
