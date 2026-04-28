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
extension Gesture {
    
    /// Adds an action to perform when the gesture ends.
    ///
    /// - Parameter action: The action to perform when this gesture ends. The
    ///   `action` closure's parameter contains the final value of the gesture.
    ///
    /// - Returns: A gesture that triggers `action` when the gesture ends.
    public func onEnded(_ action: @escaping (Self.Value) -> Void) -> _EndedGesture<Self> {
        _EndedGesture(_body: callbacks(EndedCallbacks(ended: action)))
    }
    
}

@available(iOS 13.0, *)
public struct _EndedGesture<Content: Gesture>: Gesture {
    
    public typealias Value = Content.Value
    
    public typealias Body = Never
    
    fileprivate var _body: ModifierGesture<CallbacksGesture<EndedCallbacks<Content.Value>>, Content>

    public static func _makeGesture(gesture: _GraphValue<_EndedGesture<Content>>, inputs: _GestureInputs) -> _GestureOutputs<Content.Value> {
        ModifierGesture._makeGesture(gesture: gesture[{.of(&$0._body)}], inputs: inputs)
    }

}

@available(iOS 13.0, *)
private struct EndedCallbacks<Value>: GestureCallbacks {

    internal let ended: (Value) -> ()

    internal static var initialState: Void { () }
    
    internal func dispatch(phase: GesturePhase<Value>, state: inout Void) -> (() -> ())? {
        guard case let .ended(value) = phase else {
            return nil
        }
        return {
            ended(value)
        }
    }
    
    internal func cancel(state: Void) -> (() -> ())? {
        nil
    }
    
    internal typealias StateType = Void

}
