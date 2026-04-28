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
extension Gesture where Value: PressableEventValue {
    
    @inline(__always)
    internal func pressable(pressing: ((Bool) -> Void)?, pressed: (() -> Void)?) -> ModifierGesture<CallbacksGesture<PressableGestureCallbacks<Value>>, Self> {
        self.callbacks(PressableGestureCallbacks(pressing: pressing, pressed: pressed))
    }
    
}

@available(iOS 13.0, *)
internal struct PressableGestureCallbacks<Value: PressableEventValue>: GestureCallbacks {
    
    internal let pressing: ((Bool) -> Void)?
    
    internal var pressed: (() -> Void)?
    
    @inline(__always)
    fileprivate init(pressing: ((Bool) -> Void)?, pressed: (() -> Void)?) {
        self.pressing = pressing
        self.pressed = pressed
    }
    
    internal static var initialState: Bool {
        false
    }
    
    internal func dispatch(phase: GesturePhase<Value>, state: inout Bool) -> (() -> Void)? {
        let originalState = state

        switch phase {
        case .possible, .active:
            let isPressing = Value.isPressing(phase)
            state = isPressing
            guard isPressing != originalState, let pressing = pressing else {
                return nil
            }
            
            return {
                pressing(isPressing)
            }
        case .ended:
            state = false
            guard let pressing = pressing, originalState else {
                return pressed
            }
            
            guard let pressed = pressed else {
                return {
                    pressing(false)
                }
            }
            return {
                pressing(false)
                pressed()
            }
        case .failed:
            state = false
            guard originalState, let pressing = pressing else {
                return nil
            }
            
            return {
                pressing(false)
            }
        }
    }
    
    internal func cancel(state: Bool) -> (() -> Void)? {
        guard let pressing = pressing, state else {
            return nil
        }
        
        return {
            pressing(false)
        }
    }
    
    internal typealias StateType = Bool

}
