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
internal struct ButtonBehavior<Label: View>: UnaryView, PrimitiveView {

    internal var action: () -> Void

    internal var content: (Bool) -> Label

    @State
    internal var state: (isPressed: Bool, isActive: Bool)
    
    internal var name: String?
    
    internal static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        if DanceUIFeature.gestureContainer.isEnable {
            let child = PrimitiveButtonBehaviorChild(buttonBehavior: view.value).makeAttribute()
            return PrimitiveButtonBehaviorChild<Label>.Value._makeView(view: _GraphValue(child), inputs: inputs)
        } else {
            return LegacyButtonBehavior<Label>._makeView(view: view.unsafeBitCast(to: LegacyButtonBehavior<Label>.self), inputs: inputs)
        }
    }
    
}

@available(iOS 13.0, *)
internal struct LegacyButtonBehavior<Label: View>: View {

    internal var action: () -> Void

    internal var content: (Bool) -> Label

    @State
    internal var state: (isPressed: Bool, isActive: Bool)
    
    internal var name: String?
    
    internal var body: some View {
        content(state.isPressed)
            .buttonAction(
                _ButtonGesture(action: action) { isPressed in
                    let duration = isPressed ? 0 : 0.47
                    let animation: Animation = .timingCurve(0.25, 0.1, 0.25, 1, duration: duration)
                    withAnimation(animation) {
                        state = (isPressed, state.isActive)
                    }
                }
                .onEnded {
                    state = (false, state.isActive)
                }
                .onFailed {
                    state = (false, state.isActive)
                })
        
    }
    
}

@available(iOS 13.0, *)
private struct PrimitiveButtonBehaviorChild<Label: View>: Rule {
    
    @Attribute
    fileprivate var buttonBehavior: ButtonBehavior<Label>
    
    fileprivate var value: PrimitiveButtonBehavior<Label> {
        PrimitiveButtonBehavior(action: buttonBehavior.action, content: buttonBehavior.content, state: buttonBehavior.state, name: buttonBehavior.name)
    }
    
}

@available(iOS 13.0, *)
internal struct PrimitiveButtonBehavior<Label: View>: View {

    internal var action: () -> Void

    internal var content: (Bool) -> Label

    @State
    internal var state: (isPressed: Bool, isActive: Bool)
    
    internal var name: String?
    
    @GestureCancellation
    internal var cancellation: Bool = false
    
    internal var body: some View {
        content(state.isPressed)
            .simultaneousGesture(highlightGesture, name: name ?? "ButtonHighlightGesture")
            .gesture(actionGesture, name: name ?? "ButtonActionGesture")
    }
    
    private func pressing(_ isPressed: Bool) {
        let duration = isPressed ? 0 : 0.47
        let animation: Animation = .timingCurve(0.25, 0.1, 0.25, 1, duration: duration)
        withAnimation(animation) {
            state = (isPressed, state.isActive)
        }
    }
    
    private var highlightGesture: some Gesture {
        PressableGesture(pressingAction: pressing)
            .canBeCancelled(by: $cancellation)
            .onEnded { _ in
                state = (false, state.isActive)
            }
            .isCompanion()
    }
    
    private var actionGesture: some Gesture {
        ButtonActionGesture(action: action)
            .canCancell($cancellation, on: .failed)
    }
    
}
