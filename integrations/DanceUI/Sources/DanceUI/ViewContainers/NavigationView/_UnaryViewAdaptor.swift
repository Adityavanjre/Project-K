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

@frozen
@available(iOS 13.0, *)
public struct _UnaryViewAdaptor<Content: View>: UnaryView, PrimitiveView {
    
    public var content: Content
    
    @inlinable
    public init(_ content: Content) {
        self.content = content
    }
    
    public static func _makeView(view: _GraphValue<_UnaryViewAdaptor<Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        let content = view[{ .of(&$0.content) }]
        return Content.makeDebuggableView(value: content, inputs: inputs)
    }
    
}
