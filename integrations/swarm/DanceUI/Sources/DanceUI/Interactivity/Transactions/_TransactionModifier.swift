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

@frozen
@available(iOS 13.0, *)
public struct _PushPopTransactionModifier<Content> : PrimitiveViewModifier, MultiViewModifier where Content : ViewModifier {
    
    public var content: Content
    public var base: _TransactionModifier
    
    @inlinable
    public init(content: Content, transform: @escaping (inout Transaction) -> Swift.Void) {
        self.content = content
        base = .init(transform: transform)
    }
    
    public static func _makeView(modifier: _GraphValue<_PushPopTransactionModifier<Content>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let transactionModifier = modifier[ {.of(&$0.base)} ]
        
         var newInputs = inputs
        
        newInputs.withMutableGraphInputs { base in
            base.pushTransaction(false)
            _TransactionModifier._makeInputs(modifier: transactionModifier, inputs: &base)
        }
        
        let contentModifier = modifier[\.content]
        
        return Content.makeDebuggableViewModifier(value: contentModifier, inputs: newInputs) { g, inputs in
            var newInputs = inputs
            newInputs.withMutableGraphInputs { base in
                base.popTransaction()
            }
            return body(g, newInputs)
        }
    }
}

@frozen
@available(iOS 13.0, *)
public struct _TransactionModifier : ViewModifier, _GraphInputsModifier {

    public typealias Body = Never

    public var transform: (inout Transaction) -> Void
    
    @inlinable
    public init(transform: @escaping (inout Transaction) -> Void) {
        self.transform = transform
    }
    
    public static func _makeInputs(modifier: _GraphValue<_TransactionModifier>, inputs: inout _GraphInputs) {
        inputs.transaction = Attribute(ChildTransaction(modifier: modifier.value, transaction: inputs.transaction))
    }
    
}

@frozen 
@available(iOS 13.0, *)
public struct _ValueTransactionModifier<Value: Equatable>: ViewModifier, _GraphInputsModifier {
    
    public typealias Body = Never
    
    public var value: Value
    
    public var transform: TransformWrapper
    
    @inlinable
    public init(value: Value,
                transform: @escaping (inout Transaction) -> Void) {
        self.value = value
        self.transform = TransformWrapper(transform: transform)
    }
    
    public static func _makeInputs(modifier: _GraphValue<_ValueTransactionModifier<Value>>,
                                   inputs: inout _GraphInputs) {
        inputs.transaction = Attribute(ChildValueTransaction(value: modifier[ {.of(&$0.value)} ].value,
                                                             transform: modifier[ {.of(&$0.transform)} ].value,
                                                             transaction: inputs.transaction,
                                                             updateSeed: ViewGraph.current.$updateSeed))
    }
    
}

@available(iOS 13.0, *)
private struct ChildTransaction: Rule {
    
    fileprivate typealias Value = Transaction
    
    @Attribute
    fileprivate var modifier: _TransactionModifier
    
    @Attribute
    fileprivate var transaction: Transaction
    
    fileprivate var value: Value {
        var copiedTransaction = transaction
        modifier.transform(&copiedTransaction)
        return copiedTransaction

    }
}

@available(iOS 13.0, *)
public struct TransformWrapper {
    
    @usableFromInline
    internal var transform: (inout Transaction) -> Void
    
    @usableFromInline
    internal init(transform: @escaping (inout Transaction) -> Void) {
        self.transform = transform
    }
}

@available(iOS 13.0, *)
private struct ChildValueTransaction<Value: Equatable>: StatefulRule {
    
    internal typealias Value = Transaction
    
    @Attribute
    private var value: Value
    
    @Attribute
    private var transform: TransformWrapper

    @Attribute
    private var transaction: Transaction

    @Attribute
    private var updateSeed: UInt32

    private var oldValue: Value?

    private var oldSeed: UInt32?
    
    fileprivate init(value: Attribute<Value>,
                  transform: Attribute<TransformWrapper>,
                  transaction: Attribute<Transaction>,
                  updateSeed: Attribute<UInt32>) {
        self._value = value
        self._transform = transform
        self._transaction = transaction
        self._updateSeed = updateSeed
        self.oldValue = nil
        self.oldSeed = nil
    }
    
    internal mutating func updateValue() {
        let (value, isValueChanged) = _value.changedValue()
        var newTransaction = transaction
        defer {
            self.value = newTransaction
        }
        guard isValueChanged || (self.oldSeed.map({$0 == updateSeed}) ?? false) else {
            return
        }
        
        self.oldSeed = nil
        if oldValue != value {
            transform.transform(&newTransaction)
            self.value = newTransaction
            self.oldSeed = updateSeed
        }
        oldValue = value
    }
    
}



@available(iOS 13.0, *)
extension View {
    
    /// Applies the given transaction mutation function to all animations used
    /// within the view.
    ///
    /// Use this modifier to change or replace the animation used in a view.
    /// Consider three identical animations controlled by a
    /// button that executes all three animations simultaneously:
    ///
    ///  * The first animation rotates the "Rotation" ``Text`` view by 360
    ///    degrees.
    ///  * The second uses the `transaction(_:)` modifier to change the
    ///    animation by adding a delay to the start of the animation
    ///    by two seconds and then increases the rotational speed of the
    ///    "Rotation\nModified" ``Text`` view animation by a factor of 2.
    ///  * The third animation uses the `transaction(_:)` modifier to
    ///    replace the rotation animation affecting the "Animation\nReplaced"
    ///    ``Text`` view with a spring animation.
    ///
    /// The following code implements these animations:
    ///
    ///     struct TransactionExample: View {
    ///         @State private var flag = false
    ///
    ///         var body: some View {
    ///             VStack(spacing: 50) {
    ///                 HStack(spacing: 30) {
    ///                     Text("Rotation")
    ///                         .rotationEffect(Angle(degrees:
    ///                                                 self.flag ? 360 : 0))
    ///
    ///                     Text("Rotation\nModified")
    ///                         .rotationEffect(Angle(degrees:
    ///                                                 self.flag ? 360 : 0))
    ///                         .transaction { view in
    ///                             view.animation =
    ///                                 view.animation?.delay(2.0).speed(2)
    ///                         }
    ///
    ///                     Text("Animation\nReplaced")
    ///                         .rotationEffect(Angle(degrees:
    ///                                                 self.flag ? 360 : 0))
    ///                         .transaction { view in
    ///                             view.animation = .interactiveSpring(
    ///                                 response: 0.60,
    ///                                 dampingFraction: 0.20,
    ///                                 blendDuration: 0.25)
    ///                         }
    ///                 }
    ///
    ///                 Button("Animate") {
    ///                     withAnimation(.easeIn(duration: 2.0)) {
    ///                         self.flag.toggle()
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// Use this modifier on leaf views such as ``Image`` or ``Button`` rather
    /// than container views such as ``VStack`` or ``HStack``. The
    /// transformation applies to all child views within this view; calling
    /// `transaction(_:)` on a container view can lead to unbounded scope of
    /// execution depending on the depth of the view hierarchy.
    ///
    /// - Parameter transform: The transformation to apply to transactions
    ///   within this view.
    ///
    /// - Returns: A view that wraps this view and applies a transformation to
    ///   all transactions used within the view.
    @inlinable
    public func transaction(_ transform: @escaping (inout Transaction) -> Void) -> some View {
        modifier(_TransactionModifier(transform: transform))
    }
    
    /// Applies the given transaction mutation function to all animations used
    /// within the view.
    ///
    /// Use this modifier to change or replace the animation used in a view.
    /// Consider three identical views controlled by a
    /// button that changes all three simultaneously:
    ///
    ///  * The first view animates rotating the "Rotation" ``Text`` view by 360
    ///    degrees.
    ///  * The second uses the `transaction(_:)` modifier to change the
    ///    animation by adding a delay to the start of the animation
    ///    by two seconds and then increases the rotational speed of the
    ///    "Rotation\nModified" ``Text`` view animation by a factor of 2.
    ///  * The third uses the `transaction(_:)` modifier to disable animations
    ///    affecting the "Animation\nReplaced" ``Text`` view.
    ///
    /// The following code implements these animations:
    ///
    ///     struct TransactionExample: View {
    ///         @State var flag = false
    ///
    ///         var body: some View {
    ///             VStack(spacing: 50) {
    ///                 HStack(spacing: 30) {
    ///                     Text("Rotation")
    ///                         .rotationEffect(Angle(degrees: flag ? 360 : 0))
    ///
    ///                     Text("Rotation\nModified")
    ///                         .rotationEffect(Angle(degrees: flag ? 360 : 0))
    ///                         .transaction(value: flag) { t in
    ///                             t.animation =
    ///                                 t.animation?.delay(2.0).speed(2)
    ///                         }
    ///
    ///                     Text("Animation\nReplaced")
    ///                         .rotationEffect(Angle(degrees: flag ? 360 : 0))
    ///                         .transaction(value: flag) { t in
    ///                             t.disableAnimations = true
    ///                         }
    ///                 }
    ///
    ///                 Button("Animate") {
    ///                     withAnimation(.easeIn(duration: 2.0)) {
    ///                         flag.toggle()
    ///                     }
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - value: A value to monitor for changes.
    ///   - transform: The transformation to apply to transactions
    ///     within this view.
    ///
    /// - Returns: A view that wraps this view and applies a transformation to
    ///   all transactions used within the view whenever `value` changes.
    @available(iOS 13.0, *)
    @_alwaysEmitIntoClient
    @inlinable
    public func transaction(value: some Equatable,
                            _ transform: @escaping (inout Transaction) -> Void) -> some View {
        modifier(_ValueTransactionModifier(value: value, 
                                           transform: transform))
    }
    
    /// Applies the given animation to all animatable values within this view.
    ///
    /// Use this modifier on leaf views rather than container views. The
    /// animation applies to all child views within this view; calling
    /// `animation(_:)` on a container view can lead to unbounded scope.
    ///
    /// - Parameter animation: The animation to apply to animatable values
    ///   within this view.
    ///
    /// - Returns: A view that wraps this view and applies `animation` to all
    ///   animatable values used within the view.
    @available(iOS, deprecated: 100000.0, message: "Use withAnimation or animation(_:value:) instead.")
    @inlinable
    public func animation(_ animation: Animation?) -> some View {
        return self.transaction { t in
            if !t.disablesAnimations {
                t.animation = animation
            }
        }
    }
}
