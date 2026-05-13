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
    
    /// Applies the given animation to this view when the specified value
    /// changes.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply. If `animation` is `nil`, the view
    ///     doesn't animate.
    ///   - value: A value to monitor for changes.
    ///
    /// - Returns: A view that applies `animation` to this view whenever `value`
    ///   changes.
    @inlinable
    public func animation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        return modifier(_AnimationModifier(animation: animation, value: value))
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _AnimationModifier<Value: Equatable> : ViewModifier, Equatable {
    
    public var animation: Animation?
    
    public var value: Value
    
    public typealias Body = Never
    
    @inlinable
    public init(animation: Animation?, value: Value) {
        self.animation = animation
        self.value = value
    }
    
    public static func _makeView(modifier: _GraphValue<_AnimationModifier<Value>>,
                                   inputs: _ViewInputs,
                                   body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.withMutableGraphInputs { base in
            _makeInputs(modifier: modifier, inputs: &base)
        }
        return body(_Graph(), newInputs)
    }
    
    public static func _makeViewList(modifier: _GraphValue<_AnimationModifier<Value>>,
                                       inputs: _ViewListInputs,
                                       body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        var newInputs = inputs
        newInputs.withMutableGraphInputs { base in
            _makeInputs(modifier: modifier, inputs: &base)
        }
        return body(_Graph(), newInputs)
    }
    
    internal static func _makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs) {
        let childTransaction = Attribute(ChildTransaction<Value>(value: modifier[{.of(&$0.value)}].value,
                                                                              animation: modifier[{.of(&$0.animation)}].value,
                                                                              transaction: inputs.transaction,
                                                                              updateSeed: ViewGraph.current.$updateSeed))
        inputs.transaction = childTransaction
        childTransaction.setFlags(.active, mask: .reserved)
    }
    
}

@available(iOS 13.0, *)
private struct ChildTransaction<Value: Equatable>: StatefulRule { // 608D829EB950CB571DD19875A3544F88
    
    fileprivate typealias Value = Transaction
    
    @Attribute
    fileprivate var value: Value
    
    @Attribute
    fileprivate var animation: Animation?
    
    @Attribute
    fileprivate var transaction: Transaction
    
    @Attribute
    fileprivate var updateSeed: UInt32
    
    fileprivate var oldValue: Value?
    
    fileprivate var oldSeed: UInt32?
    
    fileprivate mutating func updateValue() {
        let (value, isValueChanged) = $value.changedValue()
        var transaction = transaction
        defer {
            context.value = transaction
        }
        guard isValueChanged || oldSeed.map({ $0 != updateSeed }) ?? false else {
            return
        }
        
        if let oldValue = oldValue, !transaction.disablesAnimations, oldValue != value {
            transaction.animation = self.animation
            oldSeed = updateSeed
        }
        
        oldValue = value
    }

}
