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

import Foundation
internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {
    
    /// Sets the transparency of this view.
    ///
    /// Apply opacity to reveal views that are behind another view or to
    /// de-emphasize a view.
    ///
    /// When applying the `opacity(_:)` modifier to a view that has already had
    /// its opacity transformed, the modifier multiplies the effect of the
    /// underlying opacity transformation.
    ///
    /// The example below shows yellow and red rectangles configured to overlap.
    /// The top yellow rectangle has its opacity set to 50%, allowing the
    /// occluded portion of the bottom rectangle to be visible:
    ///
    ///     struct Opacity: View {
    ///         var body: some View {
    ///             VStack {
    ///                 Color.yellow.frame(width: 100, height: 100, alignment: .center)
    ///                     .zIndex(1)
    ///                     .opacity(0.5)
    ///
    ///                 Color.red.frame(width: 100, height: 100, alignment: .center)
    ///                     .padding(-40)
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameter opacity: A value between 0 (fully transparent) and 1 (fully
    ///   opaque).
    ///
    /// - Returns: A view that sets the transparency of this view.
    @inlinable
    public func opacity(_ opacity: Double) -> some View {
        modifier(_OpacityEffect(opacity: opacity))
    }
    
}

@frozen
@available(iOS 13.0, *)
public struct _OpacityEffect : RendererEffect, Equatable {
    
    public typealias AnimatableData = Double
    
    public var opacity: Double
    
    public var animatableData: Double {
        set {
            opacity = newValue
        }
        
        get {
            return opacity
        }
    }
    
    @inlinable
    public init(opacity: Double) {
        self.opacity = opacity
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .opacity(Float(self.opacity))
    }
    
    public static func _makeView(modifier: _GraphValue<_OpacityEffect>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {

        makeRendererEffect(effect: modifier, inputs: inputs) { graph, viewInputs in
            
            var output = body(graph, viewInputs)
            
            if inputs.preferences.requiresViewResponders {
                let responder = OpacityViewResponder(inputs: inputs)
                let children = OptionalAttribute(output.viewResponders)
                
                let filter = Attribute(
                    OpacityResponderFilter(
                        effect: modifier.value,
                        children: children,
                        responder: responder
                    )
                )

                output.viewResponders = filter
            }

            return output
        }
    }
    
}

@available(iOS 13.0, *)
private final class OpacityViewResponder: DefaultLayoutViewResponder {

    fileprivate var _opacity: Double
    
    fileprivate override init(inputs: _ViewInputs) {
        self._opacity = 1.0
        super.init(inputs: inputs)
    }

    fileprivate override var opacity: Double {
        _opacity
    }
    
    fileprivate override func extendPrintTree(string: inout String) { //BDCOV_EXCL_BLOCK 没有调用点
        string.append("opacity \(_opacity)")
    }
    
    fileprivate override func containsGlobalPoints(_ globalPoints: [CGPoint], isDerived: [Bool], cacheKey: UInt32?) -> ContainsPointsResult {
        opacity > 0 ? super.containsGlobalPoints(globalPoints, isDerived: isDerived, cacheKey: cacheKey) : ContainsPointsResult()
    }

}

@available(iOS 13.0, *)
internal struct OpacityResponderFilter: StatefulRule {
    
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var effect: _OpacityEffect

    @OptionalAttribute
    internal var children: [ViewResponder]?

    fileprivate let responder: OpacityViewResponder
    
    internal mutating func updateValue() {
        let effect = self.effect
        responder._opacity = effect.opacity
        
        if let childrenAttribute = $children {
            let (children, childrenChanged) = childrenAttribute.changedValue()
            if childrenChanged {
                responder.children = children
            }
        }
        if !hasValue {
            value = [responder]
        }
    }
    
}
