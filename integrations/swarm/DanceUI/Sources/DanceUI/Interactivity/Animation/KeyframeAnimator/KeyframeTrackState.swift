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

import Foundation

@available(iOS 13.0, *)
internal enum KeyframeTrackState<Value, KeyframePath: Keyframes> where KeyframePath.Value == Value {
    
    case eventDriven(EventDrivenState)
    
    case repeating(RepeatingState)
    
    case initial
    
    internal struct EventDrivenState {
        
        internal var trigger: AnyEquatable
        
        private var phase: Phase
        
        private enum Phase {
            
            case idle(Value)
            
            case playing(timeline: KeyframeTimeline<Value>, start: AnimationTime)
            
            
        }
        
        internal init(trigger: AnyEquatable,
                      value: Value) {
            self.trigger = trigger
            self.phase = .idle(value)
        }
        
        internal var isAnimating: Bool {
            switch phase {
            case .idle:
                return false
            case .playing:
                return true
            }
        }
        
        internal func value(time: Double) -> Value {
            switch phase {
            case .idle(let value):
                return value
            case .playing(let timeline, let start):
                var time = time
                switch start {
                case .pending:
                    time = .zero
                case .started(let start):
                    time -= start.seconds
                }
                return timeline.value(time: time)
            }
        }
        
        internal mutating func update(at time: Time,
                                      trigger: AnyEquatable,
                                      initialValue: Value, 
                                      path: (Value) -> KeyframePath) {
            guard self.trigger != trigger else {
                return
            }
            switch phase {
            case .idle(let value):
                let timeline = KeyframeTimeline(initialValue: initialValue) {
                    path(value)
                }
                phase = .playing(timeline: timeline, start: .pending(time))
            case .playing(let timeline, var start):
                var t = (time - start.time).seconds
                t = .minimum(timeline.duration, t)
                let timelineValue = timeline.value(time: t)
                let timelineVelocity = timeline.velocity(time: t)
                let timeline = KeyframeTimeline(initialValue: timelineValue,
                                                initialVelocity: timelineVelocity) {
                    path(timelineValue)
                }
                start.time = time
                phase = .playing(timeline: timeline, start: start)
            }
            self.trigger = trigger
        }
        
        @inline(__always)
        internal mutating func updateAnimation(time: Time) {
            switch phase {
            case .idle:
                return
            case .playing(let timeline, let start):
                var timeValue: Time
                var stopPending = true
                switch start {
                case .pending(let t):
                    timeValue = t
                    if time > timeValue {
                        timeValue = time
                    } else {
                        stopPending = false
                    }
                case .started(let t):
                    timeValue = t
                }
                if !stopPending || (time - timeValue).seconds <= timeline.duration { // continue
                    phase = .playing(timeline: timeline,
                                     start: stopPending ? .started(timeValue) : .pending(timeValue))
                } else { // stop
                    let value = timeline.value(progress: 1.0)
                    phase = .idle(value)
                }
            }
        }
    }
    
    internal struct RepeatingState {
        
        internal var timeline: KeyframeTimeline<Value>
        
        private var mode: Mode
        
        private enum Mode {
            
            case paused(elapsed: Double)
            
            case playing(start: AnimationTime, elapsedOffset: Double)
            
        }
        
        internal var isAnimating: Bool {
            switch mode {
            case .paused:
                return false
            case .playing:
                return true
            }
        }
        
        internal init(timeline: KeyframeTimeline<Value>,
                      time: Time,
                      pause: Bool,
                      elapsedOffset: Double) {
            self.timeline = timeline
            if pause {
                self.mode = .paused(elapsed: 0)
            } else {
                self.mode = .playing(start: .pending(time), 
                                     elapsedOffset: elapsedOffset)
            }
        }
        
        internal func value(time: Double) -> Value {
            let elapsed: Double
            switch mode {
            case .paused(let t):
                elapsed = t
            case .playing(let start, let elapsedOffset):
                elapsed = start.elapsed(time: time, offset: elapsedOffset)
            }
            let duration = timeline.duration
            return timeline.value(time: fmod(elapsed, duration))
        }
        
        internal mutating func update(at time: Time, paused: Bool) {
            switch mode {
            case .paused(let elapsed):
                guard !paused else {
                    return
                }
                mode = .playing(start: .pending(time), elapsedOffset: elapsed)
            case .playing(let start, let elapsedOffset):
                guard paused else {
                    return
                }
                let elapsed = start.elapsed(time: time.seconds, offset: elapsedOffset)
                mode = .paused(elapsed: elapsed)
            }
        }
        
        internal mutating func updateAnimation(time: Time) {
            switch mode {
            case .paused:
                return
            case .playing(let start, let elapsedOffset):
                switch start {
                case .pending(let t):
                    if time > t {
                        mode = .playing(start: .started(time),
                                        elapsedOffset: elapsedOffset)
                    } else {
                        mode = .playing(start: .pending(t),
                                        elapsedOffset: elapsedOffset)
                    }
                case .started(let t):
                    mode = .playing(start: .started(t),
                                    elapsedOffset: elapsedOffset)
                }
            }
        }
    }
    
    internal var isInitial: Bool {
        switch self {
        case .initial:
            return true
        default:
            return false
        }
    }
    
    internal var isAnimating: Bool {
        switch self {
        case .eventDriven(let eventDrivenState):
            return eventDrivenState.isAnimating
        case .repeating(let repeatingState):
            return repeatingState.isAnimating
        case .initial:
            return false
        }
    }
    
    internal mutating func updateAnimation(time: Time) {
        switch self {
        case .eventDriven(var eventDrivenState):
            eventDrivenState.updateAnimation(time: time)
            self = .eventDriven(eventDrivenState)
        case .repeating(var repeatingState):
            repeatingState.updateAnimation(time: time)
            self = .repeating(repeatingState)
        case .initial:
            return
        }
    }
    
    internal mutating func updatePlayBack(_ mode: PlaybackMode, time: Time, initialValue: Value, plan: (Value) -> KeyframePath) {
        switch mode {
        case .onChange(let trigger):
            switch self {
            case .eventDriven(var eventDrivenState):
                eventDrivenState.update(at: time,
                                        trigger: trigger,
                                        initialValue: initialValue, path: plan)
                self = .eventDriven(eventDrivenState)
            case .repeating(let repeatingState):
                let v = repeatingState.value(time: time.seconds)
                let state = KeyframeTrackState<Value, KeyframePath>.EventDrivenState(trigger: trigger,
                                                                                     value: v)
                self = .eventDriven(state)
            case .initial:
                let state = KeyframeTrackState<Value, KeyframePath>.EventDrivenState(trigger: trigger,
                                                                                     value: initialValue)
                self = .eventDriven(state)
            }
        case .repeating(let paused):
            switch self {
            case .eventDriven(let eventDrivenState):
                let stateValue = eventDrivenState.value(time: time.seconds)
                let timeline = KeyframeTimeline(initialValue: stateValue) {
                    plan(stateValue)
                }
                let state = RepeatingState(timeline: timeline,
                                           time: time,
                                           pause: paused,
                                           elapsedOffset: 0)
                self = .repeating(state)
            case .repeating(var repeatingState):
                repeatingState.update(at: time, paused: paused)
                self = .repeating(repeatingState)
            case .initial:
                let timeline = KeyframeTimeline(initialValue: initialValue) {
                    plan(initialValue)
                }
                let state = RepeatingState(timeline: timeline,
                                           time: time,
                                           pause: paused,
                                           elapsedOffset: 0)
                self = .repeating(state)
            }
        }
    }
    
    internal func value(at time: Time, initialValue: Value) -> Value {
        switch self {
        case .eventDriven(let eventDrivenState):
            return eventDrivenState.value(time: time.seconds)
        case .repeating(let repeatingState):
            return repeatingState.value(time: time.seconds)
        case .initial:
            return initialValue
        }
    }
}

@available(iOS 13.0, *)
private enum AnimationTime {
    
    case pending(Time)
    
    case started(Time)
    
    internal var time: Time {
        get {
            switch self {
            case .pending(let time):
                return time
            case .started(let time):
                return time
            }
        }

        mutating set {
            switch self {
            case .pending:
                self = .pending(newValue)
            case .started:
                self = .started(newValue)
            }
        }
    }
    
    @inline(__always)
    internal func elapsed(time: Double, offset: Double) -> Double {
        let elapsed: Double
        switch self {
        case .pending:
            elapsed = 0
        case .started(let t):
            elapsed = time - t.seconds
        }
        return elapsed + offset
    }
    
}
