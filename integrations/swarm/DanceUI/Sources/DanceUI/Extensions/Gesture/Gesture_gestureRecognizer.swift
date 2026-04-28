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
extension Gesture {
    
    @inline(__always)
    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer?) -> ModifierGesture<GestureRecognizerGesture<Value>, Self> {
        modifier(GestureRecognizerGesture<Value>(gestureRecognizer: gestureRecognizer))
    }
    
}

@available(iOS 13.0, *)
internal struct GestureRecognizerGesture<ChildValue>: GestureModifier {
    
    internal typealias BodyValue = ChildValue
    
    internal typealias Value = ChildValue
    
    weak internal var gestureRecognizer: UIGestureRecognizer?
    
    internal static func _makeGesture(
        modifier: _GraphValue<Self>,
        inputs: _GestureInputs,
        body: (_GestureInputs) -> _GestureOutputs<BodyValue>
    ) -> _GestureOutputs<Value> {
        var outputs = body(inputs)
        if inputs.requiresPlatformGestureRecognizerList {
            let gestureRecognizerList = Attribute(PlatformGestureRecognizerListFilter(child: OptionalAttribute(outputs.platformGestureRecognizerList),
                                                                                      modifier: modifier.value))
            outputs = outputs.withPlatformGestureRecognizerList(gestureRecognizerList)
        }
        return outputs
    }
}

@available(iOS 13.0, *)
private struct PlatformGestureRecognizerListFilter<ChildValue>: Rule {
    
    fileprivate typealias Value = PlatformGestureRecognizerList
    
    @OptionalAttribute
    fileprivate var child: PlatformGestureRecognizerList?
    
    @Attribute
    fileprivate var modifier: GestureRecognizerGesture<ChildValue>
    
    @inline(__always)
    fileprivate init(child: OptionalAttribute<PlatformGestureRecognizerList>, modifier: Attribute<GestureRecognizerGesture<ChildValue>>) {
        self._child = child
        self._modifier = modifier
    }
    
    fileprivate var value: Value {
        let child = child ?? PlatformGestureRecognizerList()
        guard let gestureRecognizer = modifier.gestureRecognizer else {
            return child
        }
        let retVal = child.appending(gestureRecognizer, for: [.identifier(ObjectIdentifier(gestureRecognizer))])
        return retVal
    }
    
}
