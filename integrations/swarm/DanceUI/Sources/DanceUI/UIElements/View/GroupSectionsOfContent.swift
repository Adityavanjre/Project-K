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
public struct GroupSectionsOfContent<Sections, Content>: View where Sections: View, Content: View {
    internal let sections: Sections

    internal let content: (SectionCollection) -> Content
    
    public var body: some View {
        _VariadicView.Tree(root: SectionsRoot(content: self.content), content: self.sections)
    }
}

@available(iOS 13.0, *)
internal struct SectionsRoot<Root: View>: _VariadicView_MultiViewRoot {
    
    internal let content: (SectionCollection) -> Root
    
    internal static func _makeView(root: _GraphValue<Self>,
                                   inputs: _ViewInputs,
                                   body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        .multiView(inputs: inputs) { graph, viewInputs in
            let outputs = body(_Graph(), viewInputs)
            let viewListInputs = _ViewListInputs(base: viewInputs.base)
            let viewListAttribute = outputs.makeAttribute(inputs: viewListInputs)
            let rootAttribute = root.value
            let currentSubGraph = DGSubgraphRef.current!
            let child = Child(view: rootAttribute, viewList: viewListAttribute, contentSubgraph: currentSubGraph)
            let childAttribute = Attribute(child)
            return Root.makeDebuggableViewList(value: _GraphValue(childAttribute), inputs: viewInputs.implicitRootBodyInputs)
        }
    }
    
    internal static func _makeViewList(root: _GraphValue<Self>, 
                                       inputs: _ViewListInputs,
                                       body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let outputs = body(_Graph(), inputs)
        let newListInputs = _ViewListInputs(base: inputs.base)
        let viewListAttribute = outputs.makeAttribute(inputs: newListInputs)
        let rootAttribute = root.value
        let currentSubGraph = DGSubgraphRef.current!
        let child = Child(view: rootAttribute, viewList: viewListAttribute, contentSubgraph: currentSubGraph)
        let childAttribute = Attribute(child)
        return Root.makeDebuggableViewList(value: _GraphValue(childAttribute), inputs: inputs)
    }
    
    internal static var _viewListOptions: _ViewListInputs.Options {
        [.requiresDepthAndSections, .requiresSections, .allowsNestedSections]
    }
    
    internal struct Child: Rule {
        @Attribute
        internal var view: SectionsRoot<Root>
        
        @Attribute
        internal var viewList: ViewList
        
        internal var contentSubgraph: DGSubgraphRef
        
        internal init(view: Attribute<SectionsRoot<Root>>, viewList: Attribute<ViewList>, contentSubgraph: DGSubgraphRef) {
            self._view = view
            self._viewList = viewList
            self.contentSubgraph = contentSubgraph
        }
        
        internal var value: Root {
            let viewList = self.viewList
            let items = SectionAccumulator.processUnsectionedContent(list: viewList, contentSubgraph: self.contentSubgraph)
            let viewRoot = self.view
            
            guard let items else {
                var sectionAccumulator = SectionAccumulator(contentSubgraph: self.contentSubgraph)
                sectionAccumulator.formResult(from: viewList, listAttribute: _viewList, includeEmptySectionsIf: { false })
                let configurations = sectionAccumulator.items.map({ SectionConfiguration(item: $0) })
                return viewRoot.content(SectionCollection(base: configurations))
            }
            
            guard !items.isEmpty else {
                return viewRoot.content(SectionCollection(base: []))
            }
            
            let configurations = items.map({ SectionConfiguration(item: $0) })
            return viewRoot.content(SectionCollection(base: configurations))
        }
    }
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    internal static func multiView(inputs: _ViewInputs, 
                                   body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        return withoutActuallyEscaping(body) { escapingClosure in
            let implicitRootType = inputs.implicitRootType
            var visitor = MakeViewRoot(inputs: inputs, body: escapingClosure)
            implicitRootType.visitType(visitor: &visitor.self)
            
            guard let outputs = visitor.outputs else {
                _danceuiPreconditionFailure()
            }
            
            return outputs
        }
    }
}
