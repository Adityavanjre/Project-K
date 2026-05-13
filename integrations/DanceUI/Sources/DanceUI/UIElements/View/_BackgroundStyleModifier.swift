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
public struct _BackgroundStyleModifier<Style>: ShapeStyledLeafView, PrimitiveViewModifier, MultiViewModifier where Style: ShapeStyle {
    
    public var style: Style
    
    public var ignoresSafeAreaEdges: Edge.Set
    
    @inlinable
    public init(style: Style, ignoresSafeAreaEdges: Edge.Set) {
        self.style = style
        self.ignoresSafeAreaEdges = ignoresSafeAreaEdges
    }
    
    public static func _makeView(modifier: _GraphValue<_BackgroundStyleModifier<Style>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeShapeView(modifier: modifier, inputs: inputs, shapeIsBackground: true, body: body)
    }
    
    internal func shape(size: CGSize, edgeInsets: EdgeInsets) -> (ShapeStyle_RenderedShape.Shape, CGRect) {
        let rect = CGRect(origin: .zero, size: size)
        let path = ImplicitContainerShape().path(in: rect)
        let shape = ShapeStyle_RenderedShape.Shape(path: path, fillStyle: FillStyle())
        return (shape, rect)
    }
    
    internal static func makeShapeView(modifier: _GraphValue<_BackgroundStyleModifier<Style>>,
                                       inputs: _ViewInputs,
                                       shapeIsBackground: Bool,
                                       body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let backgroundInfo = BackgroundInfo(modifier: modifier.value,
                                            environment: inputs.environment,
                                            size: inputs.size,
                                            position: inputs.position,
                                            transform: inputs.transform,
                                            safeAreaInsets: inputs.safeAreaInsets)
        let backgroundInfoAttribute = Attribute(backgroundInfo)
        var backgroundInputs = inputs
        backgroundInputs.implicitRootType = _ZStackLayout.self
        
        var primaryInputs = inputs
        let viewOriginAttribute = backgroundInfoAttribute[{.of(&$0.frame.origin)}]
        let viewSizeAttribute = backgroundInfoAttribute[{.of(&$0.frame.size)}]
        let anchorStyleAttribute = backgroundInfoAttribute[{.of(&$0.style)}]
        let animatableAttribute = AnimatableAttributeHelper<_ShapeStyle_Shape.ResolvedStyle>(phase: primaryInputs.phase,
                                                                                             time: primaryInputs.time,
                                                                                             transaction: primaryInputs.transaction)
        let styleResolver = ShapeStyleResolver(style: OptionalAttribute(anchorStyleAttribute),
                                               mode: OptionalAttribute<ShapeStyle_ResolverMode>(nil),
                                               environment: primaryInputs.environment,
                                               role: .fill,
                                               animationsDisabled: primaryInputs.base.disableAnimations,
                                               helper: animatableAttribute)
        let styleResolverAttribute = Attribute(styleResolver)
        styleResolverAttribute.flags = .active
        
        backgroundInputs.position = viewOriginAttribute
        backgroundInputs.size = viewSizeAttribute
        
        let backgroundOutputs = makeLeafView(view: modifier, inputs: backgroundInputs, style: styleResolverAttribute)
        
        if shapeIsBackground {
            let style = modifier[{.of(&$0.style)}]
            primaryInputs.applyBackgroundStyle(style.value)
        }
        
        let outputs = body(_Graph(), primaryInputs)
        let visitorOutputs = shapeIsBackground ? (backgroundOutputs, outputs) : (outputs, backgroundOutputs)
        
        var visitor = PairwisePreferenceCombinerVisitor(outputs: visitorOutputs, result: _ViewOutputs())
        
        for key in primaryInputs.preferences.keys {
            key.visitKey(&visitor)
        }
        
        visitor.result.overrideLayout(outputs.layout)
        
        return visitor.result
    }
    
    private struct BackgroundInfo<StyleType: ShapeStyle>: Rule {
        
        fileprivate struct Value {
            
            var frame: ViewFrame
            
            var style: _AnchoredShapeStyle<StyleType>
        }
        
        @Attribute
        fileprivate var modifier: _BackgroundStyleModifier<StyleType>
        
        @Attribute
        fileprivate var environment: EnvironmentValues
        
        @Attribute
        fileprivate var size: ViewSize
        
        @Attribute
        fileprivate var position: ViewOrigin
        
        @Attribute
        fileprivate var transform: ViewTransform
        
        @OptionalAttribute
        fileprivate var safeAreaInsets: SafeAreaInsets?
        
        fileprivate init(modifier: Attribute<_BackgroundStyleModifier<StyleType>>,
                         environment: Attribute<EnvironmentValues>,
                         size: Attribute<ViewSize>,
                         position: Attribute<ViewOrigin>,
                         transform: Attribute<ViewTransform>,
                         safeAreaInsets: OptionalAttribute<SafeAreaInsets>) {
            self._modifier = modifier
            self._environment = environment
            self._size = size
            self._position = position
            self._transform = transform
            self._safeAreaInsets = safeAreaInsets
        }
        
        fileprivate var value: Value {
            let size = self.size
            let viewFrame = ViewFrame(origin: self.position, size: self.size)
            let anchorShapeStyle = _AnchoredShapeStyle(style: modifier.style, bounds: CGRect(origin: .zero, size: size.value))
            var value = Value(frame: viewFrame, style: anchorShapeStyle)
            let ignoresSafeAreaEdges = modifier.ignoresSafeAreaEdges
            
            if !ignoresSafeAreaEdges.isEmpty {
                let context = _PositionAwarePlacementContext(context: AnyRuleContext.current,
                                                             size: self.$size,
                                                             environment: self.$environment,
                                                             transform: self.$transform,
                                                             position: self.$position,
                                                             safeAreaInsets: self._safeAreaInsets)
                let safeAreaInsets = context.safeAreaInsets(matching: .container)
                let edgeInsets = safeAreaInsets.in(ignoresSafeAreaEdges)
                
                let styleOrigin = value.style.bounds.origin
                value.style.bounds.origin = CGPoint(x: styleOrigin.x + edgeInsets.leading, y: styleOrigin.y + edgeInsets.top)
                
                let viewOrigin = value.frame.origin.value
                let newOrigin = CGPoint(x: viewOrigin.x - edgeInsets.leading, y: viewOrigin.y - edgeInsets.top)
                value.frame.origin.value = newOrigin
                
                let insetSize = value.frame.size.value.outset(by: edgeInsets)
                value.frame.size.value = insetSize
            }
            
            return value
        }
    }
}

@available(iOS 13.0, *)
private struct ForegroundEnvironment<Style: ShapeStyle>: Rule {
    
    @Attribute
    fileprivate var style: Style
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    fileprivate init(style: Attribute<Style>, environment: Attribute<EnvironmentValues>) {
        self._style = style
        self._environment = environment
    }
    
    fileprivate var value: EnvironmentValues {
        var shape = _ShapeStyle_Shape(operation: .multiLevel,
                                      result: .none,
                                      environment: self.environment,
                                      role: .fill,
                                      inRecursiveStyle: false)
        self.style._apply(to: &shape)
        return shape.environment
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    internal mutating func applyBackgroundStyle<Style: ShapeStyle>(_ style: Attribute<Style>) {
        var shapeStyle = _ShapeStyle_ShapeType(operation: .modifiesBackground, result: .none)
        Style._apply(to: &shapeStyle)
        if case .bool(let value) = shapeStyle.result,
           value {
            let foregroundEnv = ForegroundEnvironment(style: style, environment: self.environment)
            let foregroundEnvAttribute = Attribute(foregroundEnv)
            let newCachedEnvironemnt = MutableBox(CachedEnvironment(foregroundEnvAttribute))
            updateCachedEnvironment(newCachedEnvironemnt)
        }
    }
}
