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
@frozen
public struct _OverlayShapeModifier<Style, Bounds>: MultiViewModifier, PrimitiveViewModifier where Style: ShapeStyle, Bounds: Shape {
    
    public var style: Style
    
    public var shape: Bounds
    
    public var fillStyle: FillStyle
    
    @inlinable
    public init(style: Style, shape: Bounds, fillStyle: FillStyle) {
        self.style = style
        self.shape = shape
        self.fillStyle = fillStyle
    }
    
    public static func _makeView(modifier: _GraphValue<_OverlayShapeModifier<Style, Bounds>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let value = modifier.unsafeBitCast(to: _BackgroundShapeModifier<Style, Bounds>.self)
        return _BackgroundShapeModifier.makeShapeView(modifier: value, inputs: inputs, shapeIsBackground: false, body: body) { _, _ in}
    }
}
