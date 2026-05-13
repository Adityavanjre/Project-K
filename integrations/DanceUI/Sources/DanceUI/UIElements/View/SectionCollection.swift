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
public struct SectionCollection: RandomAccessCollection {
    
    internal let base: [SectionConfiguration]
    
    public subscript(index: Int) -> SectionConfiguration {
        base[index]
    }
    
    public var startIndex: Int {
        base.startIndex
    }
    
    public var endIndex: Int {
        base.endIndex
    }
    
    public typealias Element = SectionConfiguration
    
    public typealias Index = Int
    
    public typealias Indices = Range<Int>
    
    public typealias Iterator = IndexingIterator<SectionCollection>
    
    public typealias SubSequence = Slice<SectionCollection>
}

@available(iOS 13.0, *)
public struct SectionConfiguration: Identifiable {
    
    internal let item: SectionAccumulator.Item
    
    public struct ID: Hashable {
        internal let base: AnyHashable
    }
    
    public var id: SectionConfiguration.ID {
        .init(base: item.id)
    }
    
    public var header: SubviewsCollection {
        guard item.headerCount > 0,
              let sectionList = item.sectionList else {
            guard let subgraph = item.contentSubgraph else {
                _danceuiFatalError("content subgraph is nil.")
            }
            let emptyViewList = EmptyViewList()
            let children = _VariadicView_Children(list: emptyViewList, contentSubgraph: subgraph, transform: .init())
            return SubviewsCollection(base: children)
        }
        
        let (headerList, headerListAttribute) = sectionList.header
        return makeSubviewsCollection(from: (list: headerList, attribute: headerListAttribute))
    }
    
    public var footer: SubviewsCollection {
        guard item.footerCount > 0,
              let sectionList = item.sectionList else {
            guard let subgraph = item.contentSubgraph else {
                _danceuiFatalError("content subgraph is nil.")
            }
            let emptyViewList = EmptyViewList()
            let children = _VariadicView_Children(list: emptyViewList, contentSubgraph: subgraph, transform: .init())
            return SubviewsCollection(base: children)
        }
        
        let (footerList, footerListAttribute) = sectionList.footer
        return makeSubviewsCollection(from: (list: footerList, attribute: footerListAttribute))
    }
    
    public var content: SubviewsCollection {
        if let sectionList = item.sectionList {
            let (contentList, contentListAttribute) = sectionList.content
            return makeSubviewsCollection(from: (list: contentList, attribute: contentListAttribute))
        } else {
            let viewListSlice = ViewListSlice(base: item.list, bounds: item.start..<item.start + item.count)
            guard let subgraph = item.contentSubgraph else {
                _danceuiFatalError("content subgraph is nil.")
            }
            let children = _VariadicView_Children(list: viewListSlice, contentSubgraph: subgraph, transform: item.transform)
            return SubviewsCollection(base: children)
        }
    }
    
    internal var hasSubsections: Bool {
        guard item.features.contains(.implicit) else {
            return false
        }
        
        return item.count > 0
    }
    
    internal func makeSubviewsCollection(from: (list: ViewList, attribute: Attribute<ViewList>)) -> SubviewsCollection {
        guard let contentSubgraph = item.contentSubgraph else {
            fatalError("content subgraph is nil.")
        }
        let children = _VariadicView_Children(list: from.list, contentSubgraph: contentSubgraph, transform: item.transform)
        return SubviewsCollection(base: children)
    }
    
    
    internal struct Actions: View {
        
        internal var base: AnyView?
        
        internal var body: some View {
            base
        }
    }
}
