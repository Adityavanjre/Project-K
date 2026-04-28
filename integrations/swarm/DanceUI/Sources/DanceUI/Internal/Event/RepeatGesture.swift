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
internal struct RepeatGesture<Value>: GestureModifier {
    
    internal typealias BodyValue = Value
    
    internal var count: Int

    internal var maximumDelay: Double
    
    internal static func _makeGesture(modifier: _GraphValue<RepeatGesture<Value>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<Value>) -> _GestureOutputs<Value> {
        
        let delta = Attribute(value: UInt32())
                
        let seed = Attribute(
            RepeatResetSeed(resetSeed: inputs.resetSeed, delta: delta)
        )
        
        var newInputs = inputs
        newInputs.resetSeed = seed
        
        var outputs = body(newInputs)
        
        let phase = Attribute(
            RepeatPhase(
                modifier: modifier.value,
                phase: outputs.phase,
                time: inputs.time,
                resetSeed: inputs.resetSeed,
                resetDelta: delta,
                deadline: nil,
                index: 0,
                reset: GestureReset()
            )
        )
        
        if DanceUIFeature.gestureContainer.isEnable {
            outputs.preferences[RequiredTapCountKey.self] = RequireTapCount(modifier: modifier.value).makeAttribute()
        }
        
        return outputs.withPhase(phase)
    }

}

private struct RequireTapCount<Event>: Rule {
    
    @Attribute
    fileprivate var modifier: RepeatGesture<Event>
    
    fileprivate var value: Int? {
        modifier.count
    }
    
}

@available(iOS 13.0, *)
private struct RepeatPhase<Event>: ResettableGestureRule {

    internal typealias PhaseValue = Event

    @Attribute
    internal var modifier: RepeatGesture<Event>

    @Attribute
    internal var phase: GesturePhase<Event>

    @Attribute
    internal var time: Time

    @Attribute
    internal var resetSeed: UInt32

    @Attribute
    internal var resetDelta: UInt32

    internal var deadline: Time?

    internal var index: UInt32

    internal var reset: GestureReset
    
    internal mutating func updateValue() {
        let hasReset = resetIfNeeded(&reset) {
            deadline = nil
            index = 0
        }
        guard hasReset else {
            return
        }
        
        let overDeadLine = deadline.map {
            time > $0
        }
        
        guard overDeadLine != true else {
            value = .failed
            return
        }
        
        let phaseValue = self.phase
        switch phaseValue {
        case .possible:
            value = phaseValue
        case .active(let value):
            deadline = nil
            if index == modifier.count - 1 {
                self.value = phaseValue
            } else {
                self.value = .possible(value)
            }
        case .ended(let value):
            index &+= 1
            
            let modifier = self.modifier
            let count = modifier.count
            if index == count {
                deadline = nil
                self.value = phaseValue
            } else {
                deadline = time.advanced(by: modifier.maximumDelay)
                self.value = .possible(value)
                let index = self.index
                let resetDelta = WeakAttribute(_resetDelta)
                GraphHost.currentHost.continueTransaction {
                    _ = resetDelta.attribute?.setValue(index)
                }
            }
        case .failed:
            value = phaseValue
        }
        
        if let deadline = deadline {
            if DanceUIFeature.gestureContainer.isEnable {
                GestureGraph.current.scheduleNextGestureUpdate(byTime: deadline)
            } else {
                ViewGraph.current.scheduleNextGestureUpdate(byTime: deadline)
            }
        }
        
    }

}

@available(iOS 13.0, *)
fileprivate struct RepeatResetSeed: Rule {
    
    fileprivate typealias Value = UInt32

    @Attribute
    fileprivate var resetSeed: UInt32

    @Attribute
    fileprivate var delta: UInt32
    
    fileprivate var value: UInt32 {
        resetSeed &+ delta
    }
    
}
