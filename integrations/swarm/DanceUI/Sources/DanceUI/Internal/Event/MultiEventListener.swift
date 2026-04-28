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
internal struct MultiEventListener<A: EventType>: PrimitiveGesture {

    internal typealias Value = Dictionary<EventID, A>

    internal typealias Body = Never
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Value> {
        @Attribute(MultiEventListenerPhase<A>(
            events: inputs.events,
            position: inputs.animatedPosition(),
            transform: inputs.transform,
            resetSeed: inputs.resetSeed,
            preconvertedEventLocations: inputs.preconvertedEventLocations,
            allowsIncompleteEventSequences: inputs.allowsIncompleteEventSequences))
        var gesturePhase
        
        if DanceUIFeature.gestureContainer.isEnable {
            return _GestureOutputs.make(phase: $gesturePhase)
        } else {
            return .makeTerminal(from: inputs, with: $gesturePhase)
        }
    }

}

@available(iOS 13.0, *)
fileprivate struct MultiEventListenerPhase<A: EventType>: StatefulRule, ResettableGestureRule {

    fileprivate typealias PhaseValue = Dictionary<EventID, A>

    fileprivate typealias Value = GesturePhase<Dictionary<EventID, A>>

    @Attribute
    fileprivate var events: [EventID : EventType]

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var transform: ViewTransform

    @Attribute
    fileprivate var resetSeed: UInt32

    fileprivate let preconvertedEventLocations: Bool

    fileprivate let allowsIncompleteEventSequences: Bool

    fileprivate var latestEvents: [EventID : A] = Dictionary()

    fileprivate var reset: GestureReset = GestureReset()
    
    fileprivate mutating func updateValue() {
        guard resetIfNeeded(&reset) else {
            latestEvents.removeAll()
            value = .possible(nil)
            return
        }
        
        value = getOutputValue()
    }
    
    private mutating func getOutputValue() -> Value {
        for (eventID, event) in self.events {
            if !allowsIncompleteEventSequences {
                if let binding = event.binding,
                   !binding.isRedirected
                {
                    if !allowsIncompleteEventSequences {
                        if !latestEvents.keys.contains(eventID) {
                            let bindingForEvent = event.binding
                            if bindingForEvent?.isFirstEvent != true {
                                if !type(of: event).rebindsEachEvent {
                                    let retVal: GesturePhase<PhaseValue> = .failed
                                    return retVal
                                }
                            }
                        }
                    }
                } else {
                    if !latestEvents.keys.contains(eventID) {
                        let retVal: GesturePhase<PhaseValue> = .failed
                        return retVal
                    }
                }
                
            }
            
            if let phaseValue = A(event) {
                latestEvents[eventID] = phaseValue
            } else {
                if type(of: event).failsListenersIfUnmatched {
                    let retVal: GesturePhase<PhaseValue> = .failed
                    return retVal
                }
            }
            
        }
        
        var convertedLatestEvent = latestEvents
        
        if !self.preconvertedEventLocations {
            let viewTransform: ViewTransform = DGGraphRef.withoutUpdate {
                var transform = self.transform
                let position = self.position
                
                transform.appendViewOrigin(position)
                
                return transform
            }
            
            var events = convertedLatestEvent
            
            defaultConvertEventLocations(&events) { (points) in
                viewTransform.convert(.toGlobal, space: .local, points: &points)
            }
            
            convertedLatestEvent = events
            
        }
        
        let eventPhase = convertedLatestEvent.values.reduce(EventPhase.failed) { partialResult, event in
            if partialResult == .active {
                return .active
            }
            if event.phase == .active {
                return .active
            }
            if partialResult == .ended {
                return .ended
            }
            return event.phase != .ended ? partialResult : .ended
        }
        
        switch eventPhase {
        case .active:
            return .active(convertedLatestEvent)
        case .ended:
            return .ended(convertedLatestEvent)
        case .failed:
            return .failed
        }
    }
    
}
