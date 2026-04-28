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
public struct _OverlayStyleModifier<Style>: MultiViewModifier, PrimitiveViewModifier where Style: ShapeStyle {
    
    public var style: Style
    
    public var ignoresSafeAreaEdges: Edge.Set
    
    @inlinable
    public init(style: Style, ignoresSafeAreaEdges: Edge.Set) {
        self.style = style
        self.ignoresSafeAreaEdges = ignoresSafeAreaEdges
    }
    
    public static func _makeView(modifier: _GraphValue<_OverlayStyleModifier<Style>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let value = modifier.unsafeBitCast(to: _BackgroundStyleModifier<Style>.self)
        return _BackgroundStyleModifier.makeShapeView(modifier: value, inputs: inputs, shapeIsBackground: false, body: body)
    }
}
