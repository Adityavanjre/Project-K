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
@_spi(DanceUICompose)
public protocol _DisplayList_AnyEffectAnimator {

    func evaluate(_: _DisplayList_AnyEffectAnimation, at: Time, size: CGSize) -> (DisplayList.Effect, Bool)

}

@available(iOS 13.0, *)
internal struct EffectAnimator<A: Animatable> {

    internal var state: State

    internal enum State {

        case active(AnimatorState<A.AnimatableData>)

        case pending

        case finished

    }

}
