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

@available(iOS 13.0, *)
public enum _VariadicView {

    public typealias Root = _VariadicView_Root

    public typealias ViewRoot = _VariadicView_ViewRoot

    public typealias Children = _VariadicView_Children

    public typealias UnaryViewRoot = _VariadicView_UnaryViewRoot

    public typealias MultiViewRoot = _VariadicView_MultiViewRoot

    @frozen
    public struct Tree<Root: _VariadicView_Root, Content> {

        public var root: Root
        public var content: Content

        @usableFromInline
        internal init(root: Root, content: Content) {
            self.root = root
            self.content = content
        }

        @inlinable
        public init(_ root: Root, @ViewBuilder content: () -> Content) {
            self.root = root
            self.content = content()
        }

    }

}

@available(iOS 13.0, *)
extension _VariadicView.Tree: UnaryView, PrimitiveView, View where Root: _VariadicView_ViewRoot, Content: View {

    public typealias Body = Never

    public static func _makeView(view: _GraphValue<_VariadicView.Tree<Root, Content>>, inputs: _ViewInputs) -> _ViewOutputs {

        let rootValue = view[{ .of(&$0.root) }]
        var newInputs = inputs
        newInputs.viewListOptions = Root._viewListOptions

        return Root.makeDebuggableView(value: rootValue, inputs: newInputs) { _, inputs in
            let content = view[{ .of(&$0.content) }]
            let contentInputs = _ViewListInputs(base: inputs.base,
                                                  implicitID: 0,
                                                  options: inputs.viewListOptions,
                                                  traitKeys: ViewTraitKeys())
            return Content._makeViewList(view: content, inputs: contentInputs)
        }
    }

    public static func _makeViewList(view: _GraphValue<_VariadicView.Tree<Root, Content>>, inputs: _ViewListInputs) -> _ViewListOutputs {

        let rootValue = view[{ .of(&$0.root) }]
        var newInputs = inputs
        let rootViewListOptions = Root._viewListOptions
        if newInputs.viewListOptions != rootViewListOptions {
            newInputs.viewListOptions = rootViewListOptions
        }
        return Root._makeViewList(root: rootValue, inputs: newInputs) { _, inputs in
            let content = view[{ .of(&$0.content) }]
            let viewListOptions = inputs.unionViewListOptions(inputs.viewListOptions)
            let contentInputs = _ViewListInputs(base: inputs.base,
                                                implicitID: inputs.implicitID,
                                                options: viewListOptions,
                                                traits: .init(inputs.$traits),
                                                traitKeys: inputs.traitKeys)
            return Content._makeViewList(view: content, inputs: contentInputs)
        }
    }

    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        var newInputs = inputs
        newInputs.viewListOptions = Root._viewListOptions
        return Root._viewListCount(inputs: newInputs) { rootInputs in
            var contentInputs = rootInputs
            contentInputs.viewListOptions = rootInputs.viewListOptions.union(inputs.viewListOptions)
            return Content._viewListCount(inputs: contentInputs)
        }
    }
}

@available(iOS 13.0, *)
internal struct MakeViewRoot: _VariadicView_ImplicitRoot, _VariadicView_ImplicitRootVisitor {

    internal typealias Body = Never

    internal var inputs: _ViewInputs

    internal var body: (_Graph, _ViewInputs) -> _ViewListOutputs

    internal var outputs: _ViewOutputs?

    @inline(__always)
    internal init(inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewListOutputs) {
        self.inputs = inputs
        self.body = body
        self.outputs = nil
    }

    internal mutating func visit<RootType: _VariadicView_ImplicitRoot>(type: RootType.Type) {

        let attr = inputs.intern(RootType.implicitRoot, id: .init(1))
        outputs = type._makeView(root: _GraphValue(attr), inputs: inputs, body: body)
    }

    internal static var implicitRoot: MakeViewRoot {
        _notImplemented()
    }
}
