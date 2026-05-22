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
internal struct CombiningTransition<First: Transition, Second: Transition>: Transition {

    typealias TransitionModifier = ModifiedContent<First.TransitionModifier, Second.TransitionModifier>

    internal var transition1: First

    internal var transition2: Second

    init(transition1: First, transition2: Second) {
        self.transition1 = transition1
        self.transition2 = transition2
    }

    internal func transitionModifier(phase: TransitionPhase) -> TransitionModifier {
        let transition1Modifier = transition1.transitionModifier(phase: phase)
        let transition2Modifier = transition2.transitionModifier(phase: phase)

        return transition1Modifier.concat(transition2Modifier)
    }

}
