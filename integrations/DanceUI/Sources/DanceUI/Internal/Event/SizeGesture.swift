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
internal struct SizeGesture<A: Gesture>: Gesture {

    internal typealias Value = A.Value
    
    internal typealias Body = Never
    
    internal var content: (CGSize) -> A
    
    internal static func _makeGesture(gesture: _GraphValue<SizeGesture<A>>, inputs: _GestureInputs) -> _GestureOutputs<A.Value> {
        let sizeGestureChild = SizeGestureChild(gesture: gesture.value, size: inputs.size)
        let sizedGesture = Attribute(sizeGestureChild)
        return A._makeGesture(gesture: _GraphValue(sizedGesture), inputs: inputs)
    }

}

@available(iOS 13.0, *)
fileprivate struct SizeGestureChild<Value: Gesture>: Rule {
    
    @Attribute
    fileprivate var gesture: SizeGesture<Value>
    
    @Attribute
    fileprivate var size: ViewSize
    
    fileprivate var value: Value {
        gesture.content(size.value)
    }

}
