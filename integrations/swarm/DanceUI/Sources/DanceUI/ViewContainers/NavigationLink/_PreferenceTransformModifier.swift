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
internal import DanceUIGraph

#warning("PrimitiveSceneModifier/PrimitiveWidgetConfigurationModifier")
@frozen
@available(iOS 13.0, *)
public struct _PreferenceTransformModifier<Key: PreferenceKey>: MultiViewModifier, PrimitiveViewModifier {

    public typealias Body = Never
    
    public var transform: (inout Key.Value) -> Void
    
    @inlinable
    public init(key _: Key.Type = Key.self, transform: @escaping (inout Key.Value) -> Void) {
        self.transform = transform
    }
    
    public static func _makeView(modifier: _GraphValue<_PreferenceTransformModifier<Key>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var outputs = body(_Graph(), inputs)
        outputs.preferences.makePreferenceTransformer(inputs: inputs.preferences, key: Key.self, transform: modifier[\.transform].value)
        return outputs
    }

}

@available(iOS 13.0, *)
extension View {
    
    /// Applies a transformation to a preference value.
    @inlinable
    public func transformPreference<K>(_ key: K.Type = K.self,
                                       _ callback: @escaping (inout K.Value) -> Void) -> some View where K : PreferenceKey {
        return modifier(_PreferenceTransformModifier<K>(transform: callback))
    }
    
}
