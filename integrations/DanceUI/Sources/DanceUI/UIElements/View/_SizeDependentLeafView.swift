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
internal protocol _SizeDependentLeafView: PrimitiveView, UnaryView, ContentResponder {
    static var animatesSize: Bool { get }
    func content(size: CGSize) -> (DisplayList.Content.Value, CGRect)
    
    static func _makeLeafView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs
}

@available(iOS 13.0, *)
extension _SizeDependentLeafView {
    
    internal static var animatesSize: Bool {
        true
    }
    
    internal static func _makeLeafView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let size = inputs.animatedSize
        let origin = inputs.animatedPosition
        
        var outputs = _ViewOutputs()
        if inputs.preferences.requiresDisplayList {
            let pixelLength = inputs.environmentAttribute(keyPath: \EnvironmentValues.pixelLength)
            
            var leafDisplayList = LeafDisplayList(view: view.value,
                                                    position: origin,
                                                    size: size,
                                                    containerPosition: inputs.containerPosition,
                                                    inputPosition: inputs.position,
                                                    inputSize: inputs.size,
                                                    transform: inputs.transform,
                                                    environment: inputs.environment,
                                                    pixelLength: pixelLength,
                                                    identity: .make(),
                                                    clipIdentity: .make(),
                                                    contentSeed: .zero)
            
            leafDisplayList.$safeAreaInsets = inputs.safeAreaInsets.attribute
            
            let displayList = Attribute(leafDisplayList)
            outputs.displayList = displayList
        }
        
        if inputs.preferences.requiresViewResponders {
            let leafResponderFilter = LeafResponderFilter(
                data: view.value,
                size: size,
                position: origin,
                transform: inputs.transform,
                // We don't have to remove the `hitTestInsets` in the view
                // inputs, because this is a leaf view.
                hitTestInsets: inputs.hitTestInsets)
            outputs.viewResponders = Attribute(leafResponderFilter)
        }
        
        return outputs
    }
}

@available(iOS 13.0, *)
fileprivate struct LeafDisplayList<View: _SizeDependentLeafView> : StatefulRule {
    
    fileprivate typealias Value = DisplayList

    @Attribute
    fileprivate var view: View

    @Attribute
    fileprivate var position: ViewOrigin

    @Attribute
    fileprivate var size: ViewSize

    @Attribute
    fileprivate var containerPosition: ViewOrigin

    @Attribute
    fileprivate var inputPosition: ViewOrigin

    @Attribute
    fileprivate var inputSize: ViewSize

    @Attribute
    fileprivate var transform: ViewTransform

    @Attribute
    fileprivate var environment: EnvironmentValues

    @Attribute
    fileprivate var pixelLength: CGFloat

    @OptionalAttribute
    fileprivate var safeAreaInsets: SafeAreaInsets?

    fileprivate let identity: DisplayList.Identity

    fileprivate let clipIdentity: DisplayList.Identity

    fileprivate var contentSeed: DisplayList.Seed
    
    fileprivate var roundedSize: CGSize {
        var rect = CGRect(origin: inputPosition.value, size: inputSize.value)
        rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
        return rect.size
    }
    
    fileprivate mutating func updateValue() {
        let (size, sizeChanged) = View.animatesSize ? $size.changedValue() : $inputSize.changedValue()
        let (view, viewChanged) = $view.changedValue()
        let version = DisplayList.Version.make()

        let geometryProxy = GeometryProxy(owner: DGWeakAttribute(DGAttribute.current),
                                          _size: WeakAttribute($size),
                                          _environment: WeakAttribute($environment),
                                          _transform: WeakAttribute($transform),
                                          _position: WeakAttribute($position),
                                          _safeAreaInsets: WeakAttribute($safeAreaInsets),
                                          _seed: UInt32(version.value))
        let (value, rect) = withGeometryProxy(geometryProxy) {
            view.content(size: size.value)
        }
        
        if sizeChanged || viewChanged {
            contentSeed = DisplayList.Seed(version: version)
        }
        
        var displayListItem = DisplayList.Item(frame: CGRect(origin: CGPoint(x: position.value.x - containerPosition.value.x + rect.origin.x,
                                                                             y: position.value.y - containerPosition.value.y + rect.origin.y),
                                                             size: rect.size),
                                               version: version,
                                               value: .content(DisplayList.Content(value: value, seed: contentSeed)),
                                               identity: identity)
        displayListItem.canonicalize()
        
        var item = displayListItem
        
        if !View.animatesSize {
            let viewSize = self.size.value
            if !roundedSize.equalTo(viewSize) {
                let rect = CGRect(origin: .zero, size: viewSize)
                let effect: DisplayList.Effect = rect.isNull ? .clip(Path(.zero), FillStyle(eoFill: false, antialiased: false)) : .clip(Path(rect), FillStyle(eoFill: true, antialiased: false))
                
                displayListItem.frame = rect
                if case .empty = displayListItem.value {
                    item.value = .effect(effect, DisplayList.empty)
                    item.identity = clipIdentity
                } else {
                    item.value = .effect(effect, DisplayList(item: displayListItem))
                    item.identity = clipIdentity
                }
            }
        }
        if case .empty = item.value {
            self.value = DisplayList.empty
        } else {
            #warning("DisplayList.features")
            self.value = DisplayList(item: item)
        }
    }
}
