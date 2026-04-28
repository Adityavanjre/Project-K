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
public struct _InsettableBackgroundShapeModifier<Style, Bounds>: PrimitiveViewModifier, MultiViewModifier where Style: ShapeStyle, Bounds: InsettableShape {
    
    public var style: Style
    
    public var shape: Bounds
    
    public var fillStyle: FillStyle
    
    @inlinable
    public init(style: Style, shape: Bounds, fillStyle: FillStyle) {
        self.style = style
        self.shape = shape
        self.fillStyle = fillStyle
    }
    
    public static func _makeView(modifier: _GraphValue<_InsettableBackgroundShapeModifier<Style, Bounds>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let value = modifier.unsafeBitCast(to: _BackgroundShapeModifier<Style, Bounds>.self)
        return _BackgroundShapeModifier.makeShapeView(modifier: value,
                                                      inputs: inputs,
                                                      shapeIsBackground: true,
                                                      body: body) { primaryInputs, shapeAttribute in
            primaryInputs.setContainerShape(shapeAttribute, isSystemShape: false)
        }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    internal mutating func setContainerShape<InsetShape: InsettableShape>(_ shape: Attribute<InsetShape>, isSystemShape: Bool) {
        guard InsetShape.self != ContainerRelativeShape.self else {
            return
        }
        
        let shapeAttribute = WeakAttribute(shape)
        let animatedSizeAttribute = WeakAttribute(self.animatedSize)
        let uniqueID = UniqueID()
        let containerShapeData = ContainerShapeData(type: ContainerShapeType<InsetShape>.self,
                                                    shape: shapeAttribute.base,
                                                    size: animatedSizeAttribute,
                                                    id: uniqueID,
                                                    isSystemShape: isSystemShape)
        
        let containerShapeEnvironment = ContainerShapeEnvironment(environment: self.environment, data: containerShapeData)
        let containerShapeEnvironmentAttribute = Attribute(containerShapeEnvironment)
        
        let newCachedEnvironemnt = MutableBox(CachedEnvironment(containerShapeEnvironmentAttribute))
        updateCachedEnvironment(newCachedEnvironemnt)
        
        let containerShapeTransform = ContainerShapeTransform(transform: self.transform, position: self.animatedPosition, id: uniqueID)
        self.transform = Attribute(containerShapeTransform)
    }
}

@available(iOS 13.0, *)
private struct ContainerShapeType<InsetShape: InsettableShape>: AnyContainerShapeType {
    
    fileprivate static func path(in rect: CGRect, proxy: GeometryProxy, shape: DGWeakAttribute, size: WeakAttribute<ViewSize>, id: UniqueID) -> Path {
        guard let sizeAttribute = size.attribute,
              let proxyOwner = proxy.owner.attribute else {
            return rect.validPath
        }
        
        let anyRuleContext = AnyRuleContext(proxyOwner)
        let viewSize = anyRuleContext[sizeAttribute].value
        
        let insetShapeAttribute = WeakAttribute<InsetShape>(base: shape)
        let insetShape = anyRuleContext[insetShapeAttribute]
        
        guard let insetShapeValue = insetShape else {
            return rect.validPath
        }
        
        var targetRect = rect
        
        if let placementContext = proxy.placementContext {
            let transform = placementContext.transform
            let coordinateSpaceID = AnyHashable(id)
            targetRect = rect.mapCorners(f: { points in
                points.convert(to: .named(coordinateSpaceID), transform: transform)
            })
        }
        
        let shapeBound = CGRect(origin: .zero, size: viewSize)
        
        let minXDiff = targetRect.minX - shapeBound.minX
        let minYDiff = targetRect.minY - shapeBound.minY
        let maxXDiff = shapeBound.maxX - targetRect.maxX
        let maxYDiff = shapeBound.maxY - targetRect.maxY
        
        let minResult = min(minXDiff, minYDiff, maxXDiff, maxYDiff)
        let shape = insetShapeValue.inset(by: minResult)
        let insetRect = rect.insetBy(dx: -minResult, dy: -minResult)
        let insetPath = shape.path(in: insetRect)
        
        return insetPath
    }
     
}

@available(iOS 13.0, *)
private struct ContainerShapeEnvironment: Rule {
    
    @Attribute
    fileprivate var environment: EnvironmentValues
    
    fileprivate var data: ContainerShapeData
    
    fileprivate var value: EnvironmentValues {
        var environmentValues = environment
        environmentValues.containerShapeData = data
        return environmentValues
    }
}

@available(iOS 13.0, *)
private struct ContainerShapeTransform: Rule {
    
    @Attribute
    fileprivate var transform: ViewTransform
    
    @Attribute
    fileprivate var position: ViewOrigin
    
    fileprivate var id: UniqueID
    
    fileprivate var value: ViewTransform {
        
        var transformValue = self.transform
        let positionValue = self.position
        
        let translationX = positionValue.value.x - transformValue.positionAdjustment.width
        let translationY = positionValue.value.y - transformValue.positionAdjustment.height
        
        if translationX != 0 || translationY != 0 {
            transformValue.appendTranslation(CGSize(width: -translationX, height: -translationY))
        }
        
        transformValue.positionAdjustment = .init(width: positionValue.value.x, height: positionValue.value.y)
        transformValue.appendCoordinateSpace(name: AnyHashable(id))
        return transformValue
    }
}
