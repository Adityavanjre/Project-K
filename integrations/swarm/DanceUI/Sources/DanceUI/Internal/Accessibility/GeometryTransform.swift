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
internal func makeAccessibilityGeometryTransform(for nodeList: Attribute<AccessibilityNodeList>?, inputs: _ViewInputs, outputs: _ViewOutputs) -> Attribute<AccessibilityNodeList> {
    let geometryTransform = GeometryTransform(
        token: nodeList.map { .attribute($0.identifier) },
        accessibilityEnabled: inputs.environmentAttribute(keyPath: \.accessibilityEnabled),
        size: inputs.size,
        position: inputs.position,
        transform: inputs.transform,
        viewResponders: outputs.viewResponders,
        nodeList: nodeList ?? outputs.accessibilityNodes
    )
    
    return Attribute(geometryTransform)
}

@available(iOS 13.0, *)
fileprivate struct GeometryTransform: StatefulRule {
    
    fileprivate typealias Value = AccessibilityNodeList

    private let token: AccessibilityAttachmentToken?

    @Attribute
    private var accessibilityEnabled: Bool

    @Attribute
    private var size: ViewSize

    @Attribute
    private var position: ViewOrigin

    @Attribute
    private var transform: ViewTransform

    @OptionalAttribute
    private var viewResponders: [ViewResponder]?

    @OptionalAttribute
    private var nodeList: AccessibilityNodeList?
    
    fileprivate init(
        token: AccessibilityAttachmentToken?,
        accessibilityEnabled: Attribute<Bool>,
        size: Attribute<ViewSize>,
        position: Attribute<ViewOrigin>,
        transform: Attribute<ViewTransform>,
        viewResponders: Attribute<[ViewResponder]>?,
        nodeList: Attribute<AccessibilityNodeList>?
    ) {
        self.token = token
        self._accessibilityEnabled = accessibilityEnabled
        self._size = size
        self._position = position
        self._transform = transform
        self._viewResponders = OptionalAttribute(viewResponders)
        self._nodeList = OptionalAttribute(nodeList)
    }
    
    fileprivate mutating func updateValue() {
        guard accessibilityEnabled, let nodeList = nodeList else {
            value = .empty
            return
        }
        
        defer {
            value = nodeList
        }
        
        let token = self.token ?? .attribute(.current!)
        
        let (size, sizeChanged) = $size.changedValue()
        
        let (position, positionChanged) = $position.changedValue()
        
        var (transform, transformChanged) = $transform.changedValue()
        
        let viewRespondersChanged: Bool
        
        if let attribute = $viewResponders {
            (_, viewRespondersChanged) = attribute.changedValue()
        } else {
            viewRespondersChanged = false
        }
                
        guard sizeChanged || positionChanged || transformChanged || viewRespondersChanged else {
            return
        }
        
        transform.appendViewOrigin(position)
        
        for node in nodeList.nodes {
            if sizeChanged {
                node.updateSize(size.value, token: token)
            }
            
            if positionChanged || transformChanged {
                node.updateTransform(transform, token: token)
            }
            
            if viewRespondersChanged || !node.hasPath(for: token) {
                node.updateViewResponders(WeakAttribute($viewResponders), token: token)
            }
        }
    }

}
