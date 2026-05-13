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
@frozen
public struct _BackgroundShapeModifier<Style, Bounds>: ShapeStyledLeafView, PrimitiveViewModifier, MultiViewModifier where Style: ShapeStyle, Bounds: Shape {
    
    public var style: Style
    
    public var shape: Bounds
    
    public var fillStyle: FillStyle
    
    @inlinable
    public init(style: Style, shape: Bounds, fillStyle: FillStyle) {
        self.style = style
        self.shape = shape
        self.fillStyle = fillStyle
    }
    
    public static func _makeView(modifier: _GraphValue<_BackgroundShapeModifier<Style, Bounds>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeShapeView(modifier: modifier, inputs: inputs, shapeIsBackground: true, body: body, modifyPrimaryInputs: {_, _ in })
    }
    
    internal static func makeShapeView(modifier: _GraphValue<_BackgroundShapeModifier<Style, Bounds>>,
                                       inputs: _ViewInputs,
                                       shapeIsBackground: Bool,
                                       body: (_Graph, _ViewInputs) -> _ViewOutputs,
                                       modifyPrimaryInputs: (inout _ViewInputs, Attribute<Bounds>) -> Void) -> _ViewOutputs {
        var primaryInputs = inputs
        var backgroundInputs = inputs
        backgroundInputs.implicitRootType = _ZStackLayout.self
        
        let styleAttribute = modifier[{.of(&$0.style)}].value
        let shapeRole = Bounds.role
        let animatableAttribute = AnimatableAttributeHelper<_ShapeStyle_Shape.ResolvedStyle>(phase: primaryInputs.phase,
                                                                                             time: primaryInputs.time,
                                                                                             transaction: primaryInputs.transaction)
        let styleResolver = ShapeStyleResolver(style: OptionalAttribute(styleAttribute),
                                               mode: OptionalAttribute<ShapeStyle_ResolverMode>(nil),
                                               environment: primaryInputs.environment,
                                               role: shapeRole,
                                               animationsDisabled: primaryInputs.base.disableAnimations,
                                               helper: animatableAttribute)
        let styleResolverAttribute = Attribute(styleResolver)
        styleResolverAttribute.flags = .active
        
        let backgroundOutputs: _ViewOutputs
        
        let shapeAttribute: Attribute<Bounds>
        
        if MemoryLayout<Bounds.AnimatableData>.size == 0 {
            shapeAttribute = modifier[{.of(&$0.shape)}].value
            backgroundOutputs = makeLeafView(view: modifier, inputs: backgroundInputs, style: styleResolverAttribute)
        } else {
            let shapeValue = modifier[{.of(&$0.shape)}]
            let fillStyle = modifier[{.of(&$0.fillStyle)}]
            shapeAttribute = Bounds.makeAnimatable(value: shapeValue, inputs: primaryInputs.base)
            let animatedShape = AnimatedShape.Init(shape: shapeAttribute, fillStyle: fillStyle.value)
            let animatedShapeGraphValue = _GraphValue(animatedShape)
            backgroundOutputs = AnimatedShape.makeLeafView(view: animatedShapeGraphValue, inputs: backgroundInputs, style: styleResolverAttribute)
        }
        
        if shapeIsBackground {
            primaryInputs.applyBackgroundStyle(styleAttribute)
        }
        
        modifyPrimaryInputs(&primaryInputs, shapeAttribute)
        
        let outputs = body(_Graph(), primaryInputs)
        
        let visitorOutputs = shapeIsBackground ? (backgroundOutputs, outputs) : (outputs, backgroundOutputs)
        
        var visitor = PairwisePreferenceCombinerVisitor(outputs: visitorOutputs, result: _ViewOutputs())
        
        for key in primaryInputs.preferences.keys {
            key.visitKey(&visitor)
        }
        
        visitor.result.overrideLayout(outputs.layout)
        
        return visitor.result
    }
    
    internal func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect) {
        let rect = CGRect(origin: .zero, size: size)
        let path = self.shape.path(in: rect)
        return (ShapeStyle_RenderedShape.Shape(path: path, fillStyle: self.fillStyle), rect)
    }
}
