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

internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {

    /// Applies the given transaction mutation function to all animations used
    /// within the `body` closure.
    ///
    /// Any modifiers applied to the content of `body` will be applied to this
    /// view, and the changes to the transaction performed in the `transform`
    /// will only affect the modifiers defined in the `body`.
    ///
    /// The following code animates the opacity changing with a faster
    /// animation, while the contents of MyView are animated with the implicit
    /// transaction:
    ///
    ///     MyView(isActive: isActive)
    ///         .transaction { transaction in
    ///             transaction.animation = transaction.animation?.speed(2)
    ///         } body: { content in
    ///             content.opacity(isActive ? 1.0 : 0.0)
    ///         }
    ///
    /// - See Also: `Transaction.disablesAnimations`
    public func transaction<V: View>(_ transform: @escaping (inout Transaction) -> Void,
                                     @ViewBuilder body: (PlaceholderContentView<Self>) -> V) -> some View {
        modifier(CustomModifier(result: body(PlaceholderContentView<Self>())).transaction(transform))
    }


    /// Applies the given animation to all animatable values within the `body`
    /// closure.
    ///
    /// Any modifiers applied to the content of `body` will be applied to this
    /// view, and the `animation` will only be used on the modifiers defined in
    /// the `body`.
    ///
    /// The following code animates the opacity changing with an easeInOut
    /// animation, while the contents of MyView are animated with the implicit
    /// transaction's animation:
    ///
    ///     MyView(isActive: isActive)
    ///         .animation(.easeInOut) { content in
    ///             content.opacity(isActive ? 1.0 : 0.0)
    ///         }
    @inlinable
    public func animation<V: View>(_ animation: Animation?,
                                   @ViewBuilder body: (PlaceholderContentView<Self>) -> V) -> some View {
        self.transaction { t in
            t.animation = animation
        } body: { content in
            body(content)
        }
    }

}

@available(iOS 13.0, *)
private struct CustomModifier<R: View>: MultiViewModifier, PrimitiveViewModifier {
    
    fileprivate var result: R
    
    fileprivate static func _makeView(modifier: _GraphValue<CustomModifier<R>>,
                                      inputs: _ViewInputs, 
                                      body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.append(.view(body), for: BodyInput.self)
        let outputs = R.makeDebuggableView(value: modifier[\.result], inputs: newInputs)

        return outputs
    }
}
