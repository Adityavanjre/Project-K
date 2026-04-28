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
internal struct PanGesture: Equatable, Gesture {
    
    internal struct Value: Equatable {

        internal var timestamp: Time

        internal var translation: CGSize

        internal var velocity: _Velocity<CGSize>
        
        @inline(__always)
        internal init() {
            timestamp = .zero
            translation = .zero
            velocity = _Velocity(valuePerSecond: .zero)
        }
        
        @inline(__always)
        internal init(timestamp: Time,
                      translation: CGSize,
                      velocity: _Velocity<CGSize>,
                      location: CGPoint,
                      startLocation: CGPoint) {
            self.timestamp = timestamp
            self.translation = translation
            self.velocity = velocity
        }
    }

    internal var minimumDistance: CGFloat

    internal var allowedDirections: _EventDirections
    
    @inlinable
    internal init(minimumDistance: CGFloat = 10, allowedDirections: _EventDirections = .all) {
        self.minimumDistance = minimumDistance
        self.allowedDirections = allowedDirections
    }

    internal var body: Body {
        RawPanGesture(minimumDistance: minimumDistance,
                      allowedDirections: allowedDirections)
            .dependency(.pausedWhileActive)
    }
    
    internal typealias Body = ModifierGesture<
        DependentGesture<Value>,
        RawPanGesture
    >
    
}

@available(iOS 13.0, *)
internal struct RawPanGesture: Gesture {

    internal typealias Value = PanGesture.Value
    
    internal typealias PanEventBindings = [EventID : PanEvent]

    internal typealias Body = ModifierGesture<
        StateContainerGesture<
            StateType,
            PanEventBindings,
            PanGesture.Value
        >,
        MultiEventListener<PanEvent>
    >

    internal struct StateType: GestureStateProtocol, CustomStringConvertible, Equatable {

        fileprivate struct EventInfo: Equatable {

            fileprivate var globalTranslation: CGSize

            fileprivate var translation: CGSize

        }

        fileprivate var eventInfo: Dictionary<EventID, EventInfo>

        internal var phase: GesturePhase<Void>

        internal var phaseValue: Value

        internal var globalTranslation: CGSize
        
        @inlinable
        internal init() {
            eventInfo = [:]
            phase = .possible(nil)
            phaseValue = Value()
            globalTranslation = .zero
        }
        
        internal var description: String {
            let orderedEventInfo: [(EventID, EventInfo)] = eventInfo.map({$0}).sorted(by: {$0.key.serial < $1.key.serial})
            return """
            <\(Self.self)
                eventInfo = \(orderedEventInfo)
                phase = \(phase)
                phaseValue = \(phaseValue)
                globalTranslation = \(globalTranslation)>
            """
        }
        
        internal static func == (lhs: StateType, rhs: StateType) -> Bool {
            let orderedLhsEventInfo: [(EventID, EventInfo)] = lhs.eventInfo.map({$0}).sorted(by: {$0.key.serial < $1.key.serial})
            let orderedRhsEventInfo: [(EventID, EventInfo)] = rhs.eventInfo.map({$0}).sorted(by: {$0.key.serial < $1.key.serial})
            return orderedLhsEventInfo.elementsEqual(orderedRhsEventInfo) { lhs, rhs -> Bool in
                return lhs.0 == rhs.0 && lhs.1 == rhs.1
            } && lhs.phase === rhs.phase
            && lhs.phaseValue == rhs.phaseValue
            && lhs.globalTranslation == rhs.globalTranslation
        }
    }

    internal var minimumDistance: CGFloat
    
    internal var allowedDirections: _EventDirections
    
    internal var body: Body {
        MultiEventListener()
            .modifier(StateContainerGesture { state, phase in
                var copied = self
                copied.update(state: &state, childPhase: phase)
                return state.phase.withValue(state.phaseValue)
            })
    }
    
    private mutating func update(state: inout StateType, childPhase: GesturePhase<PanEventBindings>) {

        guard let eventBindings = childPhase.unwrapped else {
            state.phase = childPhase.set(Void())
            return
        }

        let minimumDistanceThreshold = minimumDistance
        var hasEnded = false
        var activeEventCount = 0
        var currentTime: Time = .zero
        var totalDeltaTranslation: CGSize = .zero
        var totalDeltaGlobalTranslation: CGSize = .zero

        var currentAvgTranslation = state.phaseValue.translation

        var totalLocation: CGSize = .zero

        for eachBinding in eventBindings {
            let (eventID, panEvent) = eachBinding
            switch panEvent.phase {
            case .active:
                if let oldInfo = state.eventInfo[eventID] {
                    state.eventInfo[eventID] = StateType.EventInfo(globalTranslation: panEvent.globalTranslation,
                                                                   translation: panEvent.translation)
                    totalDeltaTranslation += panEvent.translation - oldInfo.translation
                    totalDeltaGlobalTranslation += panEvent.globalTranslation - oldInfo.globalTranslation
                    totalLocation += panEvent.translation
                    activeEventCount += 1
                    currentTime = max(currentTime, panEvent.timestamp)
                    // DONE
                } else {
                    state.eventInfo[eventID] = StateType.EventInfo(globalTranslation: panEvent.globalTranslation,
                                                                   translation: panEvent.translation)
                    totalLocation += panEvent.translation
                    if case .possible = state.phase {
                        state.phaseValue.timestamp = panEvent.timestamp
                        currentAvgTranslation = .zero
                        if minimumDistanceThreshold == 0 {
                            state.phase = .active(Void())
                        }
                    }
                    // DONE
                }
            case .ended:
                guard state.eventInfo.keys.contains(eventID) else {
                    continue
                }
                state.eventInfo.removeValue(forKey: eventID)
                hasEnded = true
                // DONE
            case .failed:
                state.phase = .failed
                // DONE
            }

        }

        if activeEventCount != 0 {
            let inverseEventCount = 1 / CGFloat(activeEventCount)
            let deltaAvgGlobalTranslation = totalDeltaGlobalTranslation * inverseEventCount
            let nextAvgGlobalTranslation = deltaAvgGlobalTranslation + state.globalTranslation
            state.globalTranslation = nextAvgGlobalTranslation

            if case .possible = state.phase {
                guard allowedDirections != .empty else {
                    state.phase = .failed
                    return
                }

                let translationMagnitude = sqrt(pow(nextAvgGlobalTranslation.width, 2) + pow(nextAvgGlobalTranslation.height, 2))

                if translationMagnitude > minimumDistanceThreshold {
                    if nextAvgGlobalTranslation.withinRange(axes: allowedDirections, rangeCosine: 0.5) {
                        state.phase = .active(Void())
                    } else {
                        state.phase = .failed
                    }
                }
            }

            let timeDelta = currentTime - state.phaseValue.timestamp
            let avgDeltaTranslation = totalDeltaTranslation * inverseEventCount
            if timeDelta > .zero {
                state.phaseValue.timestamp = currentTime
                state.phaseValue.velocity = _Velocity(valuePerSecond: CGFloat(1.0 / timeDelta.seconds) * avgDeltaTranslation)
            }
            state.phaseValue.translation = avgDeltaTranslation + currentAvgTranslation
        }

        if hasEnded {
            if state.eventInfo.isEmpty {
                if currentTime - state.phaseValue.timestamp > Time(seconds: 0.2) {
                    state.phaseValue.timestamp = currentTime
                    state.phaseValue.velocity = _Velocity(valuePerSecond: .zero)
                }
                if case .active = state.phase {
                    state.phase = .ended(Void())
                } else {
                    state.phase = .failed
                }
            }
        }
    }
    
    #if BINARY_COMPATIBLE_TEST
    internal mutating func private_update(state: inout StateType, childPhase: GesturePhase<PanEventBindings>) {
        update(state: &state, childPhase: childPhase)
    }
    #endif
}

@available(iOS 13.0, *)
extension GesturePhase where Event == Void {
    
    fileprivate static func === (lhs: GesturePhase, rhs: GesturePhase) -> Bool {
        switch (lhs, rhs) {
        case (.possible(.some), .possible(.some)):
            return true
        case (.possible(.none), .possible(.none)):
            return true
        case (.active, .active):
            return true
        case (.ended, .ended):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
    
}
