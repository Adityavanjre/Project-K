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
extension ShapeStyle  {
    /// Returns a new style based on `self` that multiplies by the
    /// specified opacity when drawing.
    @inlinable
    public func opacity(_ opacity: Double) -> some ShapeStyle {
        _OpacityShapeStyle(style: self, opacity: Float(opacity))
    }
}

@available(iOS 13.0, *)
@frozen
public struct _OpacityShapeStyle<Style>: ShapeStyle where Style: ShapeStyle {
    
    // 0x0
    public var style: Style
    
    // metadata + 0x24
    public var opacity: Float
    
    @inlinable
    public init(style: Style, opacity: Float) {
        self.style = style
        self.opacity = opacity
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        guard opacity != 1 else {
            style._apply(to: &shape)
            return
        }
        
        switch shape.operation {
        case .prepare((let text, _)):
            let hasColorModifier = text.hasColorModifier
            shape.needsStyledRendering = !hasColorModifier
            // DanceUI addition ended
            
            if !hasColorModifier {
                let newText = text.foregroundColor(.primary)
                shape.result = .prepared(newText)
            } else {
                shape.result = .prepared(text)
            }
        case .resolveStyle:
            style._apply(to: &shape)
            guard case .resolved(let resolvedStyle) = shape.result else {
                return
            }
            
            switch resolvedStyle {
            case .array(let styles):
                let newStyles: [_ShapeStyle_Shape.ResolvedStyle] = styles.map { .opacity((opacity, $0)) }
                shape.result = .resolved(.array(newStyles))
            default:
                shape.result = .resolved(.opacity((opacity, resolvedStyle)))
            }
            
        case .fallbackColor(_):
            style._apply(to: &shape)
            if case .color(let color) = shape.result {
                let newColor = color.opacity(Double(opacity))
                shape.result = .color(newColor)
            }
        case .multiLevel,
             .primaryStyle:
            style.mapForegroundStyle(in: &shape) { anyShapeStyle in
                _OpacityShapeStyle<AnyShapeStyle>(style: anyShapeStyle, opacity: opacity)
            }
        }
    }
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        Style._apply(to: &type)
    }
}
