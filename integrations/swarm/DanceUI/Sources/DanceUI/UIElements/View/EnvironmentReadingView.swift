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

@available(iOS 13.0, *)
internal protocol EnvironmentalView: UnaryView, PrimitiveView {
    
    associatedtype EnvironmentBody: View
    
    func body(environment: EnvironmentValues) -> EnvironmentBody
}

@available(iOS 13.0, *)
extension EnvironmentalView {
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let value = _GraphValue(EnvironmentReadingChild(view: view.value, env: inputs.environment))
        
        let outputs = EnvironmentBody.makeDebuggableView(value: value, inputs: inputs)
        return outputs
    }
    
}
