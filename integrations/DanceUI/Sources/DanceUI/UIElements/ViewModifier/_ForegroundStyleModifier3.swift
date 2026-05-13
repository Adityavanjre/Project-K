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

@frozen
@available(iOS 13.0, *)
public struct _ForegroundStyleModifier3<S1, S2, S3>: ViewInputsModifier, PrimitiveViewModifier, MultiViewModifier where S1: ShapeStyle, S2: ShapeStyle, S3: ShapeStyle {
    
    public var primary: S1
    
    public var secondary: S2
    
    public var tertiary: S3
    
    @inlinable
    public init(primary: S1, secondary: S2, tertiary: S3) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
    }
    
    public static func _makeViewInputs(modifier: _GraphValue<_ForegroundStyleModifier3<S1, S2, S3>>, inputs: inout _ViewInputs) {
        
        let foregroundStylEnvironment = ForegroundStyleEnvironment<S1, S2, S3>(modifier: modifier.value, environment: inputs.environment)
        
        let environmentAttribute = Attribute(foregroundStylEnvironment)
        
        let newCachedEnvironemnt = MutableBox(CachedEnvironment(environmentAttribute))
        
        inputs.updateCachedEnvironment(newCachedEnvironemnt)
    }
    
    private struct ForegroundStyleEnvironment<Style1: ShapeStyle, Style2: ShapeStyle, Style3: ShapeStyle>: Rule {
        
        fileprivate typealias Value = EnvironmentValues
        
        @Attribute
        fileprivate var modifier: _ForegroundStyleModifier3<Style1, Style2, Style3>
        
        @Attribute
        fileprivate var environment: EnvironmentValues
        
        fileprivate var value: EnvironmentValues {
            
            var environment = self.environment
            
            let primary = modifier.primary
            
            let secondary = modifier.secondary
            
            let tertiary = modifier.tertiary
            
            let copyPrimaryStyle = primary.copyForegroundStyle(in: environment)
            
            let copySecondaryStyle = secondary.copyForegroundStyle(in: environment)
            
            let copyTertiaryStyle = tertiary.copyForegroundStyle(in: environment)
            
            let styleTriple = ShapeStyleTriple(primary: copyPrimaryStyle, secondary: copySecondaryStyle, tertiary: copyTertiaryStyle)
            
            environment.foregroundStyle = AnyShapeStyle(styleTriple)
            
            return environment
        }
    }
}
