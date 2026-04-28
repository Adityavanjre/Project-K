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
internal protocol RendererLeafView: _RendererLeafView, LeafViewLayout {
    
}

@available(iOS 13.0, *)
extension RendererLeafView {
    
    internal static func makeLeafView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var outputs = _makeLeafView(view: view, inputs: inputs)
        
        makeLeafLayout(&outputs, view: view, inputs: inputs)
        
        return outputs
    }
}

/// Leaf display-list for renderer leaf-view.
@available(iOS 13.0, *)
private struct LeafDisplayList<View: _RendererLeafView>: StatefulRule {
    
    fileprivate typealias Value = DisplayList
    
    @Attribute
    fileprivate var view: View
    
    @Attribute
    fileprivate var position: ViewOrigin
    
    @Attribute
    fileprivate var size: ViewSize
    
    @Attribute
    fileprivate var containerPosition: ViewOrigin
    
    fileprivate let identity: DisplayList.Identity
    
    fileprivate var contentSeed: DisplayList.Seed
    
    fileprivate init(view: Attribute<View>,
                     position: Attribute<ViewOrigin>,
                     size: Attribute<ViewSize>,
                     containerPosition: Attribute<ViewOrigin>,
                     identity: DisplayList.Identity,
                     contentSeed: DisplayList.Seed) {
        self._view = view
        self._position = position
        self._size = size
        self._containerPosition = containerPosition
        self.identity = identity
        self.contentSeed = contentSeed
    }
    
    fileprivate mutating func updateValue() {
        let size = self.size.value
        let view = $view.changedValue(options: DGInputOptions())
        let version = DisplayList.Version.make()
        if view.changed {
            contentSeed = .init(version: version)
        }
        let position = self.position
        let containerPosition = self.containerPosition
        let origin = CGPoint(x: position.value.x - containerPosition.value.x, y: position.value.y - containerPosition.value.y)
        let content = DisplayList.Content(value: view.value.content(),
                                          seed: contentSeed)
        let frame = CGRect(origin: origin, size: size)
        _danceuiPrecondition(!frame.isInfinite && !frame.isNull)
        
        var item = DisplayList.Item(
            frame: frame,
            version: version,
            value: .content(content),
            identity: identity
        )
        item.canonicalize()
        value = DisplayList(item: item)
    }
    
}

@available(iOS 13.0, *)
extension _RendererLeafView {
    
    internal static func _makeLeafView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        var outputs = _ViewOutputs()
        
        if inputs.preferences.requiresDisplayList {
            var displayListAttribute: Attribute<DisplayList>
            let leafDisplayList = LeafDisplayList(view: view.value,
                                                  position: inputs.animatedPosition,
                                                  size: inputs.animatedSize,
                                                  containerPosition: inputs.containerPosition,
                                                  identity: .make(),
                                                  contentSeed: .zero)
            let leafDisplayListAttribute = Attribute(leafDisplayList)
            displayListAttribute = leafDisplayListAttribute
            
            outputs.displayList = displayListAttribute
        }
        
        if inputs.preferences.requiresViewResponders {
            let leafResponderFilter = LeafResponderFilter(
                data: view.value,
                size: inputs.animatedSize,
                position: inputs.animatedPosition,
                transform: inputs.transform,
                // We don't have to remove the `hitTestInsets` in the view
                // inputs, because this is a leaf view.
                hitTestInsets: inputs.hitTestInsets)
            outputs.viewResponders = Attribute(leafResponderFilter)
        }
        
        return outputs
    }
}
