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
    
    /// Sequences a gesture with another one to create a new gesture, which
    /// results in the second gesture only receiving events after the first
    /// gesture succeeds.
    ///
    /// - Parameter other: A gesture you want to combine with another gesture to
    ///   create a new, sequenced gesture.
    ///
    /// - Returns: A gesture that's a sequence of two gestures.
    @inlinable
    public func sequenced<Other: Gesture>(before other: Other) -> SequenceGesture<Self, Other> {
        SequenceGesture(self, other)
    }
    
}


/// A gesture that's a sequence of two gestures.
///
/// Read <doc:Composing-DanceUI-gestures> to learn how you can create a sequence
/// of two gestures.
@frozen
@available(iOS 13.0, *)
public struct SequenceGesture<First: Gesture, Second: Gesture>: Gesture {
    
    /// The first gesture in a sequence of two gestures.
    public var first: First
    
    /// The second gesture in a sequence of two gestures.
    public var second: Second
    
    /// Creates a sequence gesture with two gestures.
    ///
    /// - Parameters:
    ///   - first: The first gesture of the sequence.
    ///   - second: The second gesture of the sequence.
    @inlinable
    public init(_ first: First, _ second: Second) {
        (self.first, self.second) = (first, second)
    }
    
    public static func _makeGesture(gesture: _GraphValue<SequenceGesture<First, Second>>, inputs: _GestureInputs) -> _GestureOutputs<SequenceGesture<First, Second>.Value> {
        .makeBinaryFiltered(
                style: .sequenced,
                parent: gesture,
                inputs: inputs) { gesture, inputs in
                    let outputs = First._makeGesture(gesture: gesture[{.of(&$0.first)}], inputs: inputs)
                    let sequenceEvents = Attribute(SequenceEvents(events: inputs.events, phase: outputs.phase))
                    inputs.events = sequenceEvents
                    inputs.allowsIncompleteEventSequences = true
                    return outputs
                } makeOutputs2: { gesture, inputs in
                    Second._makeGesture(gesture: gesture[{.of(&$0.second)}], inputs: inputs)
                } makePhase: { outputs1, outputs2, inputs, _, _ in
                    Attribute(SequencePhase<First, Second>(
                        phase0: outputs1.phase,
                        phase1: outputs2.phase,
                        resetSeed: inputs.resetSeed,
                        reset: GestureReset()
                    ))
                }
    }
    
    /// The value of a sequence gesture that helps to detect whether the first
    /// gesture succeeded, so the second gesture can start.
    @frozen
    public enum Value {
        
        /// The first gesture hasn't ended.
        case first(First.Value)
        
        /// The first gesture has ended.
        case second(First.Value, Second.Value?)
    }
    
    public typealias Body = Never
    
}

@available(iOS 13.0, *)
internal struct SequenceEvents<PhaseValue>: Rule {
    
    internal typealias Value = [EventID: EventType]
        
    @Attribute
    internal var events: [EventID: EventType]
    
    @Attribute
    internal var phase: GesturePhase<PhaseValue>
    
    internal var value: [EventID : EventType] {
        if case .ended = phase {
            return events
        } else {
            return [:]
        }
    }
}

@available(iOS 13.0, *)
internal struct SequencePhase<First: Gesture, Second: Gesture>: ResettableGestureRule {
    
    internal typealias PhaseValue = SequenceGesture<First, Second>.Value
    
    internal typealias Value = GesturePhase<SequenceGesture<First, Second>.Value>
        
    @Attribute
    internal var phase0: GesturePhase<First.Value>
    
    @Attribute
    internal var phase1: GesturePhase<Second.Value>
    
    @Attribute
    internal var resetSeed: UInt32
    
    internal var reset: GestureReset
    
    internal mutating func updateValue() {
        let resetIfNeed = resetIfNeeded(&reset)
        
        guard resetIfNeed else {
            return
        }
        
        let phase: GesturePhase<SequenceGesture<First, Second>.Value>
        switch phase0 {
        case .possible(let value):
            phase = .possible(value.map { .first($0) })
        case .active(let value):
            phase = .active(.first(value))
        case .ended(let firstValue):
            // First Gesture End, Second Gesture Begin
            switch phase1 {
            case .possible(let secondValue):
                if DanceUIFeature.gestureContainer.isEnable {
                    phase = .active(.second(firstValue, secondValue))
                } else {
                    phase = .possible(secondValue.map { .second(firstValue, $0) })
                }
            case .active(let secondValue):
                phase = .active(.second(firstValue, secondValue))
            case .ended(let secondValue):
                phase = .ended(.second(firstValue, secondValue))
            case .failed:
                phase = .failed
            }
        case .failed:
            phase = .failed
        }
        
        value = phase
    }
    
}

@available(iOS 13.0, *)
extension SequenceGesture.Value: Equatable where First.Value: Equatable, Second.Value: Equatable {
    
}
