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
public struct _ForegroundStyleModifier<Style>: ViewInputsModifier, PrimitiveViewModifier, MultiViewModifier where Style: ShapeStyle {
    
    public var style: Style
    
    @inlinable
    public init(style: Style) {
        self.style = style
    }
    
    public static func _makeViewInputs(modifier: _GraphValue<_ForegroundStyleModifier<Style>>, inputs: inout _ViewInputs) {
        
        let foregroundStylEnvironment = ForegroundStyleEnvironment<Style>(modifier: modifier.value, environment: inputs.environment)
        
        let environmentAttribute = Attribute(foregroundStylEnvironment)
        
        let newCachedEnvironment = MutableBox(CachedEnvironment(environmentAttribute))
        
        inputs.updateCachedEnvironment(newCachedEnvironment)
    }
    
    private struct ForegroundStyleEnvironment<StyleType: ShapeStyle>: Rule {
        
        fileprivate typealias Value = EnvironmentValues
        
        @Attribute
        fileprivate var modifier: _ForegroundStyleModifier<StyleType>
        
        @Attribute
        fileprivate var environment: EnvironmentValues
        
        fileprivate var value: EnvironmentValues {
            
            var environment = self.environment
            
            let style = self.modifier.style
            
            let copyForegroundStyle = style.copyForegroundStyle(in: environment)
            
            environment.foregroundStyle = copyForegroundStyle
            
            return environment
        }
    }
}

