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

/// A visual element that can be used to separate other content.
///
/// When contained in a stack, the divider extends across the minor axis of the
/// stack, or horizontally when not in a stack.
@available(iOS 13.0, *)
public struct Divider: PrimitiveView, UnaryView {
    
    public init() {
        
    }
    
    internal struct Child: Rule {
        
        internal typealias Value = ResolvedDivider
        
        internal let orientation: Axis
        
        internal var value: Value {
            ResolvedDivider(orientation: orientation)
        }
    }
    
    public static func _makeView(view: _GraphValue<Divider>, inputs: _ViewInputs) -> _ViewOutputs {

//        if inputs.preferences.requiresPlatformItemList {
//        }


        let axis = inputs.majorAxis.minor
        
        let attribute = Attribute(Child(orientation: axis))
        
        let graphValue = _GraphValue(attribute)
        
        let outputs = Child.Value.makeDebuggableView(value: graphValue, inputs: inputs)
//        if inputs.preferences.requiresPlatformItemList {
//        }
        
        return outputs
    }
}
