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
internal protocol GestureModifier {
    
    associatedtype Value

    associatedtype BodyValue
    
    static func _makeGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<Value>
    
}

@available(iOS 13.0, *)
extension GestureModifier {
    
    internal static func makeDebuggableGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<Value> {
        guard DanceUIFeature.gestureContainer.isEnable else {
            return Self._makeGesture(modifier: modifier, inputs: inputs, body: body)
        }

        var gestureOutputs = Self._makeGesture(modifier: modifier, inputs: inputs, body: body)
        
        gestureOutputs.wrapDebugOutputs(Self.self, properties: nil, inputs: inputs)
        
        return gestureOutputs
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func modifier<Modifier: GestureModifier>(_ modifier: Modifier) -> ModifierGesture<Modifier, Self> where Value == Modifier.BodyValue {
        ModifierGesture(content: self, modifier: modifier)
    }
    
}
