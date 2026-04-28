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
internal struct SpeedAnimation: Hashable, CustomAnimationModifier {

    internal var speed: Double
    
    internal func animate<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        let newTime = speed * time
        return animation.animate(value: value, time: newTime, context: &context)
    }
    
    internal func velocity<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        let newTime = speed * time
        return animation.velocity(value: value, time: newTime, context: context)
    }
}

@available(iOS 13.0, *)
extension Animation {
    /// Changes the duration of an animation by adjusting its speed.
    ///
    /// Setting the speed of an animation changes the duration of the animation
    /// by a factor of `speed`. A higher speed value causes a faster animation
    /// sequence due to a shorter duration. For example, a one-second animation
    /// with a speed of `2.0` completes in half the time (half a second).
    ///
    ///     struct ContentView: View {
    ///         @State private var adjustBy = 100.0
    ///
    ///         private var oneSecondAnimation: Animation {
    ///            .easeInOut(duration: 1.0)
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing: 40) {
    ///                 HStack(alignment: .bottom) {
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 - adjustBy)
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 + adjustBy)
    ///                 }
    ///                 .animation(oneSecondAnimation.speed(2.0), value: adjustBy)
    ///
    ///                 Button("Animate") {
    ///                     adjustBy *= -1
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// @Video(source: "animation-18-speed.mp4", poster: "animation-18-speed.png", alt: "A video that shows two capsules side by side that animate using the ease-in ease-out animation. The capsule on the left is short, while the capsule on the right is tall. They animate for half a second with the short capsule growing upwards to match the height of the tall capsule. Then the tall capsule shrinks to match the original height of the short capsule. For another half second, the capsule on the left shrinks to its original height, followed by the capsule on the right growing to its original height.")
    ///
    /// Setting `speed` to a lower number slows the animation, extending its
    /// duration. For example, a one-second animation with a speed of `0.25`
    /// takes four seconds to complete.
    ///
    ///     struct ContentView: View {
    ///         @State private var adjustBy = 100.0
    ///
    ///         private var oneSecondAnimation: Animation {
    ///            .easeInOut(duration: 1.0)
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing: 40) {
    ///                 HStack(alignment: .bottom) {
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 - adjustBy)
    ///                     Capsule()
    ///                         .frame(width: 50, height: 175 + adjustBy)
    ///                 }
    ///                 .animation(oneSecondAnimation.speed(0.25), value: adjustBy)
    ///
    ///                 Button("Animate") {
    ///                     adjustBy *= -1
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// @Video(source: "animation-19-speed-slow.mp4", poster: "animation-19-speed-slow.png", alt: "A video that shows two capsules side by side that animate using the ease-in ease-out animation. The capsule on the left is short, while the right-side capsule is tall. They animate for four seconds with the short capsule growing upwards to match the height of the tall capsule. Then the tall capsule shrinks to match the original height of the short capsule. For another four seconds, the capsule on the left shrinks to its original height, followed by the capsule on the right growing to its original height.")
    ///
    /// - Parameter speed: The speed at which DanceUI performs the animation.
    /// - Returns: An animation with the adjusted speed.
    public func speed(_ speed: Double) -> Animation {
        modifer(SpeedAnimation(speed: speed))
    }
}
