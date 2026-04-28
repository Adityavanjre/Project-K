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
internal struct EventListener<Event: EventType>: PrimitiveGesture {
    
    internal typealias Value = Event
    
    internal static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Event> {
        
        let position = inputs.animatedPosition()
        
        let phase = EventListenerPhase<Event>(
            listener: gesture.value,
            events: inputs.events,
            position: position,
            transform: inputs.transform,
            resetSeed: inputs.resetSeed,
            preconvertedEventLocations: inputs.preconvertedEventLocations,
            allowsIncompleteEventSequences: inputs.allowsIncompleteEventSequences,
            trackingID: nil,
            reset: GestureReset())
        
        let gesturePhase = Attribute(phase)
        
        if DanceUIFeature.gestureContainer.isEnable {
            return _GestureOutputs.make(phase: gesturePhase)
        } else {
            return .makeTerminal(from: inputs, with: gesturePhase)
        }
    }
}

@available(iOS 13.0, *)
internal struct EventListenerPhase<PhaseValue: EventType>: ResettableGestureRule {

    internal typealias Value = GesturePhase<PhaseValue>

    @Attribute
    internal var listener: EventListener<PhaseValue>

    @Attribute
    internal var events: EventsDict

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @Attribute
    internal var resetSeed: UInt32

    internal let preconvertedEventLocations: Bool

    internal let allowsIncompleteEventSequences: Bool

    internal var trackingID: EventID?

    internal var reset: GestureReset
    
    internal init(
        listener: Attribute<EventListener<PhaseValue>>,
        events: Attribute<[EventID : EventType]>,
        position: Attribute<ViewOrigin>,
        transform: Attribute<ViewTransform>,
        resetSeed: Attribute<UInt32>,
        preconvertedEventLocations: Bool,
        allowsIncompleteEventSequences: Bool,
        trackingID: EventID?,
        reset: GestureReset)
    {
        self._listener = listener
        self._events = events
        self._position = position
        self._transform = transform
        self._resetSeed = resetSeed
        self.preconvertedEventLocations = preconvertedEventLocations
        self.allowsIncompleteEventSequences = allowsIncompleteEventSequences
        self.trackingID = trackingID
        self.reset = reset
    }
    
    internal mutating func updateValue() {
        var reset = self.reset
        let hasReset = resetIfNeeded(&reset) {
            trackingID = nil
            value = .possible(nil)
        }
        self.reset = reset
        
        guard hasReset else {
            return
        }
        
        if let outputValue = getOutputValue() {
            value = outputValue
        }
        
    }
    
    internal mutating func getOutputValue() -> Value? {

        var matchedEvent: PhaseValue?

        var eventTypeKey: Any.Type?

        for (eventID, event) in self.events {
            eventTypeKey = eventID.type

            if allowsIncompleteEventSequences {
            } else {
                if let binding = event.binding,
                   !binding.isRedirected
                {
                    if !allowsIncompleteEventSequences {
                        if trackingID == eventID {
                        } else {

                            let bindingOrNil = event.binding

                            if bindingOrNil?.isFirstEvent == true {
                            } else {
                                if type(of: event).rebindsEachEvent {
                                } else {
                                    let failedPhase: GesturePhase<PhaseValue> = .failed
                                    return failedPhase
                                }
                            }
                        }
                    } else {
                    }
                } else {
                    if let trackingID = self.trackingID, trackingID != eventID {
                        let failedPhase: GesturePhase<PhaseValue> = .failed
                        return failedPhase
                    } else {
                    }
                }

            }

            if let convertedEvent = PhaseValue(event) {

                if let currentTrackingID = trackingID {

                    if currentTrackingID == eventID {
                        matchedEvent = convertedEvent
                    } else {
                        let failedPhase: GesturePhase<PhaseValue> = .failed
                        return failedPhase
                    }
                } else {
                    self.trackingID = eventID
                    matchedEvent = convertedEvent
                }
            } else {
                if !type(of: event).failsListenersIfUnmatched {
                } else {
                    let failedPhase: GesturePhase<PhaseValue> = .failed
                    return failedPhase
                }
            }

        }

        if let trackedEvent = matchedEvent {

            var processedEvent = trackedEvent

            if self.preconvertedEventLocations {
            } else {
                let viewTransform: ViewTransform = DGGraphRef.withoutUpdate {
                    var currentTransform = self.transform
                    let position = self.position

                    currentTransform.appendViewOrigin(position)

                    return currentTransform
                }

                let trackedID = self.trackingID!

                var events = [trackedID: trackedEvent]

                defaultConvertEventLocations(&events) { (points) in
                    viewTransform.convert(.toGlobal, space: .local, points: &points)
                }

                let searchKey = eventTypeKey.map({EventID(type:$0 , serial: trackedID.serial)})!

                processedEvent = events[searchKey]!

            }

            switch processedEvent.phase {
            case .active:
                return .active(processedEvent)
            case .ended:
                return .ended(processedEvent)
            case .failed:
                return .failed
            }

        } else {

            if !context.hasValue {
                let possiblePhase: GesturePhase<PhaseValue> = .possible(nil)
                return possiblePhase
            } else {
                return nil
            }
        }

    }
    
    internal typealias EventsDict = [EventID : EventType]
    
}

@available(iOS 13.0, *)
internal func defaultConvertEventLocations<Event>(_ events: inout [EventID : Event], converter: (inout [CGPoint]) -> Void) {
    
    var (points, eventIDs) = events.reduce(([CGPoint](), [EventID]())) { (result, keyValuePair) in
        var (points, eventIDs) = result
        let (eventID, event) = keyValuePair
        if let spatialEvent = event as? SpatialEventType {
            eventIDs.append(eventID)
            points.append(spatialEvent.globalLocation)
        }
        return (points, eventIDs)
    }
    
    guard points.count > 0 else {
        return
    }
    
    converter(&points)
    
    for (index, eachEventID) in eventIDs.enumerated() {
        if var event = events[eachEventID] as? SpatialEventType {
            event.location = points[index]
            events[eachEventID] = event as? Event
        }
    }
    
}
