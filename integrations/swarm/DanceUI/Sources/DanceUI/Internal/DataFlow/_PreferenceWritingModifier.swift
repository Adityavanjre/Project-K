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

@available(iOS 13.0, *)
extension View {
    
    /// Sets a value for the given preference.
    @inlinable
    public func preference<K: PreferenceKey>(key: K.Type = K.self, value: K.Value) -> some View {
        return modifier(_PreferenceWritingModifier<K>(value: value))
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _PreferenceWritingModifier<Key: PreferenceKey> : PrimitiveViewModifier, MultiViewModifier {
    
    public typealias Body = Never
    
    public var value: Key.Value
    
    @inlinable
    public init(key: Key.Type = Key.self, value: Key.Value) {
        self.value = value
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var childInputs = inputs
        childInputs.preferences.remove(Key.self)
        var outputs = body(_Graph(), childInputs)
        outputs.makePreferenceWriter(inputs: inputs, key: Key.self, value: modifier[{.of(&$0.value)}].value)
        return outputs
    }
    
}

@available(iOS 13.0, *)
extension _PreferenceWritingModifier: Equatable where Key.Value : Equatable {
    
    public static func == (a: _PreferenceWritingModifier<Key>, b: _PreferenceWritingModifier<Key>) -> Bool {
        return a.value == b.value
    }
    
}
