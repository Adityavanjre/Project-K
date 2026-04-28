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


/// The criteria that determines when an animation is considered finished.
@available(iOS 13.0, *)
public struct AnimationCompletionCriteria : Hashable, Sendable {

    /// The animation has logically completed, but may still be in its long
    /// tail.
    ///
    /// If a subsequent change occurs that creates additional animations on
    /// properties with `logicallyComplete` completion callbacks registered,
    /// then those callbacks will fire when the animations from the change that
    /// they were registered with logically complete, ignoring the new
    /// animations.
    public static let logicallyComplete: AnimationCompletionCriteria = .init(storage: .logicallyComplete)

    /// The entire animation is finished and will now be removed.
    ///
    /// If a subsequent change occurs that creates additional animations on
    /// properties with `removed` completion callbacks registered, then those
    /// callbacks will only fire when *all* of the created animations are
    /// complete.
    public static let removed: AnimationCompletionCriteria = .init(storage: .removed)
    
    internal enum Storage: Hashable, Equatable {
        
        case logicallyComplete
        
        case removed
        
        
    }
    
    internal var storage: Storage
}

private final class FunctionalListener: AnimationListener {

    private let added: () -> Void

    private let removed: () -> Void

    internal init(added: @escaping () -> Void,
                  removed: @escaping () -> Void) {
        self.added = added
        self.removed = removed
    }

    fileprivate func animationWasAdded() {
        added()
    }

    fileprivate func animationWasRemoved() {
        removed()
    }

    internal func checkDispatched() {

    }
}
