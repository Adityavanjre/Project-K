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
internal struct LeafResponderFilter<Responder: ContentResponder>: StatefulRule {
    
    internal typealias Value = [ViewResponder]
    
    @Attribute
    internal var data: Responder
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var transform: ViewTransform
    
    @OptionalAttribute
    internal var hitTestInsets: EdgeInsets??
    
    internal let responder: LeafViewResponder<Responder>
    
    @inlinable
    internal init(data: Attribute<Responder>,
                  size: Attribute<ViewSize>,
                  position: Attribute<ViewOrigin>,
                  transform: Attribute<ViewTransform>,
                  hitTestInsets: Attribute<EdgeInsets?>?) {
        _data = data
        _size = size
        _position = position
        _transform = transform
        _hitTestInsets = OptionalAttribute(hitTestInsets)
        responder = .init()
    }
    
    internal mutating func updateValue() {
        responder.helper.update(data: $data.changedValue(),
                                size: $size.changedValue(),
                                position: $position.changedValue(),
                                hitTestInsets: $hitTestInsets?.changedValue(),
                                transform: $transform.changedValue(),
                                parent: responder)
        guard !hasValue else {
            return
        }
        value = [responder]
    }

}
