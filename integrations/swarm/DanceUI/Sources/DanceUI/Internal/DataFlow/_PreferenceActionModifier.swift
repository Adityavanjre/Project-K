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
    
    /// Adds an action to perform when the specified preference key's value
    /// changes.
    ///
    /// - Parameters:
    ///   - key: The key to monitor for value changes.
    ///   - action: The action to perform when the value for `key` changes. The
    ///     `action` closure passes the new value as its parameter.
    ///
    /// - Returns: A view that triggers `action` when the value for `key`
    ///   changes.
    @inlinable
    public func onPreferenceChange<K: PreferenceKey>(_ key: K.Type = K.self, perform action: @escaping (K.Value) -> Void) -> some View where K.Value : Equatable {
        modifier(_PreferenceActionModifier<K>(action: action))
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _PreferenceActionModifier<Key: PreferenceKey> : PrimitiveViewModifier, MultiViewModifier where Key.Value : Equatable {
    
    public typealias Body = Never
    
    public var action: (Key.Value) -> Void
    
    @inlinable
    public init(action: @escaping (Key.Value) -> Void) {
        self.action = action
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        var bodyInputs = inputs
        
        bodyInputs.preferences.add(Key.self)
        
        let outputs = body(_Graph(), bodyInputs)
        
        if let value = outputs[Key.self] {
            
            let attr = Attribute(PreferenceBinder<Key>(modifier: modifier.value, keyValue: value, phase: inputs.phase, lastResetSeed: 0, lastValue: nil))
            
            attr.setFlags(.active, mask: .reserved)
            
        }
        
        return outputs
    }

}

@available(iOS 13.0, *)
private struct PreferenceBinder<Key: PreferenceKey>: StatefulRule where Key.Value: Equatable {

    fileprivate typealias Value = Void

    fileprivate typealias PreferenceValue = Key.Value

    @Attribute
    fileprivate var modifier: _PreferenceActionModifier<Key>

    @Attribute
    fileprivate var keyValue: PreferenceValue

    @Attribute
    fileprivate var phase: _GraphInputs.Phase
    
    fileprivate var cycleDetector = UpdateCycleDetector()
    
    fileprivate var lastResetSeed: UInt32
    
    fileprivate var lastValue: PreferenceValue?
    
    fileprivate mutating func updateValue() {
        
        resetIfNeeded(phase: phase, reset: &lastResetSeed) {
            lastValue = nil
            cycleDetector.reset()
        }

        let (value, hasValueChanged) = $keyValue.changedValue()

        guard hasValueChanged && self.lastValue != value else {
            return
        }

        self.lastValue = value

        guard cycleDetector.noCyclicUpdate(on: "Bound preference \(Key.self)", shouldLogCyclicUpdate: true) else {
            return
        }
        
        let modifier = DGGraphRef.withoutUpdate {
            self.modifier
        }
        
        Update.enqueueAction {
            modifier.action(value)
        }
        
    }
    
}
