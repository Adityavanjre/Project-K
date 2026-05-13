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
extension View {
    
    /// Defines the content shape for hit testing.
    ///
    /// - Parameters:
    ///   - shape: The hit testing shape for the view.
    ///   - eoFill: A Boolean that indicates whether the shape is interpreted
    ///     with the even-odd winding number rule.
    ///
    /// - Returns: A view that uses the given shape for hit testing.
    @inlinable
    public func contentShape<S>(_ shape: S, eoFill: Bool = false) -> some View where S : Shape {
        modifier(_ContentShapeModifier(shape: shape, eoFill: eoFill))
    }
    
}


@frozen
@available(iOS 13.0, *)
public struct _ContentShapeModifier<ContentShape: Shape>: MultiViewModifier, PrimitiveViewModifier, ContentResponder, RendererEffect {
    
    public var shape: ContentShape
    
    public var eoFill: Bool
    
    public var insets: EdgeInsets?
    
    @inlinable
    public init(shape: ContentShape, eoFill: Bool = false) {
        self.init(shape: shape, eoFill: eoFill, insets: nil)
    }
    
    @inlinable
    public init(shape: ContentShape, eoFill: Bool = false, insets: EdgeInsets?) {
        self.shape = shape
        self.eoFill = eoFill
        self.insets = insets
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        return .gestureRecognizers([])
    }
    
    public static func _makeView(modifier: _GraphValue<_ContentShapeModifier<ContentShape>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        var bodyInputs = inputs
        bodyInputs.hitTestInsets = nil
        
        var outputs = if DanceUIFeature.gestureContainer.isEnable {
            makeRendererEffect(effect: modifier, inputs: bodyInputs, body: body)
        } else {
            body(_Graph(), bodyInputs)
        }
        
        if inputs.preferences.requiresViewResponders {
            let position = inputs.animatedPosition
            let size = inputs.animatedSize
            
            let children = outputs.viewResponders ?? ViewGraph.current.$emptyViewResponders
            
            let shapeResponder = ShapeResponder<ContentShape>(inputs: inputs)
            
            let responderFilter = ShapeResponderFilter(modifier: modifier.value,
                                                       position: position,
                                                       size: size,
                                                       transform: inputs.transform,
                                                       hitTestInsets: inputs.hitTestInsets,
                                                       children: children,
                                                       responder: shapeResponder)
            
            outputs.viewResponders = Attribute(responderFilter)
            
            if inputs.preferences.requiresAccessibilityNodes {
                outputs.accessibilityNodes = makeAccessibilityGeometryTransform(for: nil, inputs: inputs, outputs: outputs)
            }
        }
        
        return outputs
    }
    
    public typealias Body = Never
    
    internal func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64 {
        let path = contentPath(size: size, edgeInsets: edgeInsets)
        return BitVector64().contained(points: points) { point in
            path.contains(point, eoFill: eoFill)
        }
    }
    
    internal func contentPath(size: CGSize, edgeInsets: EdgeInsets) -> Path {
        shape.path(in: CGRect(origin: .zero, size: size).inset(by: edgeInsets))
    }
    
}

@available(iOS 13.0, *)
private final class ShapeResponder<ContentShape: Shape>: DefaultLayoutViewResponder {
    
    fileprivate var helper: ContentResponderHelper<_ContentShapeModifier<ContentShape>>!
    
    fileprivate override init(inputs: _ViewInputs) {
        super.init(inputs: inputs)
        helper = ContentResponderHelper(identifier: ObjectIdentifier(self))
    }
    
    fileprivate override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        helper.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey, children: children)
    }
    
    fileprivate override func addContentPath(to path: inout Path, in coordinateSpace: CoordinateSpace, observer: ContentPathObserver?) {
        helper.addContentPath(to: &path, in: coordinateSpace, observer: observer)
    }
    
    fileprivate override var visualDebugGeometries: [VisualDebugGeometry] {
        // FIXME: Use a content path instead.
        [helper.globalGeometry] + children.map({$0.visualDebugGeometries}).flatMap({$0})
    }

}

@available(iOS 13.0, *)
private struct ShapeResponderFilter<ContentShape: Shape>: StatefulRule {
    
    fileprivate typealias Value = [ViewResponder]
    
    @Attribute
    fileprivate var modifier: _ContentShapeModifier<ContentShape>

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var size: ViewSize

    @Attribute
    fileprivate var transform: ViewTransform
    
    @OptionalAttribute
    fileprivate var hitTestInsets: EdgeInsets??

    @Attribute
    fileprivate var children: [ViewResponder]

    fileprivate let responder: ShapeResponder<ContentShape>
    
    internal init(
        modifier: Attribute<_ContentShapeModifier<ContentShape>>,
        position: Attribute<ViewOrigin>,
        size: Attribute<ViewSize>,
        transform: Attribute<ViewTransform>,
        hitTestInsets: Attribute<EdgeInsets?>?,
        children: Attribute<[ViewResponder]>,
        responder: ShapeResponder<ContentShape>
    ) {
        self._modifier = modifier
        self._position = position
        self._size = size
        self._transform = transform
        self._hitTestInsets = OptionalAttribute(hitTestInsets)
        self._children = children
        self.responder = responder
    }
    
    fileprivate mutating func updateValue() {
        responder.helper.update(data: $modifier.changedValue(),
                                size: $size.changedValue(),
                                position: $position.changedValue(),
                                hitTestInsets: $hitTestInsets?.changedValue(),
                                transform: $transform.changedValue(),
                                parent: responder)
        
        responder.children = children
        
        if !hasValue {
            value = [responder]
        }
    }

}
