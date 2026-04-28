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
internal protocol CustomAnimationModifier: Hashable {
    
    func animate<V: VectorArithmetic, Animation: CustomAnimation>(animation: Animation,
                                                                  value: V,
                                                                  time: TimeInterval,
                                                                  context: inout AnimationContext<V>) -> V?
    
    func velocity<V: VectorArithmetic, Animation: CustomAnimation>(animation: Animation,
                                                                   value: V,
                                                                   time: TimeInterval,
                                                                   context: AnimationContext<V>) -> V?
    
}

@available(iOS 13.0, *)
internal struct InternalCustomAnimationModifiedContent<Base: CustomAnimation,
                                                       Modifier: CustomAnimationModifier>: InternalCustomAnimation {
    
    internal var _base: CustomAnimationModifiedContent<Base, Modifier>
    
    internal func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
        _base.animate(value: value, time: time, context: &context)
    }
    
    internal func velocity<V>(value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic {
        _base.velocity(value: value, time: time, context: context)
    }
    
    internal func shouldMerge<V>(previous: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> Bool where V : VectorArithmetic {
        _base.shouldMerge(previous: previous, value: value, time: time, context: &context)
    }
    
    
}

@available(iOS 13.0, *)
internal struct CustomAnimationModifiedContent<Base: CustomAnimation,
                                               Modifier: CustomAnimationModifier>: InternalCustomAnimation {
    
    internal var base: Base
    
    internal var modifier: Modifier
    
    internal func animate<V>(value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic {
        modifier.animate(animation: base, value: value, time: time, context: &context)
    }
    
    internal func velocity<V>(value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic {
        modifier.velocity(animation: base, value: value, time: time, context: context)
    }
    
    internal func shouldMerge<V>(previous: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> Bool where V : VectorArithmetic {
        guard let previous = previous.base as? Self,
              self == previous else {
            return false
        }
        return self.base.shouldMerge(previous: Animation(previous.base), value: value, time: time, context: &context)
    }
    
}

@available(iOS 13.0, *)
extension Animation {
    
    internal func modifer<M: CustomAnimationModifier>(_ modifier: M) -> Animation {
        Animation(internal: self.box.modifier(modifier))
    }
    
}
