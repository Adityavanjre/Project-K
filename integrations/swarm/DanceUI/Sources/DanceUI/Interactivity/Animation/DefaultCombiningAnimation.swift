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

@available(iOS 13.0, *)
internal struct DefaultCombiningAnimation: CustomAnimation {
    
    internal var entries: [Entry]
    
    
    internal struct Entry: Equatable, Hashable {
        
        internal var animation: Animation
        
        internal var elapsed: Double
    }
    
    internal func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
        
        var combiningState = context.state[CombinedAnimationState<V>.self]
        defer {
            context.state[CombinedAnimationState<V>.self] = combiningState
        }
        guard combiningState.entries.count == entries.count && !entries.isEmpty else {
            return nil
        }
        var resultValue: V = .zero
        for (index, entry) in entries.enumerated() {
            let stateEntry = combiningState.entries[index]
            guard let entryState = stateEntry.state else {
                resultValue = stateEntry.value
                continue
            }
            let newValue = stateEntry.value - resultValue
            let elapsed = time - entry.elapsed
            var entryContext = AnimationContext(state: entryState,
                                                isLogicallyComplete: false,
                                                _environment: context._environment)
            let animateValue = entry.animation.animate(value: newValue,
                                                       time: elapsed,
                                                       context: &entryContext)
            if let value = animateValue {
                combiningState.entries[index].state = entryContext.state
                resultValue += value
            } else {
                combiningState.entries[index].state = nil
                resultValue += newValue
            }
            
            guard index == entries.count - 1 else {
                continue
            }
            context.isLogicallyComplete = entryContext.isLogicallyComplete
            if animateValue == nil {
                return nil
            } else {
                return resultValue
            }
        }

        return nil

    }
}

@available(iOS 13.0, *)
internal struct CombinedAnimationState<Value: VectorArithmetic>: AnimationStateKey {
    
    internal typealias Value = CombinedAnimationState<Value>
    
    internal static var defaultValue: CombinedAnimationState<Value> {
        .init(entries: [])
    }
    
    internal var entries: [Entry]
    
    internal struct Entry {
        
        internal var value: Value
        
        internal var state: AnimationState<Value>?
    }
}
