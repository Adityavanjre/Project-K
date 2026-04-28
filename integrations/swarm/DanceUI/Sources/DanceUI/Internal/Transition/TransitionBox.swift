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
internal final class TransitionBox<T: Transition>: AnyTransitionBox {

    internal let base: T

    internal init(_ base: T) {
        self.base = base
    }

    internal override var isIdentity: Bool {
        T.TransitionModifier.self == EmptyModifier.self
    }

    internal override func visitBase<Visitor: TransitionVisitor>(applying visitor: inout Visitor) {
        visitor.visit(base)
    }

    internal override func visitType<Visitor: TransitionTypeVisitor>(applying visitor: inout Visitor) {
        visitor.visit(T.self)
    }

    internal override var hasMotion: Bool {
        get {
            false
        }
    }

}
