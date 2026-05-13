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

@available(iOS 13.0, *)
internal struct EnvironmentBox<ValueType>: DynamicPropertyBox {
    
    internal typealias Property = Environment<ValueType>
    
    @Attribute
    internal var environment: EnvironmentValues

    internal var keyPath: KeyPath<EnvironmentValues, ValueType>?

    internal var value: ValueType?
    
    internal var hadObservation : Bool
    
    internal init(environment: Attribute<EnvironmentValues>) {
        self._environment = environment
        self.keyPath = nil
        self.value = nil
        self.hadObservation = false
    }
    
    internal mutating func update(property: inout Environment<ValueType>, phase: _GraphInputs.Phase) -> Bool {
        let (environment, isEnvironmentChanged) = $environment.changedValue()
        
        guard case let .keyPath(keyPath) = property.content else {
            return false
        }
        
        let isKeyPathChanged = keyPath != self.keyPath
        
        if isKeyPathChanged {
            self.keyPath = keyPath
        }
        
        var isValueChanged: Bool = false
        
        if isKeyPathChanged || isEnvironmentChanged || hadObservation {
            let (newValue, accessList) = _withObservation {
                environment[keyPath: keyPath]
            }
            
            hadObservation = accessList != nil
            
            if let oldValue = self.value {
                if !DGCompareValues(lhs: oldValue, rhs: newValue) {
                    self.value = newValue
                    isValueChanged = true
                }
            } else {
                self.value = newValue
                isValueChanged = true
            }
        }
        
        guard let value = self.value else {
            _danceuiPreconditionFailure("No Environment Value")
        }
        
        property.content = .value(value)
        
        return isValueChanged
    }
    
}
