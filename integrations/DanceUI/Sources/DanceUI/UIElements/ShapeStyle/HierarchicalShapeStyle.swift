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

// A shape style that maps to one of the numbered content styles.
@frozen
@available(iOS 13.0, *)
public struct HierarchicalShapeStyle: ShapeStyle {
    
    internal var id: UInt32
    
    /// A shape style that maps to the first level of the current
    /// content style.
    public static let primary: HierarchicalShapeStyle = HierarchicalShapeStyle(id: 0x0)
    
    /// A shape style that maps to the second level of the current
    /// content style.
    public static let secondary: HierarchicalShapeStyle = HierarchicalShapeStyle(id: 0x1)
    
    /// A shape style that maps to the third level of the current
    /// content style.
    public static let tertiary: HierarchicalShapeStyle = HierarchicalShapeStyle(id: 0x2)
    
    /// A shape style that maps to the fourth level of the current
    /// content style.
    public static let quaternary: HierarchicalShapeStyle = HierarchicalShapeStyle(id: 0x3)
    
    internal static let quinary: HierarchicalShapeStyle = HierarchicalShapeStyle(id: 0x4)
    
    internal static var sharedPrimary: AnyShapeStyle {
        AnyShapeStyle(HierarchicalShapeStyle.primary)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare,
             .resolveStyle,
             .fallbackColor,
             .multiLevel:
            if shape.inRecursiveStyle {
                LegacyContentStyle.sharedPrimary._apply(to: &shape)
            } else {
                shape.inRecursiveStyle = true
                let environment = shape.environment
                var resolvedShapeStyle: AnyShapeStyle? = nil
                
                if let foregroundStyle = environment.foregroundStyle {
                    if let primaryStyle = foregroundStyle.primaryStyle(in: environment) {
                        resolvedShapeStyle = primaryStyle
                    } else {
                        resolvedShapeStyle = foregroundStyle
                    }
                } else if let defaultForegroundStyle = environment.defaultForegroundStyle {
                    if let primaryStyle = defaultForegroundStyle.primaryStyle(in: environment) {
                        resolvedShapeStyle = primaryStyle
                    } else {
                        resolvedShapeStyle = defaultForegroundStyle
                    }
                }
                
                if let targetShapeStyle = resolvedShapeStyle {
                    apply(targetShapeStyle, shape: &shape)
                } else {
                    let systemColorStyle = SystemColorsStyle()
                    apply(systemColorStyle, shape: &shape)
                }
                
                shape.inRecursiveStyle = false
            }
        case .primaryStyle:
            shape.result = .style(HierarchicalShapeStyle.sharedPrimary)
        }
    }
    
    private func apply<Style: ShapeStyle>(_ style: Style, shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .multiLevel:
            if self.id == 0 {
                shape.result = .style(AnyShapeStyle(style))
            } else {
                let offsetShapeStyle = OffsetShapeStyle(base: style, offset: Int(self.id))
                shape.result = .style(AnyShapeStyle(offsetShapeStyle))
            }
        default:
            if self.id == 0 {
                style._apply(to: &shape)
            } else {
                let offsetShapeStyle = OffsetShapeStyle(base: style, offset: Int(self.id))
                offsetShapeStyle._apply(to: &shape)
            }
        }
    }
    
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        type.result = .bool(false)
    }
}
