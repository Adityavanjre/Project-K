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
    
    @inlinable
    public func observed(by action: @escaping (_ phase: ObservedGesturePhase<Value>) -> Void) -> _ObservedGesture<Self> {
        _ObservedGesture(base: self, action: action)
    }
    
}

@frozen
@available(iOS 13.0, *)
public struct _ObservedGesture<Base: Gesture>: Gesture {
    
    public typealias Value = Base.Value
    
    public typealias Body = Never
    
    public var base: Base
    
    public var action: (_ phase: ObservedGesturePhase<Value>) -> Void
    
    @inlinable
    public init(base: Base, action: @escaping (_ phase: ObservedGesturePhase<Value>) -> Void) {
        self.base = base
        self.action = action
    }
    
    public static func _makeGesture(gesture: _GraphValue<Self>, inputs: _GestureInputs) -> _GestureOutputs<Self.Value> {
        let baseInputs = inputs
        
        let outputs = Base._makeGesture(gesture: gesture[{.of(&$0.base)}], inputs: baseInputs)
        
        let phase = GestureObservingPhase(gesture: gesture.value,
                                          phase: outputs.phase,
                                          resetSeed: inputs.resetSeed)
        
        let wrappedPhase = Attribute(phase)
        wrappedPhase.setFlags([.active, .removable], mask: .reserved)
        
        return outputs.withPhase(wrappedPhase)
    }
    
}

@available(iOS 13.0, *)
private struct GestureObservingPhase<Base: Gesture>: ResettableGestureRule, RemovableAttribute {
    
    fileprivate typealias PhaseValue = Base.Value
        
    fileprivate typealias Value = GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var gesture: _ObservedGesture<Base>
    
    @Attribute
    fileprivate var phase: GesturePhase<PhaseValue>
    
    @Attribute
    fileprivate var resetSeed: UInt32
    
    fileprivate var reset: GestureReset
    
    fileprivate var resetCallback: ((PhaseValue?) -> Void)? = nil
    
    fileprivate init(gesture: Attribute<_ObservedGesture<Base>>,
                     phase: Attribute<GesturePhase<PhaseValue>>,
                     resetSeed: Attribute<UInt32>,
                     reset: GestureReset = GestureReset(),
                     resetCallback: ((PhaseValue?) -> Void)? = nil) {
        self._gesture = gesture
        self._phase = phase
        self._resetSeed = resetSeed
        self.reset = reset
        self.resetCallback = resetCallback
    }
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        let pointer = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        pointer.pointee.resetObserver(nil)
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        
    }
    
    fileprivate mutating func updateValue() {
        
        var reset = self.reset
        
        let hasReset = resetIfNeeded(&reset) {
            resetObserver(nil)
        }
        self.reset = reset
        
        guard hasReset else {
            return
        }
        
        switch phase {
        case .possible(let value):
            let gesture = DGGraphRef.withoutUpdate { self.gesture }
            
            let action = gesture.action
            
            resetCallback = { phaseValue in
                action(phaseValue.map({.ended($0)}) ?? .failed)
            }
            
            Update.enqueueAction {
                action(.possible(value))
            }
        case .active(let value):
            let gesture = DGGraphRef.withoutUpdate { self.gesture }
            
            let action = gesture.action
            
            resetCallback = { phaseValue in
                action(phaseValue.map({.ended($0)}) ?? .failed)
            }
            
            Update.enqueueAction {
                action(.active(value))
            }
        case .ended(let value):
            resetObserver(value)
        case .failed:
            resetObserver(nil)
        }
        
        value = phase
    }
    
    fileprivate mutating func resetObserver(_ phaseValue: PhaseValue?) {
        guard let callback = resetCallback else {
            return
        }
        
        Update.enqueueAction {
            callback(phaseValue)
        }
        
        self.resetCallback = nil
    }
    
}
