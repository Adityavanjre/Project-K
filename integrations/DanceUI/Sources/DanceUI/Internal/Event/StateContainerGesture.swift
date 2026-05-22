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
    internal func _updating<State: GestureStateProtocol, StatedEvent>(state: State.Type, body: @escaping (inout State, GesturePhase<Value>) -> GesturePhase<StatedEvent>) -> ModifierGesture<StateContainerGesture<State, Value, StatedEvent>, Self> {
        modifier(StateContainerGesture(body: body))
    }
    
}

@available(iOS 13.0, *)
internal struct StateContainerGesture<State: GestureStateProtocol, ChildEvent, StateEvent>: GestureModifier {
    
    internal typealias Value = StateEvent
    
    internal typealias BodyValue = ChildEvent

    internal var body: (inout State, GesturePhase<ChildEvent>) -> GesturePhase<StateEvent>
    
    internal static func _makeGesture(modifier: _GraphValue<StateContainerGesture<State, ChildEvent, StateEvent>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<ChildEvent>) -> _GestureOutputs<StateEvent> {
        let childOutputs = body(inputs)
        @Attribute(StateContainerPhase(modifier: modifier.value,
                                       childPhase: childOutputs.phase,
                                       resetSeed: inputs.resetSeed,
                                       state: State(),
                                       reset: GestureReset()))
        var phase
        return childOutputs.withPhase($phase)
    }

}

@available(iOS 13.0, *)
fileprivate struct StateContainerPhase<State: GestureStateProtocol, StateEvent, ChildEvent>: ResettableGestureRule {
    
    fileprivate typealias Value = GesturePhase<PhaseValue>
    
    fileprivate typealias PhaseValue = StateEvent
    
    @Attribute
    fileprivate var modifier: StateContainerGesture<State, ChildEvent, StateEvent>

    @Attribute
    fileprivate var childPhase: GesturePhase<ChildEvent>

    @Attribute
    fileprivate var resetSeed: UInt32
    
    fileprivate var state: State

    fileprivate var reset: GestureReset
    
    internal mutating func updateValue() {
        guard resetIfNeeded(&reset, {
            state = State()
        }) else {
            return
        }
        
        value = modifier.body(&state, childPhase)
    }
    
}
