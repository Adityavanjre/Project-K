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
    
    /// Adds insets to hit-testable content like ``Text``, ``Image``, ``Color``
    /// ``UIViewRepresentable``, ``ScrollView``,
    /// ``View/contentShape(_:eoFill:)``, etc.
    ///
    /// - Parameter insets: ``EdgeInsets``? The insets applied to the
    ///     hit-testable content. Positive values make the hit-testable area
    ///     smaller, and negative values make it larger.
    ///
    public func hitTestInsets(_ insets: EdgeInsets?) -> some View {
        modifier(HitTestInsetsViewModifier(edgeInsets: insets))
    }
    
}

@available(iOS 13.0, *)
internal struct HitTestInsetsViewModifier: ViewInputsModifier, UnaryViewModifier, PrimitiveViewModifier {
    
    internal let edgeInsets: EdgeInsets?
    
    internal static func _makeViewInputs(modifier: _GraphValue<Self>, inputs: inout _ViewInputs) {
        @Attribute(CompositeHitTestInsets(inherited: inputs.hitTestInsets, modifier: modifier.value))
        var hitTestInsets: EdgeInsets?
        inputs.hitTestInsets = $hitTestInsets
    }
}

@available(iOS 13.0, *)
private struct HitTestInsetsKey: ViewInput {
    
    fileprivate static var defaultValue: Attribute<EdgeInsets?>? {
        nil
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var hitTestInsets: Attribute<EdgeInsets?>? {
        get {
            self[HitTestInsetsKey.self]
        }
        set {
            self[HitTestInsetsKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct CompositeHitTestInsets: Rule {
    
    // Yes, double question mark is intended.
    // We need an Optional<EdgeInsets> which offered by an OptionalAttribute.
    @OptionalAttribute
    internal var inherited: EdgeInsets??
    
    @Attribute
    internal var modifier: HitTestInsetsViewModifier
    
    @inline(__always)
    internal init(inherited: Attribute<EdgeInsets?>?, modifier: Attribute<HitTestInsetsViewModifier>) {
        self._inherited = OptionalAttribute(inherited)
        self._modifier = modifier
    }
    
    internal var value: EdgeInsets? {
        let inherited = inherited?.map({$0})
        let edgeInsets = modifier.edgeInsets
        switch (inherited, edgeInsets) {
        case (.some(let lhs), .some(let rhs)):
            return lhs + rhs
        case (.some(let lhs), .none):
            return lhs
        case (.none, .some(let rhs)):
            return rhs
        default:
            return nil
        }
    }
    
}
