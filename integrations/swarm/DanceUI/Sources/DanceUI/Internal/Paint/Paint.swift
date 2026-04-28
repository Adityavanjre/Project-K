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
internal protocol Paint: ShapeStyle {
    
    associatedtype ResolvedPaintType: ResolvedPaint
    
    func resolvePaint(in environment: EnvironmentValues) -> ResolvedPaintType
    
}

@available(iOS 13.0, *)
extension Text {
    @inline(__always)
    internal var hasColorModifier: Bool {
        var hasColorModifier = false
        for modifier in self.modifiers {
            if case .color = modifier {
                hasColorModifier = true
                break
            }
        }
        return hasColorModifier
    }
}

@available(iOS 13.0, *)
extension Paint {
    
    public static func _makeView<ShapeType: Shape>(view: _GraphValue<_ShapeView<ShapeType, Self>>, inputs: _ViewInputs) -> _ViewOutputs {
        legacyMakeShapeView(view: view, inputs: inputs)
    }
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare((let text, _)):
            let hasColorModifier = text.hasColorModifier
            shape.needsStyledRendering = !hasColorModifier
            
            if !hasColorModifier {
                let newText = text.foregroundColor(.primary)
                shape.result = .prepared(newText)
            } else {
                shape.result = .prepared(text)
            }
        case .resolveStyle(let range):
            guard !range.isEmpty else {
                return
            }
            
            let enviorments = shape.environment
            let opacity = enviorments.colorOpacity(with: range.lowerBound)
            
            if let paintBounds = shape.bounds {
                let paint = resolvePaint(in: enviorments)
                let resolvedPaint = AnchoredResolvedPaint(paint: paint, bounds: paintBounds)
                let anyResolvedPaint = _AnyResolvedPaint(resolvedPaint)
                shape.result = .resolved(.opacity((opacity, .paint(anyResolvedPaint))))
            } else {
                let paint = resolvePaint(in: enviorments)
                let anyResolvedPaint = _AnyResolvedPaint(paint)
                shape.result = .resolved(.opacity((opacity, .paint(anyResolvedPaint))))
            }
            
        case .fallbackColor,
                .multiLevel,
                .primaryStyle:
            break
        }
    }
}
