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

/// An effect that changes the visual appearance of a view, largely without
/// changing its ancestors or descendants.
///
/// The only change the effect makes to the view's ancestors and descendants is
/// to change the coordinate transform to and from them.
@available(iOS 13.0, *)
public protocol GeometryEffect: ViewModifier, Animatable where Body == Never {

    /// Returns the current value of the effect.
    func effectValue(size: CGSize) -> ProjectionTransform
    
    static var _affectsLayout: Bool { get }
}

@available(iOS 13.0, *)
extension GeometryEffect {
    
    public static var _affectsLayout: Bool {
        true
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let animatable = makeAnimatable(value: modifier, inputs: inputs.base)
        let layoutDirection = inputs.environmentAttribute(keyPath: \.layoutDirection)
        let size = inputs.animatedSize
        let position = inputs.animatedPosition
        
        let transform = GeometryEffectTransform(effect: animatable,
                                                size: size,
                                                position: position,
                                                transform: inputs.transform,
                                                layoutDirection: layoutDirection)
        var newInputs = inputs
        newInputs.transform = Attribute(transform)
        let zeroPosition = ViewGraph.current.$zeroPoint
        newInputs.position = zeroPosition
        newInputs.containerPosition = zeroPosition
        newInputs.size = Attribute(RoundedSize(position: inputs.position,
                                               size: inputs.size,
                                               pixelLength: inputs.environmentAttribute(keyPath: \.pixelLength)))
        
        var outputs = body(_Graph(), newInputs)
        guard inputs.preferences.requiresDisplayList else {
            return outputs
        }
        let id: DisplayList.Identity = .make()
        
        let displayList = GeometryEffectDisplayList(effect: animatable,
                                                    position: inputs.animatedPosition,
                                                    size: inputs.animatedSize,
                                                    layoutDirection: layoutDirection,
                                                    containerPosition: inputs.containerPosition,
                                                    content: .init(outputs.displayList),
                                                    identity: id)
        outputs.displayList = Attribute(displayList)
        return outputs
    }

    public static func _makeViewList(modifier: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        var outputs = body(_Graph(), inputs)
        outputs.multiModifier(modifier, inputs: inputs)
        return outputs
    }
}

@available(iOS 13.0, *)
internal struct RoundedSize: Rule {
    
    internal typealias Value = ViewSize
    
    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var pixelLength: CGFloat
    
    internal var value: Value {
        var value = self.size
        var rect = CGRect(origin: self.position.value, size: value.value)
        rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
        value.value = rect.size
        return value
    }

}
