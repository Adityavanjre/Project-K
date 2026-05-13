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
internal protocol RendererEffect: MultiViewModifier, PrimitiveViewModifier, Animatable {
    
    func effectValue(size: CGSize) -> DisplayList.Effect
    
    static var isolatesChildPosition: Bool {get}
}

@available(iOS 13.0, *)
extension RendererEffect {
    
    internal static var isolatesChildPosition: Bool {
        false
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeRendererEffect(effect: modifier, inputs: inputs, body: body)
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal static func makeRendererEffect(effect: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let animatable = makeAnimatable(value: effect, inputs: inputs.base)
        let containerPosition: Attribute<ViewOrigin>
        
        var newInputs = inputs
        if isolatesChildPosition {
            let resetTransform = ResetPositionTransform(position: inputs.animatedPosition,
                                                        transform: inputs.transform)
            containerPosition = ViewGraph.current.$zeroPoint
            newInputs.transform = Attribute(resetTransform)
        } else {
            containerPosition = inputs.animatedPosition
        }
        
        newInputs.containerPosition = containerPosition
        
        var bodyOutput = body(_Graph(), newInputs)
        
        guard newInputs.preferences.requiresDisplayList else {
            return bodyOutput
        }
        let effectDisplayList = RendererEffectDisplayList<Self>(identity: .make(),
                                                                effect: animatable,
                                                                position: inputs.animatedPosition,
                                                                size: inputs.animatedSize,
                                                                transform: inputs.transform,
                                                                containerPosition: inputs.containerPosition,
                                                                environment: inputs.environment,
                                                                safeAreaInsets: inputs.safeAreaInsets,
                                                                content: .init(bodyOutput.displayList))
        bodyOutput.displayList = Attribute(effectDisplayList)
        
        return bodyOutput
    }
}

@available(iOS 13.0, *)
private struct RendererEffectDisplayList<Effect: RendererEffect>: Rule {
    
    internal typealias Value = DisplayList
    
    internal let identity: DisplayList.Identity
    
    @Attribute
    internal var effect: Effect
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var transform: ViewTransform
    
    @Attribute
    internal var containerPosition: ViewOrigin
    
    @Attribute
    internal var environment: EnvironmentValues
    
    @OptionalAttribute
    internal var safeAreaInsets: SafeAreaInsets?
    
    @OptionalAttribute
    internal var content: DisplayList?
    
    
    internal var value: DisplayList {
        guard let contentDisplayList = content, !contentDisplayList.items.isEmpty else {
            return .empty
        }
        let version = DisplayList.Version.make()
        let geometryProxy = GeometryProxy(owner: DGWeakAttribute(DGAttribute.current),
                                          _size: WeakAttribute($size),
                                          _environment: WeakAttribute($environment),
                                          _transform: WeakAttribute($transform),
                                          _position: WeakAttribute($position),
                                          _safeAreaInsets: WeakAttribute($safeAreaInsets),
                                          _seed: UInt32(version.value))
        let size = size.value
        let effectValue = withGeometryProxy(geometryProxy) {
            effect.effectValue(size: size)
        }
        
        
        let origin = CGPoint(x: position.value.x - containerPosition.value.x, y: position.value.y - containerPosition.value.y)
        let item = DisplayList.Item(frame: .init(origin: origin, size: size),
                                    version: version,
                                    value: .effect(effectValue, contentDisplayList),
                                    identity: identity).canonicalized()
        
        return DisplayList(item: item)
    }
    
}
