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

    /// Sets whether this view should ignore the system Smart Invert setting.
    ///
    /// Use this modifier to suppress Smart Invert in a view that shouldn't
    /// be inverted. Or pass an `active` argument of `false` to begin following
    /// the Smart Invert setting again when it was previously disabled.
    ///
    /// - Parameter active: A true value ignores the system Smart Invert
    ///   setting. A false value follows the system setting.
    @inlinable
    public func accessibilityIgnoresInvertColors(_ active: Bool = true) -> some View {
        modifier(_AccessibilityIgnoresInvertColorsViewModifier(active: active))
    }

}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// Whether the system preference for Invert Colors is enabled.
    ///
    /// If this property's value is true then the display will be inverted.
    /// In these cases it may be needed for UI drawing to be adjusted to in
    /// order to display optimally when inverted.
    public var accessibilityInvertColors: Bool {
        self[AccessibilityInvertColorsKey.self]
    }
    
    public var _accessibilityInvertColors: Bool {
        get {
            self[AccessibilityInvertColorsKey.self]
        }
        set {
            self[AccessibilityInvertColorsKey.self] = newValue
        }
    }
    
    internal var ignoreInvertColorsFilterActive: Bool {
        get {
            self[IgnoreInvertColorsFilterActiveKey.self]
        }
        set {
            self[IgnoreInvertColorsFilterActiveKey.self] = newValue
        }
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _AccessibilityIgnoresInvertColorsViewModifier: PrimitiveViewModifier, MultiViewModifier {

    public var active: Bool
    
    @inlinable
    public init(active: Bool) {
        self.active = active
    }
    
    public static func _makeView(modifier: _GraphValue<_AccessibilityIgnoresInvertColorsViewModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let child = ChildModifier(modifier: modifier.value, environment: inputs.environment)
        let childEnvironment = ChildEnvironment(modifier: modifier.value, environment: inputs.environment)
        var newInputs = inputs
        newInputs.updateCachedEnvironment(MutableBox(CachedEnvironment(Attribute(childEnvironment))))
        return IgnoreColorInvertEffect.makeRendererEffect(
            effect: _GraphValue(child),
            inputs: newInputs,
            body: body
        )
    }
    
    
    private struct ChildModifier: Rule {

        @Attribute
        private var modifier: _AccessibilityIgnoresInvertColorsViewModifier

        @Attribute
        private var environment: EnvironmentValues
        
        fileprivate init(modifier: Attribute<_AccessibilityIgnoresInvertColorsViewModifier>, environment: Attribute<EnvironmentValues>) {
            self._modifier = modifier
            self._environment = environment
        }

        fileprivate var value: IgnoreColorInvertEffect {
            let environment = environment
            guard environment.accessibilityInvertColors else {
                return IgnoreColorInvertEffect(applyFilter: false)
            }
            return IgnoreColorInvertEffect(
                applyFilter: environment.ignoreInvertColorsFilterActive != modifier.active
            )
        }
        
    }
    
    
    private struct ChildEnvironment: Rule {

        @Attribute
        private var modifier: _AccessibilityIgnoresInvertColorsViewModifier

        @Attribute
        private var environment: EnvironmentValues
        
        fileprivate init(modifier: Attribute<_AccessibilityIgnoresInvertColorsViewModifier>, environment: Attribute<EnvironmentValues>) {
            self._modifier = modifier
            self._environment = environment
        }
        
        fileprivate var value: EnvironmentValues {
            var environment = environment
            if environment.accessibilityInvertColors {
                environment.ignoreInvertColorsFilterActive = modifier.active
            } else {
                environment.ignoreInvertColorsFilterActive = false
            }
            return environment
        }

    }

}

@available(iOS 13.0, *)
fileprivate struct IgnoreColorInvertEffect: Equatable, RendererEffect {

    private let applyFilter: Bool
    
    fileprivate init(applyFilter: Bool) {
        self.applyFilter = applyFilter
    }
    
    fileprivate func effectValue(size: CGSize) -> DisplayList.Effect {
        guard applyFilter else {
            return .identity
        }
        return .filter(.colorInvert)
    }

}

@available(iOS 13.0, *)
fileprivate struct IgnoreInvertColorsFilterActiveKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Bool { false }

}

@available(iOS 13.0, *)
fileprivate struct AccessibilityInvertColorsKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Value { false }
    
}
