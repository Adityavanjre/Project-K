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
internal struct AsymmetricTransition<Insertion: Transition, Removal: Transition>: Transition {

    typealias TransitionModifier = ModifiedContent<Insertion.TransitionModifier, Removal.TransitionModifier>

    internal var insertion: Insertion

    internal var removal: Removal

    init(insertion: Insertion, removal: Removal) {
        self.insertion = insertion
        self.removal = removal
    }

    internal func transitionModifier(phase: TransitionPhase) -> ModifiedContent<Insertion.TransitionModifier, Removal.TransitionModifier> {
        let insertionModifier = insertion.transitionModifier(phase: phase == .didRemove ? .normal : phase)
        let removalModifier = removal.transitionModifier(phase: phase == .willInsert ? .normal : phase)

        return insertionModifier.concat(removalModifier)
    }
}
