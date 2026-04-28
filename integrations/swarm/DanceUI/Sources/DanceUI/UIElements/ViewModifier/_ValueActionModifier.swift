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

private protocol ValueActionModifierProtocol {
    
    associatedtype Value: Equatable
    
    var value: Value { get }
}


@frozen
@available(iOS 13.0, *)
public struct _ValueActionModifier<Value: Equatable> : PrimitiveViewModifier, ValueActionModifierProtocol {
    
    public typealias Body = Never
    
    public var value: Value
    
    public var action: (Value, Value) -> Void
    
    @inlinable
    public init(value: Value, action: @escaping (Value) -> Void) {
        (self.value, self.action) = (value, { _, newValue in action(newValue) })
    }
    
    @inlinable
    internal init(value: Value, action: @escaping () -> Void) {
        self.init(value: value, action: { _, _ in action() })
    }
    
    @inlinable
    internal init(value: Value, action: @escaping (Value, Value) -> Void) {
        (self.value, self.action) = (value, action)
    }
    
    public static func _makeViewList(modifier: _GraphValue<_ValueActionModifier<Value>>,
                                     inputs: _ViewListInputs,
                                     body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        
        
        let dispatcher = ValueActionDispatcher(
            modifier: modifier.value,
            phase: inputs.base.phase,
            oldValue: nil,
            lastResetSeed: 0
        )
        
        let attribute = Attribute(dispatcher)
        
        attribute.flags = .active
        
        return body(_Graph(), inputs)
    }
    
    public static func _makeView(modifier: _GraphValue<_ValueActionModifier<Value>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let dispatcher = ValueActionDispatcher(
            modifier: modifier.value,
            phase: inputs.base.phase,
            oldValue: nil,
            lastResetSeed: 0
        )
        
        let attribute = Attribute(dispatcher)
        
        attribute.flags = .active
        
        return body(_Graph(), inputs)
    }
}

@available(iOS 13.0, *)
internal struct ValueActionDispatcher<A: Equatable>: StatefulRule {
    
    internal typealias Value = Void
    
    @Attribute
    internal var modifier: _ValueActionModifier<A>

    @Attribute
    internal var phase: _GraphInputs.Phase

    internal var oldValue: _ValueActionModifier<A>?

    internal var lastResetSeed: UInt32

    internal var cycleDetector = UpdateCycleDetector()
    
    internal mutating func updateValue() {
        
        resetIfNeeded(phase: phase, reset: &lastResetSeed) {
            oldValue = nil
            cycleDetector.reset()
        }
        
        let newValue = modifier
        
        defer {
            oldValue = newValue
        }
        
        guard oldValue.map({$0.value == newValue.value}) == false else {
            return
        }
        
        guard cycleDetector.noCyclicUpdate(on: "onChange (of: \(A.self)) action", shouldLogCyclicUpdate: true) else {
            return
        }
        
        let modifier = oldValue ?? newValue
        
        Update.enqueueAction {
            newValue.action(modifier.value, newValue.value)
        }
    }
    
}
