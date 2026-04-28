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
internal protocol GestureCallbacks {
    
    associatedtype StateType
    
    associatedtype Value
    
    static var initialState: StateType { get }
    
    func dispatch(phase: GesturePhase<Value>, state: inout StateType) -> (() -> Void)?
    
    func cancel(state: StateType) -> (() -> Void)?
    
}

@available(iOS 13.0, *)
extension GestureCallbacks where StateType: GestureStateProtocol {
    
    internal static var initialState: StateType {
        StateType()
    }
    
}

@available(iOS 13.0, *)
internal struct CallbacksGesture<Callbacks: GestureCallbacks>: GestureModifier {
    
    internal typealias Value = Callbacks.Value

    internal typealias BodyValue = Callbacks.Value

    internal var callbacks: Callbacks
    
    internal static func _makeGesture(modifier: _GraphValue<CallbacksGesture<Callbacks>>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<Callbacks.Value>) -> _GestureOutputs<Callbacks.Value> {
        
        var childInputs = inputs
        
        let childOutputs = body(childInputs)
        
        let phase = Attribute(
            CallbacksPhase(
                modifier: modifier.value,
                phase: childOutputs.phase,
                resetSeed: inputs.resetSeed,
                usesGestureGraph: inputs.gestureGraph,
                state: Callbacks.initialState,
                cancel: nil,
                reset: GestureReset(),
                includeDebugOutput: inputs.includeDebugOutput
            )
        )
        
        phase.setFlags([.active, .removable], mask: .reserved)
        return childOutputs.withPhase(phase)
    }

}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func callbacks<CallBacks: GestureCallbacks>(_ callbacks: CallBacks) -> ModifierGesture<CallbacksGesture<CallBacks>, Self> where Self.Value == CallBacks.Value {
        modifier(CallbacksGesture(callbacks: callbacks))
    }
    
}

@available(iOS 13.0, *)
fileprivate struct CallbacksPhase<Callbacks: GestureCallbacks>: RemovableAttribute, ResettableGestureRule {

    fileprivate typealias PhaseValue = Callbacks.Value

    @Attribute
    fileprivate var modifier: CallbacksGesture<Callbacks>

    @Attribute
    fileprivate var phase: GesturePhase<Callbacks.Value>

    @Attribute
    fileprivate var resetSeed: UInt32

    fileprivate var usesGestureGraph: Bool

    fileprivate var state: Callbacks.StateType

    /// Provides an opportunity that to notify the client code that the
    /// gesture is trigerred but is still not recognized.
    fileprivate var cancel: ((Callbacks.StateType) -> (() -> Void)?)?

    fileprivate var reset: GestureReset
    
    fileprivate let includeDebugOutput: Bool
    
    fileprivate mutating func updateValue() {
        let hasReset = resetIfNeeded(&reset) {
            if let cancel = cancel, let action = cancel(state) {
                Update.enqueueAction {
                    action()
                }
            }
            state = Callbacks.initialState
            cancel = nil
        }
        guard hasReset else {
            return
        }
        
        let (phase, changed) = $phase.changedValue()
        if changed {
            let modifierValue = modifier
            if let action = modifierValue.callbacks.dispatch(phase: phase, state: &state) {
                enqueueAction(action)
            }
            
            // GesturePhase<Callbacks.Value>
            value = phase
            
            if !phase.isTerminal {
                cancel = modifierValue.callbacks.cancel
            } else {
                cancel = nil
            }
            
        } else {
            if context.hasValue {
                let value = self.value
                self.value = value
            }
        }
    }
    
    fileprivate static func willRemove(attribute: DGAttribute) {
        let instancePtr = attribute.info.body.assumingMemoryBound(to: CallbacksPhase.self)
        guard let cancel = instancePtr.pointee.cancel else {
            return
        }
        
        guard let action = cancel(instancePtr.pointee.state) else {
            return
        }
        
        Update.enqueueAction(action)
    }
    
    fileprivate static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    fileprivate func enqueueAction(_ action: @escaping () -> Void) {
        if usesGestureGraph {
            GestureGraph.current.enqueueAction(action)
        } else {
            Update.enqueueAction(action)
        }
    }
    
}
