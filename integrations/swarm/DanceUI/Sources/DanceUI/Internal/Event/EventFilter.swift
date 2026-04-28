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
internal struct EventFilter<Value>: GestureModifier {
        
    internal typealias BodyValue = Value

    internal var predicate: (EventType) -> Bool
    
    internal static func _makeGesture(modifier: _GraphValue<EventFilter<Value>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<Value>) -> _GestureOutputs<Value> {
        
        let filteredEvents = Attribute(
            EventFilterEvents<Value>(modifier: modifier.value, events: inputs.events)
        )
        
        var bodyInputs = inputs
        
        bodyInputs.events = filteredEvents[{.of(&$0.events)}]
        
        let bodyOutputs = body(bodyInputs)
        
        let outputs = Attribute(
            EventFilterPhase(phase: bodyOutputs.phase, filteredEvents: filteredEvents)
        )
        
        return bodyOutputs.withPhase(outputs)
    }
}

@available(iOS 13.0, *)
fileprivate struct EventFilterPhase<EventValue>: Rule {
        
    internal typealias Value = GesturePhase<EventValue>
    
    @Attribute
    internal var phase: GesturePhase<EventValue>

    @Attribute
    internal var filteredEvents: FilteredEvents
    
    fileprivate var value: GesturePhase<EventValue> {
        filteredEvents.failed ? .failed : phase
    }
}

@available(iOS 13.0, *)
fileprivate struct EventFilterEvents<Event>: Rule {
        
    fileprivate typealias Value = FilteredEvents
    
    @Attribute
    fileprivate var modifier: EventFilter<Event>

    @Attribute
    fileprivate var events: [EventID: EventType]
    
    fileprivate var value: FilteredEvents {
        let filteredEvents = events.optimisticFilter { (_, event) in
            return modifier.predicate(event)
        }
        return FilteredEvents(events: filteredEvents, failed: filteredEvents.count != events.count)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct FilteredEvents {
    
    fileprivate var events: [EventID : EventType]

    fileprivate var failed: Bool
    
}
