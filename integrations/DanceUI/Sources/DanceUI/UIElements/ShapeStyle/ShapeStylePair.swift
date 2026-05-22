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
internal struct ShapeStylePair<Style1: ShapeStyle, Style2: ShapeStyle>: ShapeStyle {
    
    internal var primary: Style1
    
    internal var secondary: Style2
    
    internal func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare((let text, let level)):
            if level == 0 {
                primary._apply(to: &shape)
            } else {
                shape.operation = .prepare((text, 0))
                secondary._apply(to: &shape)
            }
        case .resolveStyle(let range):
            let lowerBound = range.lowerBound
            let upperBound = range.upperBound
            guard !range.isEmpty,
                  lowerBound != upperBound else {
                return
            }
            
            if lowerBound == 0 {
                primary._apply(to: &shape)
                guard upperBound != 1 else {
                    return
                }
                applySecondaryStyle(to: &shape, primaryStyleResult: shape.result)
            } else {
                applySecondaryStyle(to: &shape, primaryStyleResult: shape.result)
            }
            
        case .fallbackColor(let value):
            if value == 0 {
                primary._apply(to: &shape)
            } else {
                secondary._apply(to: &shape)
            }
            
        case .multiLevel,
             .primaryStyle:
            break
            
        }
    }
    
    internal static func _apply(to type: inout _ShapeStyle_ShapeType) {
        Style1._apply(to: &type)
    }
    
    @inline(__always)
    private func applySecondaryStyle(to shape: inout _ShapeStyle_Shape,
                                     primaryStyleResult: _ShapeStyle_Shape.Result) {
        shape.reset()
        secondary._apply(to: &shape)
        if case .resolved(let primaryStyle) = primaryStyleResult,
           case .resolved(let secondaryStyle) = shape.result {
            shape.result = .resolved(.array([primaryStyle, secondaryStyle]))
        }
    }
}
