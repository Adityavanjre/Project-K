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
internal struct TupleGesture<Head: Gesture, Tail: Gesture>: PrimitiveGesture {
    
    internal typealias Value = Tuple<Head.Value, Tail.Value>

    internal var head: Head

    internal var tail: Tail
    
    internal static func _makeGesture(gesture: _GraphValue<TupleGesture<Head, Tail>>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        let tupleEvents = TupleEvents(
            events: inputs.events,
            resetSeed: inputs.resetSeed,
            trackingID: nil,
            reset: GestureReset()
        ).makeAttribute()
        
        let head = gesture[ { .of(&$0.head) } ]
        var headInputs = inputs
        headInputs.events = tupleEvents[ {.of(&$0.head) }]
        let headOutput = Head._makeGesture(gesture: head, inputs: headInputs)
        
        let tail = gesture[ { .of(&$0.tail) } ]
        var tailInputs = inputs
        tailInputs.events = tupleEvents[ {.of(&$0.tail) }]
        let tailOutput = Tail._makeGesture(gesture: tail, inputs: tailInputs)
        
        let phase = TuplePhase(head: headOutput.phase, tail: tailOutput.phase).makeAttribute()
        
        if DanceUIFeature.gestureContainer.isEnable {
            var base = _GestureOutputs(phase: phase, preferences: PreferencesOutputs())
            
            var visitor = PairwisePreferenceCombinerVisitor_FeatureGestureContainer(outputs: (headOutput.preferences, tailOutput.preferences), result: PreferencesOutputs())
            for key in inputs.preferences.keys {
                key.visitKey(&visitor)
            }
            
            base.preferences = visitor.result
            
            return base
        } else {
            return .makeMerged(phase: phase, inputs: inputs, outputs1: headOutput, outputs2: tailOutput)
        }
    }

}

@available(iOS 13.0, *)
fileprivate struct TupleEvents: ResettableGestureRule {
    
    fileprivate typealias PhaseValue = Void
    
    @Attribute
    private var events: [EventID: EventType]

    @Attribute
    fileprivate var resetSeed: UInt32

    private var trackingID: EventID?

    fileprivate var reset: GestureReset
    
    fileprivate init(events: Attribute<[EventID: EventType]>, resetSeed: Attribute<UInt32>, trackingID: EventID? = nil, reset: GestureReset) {
        self._events = events
        self._resetSeed = resetSeed
        self.trackingID = trackingID
        self.reset = reset
    }
    
    fileprivate mutating func updateValue() {
        let resetSeed = resetSeed
        if resetSeed != reset.seed {
            reset.seed = resetSeed
            trackingID = nil
        }
        
        let events = events
        var result = Value(head: [:], tail: [:])
        
        for event in events {
            if trackingID == nil {
                trackingID = event.key
            }
            if trackingID == event.key {
                result.head[event.key] = event.value
            } else {
                result.tail[event.key] = event.value
            }
        }

        value = result
    }
    
    
    fileprivate struct Value {

        fileprivate var head: [EventID: EventType]

        fileprivate var tail: [EventID: EventType]

    }

}

@available(iOS 13.0, *)
fileprivate struct TuplePhase<Head, Tail>: Rule {
    
    fileprivate typealias Value = GesturePhase<Tuple<Head, Tail>>

    @Attribute
    private var head: GesturePhase<Head>

    @Attribute
    private var tail: GesturePhase<Tail>
    
    fileprivate init(head: Attribute<GesturePhase<Head>>, tail: Attribute<GesturePhase<Tail>>) {
        self._head = head
        self._tail = tail
    }
    
    fileprivate var value: Value {
        let head = head
        let tail = tail
        
        if Tail.self != EmptyTuple.self {
            if case .possible = head, case .ended = tail {
                return .failed
            }
            
            if case .ended = head, case .possible = tail {
                return .failed
            }
        }
        return head.and(tail) { headValue, tailValue in
            Tuple(head: headValue, tail: tailValue)
        }
    }

}


#if BINARY_COMPATIBLE_TEST || DEBUG
@available(iOS 13.0, *)
internal struct Testable_TupleEvents: Rule {
    
    internal typealias Value = Testable_Value
    
    @Attribute
    private var box: TupleEvents.Value
    
    internal init(events: Attribute<[EventID: EventType]>, resetSeed: Attribute<UInt32>, trackingID: EventID? = nil, reset: GestureReset) {
        self._box = TupleEvents(
            events: events,
            resetSeed: resetSeed,
            trackingID: trackingID,
            reset: reset
        ).makeAttribute()
    }
    
    internal var value: Testable_Value {
        Testable_Value(head: box.head, tail: box.tail)
    }

    
    internal struct Testable_Value {

        internal var head: [EventID: EventType]

        internal var tail: [EventID: EventType]

    }

}

@available(iOS 13.0, *)
internal struct Testable_TuplePhase<Head, Tail>: Rule {
    
    @Attribute
    internal var value: GesturePhase<Tuple<Head, Tail>>
    
    internal init(head: Attribute<GesturePhase<Head>>, tail: Attribute<GesturePhase<Tail>>) {
        self._value = TuplePhase(head: head, tail: tail).makeAttribute()
    }
    
}

#endif
