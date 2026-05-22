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

@available(iOS 13.0, *)
internal struct ShapeStyleTriple<Style1: ShapeStyle, Style2: ShapeStyle, Style3: ShapeStyle>: ShapeStyle {
    
    internal var primary: Style1
    
    internal var secondary: Style2
    
    internal var tertiary: Style3
    
    internal func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare((let text, let level)):
            if level == 0 {
                primary._apply(to: &shape)
            } else if level == 1 {
                shape.operation = .prepare((text, 0))
                secondary._apply(to: &shape)
            } else {
                shape.operation = .prepare((text, 0))
                tertiary._apply(to: &shape)
            }
        case .resolveStyle(let range):
            let lowerBound = range.lowerBound
            let upperBound = range.upperBound
            guard !range.isEmpty,
                  lowerBound != upperBound else {
                return
            }
            
            var resolvedStyles: [_ShapeStyle_Shape.ResolvedStyle] = []
            if lowerBound == 0 {
                resolve(primary, shape: &shape, resolvedStyles: &resolvedStyles)
                if upperBound >= 2 {
                    resolve(secondary, shape: &shape, resolvedStyles: &resolvedStyles)
                    resolve(tertiary, shape: &shape, resolvedStyles: &resolvedStyles)
                }
            } else {
                if lowerBound > 1 {
                    resolve(tertiary, shape: &shape, resolvedStyles: &resolvedStyles)
                } else {
                    if upperBound >= 2 {
                        resolve(secondary, shape: &shape, resolvedStyles: &resolvedStyles)
                        resolve(tertiary, shape: &shape, resolvedStyles: &resolvedStyles)
                    }
                }
            }
            
            if resolvedStyles.isEmpty {
                shape.result = .none
            } else if resolvedStyles.count == 1 {
                shape.result = .resolved(resolvedStyles[0])
            } else {
                shape.result = .resolved(.array(resolvedStyles))
            }
        case .fallbackColor(let value):
            shape.operation = .fallbackColor(0)
            if value == 0 {
                primary._apply(to: &shape)
            } else if value == 1 {
                secondary._apply(to: &shape)
            } else {
                tertiary._apply(to: &shape)
            }
        case .multiLevel,
             .primaryStyle:
            break
        }
    }
    
    @inline(__always)
    private func resolve<Style: ShapeStyle>(_ style: Style,
                                            shape: inout _ShapeStyle_Shape,
                                            resolvedStyles: inout [_ShapeStyle_Shape.ResolvedStyle]) {
        shape.operation = .resolveStyle(0..<1)
        style._apply(to: &shape)
        if case .resolved(let style) = shape.result {
            resolvedStyles.append(style)
            shape.result = .none
        }
    }
    
    internal static func _apply(to type: inout _ShapeStyle_ShapeType) {
        Style1._apply(to: &type)
    }
}
