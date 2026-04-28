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
import Foundation

@available(iOS 13.0, *)
internal struct ShapeStyleResolver<StyleType: ShapeStyle>: StatefulRule, ObservedAttribute {
    
    internal typealias Value = _ShapeStyle_Shape.ResolvedStyle
    
    @OptionalAttribute
    internal var style: StyleType?
    
    @OptionalAttribute
    internal var mode: ShapeStyle_ResolverMode?
    
    @Attribute
    internal var environment: EnvironmentValues
    
    internal var role: ShapeRole
    
    internal var animationsDisabled: Bool
    
    internal var helper: AnimatableAttributeHelper<_ShapeStyle_Shape.ResolvedStyle>
    
    internal let tracker: PropertyList.Tracker = .init()
    
    internal mutating func updateValue() {
        
        let styleTupleValue = $style?.changedValue()
        
        let styleValue = styleTupleValue?.value
        
        let styleChange = styleTupleValue?.changed ?? false
        
        let (environmentValues, isEnvironmentValueChanged) = _environment.changedValue()
        
        let isEnvironmentChanged = isEnvironmentValueChanged && environmentValues.hasDifferentUsedValues(with: tracker)
        
        let hasAnimatorState = helper.animatorState != nil
        
        var maxLevels: Int = 1
        
        var modeChange: Bool = false
        
        if let (modeValue, isModeChange) = $mode?.changedValue() {
            modeChange = isModeChange
            switch modeValue {
            case .maxLevels(let value),
                 .maxOpacities(let value):
                maxLevels = Int(value & 0xffff)
            default:
                break
            }
        }
        
        let shouldUpdateValue = styleChange || modeChange || !hasValue || isEnvironmentChanged
        
        if shouldUpdateValue || hasAnimatorState || helper.checkReset() {
            let newEnvironments = environmentValues.withTracker(tracker)
            var initShape = _ShapeStyle_Shape(operation: .resolveStyle(0..<maxLevels),
                                              result: .none,
                                              environment: newEnvironments,
                                              bounds: nil,
                                              role: self.role,
                                              inRecursiveStyle: false)
            
            if let shapeStyle = styleValue {
                _apply(shapeStyle: shapeStyle, shape: &initShape, mode: self.mode)
            } else {
                let foregroundStyle = ForegroundStyle()
                _applyForegroundStyle(foregroundStyle: foregroundStyle, shape: &initShape, mode: self.mode)
            }
            
            guard case .resolved(var resolvedStyle) = initShape.result else {
                self.value = .color(Color.Resolved.init())
                return
            }
            
            // TODO: _notImplemented ShapeStyleResolver.updateValue for self.mode is not nil
//            if let mode = self.mode,
//               case .maxOpacities(let value) = mode {
//                
//            }
            
            var animationsDisabled = self.animationsDisabled
            
            if !animationsDisabled {
                var resolvedStyleTupleValue: (value: _ShapeStyle_Shape.ResolvedStyle, changed: Bool) = (resolvedStyle, true)
                helper.update(value: &resolvedStyleTupleValue, environment: _environment)
                animationsDisabled = resolvedStyleTupleValue.changed
                resolvedStyle = resolvedStyleTupleValue.value
            }
            
            if shouldUpdateValue || hasAnimatorState || animationsDisabled {
                self.value = resolvedStyle
            }
        }
    }
    
    internal mutating func destroy() {
        helper.removeListeners()
    }
    
    private func _applyForegroundStyle(foregroundStyle: ForegroundStyle,
                                       shape: inout _ShapeStyle_Shape,
                                       mode: ShapeStyle_ResolverMode?) {
        if let modeValue = mode,
           case .multicolor(_) = modeValue {
            
            guard case .resolveStyle = shape.operation else {
                return
            }
            
            foregroundStyle._apply(to: &shape)
            
            guard case .resolved = shape.result else {
                return
            }
            
            // TODO: _notImplemented ResolvedMulticolorStyle in _applyForegroundStyle unused
//            let resolvedMulticolorStyle = ResolvedMulticolorStyle(in: shape.environment, bundle: bundle)
//            shape.result = .resolved(.array([.multicolor(resolvedMulticolorStyle)]))
        } else {
            if shape.inRecursiveStyle {
                LegacyContentStyle.sharedPrimary._apply(to: &shape)
            } else {
                shape.inRecursiveStyle = true
                let resolvedForegroundStyle = shape.environment.effectiveForegroundStyle
                resolvedForegroundStyle._apply(to: &shape)
                shape.inRecursiveStyle = false
            }
        }
    }
    
    private func _apply(shapeStyle: StyleType,
                        shape: inout _ShapeStyle_Shape,
                        mode: ShapeStyle_ResolverMode?) {
        if let modeValue = mode,
           case .multicolor(_) = modeValue {
            // TODO: _notImplemented MulticolorSymbolStyle in _apply unused
//            let mutileColorStyle = MulticolorSymbolStyle(base: shapeStyle, bundle: bundle)
//            mutileColorStyle._apply(to: &shape)
        } else {
            shapeStyle._apply(to: &shape)
        }
    }
}

@available(iOS 13.0, *)
internal enum ShapeStyle_ResolverMode: Equatable {
    
    case maxLevels(UInt16)
    
    case maxOpacities(UInt16)
    
    case multicolor(Bundle?)
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal var effectiveForegroundStyle: AnyShapeStyle {
        if let foregroundStyle = self.foregroundStyle {
            return foregroundStyle
        }
        
        if let defaultForegroundStyle = self.defaultForegroundStyle {
            return defaultForegroundStyle
        }
        
        return HierarchicalShapeStyle.sharedPrimary
    }
    
    @inline(__always)
    internal var foregroundStyle: AnyShapeStyle? {
        get {
            self[ForegroundStyleKey.self]
        }
        
        set {
            self[ForegroundStyleKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var defaultForegroundStyle: AnyShapeStyle? {
        get {
            self[DefaultForegroundStyleKey.self]
        }
        
        set {
            self[DefaultForegroundStyleKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct ForegroundStyleKey: EnvironmentKey {
    
    fileprivate typealias Value = AnyShapeStyle?
    
    fileprivate static var defaultValue: AnyShapeStyle? {
        nil
    }
}

@available(iOS 13.0, *)
private struct DefaultForegroundStyleKey: EnvironmentKey {
    
    fileprivate typealias Value = AnyShapeStyle?
    
    fileprivate static var defaultValue: AnyShapeStyle? {
        nil
    }
}
