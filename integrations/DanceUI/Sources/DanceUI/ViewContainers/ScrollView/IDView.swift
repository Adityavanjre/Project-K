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
@usableFromInline
@frozen
internal struct IDView<Content: View, ID: Hashable>: View, PrimitiveView {
    

    @usableFromInline
    internal var content: Content
    
    @usableFromInline
    internal var id: ID
    
    @inlinable
    internal init(_ content: Content, id: ID) {
        self.content = content
        self.id = id
    }
    
    @usableFromInline
    internal static func _makeView(view: _GraphValue<IDView<Content, ID>>, inputs: _ViewInputs) -> _ViewOutputs {
        let id = view[{.of(&$0.id)}]
        var newInputs = inputs
        newInputs.phase = Attribute(IDPhase(id: id.value, phase: inputs.phase))
        return Content.makeDebuggableView(value: view[{.of(&$0.content)}], inputs: newInputs)
    }
    
    @usableFromInline
    internal static func _makeViewList(view: _GraphValue<IDView<Content, ID>>, inputs: _ViewListInputs) -> _ViewListOutputs {
        var newInputs = inputs
        newInputs.needTransition = true
        let viewList = IDViewList(view: view.value, inputs: newInputs, lastItem: nil)
        return _ViewListOutputs(
            views: .dynamicList(Attribute(viewList), nil),
            nextImplicitID: newInputs.implicitID,
            staticCount: nil
        )
    }
    
    @usableFromInline
    internal static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        Content._viewListCount(inputs: inputs)
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Binds a view's identity to the given proxy value.
    ///
    /// When the proxy value specified by the `id` parameter changes, the
    /// identity of the view — for example, its state — is reset.
    @inlinable
    public func id<ID: Hashable>(_ id: ID) -> some View {
        IDView(self, id: id)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct IDPhase<ID: Hashable>: StatefulRule {
    
    internal typealias Value = _GraphInputs.Phase
    
    @Attribute
    internal var id: ID

    @Attribute
    internal var phase: _GraphInputs.Phase
    
    internal var lastID: ID? = nil
    
    internal var delta: UInt32 = 0
    
    internal mutating func updateValue() {
        let id = self.id
        if lastID != id {
            lastID = id
            delta &+= 1
        }
        var phase = self.phase
        phase.seed &+= delta
        value = phase
    }
}
