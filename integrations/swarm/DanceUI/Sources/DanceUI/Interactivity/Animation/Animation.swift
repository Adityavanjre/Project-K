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

/// The way a view changes over time to create a smooth visual transition from
/// one state to another.
///
/// An `Animation` provides a visual transition of a view when a state value
/// changes from one value to another. The characteristics of this transition
/// vary according to the animation type. For instance, a ``linear`` animation
/// provides a mechanical feel to the animation because its speed is consistent
/// from start to finish. In contrast, an animation that uses easing, like
/// ``easeOut``, offers a more natural feel by varying the acceleration
/// of the animation.
///
/// To apply an animation to a view, add the ``View/animation(_:value:)``
/// modifier, and specify both an animation type and the value to animate. For
/// instance, the ``Circle`` view in the following code performs an
/// ``easeIn`` animation each time the state variable `scale` changes:
///
///     struct ContentView: View {
///         @State private var scale = 0.5
///
///         var body: some View {
///             VStack {
///                 Circle()
///                     .scaleEffect(scale)
///                     .animation(.easeIn, value: scale)
///                 HStack {
///                     Button("+") { scale += 0.1 }
///                     Button("-") { scale -= 0.1 }
///                 }
///             }
///             .padding()
///         }
///
/// @Video(source: "animation-01-overview-easein.mp4", alt: "A video that shows a circle enlarging then shrinking to its original size using an ease-in animation.")
///
/// When the value of `scale` changes, the modifier
/// ``View/scaleEffect(_:anchor:)-9ms09`` resizes ``Circle`` according to the
/// new value. The transition between sizes can be animated because
/// ``Circle`` conforms to the ``Shape`` protocol. Shapes conform to
/// the ``Animatable`` protocol, which describes how to animate a property of a
/// view.
///
/// In addition to adding an animation to a view, you can also configure the
/// animation by applying animation modifiers to the animation type. For
/// example, you can:
///
/// - Delay the start of the animation by using the ``delay(_:)`` modifier.
/// - Repeat the animation by using the ``repeatCount(_:autoreverses:)`` or
/// ``repeatForever(autoreverses:)`` modifiers.
/// - Change the speed of the animation by using the ``speed(_:)`` modifier.
///
/// For example, the ``Circle`` view in the following code repeats
/// the ``easeIn`` animation three times by using the
/// ``repeatCount(_:autoreverses:)`` modifier:
///
///     struct ContentView: View {
///         @State private var scale = 0.5
///
///         var body: some View {
///             VStack {
///                 Circle()
///                     .scaleEffect(scale)
///                     .animation(.easeIn.repeatCount(3), value: scale)
///                 HStack {
///                     Button("+") { scale += 0.1 }
///                     Button("-") { scale -= 0.1 }
///                 }
///             }
///             .padding()
///         }
///     }
///
/// @Video(source: "animation-02-overview-easein-repeat.mp4", alt: "A video that shows a circle that repeats the ease-in animation three times: enlarging, then shrinking, then enlarging again. The animation reverses causing the circle to shrink, then enlarge, then shrink to its original size.")
///
/// A view can also perform an animation when a binding value changes. To
/// specify the animation type on a binding, call its ``Binding/animation(_:)``
/// method. For example, the view in the following code performs a
/// ``linear`` animation, moving the box truck between the leading and trailing
/// edges of the view. The truck moves each time a person clicks the ``Toggle``
/// control, which changes the value of the `$isTrailing` binding.
///
///     struct ContentView: View {
///         @State private var isTrailing = false
///
///         var body: some View {
///            VStack(alignment: isTrailing ? .trailing : .leading) {
///                 Image(systemName: "box.truck")
///                     .font(.system(size: 64))
///
///                 Toggle("Move to trailing edge",
///                        isOn: $isTrailing.animation(.linear))
///             }
///         }
///     }
///
/// @Video(source: "animation-03-overview-binding.mp4", alt: "A video that shows a box truck that moves from the leading edge of a view to the trailing edge. The box truck then returns to the view's leading edge.")
@frozen
@available(iOS 13.0, *)
public struct Animation: Equatable {
    
    internal var box: AnimationBoxBase
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Animation, rhs: Animation) -> Bool {
        lhs.box.isEqual(to: rhs.box)
    }
    
    /// Create an `Animation` that contains the specified custom animation.
    public init<A: CustomAnimation>(_ base: A) {
        self.box = AnimationBox(_base: base)
    }
    
    internal init<A: CustomAnimation>(internal base: A) {
        self.box = InternalAnimationBox(_base: base)
    }
    
    internal static func uiViewAnimation(curve: Int, duration: Double) -> Animation? {
        guard curve <= 7, curve >= 0 else {
            return nil
        }
        
        var arg0, arg1, arg2, arg3: Double
        switch curve {
        case 0, 6:
            arg0 = 0.42
            arg1 = 0
            arg2 = 0.58
            arg3 = 1
        case 1:
            arg0 = 0.42
            arg1 = 0
            arg2 = 1
            arg3 = 1
        case 2:
            arg0 = 0
            arg1 = 0
            arg2 = 0.58
            arg3 = 1
        case 3:
            arg0 = 0
            arg1 = 0
            arg2 = 1
            arg3 = 1
        case 4:
            arg0 = 0.66
            arg1 = 0
            arg2 = 0.33
            arg3 = 1
        case 5:
            arg0 = 0.25
            arg1 = 0.10000000000000001
            arg2 = 0.25
            arg3 = 1
        case 7:
            return Animation(internal: SpringAnimation(mass: 3, stiffness: 1000, damping: 500, initialVelocity: _Velocity()))
        default:
            return nil
        }
        let curve = UnitCurve(function: .bezier(startControlPoint: .init(x: arg0,
                                                                         y: arg1),
                                                endControlPoint: .init(x: arg2,
                                                                       y: arg3)))
        return Animation(internal: BezierAnimation(duration: duration,
                                                   curve: curve))
    }
}

/// Returns the result of recomputing the view's body with the provided
/// animation.
///
/// This function sets the given ``Animation`` as the ``Transaction/animation``
/// property of the thread's current ``Transaction``.
@available(iOS 13.0, *)
public func withAnimation<Result>(_ animation: Animation? = .default,
                                  _ body: () throws -> Result) rethrows -> Result {
    let transaction = Transaction(animation: animation)
    return try withTransaction(transaction) {
        try body()
    }
}

/// Returns the result of recomputing the view's body with the provided
/// animation, and runs the completion when all animations are complete.
///
/// This function sets the given ``Animation`` as the ``Transaction/animation``
/// property of the thread's current ``Transaction`` as well as calling
/// ``Transaction/addAnimationCompletion(criteria:_:)`` with the specified completion.
///
/// The completion callback will always be fired exactly one time. If no
/// animations are created by the changes in `body`, then the callback will be
/// called immediately after `body`.
@available(iOS 13.0, *)
public func withAnimation<Result>(_ animation: Animation? = .default,
                                  completionCriteria: AnimationCompletionCriteria = .logicallyComplete,
                                  _ body: () throws -> Result,
                                  completion: @escaping () -> Void) rethrows -> Result {
    var transaction = Transaction(animation: animation)
    transaction.addAnimationCompletion(criteria: completionCriteria, completion)
    return try withTransaction(transaction) {
        try body()
    }
}


