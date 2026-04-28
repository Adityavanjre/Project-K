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
public struct _BackgroundModifier<Background: View>: MultiViewModifier, PrimitiveViewModifier {
    
    public typealias Body = Never
    
    public typealias Content = Background
    
    // 0x0
    public var background: Background
    
    // 0x8
    public var alignment: Alignment
    
    @inlinable
    public init(background: Background, alignment: Alignment) {
        self.background = background
        self.alignment = alignment
    }
    
    public static func _makeView(modifier: _GraphValue<_BackgroundModifier<Background>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let background = modifier[{ .of(&$0.background) }]
        let alignment = modifier[{ .of(&$0.alignment) }]
        return makeSecondaryLayerView(secondaryLayer: background.value, alignment: alignment.value, inputs: inputs, body: body, flipOrder: true)
    }
    
}

@available(iOS 13.0, *)
extension _BackgroundModifier where Background: Equatable {
    
}
