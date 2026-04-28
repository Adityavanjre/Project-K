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
internal struct DelayAnimation: Equatable, CustomAnimationModifier {

    internal var delay: Double
    
    internal func animate<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        animation.animate(value: value, time: delayedTime(time), context: &context)
    }
    
    internal func velocity<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        animation.velocity(value: value, time: delayedTime(time), context: context)
    }
    
    private func delayedTime(_ time: Double) -> Double {
        var newTime = time - delay
        newTime = newTime > 0 ? newTime : 0
        return newTime
    }
    
}

@available(iOS 13.0, *)
extension Animation {

    /// Delays the start of the animation by the specified number of seconds.
    ///
    /// Use this method to delay the start of an animation. For example, the
    /// following code animates the height change of two capsules.
    /// Animation of the first ``Capsule`` begins immediately. However,
    /// animation of the second one doesn't begin until a half second later.
    ///
    ///     struct ContentView: View {
    ///         @State private var adjustBy = 100.0
    ///
    ///         var body: some View {
    ///             VStack(spacing: 40) {
    ///                 HStack(alignment: .bottom) {
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 - adjustBy)
    ///                         .animation(.easeInOut, value: adjustBy)
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 + adjustBy)
    ///                         .animation(.easeInOut.delay(0.5), value: adjustBy)
    ///                 }
    ///
    ///                 Button("Animate") {
    ///                     adjustBy *= -1
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// @Video(source: "animation-15-delay.mp4", poster: "animation-15-delay.png", alt: "A video that shows two capsules side by side that animate using the ease-in ease-out animation. The capsule on the left is short, while the capsule on the right is tall. As they animate, the short capsule grows upwards to match the height of the tall capsule. Then the tall capsule shrinks to match the original height of the short capsule. Then the capsule on the left shrinks to its original height, followed by the capsule on the right growing to its original height.")
    ///
    /// - Parameter delay: The number of seconds to delay the start of the
    /// animation.
    /// - Returns: An animation with a delayed start.
    public func delay(_ delay: TimeInterval) -> Animation {
        modifer(DelayAnimation(delay: delay))
    }
}
