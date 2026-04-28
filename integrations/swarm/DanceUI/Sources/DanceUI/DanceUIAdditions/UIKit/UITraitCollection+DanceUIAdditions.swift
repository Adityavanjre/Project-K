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

import UIKit

@available(iOS 13.0, *)
extension UITraitCollection {
    
    internal func byOverriding(with environment: EnvironmentValues,
                               viewPhase: _GraphInputs.Phase = _GraphInputs.Phase(),
                               focusedValues: FocusedValues = FocusedValues()) -> UITraitCollection {
        let environmentWrapper = EnvironmentWrapper(
            environment: environment,
            phase: viewPhase,
            focusedValues: focusedValues
        )
        
        let environment = environmentWrapper.environment
        
        var traitCollections: [UITraitCollection] = [self]
        traitCollections.reserveCapacity(11)
        
        traitCollections.append(UITraitCollection(my__environmentWrapper: environmentWrapper))
        
        let environmentLayoutDirection = UITraitEnvironmentLayoutDirection(environment.layoutDirection)
        
        if environmentLayoutDirection != layoutDirection {
            traitCollections.append(UITraitCollection(layoutDirection: environmentLayoutDirection))
        }
        
        let environmentDisplayScale = environment.displayScale
        
        if environmentDisplayScale != displayScale {
            traitCollections.append(UITraitCollection(displayScale: environmentDisplayScale))
        }
        
        let environmentContentSizeCategory = UIContentSizeCategory(environment.preferredContentSizeCategory)
        
        if environmentContentSizeCategory != preferredContentSizeCategory {
            traitCollections.append(UITraitCollection(preferredContentSizeCategory: environmentContentSizeCategory))
        }
        
        if #available(iOS 12.0, *) {
            let environmentUserInterfaceStyle = UIUserInterfaceStyle(environment.colorScheme)
            if environmentUserInterfaceStyle != userInterfaceStyle {
                traitCollections.append(UITraitCollection(userInterfaceStyle: environmentUserInterfaceStyle))
            }
        } else {
            // Fallback on earlier versions
        }

        let environmentDisplayGamut = UIDisplayGamut(environment.displayGamut)
        
        if environmentDisplayGamut != displayGamut {
            traitCollections.append(UITraitCollection(displayGamut: environmentDisplayGamut))
        }
        
        if #available(iOS 13.0, *) {
            let environmentAccessibilityContrast = UIAccessibilityContrast(environment.colorSchemeContrast)
            
            if environmentAccessibilityContrast != accessibilityContrast {
                traitCollections.append(UITraitCollection(accessibilityContrast: environmentAccessibilityContrast))
            }
        } else {
            // Fallback on earlier versions
        }
        
        let environmentHozirontalSizeClass = UIUserInterfaceSizeClass(environment.horizontalSizeClass)
        
        if environmentHozirontalSizeClass != horizontalSizeClass {
            traitCollections.append(UITraitCollection(horizontalSizeClass: horizontalSizeClass))
        }
        
        let environmentVerticalSizeClass = UIUserInterfaceSizeClass(environment.verticalSizeClass)
        
        if environmentVerticalSizeClass != verticalSizeClass {
            traitCollections.append(UITraitCollection(verticalSizeClass: verticalSizeClass))
        }
        
        if #available(iOS 13.0, *) {
            let environmentUserInterfaceLevel = UIUserInterfaceLevel(rawValue: environment.backgroundInfo.layer)!
            
            if environmentUserInterfaceLevel != userInterfaceLevel {
                traitCollections.append(UITraitCollection(userInterfaceLevel: environmentUserInterfaceLevel))
            }
        } else {
            // Fallback on earlier versions
        }
        
        return UITraitCollection(traitsFrom: traitCollections)
    }
    

    internal func byMutating(gestureRecognizerObservers: GestureObservers = GestureObservers()) -> UITraitCollection {
        var envWrapper = my__environmentWrapper as? EnvironmentWrapper
        envWrapper?.gestureRecognizerObservers = gestureRecognizerObservers
        return self
    }
    
    internal var baseEnvironment: EnvironmentValues {
        guard let environmentWrapper = my__environmentWrapper as? EnvironmentWrapper else {
            var environment = EnvironmentValues()
            environment.locale = Locale.current
            return environment
        }
        return environmentWrapper.environment
    }
    

    internal var baseGestureRecognizerObservers: GestureObservers {
        guard let environmentWrapper = my__environmentWrapper as? EnvironmentWrapper else {
            return GestureObservers()
        }
        return environmentWrapper.gestureRecognizerObservers
    }
    
    internal var viewPhase: _GraphInputs.Phase {
        guard let environmentWrapper = my__environmentWrapper as? EnvironmentWrapper else {
            return _GraphInputs.Phase()
        }
        return environmentWrapper.phase
    }
    
    internal func resolvedEnvironment(base: EnvironmentValues) -> EnvironmentValues {
        var resolved = EnvironmentValues(base)
        
        resolved.layoutDirection = LayoutDirection(layoutDirection)
        
        if let contentSizeCategory = ContentSizeCategory(preferredContentSizeCategory) {
            resolved.preferredContentSizeCategory = contentSizeCategory
        }
        
        if #available(iOS 13.0, *) {
            if let legibilityWeight = LegibilityWeight(legibilityWeight) {
                resolved.legibilityWeight = legibilityWeight
            }
        }
        
        if let displayGamut = DisplayGamut(displayGamut) {
            resolved.displayGamut = displayGamut
        }
        
        if #available(iOS 13.0, *) {
            if let colorSchemeContrast = ColorSchemeContrast(accessibilityContrast) {
                resolved.colorSchemeContrast = colorSchemeContrast
            }
        } else {
            // Fallback on earlier versions
        }

        resolved.colorScheme = self.effectiveColorScheme
        
        resolved.displayScale = max(displayScale, 1)
        
        resolved.horizontalSizeClass = UserInterfaceSizeClass(horizontalSizeClass)
        
        resolved.verticalSizeClass = UserInterfaceSizeClass(verticalSizeClass)
        
        var backgroundInfo = resolved.backgroundInfo
        if #available(iOS 13.0, *) {
            backgroundInfo.layer = userInterfaceLevel.rawValue
        } else {
            // Fallback on earlier versions
        }
        
        resolved.backgroundInfo = backgroundInfo
        
        resolved._accessibilityReduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        
        resolved._accessibilityReduceMotion = UIAccessibility.isReduceMotionEnabled
        
        resolved._accessibilityInvertColors = UIAccessibility.isInvertColorsEnabled
        
        return resolved
    }
    
    internal var effectiveColorScheme: ColorScheme {
        guard #available(iOS 12, *) else {
            return .light
        }
        return ColorScheme(userInterfaceStyle)
    }
    
}

@objc(DanceUIEnvironmentWrapper)
@available(iOS 13.0, *)
private final class EnvironmentWrapper: NSObject, NSSecureCoding {
    
    internal let environment: EnvironmentValues
    
    internal let phase: _GraphInputs.Phase
    
    internal let focusedValues: FocusedValues
    
    /// Gesture recognizer observers
    ///
    /// - Note: `UITraitCollection` and its contents adopts immutable pattern.
    /// But this property is `var` instead of `let` because init-by-default-
    /// value + mutable variable + builder pattern is better for organizing
    /// extension codes.
    ///
    internal var gestureRecognizerObservers: GestureObservers
    
    internal init(environment: EnvironmentValues, phase: _GraphInputs.Phase, focusedValues: FocusedValues) {
        self.environment = environment
        self.phase = phase
        self.focusedValues = focusedValues
        self.gestureRecognizerObservers = GestureObservers()
    }
    
    internal final class var supportsSecureCoding: Bool {
        true
    }
    
    internal required init?(coder: NSCoder) {
        return nil
    }
    
    internal func encode(with coder: NSCoder) {
        
    }
    
    internal override func isEqual(_ object: Any?) -> Bool {
        guard let another = object as? EnvironmentWrapper else {
            return false
        }
        var result = phase == another.phase &&
            !environment.mayNotBeEqual(to: another.environment) &&
            !focusedValues.plist.mayNotBeEqual(to: another.focusedValues.plist)
        result = result && !gestureRecognizerObservers.mayNotBeEqual(to: another.gestureRecognizerObservers)
        return result
    }

}
