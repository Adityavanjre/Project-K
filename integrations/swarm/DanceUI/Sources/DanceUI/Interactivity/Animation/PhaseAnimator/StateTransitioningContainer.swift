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
extension PhaseAnimator {
    
    internal struct StateTransitioningContainer: UnaryView, PrimitiveView {

        internal var phases: [Phase]

        internal var content: (Phase) -> Content

        internal var animation: (Phase) -> Animation?

        internal var behavior: Behavior
        
        internal init(phases: [Phase],
                      content: @escaping (Phase) -> Content,
                      animation: @escaping (Phase) -> Animation?,
                      behavior: PhaseAnimator<Phase, Content>.Behavior) {
            self.phases = phases
            self.content = content
            self.animation = animation
            self.behavior = behavior
        }
        
        internal static func _makeView(view: _GraphValue<PhaseAnimator<Phase, Content>.StateTransitioningContainer>, inputs: _ViewInputs) -> _ViewOutputs {
            let isVisible = WeakAttribute(Attribute(value: false))
            let completion = AnimationCompletion(seed: .max, didAnimate: false)
            let animationCompletion = WeakAttribute(Attribute(value: completion))
            let child = Attribute(Child(view: view.value,
                                        transaction: inputs.transaction,
                                        phase: inputs.phase,
                                        animationCompletion: animationCompletion,
                                        isVisible: isVisible,
                                        currentIndex: 0,
                                        completionSeed: 0,
                                        resetSeed: 0,
                                        endlessLoopState: .animating,
                                        lastBehavior: nil))
            let visibleHandler = appearanceHandler(isVisible, value: true)
            let invisibleHandler = appearanceHandler(isVisible, value: false)
            let appearanceAction = Attribute(value: _AppearanceActionModifier(appear: visibleHandler, disappear: invisibleHandler))
            return _AppearanceActionModifier._makeView(modifier: .init(appearanceAction), inputs: inputs) { _, inputs in
                var newInputs = inputs
                newInputs.transaction = child[{ .of(&$0.transaction) }]
                return Content._makeView(view: .init(child[{ .of(&$0.content) }]), inputs: newInputs)
            }
        }
        
        internal static func appearanceHandler(_ attribute: WeakAttribute<Bool>, value: Bool) -> (() -> Void) {
            weak var host = GraphHost.currentHost
            return {
                Update.ensure172 {
                    guard let host = host else {
                        return
                    }
                    let mutation = VisibilityMutation(signal: attribute, value: value)
                    host.asyncTransaction(Transaction.current,
                                          mutation: mutation,
                                          style: .ignoresFlushWhenUpdating,
                                          mayDeferUpdate: true)
                }
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension PhaseAnimator.StateTransitioningContainer {
    
    internal struct AnimationCompletion {
        
        internal var seed: Int
        
        internal var didAnimate: Bool
    }
    
    internal struct Child: StatefulRule {

        internal typealias Value = (content: Content, transaction: Transaction)

        @Attribute
        internal var view: PhaseAnimator.StateTransitioningContainer

        @Attribute
        internal var transaction: Transaction

        @Attribute
        internal var phase: _GraphInputs.Phase

        @WeakAttribute
        internal var animationCompletion: AnimationCompletion?

        @WeakAttribute
        internal var isVisible: Bool?

        internal var currentIndex: Int

        internal var completionSeed: Int

        internal var resetSeed: UInt32

        fileprivate var endlessLoopState: EndlessLoopState

        internal var lastBehavior: PhaseAnimator.Behavior?
        
        private var clampedIndex: Int {
            switch endlessLoopState {
            case .paused:
                return 0
            case .animating, .monitoring:
                break
            }
            let view = self.view
            return min(view.phases.count - 1, currentIndex)
            
        }
        
        fileprivate enum EndlessLoopState: Equatable {
            case monitoring(firstNonAnimatedPhaseIndex: Int)
            case animating
            case paused
        }
        
        internal mutating func updateValue() {
            if resetSeed != self.phase.seed {
                reset()
            }
            let (view, isViewChanged) = self.$view.changedValue()
            let phases = view.phases
            let content = view.content
            var transaction = DGGraphRef.withoutUpdate {
                self.transaction
            }
            defer {
                let viewContent = content(phases[clampedIndex])
                self.value = (viewContent, transaction)
            }
            guard let isVisibleAttribute = self.$isVisible else {
                return
            }
            let (isVisible, isVisibleChanged) = isVisibleAttribute.changedValue(options: .init(rawValue: 0x1))
            if isVisibleChanged {
                if !isVisible {
                    reset()
                } else {
                    switch view.behavior {
                    case .eventDriven:
                        break
                    case .repeating:
                        advance(from: currentIndex, transaction: &transaction, view: view)
                    }
                }
            }
            
            if isViewChanged {
                let endlessLoopState = self.endlessLoopState
                self.endlessLoopState = .animating
                switch endlessLoopState {
                case .monitoring, .animating:
                    break
                case .paused:
                    switch view.behavior {
                    case .eventDriven:
                        break
                    case .repeating:
                        advance(from: currentIndex, transaction: &transaction, view: view)
                    }
                }
            }
            
            if let lastBehavior = lastBehavior, lastBehavior != view.behavior {
                switch (lastBehavior, view.behavior) {
                case (.eventDriven(let lastTrigger), .eventDriven(let trigger)):
                    if lastTrigger != trigger {
                        advance(from: 0, transaction: &transaction, view: view)
                    }
                case (.eventDriven, .repeating):
                    advance(from: currentIndex, transaction: &transaction, view: view)
                case (.repeating, .eventDriven):
                    advance(to: 0, transaction: &transaction, view: view)
                case (.repeating, .repeating):
                    break
                }
            }
            lastBehavior = view.behavior
            guard let animationCompletionAttribute = $animationCompletion else {
                return
            }
            let (animationCompletion, isAnimationCompletionChanged) = animationCompletionAttribute.changedValue()
            guard isAnimationCompletionChanged, animationCompletion.seed == completionSeed else {
                return
            }
            switch view.behavior {
            case .repeating:
                break
            case .eventDriven:
                guard currentIndex != 0 else {
                    return
                }
            }
            if !animationCompletion.didAnimate {
                switch endlessLoopState {
                case .monitoring, .paused:
                    break
                case .animating:
                    self.endlessLoopState = .monitoring(firstNonAnimatedPhaseIndex: currentIndex)
                }
            } else {
                endlessLoopState = .animating
            }
            advance(from: currentIndex, transaction: &transaction, view: view)
        }
        
        internal mutating func reset() {
            currentIndex = 0
            lastBehavior = nil
            endlessLoopState = .animating
            completionSeed &+= 1
        }
        
        internal mutating func advance(from index: Int,
                              transaction: inout Transaction,
                              view: PhaseAnimator.StateTransitioningContainer) {
            guard view.phases.count >= 2 else {
                return
            }
            var advancedIndex = index + 1
            advancedIndex = advancedIndex < view.phases.count ? advancedIndex : 0
            advance(to: advancedIndex, transaction: &transaction, view: view)
        }
        
        internal mutating func advance(to index: Int,
                              transaction: inout Transaction,
                              view: PhaseAnimator.StateTransitioningContainer) {
            switch endlessLoopState {
            case .monitoring(let firstNonAnimatedPhaseIndex):
                guard index != firstNonAnimatedPhaseIndex else {
                    endlessLoopState = .paused
                    currentIndex = 0
                    return
                }
            case .animating:
                break
            case .paused:
                return
            }
            
            guard index < view.phases.count else {
                advance(from: index, transaction: &transaction, view: view)
                return
            }
            self.currentIndex = index
            self.completionSeed &+= 1
            let animationCompletionAttribute = _animationCompletion
            let seed = completionSeed
            if let animation = view.animation(view.phases[index]) {
                weak var host = GraphHost.currentHost
                transaction.animation = animation
                transaction.addAnimationLogicalListener { info in
                    Update.ensure172 {
                        guard let host = host else {
                            return
                        }
                        let mutation = CustomGraphMutation {
                            setAnimationCompletion(.init(seed: seed, didAnimate: info.completedCount > 0))
                        }
                        host.asyncTransaction(Transaction(), mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
                    }
                }
            } else {
                GraphHost.currentHost.continueTransaction {
                    setAnimationCompletion(.init(seed: seed, didAnimate: false))
                }
            }
            func setAnimationCompletion(_ completion: AnimationCompletion) {
                guard let attribute = animationCompletionAttribute.attribute else {
                    return
                }
                _ = attribute.setValue(completion)
            }
        }
    }
    
    fileprivate struct VisibilityMutation: GraphMutation {
        
        @WeakAttribute
        internal var signal: Bool?
        
        internal var value: Bool
        
#if DEBUG || DANCE_UI_INHOUSE
        internal let file: StaticString

        internal let line: UInt

        internal let function: StaticString

        fileprivate init(signal: WeakAttribute<Bool>,
                         value: Bool,
                         file: StaticString = #fileID,
                         line: UInt = #line,
                         function: StaticString = #function) {
            self._signal = signal
            self.value = value
            self.file = file
            self.line = line
            self.function = function
        }
#else
        fileprivate init(signal: WeakAttribute<Bool>,
                         value: Bool) {
            self._signal = signal
            self.value = value
        }
#endif
        
        fileprivate mutating func apply() {
            guard let attribute = self.$signal else {
                return
            }
            _ = attribute.setValue(value)
        }
        
        fileprivate mutating func combine<T>(with mutation: T) -> Bool where T : GraphMutation {
            guard let commitMutation = mutation as? VisibilityMutation else {
                return false
            }
            value = commitMutation.value
            return true
        }
    }
}
