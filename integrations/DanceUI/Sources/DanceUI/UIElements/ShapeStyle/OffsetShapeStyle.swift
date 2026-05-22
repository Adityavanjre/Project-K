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
internal struct OffsetShapeStyle<Style: ShapeStyle>: ShapeStyle {
    
    internal var base: Style

    internal var offset: Int
    
    internal func _apply(to shape: inout _ShapeStyle_Shape) {
        switch shape.operation {
        case .prepare((let text, let level)):
            let newOffset = level + offset
            shape.operation = .prepare((text, newOffset))
            base._apply(to: &shape)
        case .resolveStyle(let range):
            let start = range.lowerBound + offset
            let end = range.upperBound + offset
            guard start < end else {
                _danceuiFatalError("start index less than end index.")
            }
            
            shape.operation = .resolveStyle((start..<end))
            base._apply(to: &shape)
        case .fallbackColor(let value):
            let newOffset = offset + value
            shape.operation = .fallbackColor(newOffset)
            base._apply(to: &shape)
        case .multiLevel,
             .primaryStyle:
            shape.result = .none
        }
    }
    
    internal static func _apply(to type: inout _ShapeStyle_ShapeType) {
        Style._apply(to: &type)
    }
}
