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
internal struct EmptyTupleGesture: PrimitiveGesture {
    
    internal typealias Value = EmptyTuple
    
    internal static func _makeGesture(gesture: _GraphValue<EmptyTupleGesture>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        let phase = EmptyTuplePhase(
            events: inputs.events,
            resetSeed: inputs.resetSeed,
            failed: false,
            reset: GestureReset()
        ).makeAttribute()
        
        if DanceUIFeature.gestureContainer.isEnable {
            return _GestureOutputs.make(phase: phase)
        } else {
            return .makeTerminal(from: inputs, with: phase)
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct EmptyTuplePhase: ResettableGestureRule {
    
    fileprivate typealias PhaseValue = EmptyTuple

    @Attribute
    private var events: [EventID: EventType]

    @Attribute
    fileprivate var resetSeed: UInt32

    private var failed: Bool

    fileprivate var reset: GestureReset
    
    internal init(
        events: Attribute<[EventID: EventType]>,
        resetSeed: Attribute<UInt32>,
        failed: Bool,
        reset: GestureReset
    ) {
        self._events = events
        self._resetSeed = resetSeed
        self.failed = failed
        self.reset = reset
    }
    
    fileprivate mutating func updateValue() {
        @inline(__always)
        func update() {
            if events.count == 0 {
                value = .ended(EmptyTuple())
            } else {
                failed = true
                value = .failed
            }
        }
        
        var reset = reset
        let hadReset = resetIfNeeded(&reset) {
            failed = false
            update()
        }
        self.reset = reset

        guard hadReset else {
            return
        }
        
        guard !failed else {
            value = .failed
            return
        }
        
        update()
    }

}

#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
internal struct Testable_EmptyTuplePhase: Rule {
        
    @Attribute
    internal var value: GesturePhase<EmptyTuple>
    
    internal init(
        events: Attribute<[EventID: EventType]>,
        resetSeed: Attribute<UInt32>,
        failed: Bool,
        reset: GestureReset
    ) {
        self._value = EmptyTuplePhase(
            events: events,
            resetSeed: resetSeed,
            failed: failed,
            reset: reset
        ).makeAttribute()
    }
    
}

#endif
