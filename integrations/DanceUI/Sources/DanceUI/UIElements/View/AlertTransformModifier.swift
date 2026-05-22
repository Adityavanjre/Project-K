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
internal struct AlertTransformModifier<KeyType: PreferenceKey>: PrimitiveViewModifier, MultiViewModifier {
    
    internal var transform: (inout KeyType.Value, ViewIdentity, CGRect) -> ()
    
    fileprivate struct Transform: StatefulRule {
        
        fileprivate typealias Value = (inout KeyType.Value) -> ()
        
        @Attribute
        fileprivate var modifier: AlertTransformModifier<KeyType>
        
        @Attribute
        fileprivate var phase: _GraphInputs.Phase
        
        @Attribute
        fileprivate var position: ViewOrigin
        
        @Attribute
        fileprivate var size: ViewSize
        
        @Attribute
        fileprivate var transform: ViewTransform
        
        fileprivate var helper: ViewIdentity.Tracker
        
        fileprivate mutating func updateValue() {
            
            if helper.id.seed == 0 || phase.seed != helper.resetSeed {
                helper = ViewIdentity.Tracker(id: ViewIdentity.make(), resetSeed: phase.seed)
            }
            
            var transform = self.transform
            
            let transformWidth = position.value.x - transform.positionAdjustment.width
            
            let transformHeight = position.value.y - transform.positionAdjustment.height
            
            if transformWidth != 0 || transformHeight != 0 {
                transform.appendTranslation(.init(width: -transformWidth, height: -transformHeight))
            }
            
            let space: CoordinateSpace = .named(.init(HostingViewCoordinateSpace()))
            let size = self.size.value
            var rect: CGRect = .init(x: 0, y: 0, width: size.width, height: size.height)
            
            if rect.isValid {
                var cornerPoints = rect.cornerPoints
                
                cornerPoints.convert(to: space, transform: transform)
                
                if cornerPoints.count < 4 {
                    _danceuiFatalError("cornerPoints count less than 4.")
                }
                
                let newRect: CGRect = .init(cornerPoints: ArraySlice(cornerPoints))
                
                rect = newRect
            }
            
            let modifierValue = _modifier.value
            
            let viewId = helper.id
            
            self.value = { value in
                modifierValue.transform(&value, viewId, rect)
            }
        }
    }
    
    internal static func _makeView(modifier: _GraphValue<AlertTransformModifier<KeyType>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let animatedPosition = inputs.animatedPosition
        
        let animatedSize = inputs.animatedSize
        
        var outputs = body(_Graph(), inputs)
        
        let transform =  Transform(modifier: modifier.value, phase: inputs.base.phase, position: animatedPosition, size: animatedSize, transform: inputs.transform, helper: .init(id: .zero, resetSeed: 0x0))
        
        let transformAttribute = Attribute.init(transform)
        
        outputs.preferences.makePreferenceTransformer(inputs: inputs.preferences, key: KeyType.self, transform: transformAttribute)
        
        return outputs
    }
}
