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
    
    /// Returns a gesture that's the result of mapping the given closure over
    /// the gesture.
    public func map<T>(_ body: @escaping (Self.Value) -> T) -> _MapGesture<Self, T> {
        _MapGesture(_body: modifier(MapGesture { phase in
            phase.map(body)
        }))
    }
    
    internal func mapPhase<T>(_ body: @escaping (GesturePhase<Self.Value>) -> GesturePhase<T>) -> ModifierGesture<MapGesture<Self.Value, T>, Self> {
        modifier(MapGesture(body: body))
    }
    
}

@available(iOS 13.0, *)
public struct _MapGesture<Content: Gesture, Value>: Gesture {
    
    public typealias Body = Never
    
    internal var _body: ModifierGesture<MapGesture<Content.Value, Value>, Content>
    
    public static func _makeGesture(gesture: _GraphValue<_MapGesture<Content, Value>>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        if DanceUIFeature.gestureContainer.isEnable {
            return ModifierGesture.makeDebuggableGesture(gesture: gesture[{.of(&$0._body)}], inputs: inputs)
        } else {
            return ModifierGesture._makeGesture(gesture: gesture[{.of(&$0._body)}], inputs: inputs)
        }
    }
    
}

@available(iOS 13.0, *)
internal struct MapGesture<FromValue, ToValue>: GestureModifier {
    
    internal typealias Value = ToValue
    
    internal typealias BodyValue = FromValue
    
    internal var body: (GesturePhase<FromValue>) -> GesturePhase<ToValue>
    
    @inlinable
    internal init(body: @escaping (GesturePhase<FromValue>) -> GesturePhase<ToValue>) {
        self.body = body
    }
    
    internal static func _makeGesture(modifier: _GraphValue<MapGesture<FromValue, ToValue>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<FromValue>) -> _GestureOutputs<ToValue> {
        let outputs = body(inputs)
        
        @Attribute(MapPhase(modifier: modifier.value,
                            phase: outputs.phase,
                            resetSeed: inputs.resetSeed,
                            reset: GestureReset()))
        var mapPhase;
        
        return outputs.withPhase($mapPhase)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct MapPhase<FromValue, ToValue>: ResettableGestureRule {

    fileprivate typealias PhaseValue = ToValue

    fileprivate typealias Value = GesturePhase<PhaseValue>

    @Attribute
    fileprivate var modifier: MapGesture<FromValue, ToValue>

    @Attribute
    fileprivate var phase: GesturePhase<FromValue>

    @Attribute
    fileprivate var resetSeed: UInt32

    fileprivate var reset: GestureReset

    fileprivate mutating func updateValue() {
        if resetIfNeeded(&reset) {
            value = modifier.body(phase)
        }
    }
    
}
