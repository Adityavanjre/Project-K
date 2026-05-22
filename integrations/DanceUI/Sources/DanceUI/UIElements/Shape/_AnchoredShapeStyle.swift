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

@frozen
@available(iOS 13.0, *)
public struct _AnchoredShapeStyle<S>: ShapeStyle where S: ShapeStyle {
    
    public var style: S
    
    public var bounds: CGRect
    
    @inlinable
    internal init(style: S, bounds: CGRect) {
        self.style = style
        self.bounds = bounds
    }
    
    public static func _makeView<ShapeType>(view: _GraphValue<_ShapeView<ShapeType, _AnchoredShapeStyle<S>>>, inputs: _ViewInputs) -> _ViewOutputs where ShapeType : Shape {
        legacyMakeShapeView(view: view, inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension _AnchoredShapeStyle {
    
    public func _apply(to shape: inout _ShapeStyle_Shape) {
        shape.bounds = self.bounds
        style._apply(to: &shape)
    }
    
    public static func _apply(to type: inout _ShapeStyle_ShapeType) {
        S._apply(to: &type)
    }
}
