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
extension View {
    
    /// Sets a value for the specified preference key, the value is a
    /// function of a geometry value tied to the current coordinate
    /// space, allowing readers of the value to convert the geometry to
    /// their local coordinates.
    ///
    /// - Parameters:
    ///   - key: the preference key type.
    ///   - value: the geometry value in the current coordinate space.
    ///   - transform: the function to produce the preference value.
    ///
    /// - Returns: a new version of the view that writes the preference.
    @inlinable
    public func anchorPreference<A, K: PreferenceKey>(key _: K.Type = K.self,
                                                      value: Anchor<A>.Source,
                                                      transform: @escaping (Anchor<A>) -> K.Value) -> some View {
        let writingModifier = _AnchorWritingModifier<A, K>(anchor: value, transform: transform)
        return self.modifier(writingModifier)
    }
    
    /// Sets a value for the specified preference key, the value is a
    /// function of the key's current value and a geometry value tied
    /// to the current coordinate space, allowing readers of the value
    /// to convert the geometry to their local coordinates.
    ///
    /// - Parameters:
    ///   - key: the preference key type.
    ///   - value: the geometry value in the current coordinate space.
    ///   - transform: the function to produce the preference value.
    ///
    /// - Returns: a new version of the view that writes the preference.
    @inlinable
    public func transformAnchorPreference<A, K: PreferenceKey>(key _: K.Type = K.self,
                                                               value: Anchor<A>.Source,
                                                               transform: @escaping (inout K.Value, Anchor<A>) -> Void) -> some View {
        let transformModifier = _AnchorTransformModifier<A, K>(anchor: value, transform: transform)
        return self.modifier(transformModifier)
    }
}
