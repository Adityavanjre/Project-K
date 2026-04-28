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

/// A container that animates its content by automatically cycling through
/// a collection of phases that you provide, each defining a discrete step
/// within an animation.
///
/// Use one of the phase animator view modifiers like
/// ``View/phaseAnimator(_:content:animation:)`` to create a phased animation
/// in your app.
@available(iOS 13.0, *)
public struct PhaseAnimator<Phase: Equatable, Content: View>: View {
    
    internal var phases: [Phase]
    
    internal var content: (Phase) -> Content
    
    internal var animation: (Phase) -> Animation?
    
    internal var behavior: Behavior
    
    internal enum Behavior: Equatable {
        
        case eventDriven(trigger: AnyEquatable)
        
        case repeating
        
        
    }
    
    internal struct EmptyPhasesView: View {

        var body: some View {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(.body))
                .padding(8)
                .foregroundStyle(Color.red)
                .background {
                    Color.yellow
                }
        }
        
    }
    
    public init(_ phases: some Sequence<Phase>,
                trigger: some Equatable,
                @ViewBuilder content: @escaping (Phase) -> Content,
                animation: @escaping (Phase) -> Animation? = { _ in .default }) {
        self.phases = phases.map({$0})
        self.behavior = .eventDriven(trigger: .init(value: trigger))
        self.content = content
        self.animation = animation
    }
    
    public init(_ phases: some Sequence<Phase>,
                @ViewBuilder content: @escaping (Phase) -> Content,
                animation: @escaping (Phase) -> Animation? = { _ in .default }) {
        self.phases = phases.map({$0})
        self.behavior = .repeating
        self.content = content
        self.animation = animation
    }
    
    public var body: some View {
        if phases.isEmpty {
            EmptyPhasesView()
                .onAppear {
                    print("PhaseAnimator requires at least one phase value")
                }
        } else {
            StateTransitioningContainer(phases: phases, 
                                        content: content,
                                        animation: animation,
                                        behavior: behavior)
        }
    }
}


@available(iOS 13.0, *)
private struct CustomModifier<R: View>: MultiViewModifier, PrimitiveViewModifier {
    
    fileprivate var result: R
    
    fileprivate static func _makeView(modifier: _GraphValue<CustomModifier<R>>,
                                      inputs: _ViewInputs,
                                      body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.append(.view(body), for: BodyInput.self)
        let outputs = R.makeDebuggableView(value: modifier[\.result], inputs: newInputs)
        return outputs
    }
}


@available(iOS 13.0, *)
extension View {
    
    /// Cycles through the given phases when the trigger value changes,
    /// updating the view using the modifiers you apply in `body`.
    ///
    /// The phases that you provide specify the individual values that will
    /// be animated to when the trigger value changes.
    ///
    /// When the view first appears, the value from the first phase is provided
    /// to the `content` closure. When the trigger value changes, the content
    /// closure is called with the value from the second phase and its
    /// corresponding animation. This continues until the last phase is
    /// reached, after which the first phase is animated to.
    ///
    /// - Parameters:
    ///   - phases: Phases defining the states that will be cycled through.
    ///     This sequence must not be empty. If an empty sequence is provided,
    ///     a visual warning will be displayed in place of this view, and a
    ///     warning will be logged.
    ///   - trigger: A value to observe for changes.
    ///   - content: A view builder closure that takes two parameters. The first
    ///     parameter is a proxy value representing the modified view. The
    ///     second parameter is the current phase.
    ///   - animation: A closure that returns the animation to use when
    ///     transitioning to the next phase. If `nil` is returned, the
    ///     transition will not be animated.
    public func phaseAnimator<Phase: Equatable>(_ phases: some Sequence<Phase>,
                                                trigger: some Equatable,
                                                @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View,
                                                animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View {
        PhaseAnimator(phases,
                      trigger: trigger,
                      content: { phase in
            let content = content(PlaceholderContentView<Self>(), phase)
            modifier(CustomModifier(result: content))
        },
                      animation: animation)
    }
    
    
    /// Cycles through the given phases continuously, updating the content
    /// using the view builder closure that you supply.
    ///
    /// The phases that you provide define the individual values that will
    /// be animated between.
    ///
    /// When the view first appears, the the first phase is provided
    /// to the `content` closure. The animator then immediately animates
    /// to the second phase, using an animation returned from the `animation`
    /// closure. This continues until the last phase is reached, after which
    /// the animator loops back to the beginning.
    ///
    /// - Parameters:
    ///   - phases: Phases defining the states that will be cycled through.
    ///     This sequence must not be empty. If an empty sequence is provided,
    ///     a visual warning will be displayed in place of this view, and a
    ///     warning will be logged.
    ///   - content: A view builder closure that takes two parameters. The first
    ///     parameter is a proxy value representing the modified view. The
    ///     second parameter is the current phase.
    ///   - animation: A closure that returns the animation to use when
    ///     transitioning to the next phase. If `nil` is returned, the
    ///     transition will not be animated.
    public func phaseAnimator<Phase: Equatable>(_ phases: some Sequence<Phase>,
                                                @ViewBuilder content: @escaping (PlaceholderContentView<Self>, Phase) -> some View,
                                                animation: @escaping (Phase) -> Animation? = { _ in .default }) -> some View {
        PhaseAnimator(phases, content: { phase in
            let content = content(PlaceholderContentView<Self>(), phase)
            modifier(CustomModifier(result: content))
        }, animation: animation)
    }
    
}
