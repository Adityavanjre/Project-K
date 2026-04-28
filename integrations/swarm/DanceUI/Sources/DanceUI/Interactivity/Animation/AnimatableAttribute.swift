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

@available(iOS 13.0, *)
internal struct AnimatableAttribute<Source: Animatable>: StatefulRule, ObservedAttribute {
    
    internal typealias Value = Source
    
    @Attribute
    internal var source: Source
    
    @Attribute
    internal var environment: EnvironmentValues
    
    internal var helper: AnimatableAttributeHelper<Source>
    
    internal init(source: Attribute<Source>,
                  phase: Attribute<_GraphInputs.Phase>,
                  time: Attribute<Time>,
                  transaction: Attribute<Transaction>,
                  environment: Attribute<EnvironmentValues>) {
        _source = source
        _environment = environment
        helper = AnimatableAttributeHelper(phase: phase, time: time, transaction: transaction)
    }
    
    internal mutating func updateValue() {
        var interpolatedSource = $source.changedValue()
        helper.update(value: &interpolatedSource, environment: _environment)
        
        guard interpolatedSource.changed || !hasValue else {
            return
        }
        
        value = interpolatedSource.value
    }
    
    internal mutating func destroy() {
        helper.removeListeners()
    }
    
}
