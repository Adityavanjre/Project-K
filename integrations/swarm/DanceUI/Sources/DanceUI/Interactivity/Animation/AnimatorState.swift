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
internal final class AnimatorState<Value: VectorArithmetic> {
    
    fileprivate let second = 0.016666666666666668
    
    internal var animation: Animation
    
    internal var state: AnimationState<Value>
    
    internal var interval: Value
    
    internal var beginTime: Time
    
    internal var quantizedFrameInterval: Double

    internal var nextTime: Time
    
    internal var previousAnimationValue: Value
    
    internal var reason: UInt32?
    
    fileprivate var phase: Phase
    
    internal var listeners: [AnimationListener]
    
    internal var logicalListeners: [AnimationListener]
    
    internal var isLogicallyComplete: Bool
    
    fileprivate var forks: [Fork]
    
    @inlinable
    internal init(animation: Animation,
                  interval: Value,
                  at time: Time,
                  in transaction: Transaction) {
        self.animation = animation
        self.state = .init()
        self.interval = interval
        self.beginTime = time
        self.nextTime = time
        self.previousAnimationValue = .zero
        var reason: UInt32? = nil
        if let animationFrameInterval = transaction.animationFrameInterval {
            if animationFrameInterval <= 0 {
                quantizedFrameInterval = 0
            } else {
                quantizedFrameInterval = AnimatorState<Value>.quantizedFrameInterval(animationFrameInterval)
                if quantizedFrameInterval < second {
                    reason = transaction.animationReason
                } else {
                    reason = nil
                }
            }
        } else {
            quantizedFrameInterval = 0
            reason = nil
        }
        self.reason = reason
        self.phase = .pending
        self.listeners = []
        self.logicalListeners = []
        self.isLogicallyComplete = false
        self.forks = []
    }
    
    /// Updates the animator. Returns `true` the when animation ended, returns
    /// `fasle` when the animation is ongoing.
    ///
    internal func update(_ value: inout Value,
                         at time: Time,
                         environment: Attribute<EnvironmentValues>) -> Bool {
        guard time.seconds > nextTime.seconds + (quantizedFrameInterval * -0.5) else {
            value += previousAnimationValue
            value -= interval
            return false
        }
        switch phase {
        case .pending:
            self.beginTime = time
            self.phase = .first
        case .first:
            self.beginTime = time
            self.phase = .second
            nextTime = nextTime - self.beginTime + time
            value += previousAnimationValue
            value -= interval
            return false
        case .second:
            if beginTime.distance(to: time) > second * 2 {
                self.beginTime = time.advanced(by: -(second * 2))
            }
            self.phase = .running
        case .running:
            break
        }
        
        let intervalSeconds = beginTime.distance(to: time)
        return withMutableAnimationContext(environment: environment) { context in
            let stop: Bool
            if let newValue = animation.animate(value: self.interval,
                                                time: intervalSeconds,
                                                context: &context) {
                updateListeners(isLogicallyComplete: context.isLogicallyComplete,
                                time: intervalSeconds,
                                environment: environment)
                value += newValue
                value -= interval
                previousAnimationValue = newValue
                nextTime = time
                if quantizedFrameInterval > 0 {
                    nextTime = Time(seconds: (round(time.seconds / quantizedFrameInterval) + 1) * quantizedFrameInterval)
                }
                stop = false
            } else {
                stop = true
            }
            return stop
        }
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal func combine(newAnimaition: Animation,
                          newInterval: Value,
                          at time: Time,
                          in transaction: Transaction,
                          environment: Attribute<EnvironmentValues>) {
        if phase != .first {
            _defaultCombine(newAnimation: newAnimaition,
                            newInterval: newInterval,
                            at: time,
                            environment: environment)
        } else {
            //            if #warning("Semantics") {
            //                self.animator = newAnimator
            //                self.interval = newInterval
            //            } else {
            _defaultCombine(newAnimation: newAnimaition,
                            newInterval: newInterval,
                            at: time,
                            environment: environment)
            //            }
        }
        guard let animationFrameInterval = transaction.animationFrameInterval else {
            return
        }
        quantizedFrameInterval = AnimatorState<Value>.quantizedFrameInterval(animationFrameInterval)
        if quantizedFrameInterval < second {
            reason = transaction.animationReason ?? self.reason
        } else {
            reason = nil
        }
    }
    
//    @inline(__always)
    private func _defaultCombine(newAnimation: Animation,
                                 newInterval: Value,
                                 at time: Time,
                                 environment: Attribute<EnvironmentValues>) {
        let elapsed = beginTime.distance(to: time)
        forkListeners(animation: self.animation, state: self.state, intervale: self.interval)
        withMutableAnimationContext(environment: environment) { context in
            self.isLogicallyComplete = false
            if newAnimation.shouldMerge(previous: animation,
                                        value: self.interval,
                                        time: elapsed,
                                        context: &context) {
                self.animation = newAnimation
            } else {
                if var combiningAnimation = self.animation.base as? DefaultCombiningAnimation {
                    var combiningState = context.state[CombinedAnimationState<Value>.self]
                    combiningState.entries.append(CombinedAnimationState.Entry(value: self.interval + newInterval,
                                                                               state: AnimationState()))
                    context.state[CombinedAnimationState<Value>.self] = combiningState
                    combiningAnimation.entries.append(.init(animation: newAnimation, elapsed: elapsed))
                    self.animation = Animation(combiningAnimation)
                } else {
                    let combiningState = CombinedAnimationState(entries: [CombinedAnimationState.Entry(value: self.interval,
                                                                                                       state: self.state),
                                                                          CombinedAnimationState.Entry(value: self.interval +  newInterval,
                                                                                                       state: AnimationState())])
                    context.state[CombinedAnimationState<Value>.self] = combiningState
                    let entries: [DefaultCombiningAnimation.Entry] = [.init(animation: animation, elapsed: 0),
                                                                      .init(animation: newAnimation, elapsed: elapsed)]
                    self.animation = Animation(DefaultCombiningAnimation(entries: entries))
                }
            }
        }
        self.interval += newInterval
        self.nextTime = time
    }
    
    internal func forkListeners(animation: Animation, state: AnimationState<Value>, intervale: Value) {
        guard !isLogicallyComplete && !logicalListeners.isEmpty else {
            return
        }
        let newFork = Fork(animation: animation, state: state, interval: intervale, listeners: logicalListeners)
        self.forks.append(newFork)
        self.logicalListeners = []
    }
    
    @inline(__always)
    private func withMutableAnimationContext<R>(environment: Attribute<EnvironmentValues>,
                                                _ body: (inout AnimationContext<Value>) -> R) -> R {
        var context = AnimationContext(state: state,
                                       isLogicallyComplete: isLogicallyComplete,
                                       _environment: WeakAttribute(environment))
        defer {
            self.state = context.state
        }
        return body(&context)
    }
    
    internal func updateListeners(isLogicallyComplete: Bool,
                                  time: TimeInterval,
                                  environment: Attribute<EnvironmentValues>) {
        if !self.isLogicallyComplete && isLogicallyComplete {
            self.isLogicallyComplete = true
            logicalListeners.forEach { $0.animationWasRemoved() }
            logicalListeners = []
        }
        
        // Clean up forks that need to be removed
        var offsets = IndexSet()
        for idx in forks.indices {
            guard forks[idx].update(time: time, environment: environment) else {
                continue
            }
            forks[idx].listeners.forEach { $0.animationWasRemoved() }
            offsets.insert(idx)
        }
        forks.remove(atOffsets: offsets)
    }
    
    private static func quantizedFrameInterval(_ interval: Double) -> Double {
        exp2(floor(log2(interval * 240) + 0.01)) * 0.00416667
    }

    internal func addListeners(_ transaction: Transaction) {
        if let listener = transaction.listener {
            listeners.append(listener)
            listener.animationWasAdded()
        }
        if let listener = transaction.logicalListener {
            listener.animationWasAdded()
            guard !isLogicallyComplete else {
                listener.animationWasRemoved()
                return
            }
            logicalListeners.append(listener)
        }
    }
    
    internal func removeListeners() {
        listeners.forEach { $0.animationWasRemoved() }
        listeners = []
        logicalListeners.forEach { $0.animationWasRemoved() }
        logicalListeners = []
    }
    
    fileprivate struct Fork {
        
        internal var animation: Animation
        
        internal var state: AnimationState<Value>
        
        internal var interval: Value
        
        internal var listeners: [AnimationListener]
        
        internal func update(time: TimeInterval, environment: Attribute<EnvironmentValues>) -> Bool {
            var context = AnimationContext(state: state,
                                           isLogicallyComplete: false,
                                           _environment: WeakAttribute(environment))
            let animateValue = animation.animate(value: interval, time: time, context: &context)
            return animateValue == nil || context.isLogicallyComplete
        }
        
    }
}

#if DEBUG
@available(iOS 13.0, *)
extension AnimatorState: CustomStringConvertible {
    var description: String {
        "<AnimatorState<\(Value._typeVectorDescription)> : \(Unmanaged.passUnretained(self).toOpaque()); animation = \(animation); beginTime = \(beginTime); nextTime = \(nextTime); interval: \(interval._vectorDescription); previousAnimationValue = \(previousAnimationValue._vectorDescription)>"
    }
}
#endif

@available(iOS 13.0, *)
extension AnimatorState {
    
    fileprivate enum Phase {
        
        case pending
        
        case first
        
        case second
        
        case running
        
    }
    
}
