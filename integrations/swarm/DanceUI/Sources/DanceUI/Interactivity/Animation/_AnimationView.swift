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
public struct _AnimationView<Content: View & Equatable>: PrimitiveView {
    
    internal var content: Content
    
    internal var animation: Animation?
    
    public init(content: Content,
                animation: Animation? = nil) {
        self.content = content
        self.animation = animation
    }
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        
        var contentInputs = inputs
        let contentGraphValue = contentInputs.withMutableGraphInputs { base in
            _makeInputs(view: view, inputs: &base)
        }
        
        let outputs = Content._makeView(view: contentGraphValue, inputs: contentInputs)
        return outputs
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        var contentInputs = inputs
        let contentGraphValue = contentInputs.withMutableGraphInputs { base in
            _makeInputs(view: view, inputs: &base)
        }
        let outputs = Content._makeViewList(view: contentGraphValue, inputs: contentInputs)
        return outputs
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
    
    private static func _makeInputs(view: _GraphValue<Self>, inputs: inout _GraphInputs) -> _GraphValue<Content> {
        let viewGraph = ViewGraph.current
        let content = view[{ .of(&$0.content) }]
        let childTransaction = ChildTransaction(value: content.value,
                                                animation:  view[{ .of(&$0.animation) }].value,
                                                transaction: inputs.transaction,
                                                updateSeed: viewGraph.$updateSeed,
                                                oldValue: nil,
                                                oldSeed: .max)
        let transaction = Attribute(childTransaction)
        inputs.transaction = transaction
        transaction.flags = .init([.active])
        return content
    }
    
}

@available(iOS 13.0, *)
private struct ChildTransaction<Content: Equatable>: StatefulRule {
    
    fileprivate typealias Value = Transaction
    
    @Attribute
    private var value: Content

    @Attribute
    private var animation: Animation?

    @Attribute
    private var transaction: Transaction

    @Attribute
    private var updateSeed: UInt32

    private var oldValue: Content?

    private var oldSeed: UInt32?
    
    internal init(value: Attribute<Content>,
                  animation: Attribute<Animation?>,
                  transaction: Attribute<Transaction>,
                  updateSeed: Attribute<UInt32>,
                  oldValue: Content? = nil,
                  oldSeed: UInt32? = nil) {
        self._value = value
        self._animation = animation
        self._transaction = transaction
        self._updateSeed = updateSeed
        self.oldValue = oldValue
        self.oldSeed = oldSeed
    }
    
    fileprivate mutating func updateValue() {
        let (value, isValueChanged) = _value.changedValue()
        var transaction = self.transaction
        
        defer {
            self.value = transaction
        }
        
        guard isValueChanged || (self.oldSeed.map({$0 == updateSeed}) ?? false) else {
            return
        }
        
        self.oldSeed = nil
        if let oldValue = oldValue, !transaction.disablesAnimations, oldValue != value {
            transaction.animation = animation
            self.oldSeed = updateSeed
        }
        oldValue = value
    }
    
}

@available(iOS 13.0, *)
extension View where Self : Equatable {

    /// Applies the given animation to this view when this view changes.
    ///
    /// - Parameters:
    ///   - animation: The animation to apply. If `animation` is `nil`, the view
    ///     doesn't animate.
    ///
    /// - Returns: A view that applies `animation` to this view whenever it
    ///   changes.
    @inlinable public func animation(_ animation: Animation?) -> some View {
        _AnimationView(content: self, animation: animation)
    }

}
