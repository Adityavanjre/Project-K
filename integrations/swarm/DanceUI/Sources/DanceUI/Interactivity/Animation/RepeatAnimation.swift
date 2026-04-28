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
internal struct RepeatAnimation: Hashable, CustomAnimationModifier {
    
    internal var repeatCount: Int?
    
    internal var autoreverses: Bool
    
    func animate<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: inout AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        var state = context.repeatState
        defer {
            context.repeatState = state
        }
        var reverseFlag = false
        if autoreverses {
            reverseFlag = state.index % 0x2 == 0x1
        }
        
        if let currentValue = animation.animate(value: value, time: time - state.timeOffset, context: &context) {
            if reverseFlag {
                return value - currentValue
            }
            return currentValue
        } else {
            state.index += 1
            state.timeOffset = time
            context.state = AnimationState()
            if repeatCount == nil || state.index < repeatCount! {
                if reverseFlag {
                    return .zero
                } else {
                    return value
                }
            } else {
                return nil
            }
        }
    }
    
    func velocity<V, Animation>(animation: Animation, value: V, time: TimeInterval, context: AnimationContext<V>) -> V? where V : VectorArithmetic, Animation : CustomAnimation {
        let state = context.repeatState
        return animation.velocity(value: value, time: time - state.timeOffset, context: context)
    }
}

internal struct RepeatState: AnimationStateKey {
    
    internal typealias Value = RepeatState
    
    static var defaultValue: RepeatState {
        RepeatState(index: 0, timeOffset: 0)
    }
    
    internal var index: Int

    internal var timeOffset: Double

}

@available(iOS 13.0, *)
extension AnimationContext {
    
    fileprivate var repeatState: RepeatState {
        get {
            state[RepeatState.self]
        }
        set {
            state[RepeatState.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension Animation {
    
    /// Repeats the animation for a specific number of times.
    ///
    /// Use this method to repeat the animation a specific number of times. For
    /// example, in the following code, the animation moves a truck from one
    /// edge of the view to the other edge. It repeats this animation three
    /// times.
    ///
    ///     struct ContentView: View {
    ///         @State private var driveForward = true
    ///
    ///         private var driveAnimation: Animation {
    ///             .easeInOut
    ///             .repeatCount(3, autoreverses: true)
    ///             .speed(0.5)
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(alignment: driveForward ? .leading : .trailing, spacing: 40) {
    ///                 Image(systemName: "box.truck")
    ///                     .font(.system(size: 48))
    ///                     .animation(driveAnimation, value: driveForward)
    ///
    ///                 HStack {
    ///                     Spacer()
    ///                     Button("Animate") {
    ///                         driveForward.toggle()
    ///                     }
    ///                     Spacer()
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// @Video(source: "animation-16-repeat-count.mp4", alt: "A video that shows a box truck moving from the leading edge of a view to the trailing edge, and back again before looping in the opposite direction.")
    ///
    /// The first time the animation runs, the truck moves from the leading
    /// edge to the trailing edge of the view. The second time the animation
    /// runs, the truck moves from the trailing edge to the leading edge
    /// because `autoreverse` is `true`. If `autoreverse` were `false`, the
    /// truck would jump back to leading edge before moving to the trailing
    /// edge. The third time the animation runs, the truck moves from the
    /// leading to the trailing edge of the view.
    ///
    /// - Parameters:
    ///   - repeatCount: The number of times that the animation repeats. Each
    ///   repeated sequence starts at the beginning when `autoreverse` is
    ///  `false`.
    ///   - autoreverses: A Boolean value that indicates whether the animation
    ///   sequence plays in reverse after playing forward. Autoreverse counts
    ///   towards the `repeatCount`. For instance, a `repeatCount` of one plays
    ///   the animation forward once, but it doesn’t play in reverse even if
    ///   `autoreverse` is `true`. When `autoreverse` is `true` and
    ///   `repeatCount` is `2`, the animation moves forward, then reverses, then
    ///   stops.
    /// - Returns: An animation that repeats for specific number of times.
    public func repeatCount(_ repeatCount: Int, autoreverses: Bool = true) -> Animation {
        modifer(RepeatAnimation(repeatCount: repeatCount, autoreverses: autoreverses))
    }
    
    /// Repeats the animation for the lifespan of the view containing the
    /// animation.
    ///
    /// Use this method to repeat the animation until the instance of the view
    /// no longer exists, or the view’s explicit or structural identity
    /// changes. For example, the following code continuously rotates a
    /// gear symbol for the lifespan of the view.
    ///
    ///     struct ContentView: View {
    ///         @State private var rotationDegrees = 0.0
    ///
    ///         private var animation: Animation {
    ///             .linear
    ///             .speed(0.1)
    ///             .repeatForever(autoreverses: false)
    ///         }
    ///
    ///         var body: some View {
    ///             Image(systemName: "gear")
    ///                 .font(.system(size: 86))
    ///                 .rotationEffect(.degrees(rotationDegrees))
    ///                 .onAppear {
    ///                     withAnimation(animation) {
    ///                         rotationDegrees = 360.0
    ///                     }
    ///                 }
    ///         }
    ///     }
    ///
    /// @Video(source: "animation-17-repeat-forever.mp4", alt: "A video that shows a gear that continuously rotates clockwise.")
    ///
    /// - Parameter autoreverses: A Boolean value that indicates whether the
    /// animation sequence plays in reverse after playing forward.
    /// - Returns: An animation that continuously repeats.
    public func repeatForever(autoreverses: Bool = true) -> Animation {
        modifer(RepeatAnimation(repeatCount: nil, autoreverses: autoreverses))
    }
}
