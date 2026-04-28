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
internal struct HitTestInsetsGesture<A: Gesture>: Gesture {

    internal typealias Value = A.Value
    
    internal typealias Body = Never
    
    internal var content: (EdgeInsets?) -> A
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<A.Value> {
        @Attribute(HitTestInsetsGestureChild(gesture: gesture.value, hitTestInsets: inputs.hitTestInsets))
        var child
        return A._makeGesture(gesture: _GraphValue($child), inputs: inputs)
    }

}

// $b16ffc
@available(iOS 13.0, *)
private struct HitTestInsetsGestureChild<Value: Gesture>: Rule {
    
    @Attribute
    fileprivate var gesture: HitTestInsetsGesture<Value>
    
    @OptionalAttribute
    fileprivate var hitTestInsets: EdgeInsets??
    
    internal init(gesture: Attribute<HitTestInsetsGesture<Value>>, hitTestInsets: Attribute<EdgeInsets?>?) {
        self._gesture = gesture
        self._hitTestInsets = OptionalAttribute(hitTestInsets)
    }
    
    fileprivate var value: Value {
        gesture.content(hitTestInsets ?? nil)
    }

}
