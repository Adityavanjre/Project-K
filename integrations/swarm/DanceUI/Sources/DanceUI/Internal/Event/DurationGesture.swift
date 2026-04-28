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
    
    internal func duration(minimumDuration: Double, maximumDuration: Double) -> ModifierGesture<DurationGesture<Value>, Self> {
        modifier(DurationGesture(minimumDuration: minimumDuration, maximumDuration: maximumDuration))
    }
    
}

@available(iOS 13.0, *)
internal struct DurationGesture<BodyValue>: GestureModifier {
    
    internal typealias Value = Double

    internal var minimumDuration: Double
    
    internal var maximumDuration: Double
    
    internal init(minimumDuration: Double, maximumDuration: Double) {
        assert(minimumDuration <= maximumDuration)
        var minimumDuration = minimumDuration
        if minimumDuration > maximumDuration {
            minimumDuration = maximumDuration
        }

        self.minimumDuration = minimumDuration
        self.maximumDuration = maximumDuration
    }
    
    internal static func _makeGesture(modifier: _GraphValue<DurationGesture<BodyValue>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<Double> {
        
        let outputs = body(inputs)
        
        let phaseValue = DurationPhase<BodyValue>(
            modifier: modifier.value,
            childPhase: outputs.phase,
            time: inputs.time,
            resetSeed: inputs.resetSeed,
            useGestureGraph: inputs.gestureGraph,
            start: nil,
            reset: .init(seed: 0)
        )
        
        let attribute = Attribute(phaseValue)
        
        return outputs.withPhase(attribute)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct DurationPhase<EventType>: ResettableGestureRule {

    fileprivate typealias PhaseValue = Double

    fileprivate typealias Value = GesturePhase<Double>

    @Attribute
    fileprivate var modifier: DurationGesture<EventType>

    @Attribute
    fileprivate var childPhase: GesturePhase<EventType>

    @Attribute
    fileprivate var time: Time

    @Attribute
    fileprivate var resetSeed: UInt32

    fileprivate let useGestureGraph: Bool

    fileprivate var start: Time?

    fileprivate var reset: GestureReset

    fileprivate mutating func updateValue() {
        let isReset = resetIfNeeded(&reset) {
            start = nil
        }

        guard isReset else {
            return
        }

        var duration: Time?
        
        let time = self.time
        let modifier = self.modifier
        let childPhase = self.childPhase
        
        if let startTime = start {
            duration = time - startTime
        } else {
            if childPhase.isActive {
                start = time
                duration = .zero
            } else {
                duration = nil
            }
        }
        
        let nextPhase: GesturePhase<Double>
        defer {
            value = nextPhase
        }
         
        switch childPhase {
        case .possible(_):
            nextPhase = .possible(duration?.seconds)
        case .active(_):
            if modifier.minimumDuration > duration!.seconds {
                nextPhase = .possible(duration?.seconds)
            } else if modifier.maximumDuration > duration!.seconds {
                nextPhase = .active(duration!.seconds)
            } else {
                nextPhase = .failed
                return
            }
        case .ended(_):
            if duration!.seconds < modifier.minimumDuration || duration!.seconds > modifier.maximumDuration {
                nextPhase = .failed
            } else {
                nextPhase = .ended(duration!.seconds)
            }
            return
        case .failed:
            nextPhase = .failed
            return
        }
        // possible || active
        
        if let startTime = start {
            var gesturesUpdateDuration: Time
            if let duration = duration, modifier.minimumDuration > duration.seconds {
                gesturesUpdateDuration = modifier.minimumDuration.toTime()
            } else {
                gesturesUpdateDuration = modifier.maximumDuration.toTime()
            }
            if useGestureGraph {
                GestureGraph.current.scheduleNextGestureUpdate(byTime: startTime + gesturesUpdateDuration)
            } else {
                ViewGraph.current.scheduleNextGestureUpdate(byTime: startTime + gesturesUpdateDuration)
            }
        }
    }
    
}
