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
    
    @inlinable
    public func hidden() -> some View {
        return modifier(_HiddenModifier())
    }
    
    @inline(__always)
    internal func hiddenAllowingAccessibility() -> some View {
        return modifier(HiddenModifierAllowingAccessibility())
    }
    
    @inline(__always)
    internal func hiddenAllowingPlatformItemList() -> some View {
        return modifier(HiddenModifierAllowingPlatformItemList())
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _HiddenModifier: PrimitiveViewModifier, MultiViewModifier {
    
    public typealias Body = Never
    
    @inlinable
    public init() {
        
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeHiddenView(inputs: inputs, body: body)
    }
    
}

@available(iOS 13.0, *)
internal struct HiddenModifierAllowingAccessibility: PrimitiveViewModifier, MultiViewModifier {
    
    internal typealias Body = Never
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeHiddenView(allowedKeys: .accessibility, inputs: inputs, body: body)
    }
    
}

@available(iOS 13.0, *)
internal struct HiddenModifierAllowingPlatformItemList: PrimitiveViewModifier, MultiViewModifier {
    
    internal typealias Body = Never
    
    internal static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeHiddenView(allowedKeys: .platformItemList, inputs: inputs, body: body)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct AllowedPreferenceKeys: OptionSet {

    fileprivate let rawValue: Int
    
    fileprivate static let accessibility = AllowedPreferenceKeys(rawValue: 0x1)
    
    fileprivate static let platformItemList = AllowedPreferenceKeys(rawValue: 0x2)

}

@available(iOS 13.0, *)
fileprivate func makeHiddenView(
    allowedKeys: AllowedPreferenceKeys = AllowedPreferenceKeys(),
    inputs: _ViewInputs,
    body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
    
    var keys = inputs.preferences.keys
    keys.removeHiddenKeys(allowing: allowedKeys)
    
    let map = DanceUIGraph.Map<PreferenceKeys, PreferenceKeys>(inputs.preferences.hostKeys) { keys in
        var copied = keys
        copied.removeHiddenKeys(allowing: allowedKeys)
        return copied
    }
    
    var newInputs = inputs
    
    newInputs.preferences = PreferencesInputs(keys: keys, hostKeys: Attribute(map))
    
    return body(_Graph(), newInputs)
}

@available(iOS 13.0, *)
extension PreferenceKeys {
    
    fileprivate mutating func removeHiddenKeys(allowing keys: AllowedPreferenceKeys) {
        remove(DisplayList.Key.self)
        remove(ViewRespondersKey.self)
        if !keys.contains(.accessibility) {
            remove(AccessibilityNodesKey.self)
        }
        if !keys.contains(.platformItemList) {
            remove(PlatformItemList.Key.self)
        }
    }
    
}
