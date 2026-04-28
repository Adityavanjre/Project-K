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

@available(iOS 13.0, *)
extension Gesture where Self.Value : Equatable {
    
    /// Adds an action to perform when the gesture's value changes.
    ///
    /// - Parameter action: The action to perform when this gesture's value
    ///   changes. The `action` closure's parameter contains the gesture's new
    ///   value.
    ///
    /// - Returns: A gesture that triggers `action` when this gesture's value
    ///   changes.
    public func onChanged(_ action: @escaping (Value) -> Void) -> _ChangedGesture<Self> {
        _ChangedGesture(_body: callbacks(ChangedCallbacks(changed: action)))
    }
    
}

@available(iOS 13.0, *)
public struct _ChangedGesture<Content: Gesture>: Gesture where Content.Value : Equatable {
    
    public typealias Value = Content.Value
    
    public typealias Body = Never
    
    fileprivate var _body: ModifierGesture<
        CallbacksGesture<ChangedCallbacks<Content.Value>>,
        Content
    >
    
    public static func _makeGesture(gesture: _GraphValue<_ChangedGesture<Content>>, inputs: _GestureInputs) -> _GestureOutputs<Content.Value> {
        var childInputs = inputs
        if DanceUIFeature.gestureContainer.isEnable {
            childInputs.options.insert(.hasChangedCallbacks)
        }
        return ModifierGesture._makeGesture(gesture: gesture[{.of(&$0._body)}], inputs: childInputs)
    }
    
}

private struct ChangedCallbacks<Value: Equatable>: GestureCallbacks {
    
    fileprivate let changed: (Value) -> Void
    
    fileprivate init(changed: @escaping (Value) -> Void) {
        self.changed = changed
    }
    
    fileprivate func dispatch(phase: GesturePhase<Value>, state: inout StateType) -> (() -> Void)? {
        guard case let .active(value) = phase, state.oldValue != value else {
            return nil
        }
        state.oldValue = value
        return {
            changed(value)
        }
    }
    
    fileprivate func cancel(state: StateType) -> (() -> Void)? {
        nil
    }
    
    fileprivate struct StateType: GestureStateProtocol {

        fileprivate var oldValue: Value?
        
        fileprivate init() {
            self.oldValue = nil
        }

    }
    
}
