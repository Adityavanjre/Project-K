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
internal struct SectionAccumulator {
    
    internal var pendingChunks: [RowIDs.Chunk]
    
    internal var pendingChunkIDCount: Int
    
    internal var lastExplicitSectionEnd: Int
    
    internal var list: ViewList?
    
    internal var contentSubgraph: DGSubgraphRef?
    
    internal var items: [Item]
    
    internal var viewCount: Int
    
    internal init(contentSubgraph: DGSubgraphRef?) {
        self.pendingChunks = []
        self.pendingChunkIDCount = 0
        self.lastExplicitSectionEnd = 0
        self.list = nil
        self.contentSubgraph = contentSubgraph
        self.items = []
        self.viewCount = 0
    }
    
    internal static func processUnsectionedContent(list: ViewList,
                                                   contentSubgraph: DGSubgraphRef?) -> [Item]? {
        guard let traitKeys = list.traitKeys,
              !traitKeys.contains(IsSectionedTraitKey.self) else {
            return nil
        }
        
        guard let viewIds = list.viewIDs,
              !viewIds.isEmpty else {
            return []
        }
        
        return [SectionAccumulator.Item.implicitSentinel(list, contentSubgraph: contentSubgraph)]
    }
    
    internal mutating func formResult(from: ViewList,
                                      listAttribute: Attribute<ViewList>?,
                                      includeEmptySectionsIf: () -> Bool) {
        Update.perform {
            self.list = from
            var sublistTransform = _ViewList_SublistTransform()
            let iteratorStyle = _ViewList_IteratorStyle.default
            var index: Int = 0
            let listGraphValue: _GraphValue<ViewList>? = listAttribute.map({ .init($0) })
            let _ = from.applyNodes(from: &index, style: iteratorStyle, list: listGraphValue, transform: &sublistTransform) { start, style, node, transform in
                self.apply(start: &start, style: style, node: node, transform: &transform, includeEmptySection: includeEmptySectionsIf)
            }
            
            if self.lastExplicitSectionEnd < self.viewCount {
                appendImplicitSection()
            }
            
            if items.isEmpty {
                if viewCount > 0 {
                    self.items = [Item.implicitSentinel(from, contentSubgraph: nil)]
                } else {
                    self.items = []
                }
            }
            
            self.list = nil
        }
    }
    
    internal mutating func apply(start: inout Int,
                                 style: _ViewList_IteratorStyle,
                                 node: _ViewList_Node,
                                 transform: inout _ViewList_SublistTransform,
                                 includeEmptySection: () -> Bool) -> Bool {
        switch node {
        case .list((let viewList, let viewListAttribite)):
            guard let traitKeys = viewList.traitKeys,
                  !traitKeys.contains(IsSectionedTraitKey.self) else {
                return viewList.applyNodes(from: &start,
                                           style: style,
                                           list: viewListAttribite,
                                           transform: &transform) { indexValue, iteratorStyle, viewListNode, subListTransfrom in
                    apply(start: &indexValue, style: iteratorStyle, node: viewListNode, transform: &subListTransfrom, includeEmptySection: includeEmptySection)
                }
            }
            
            let count = viewList.count
            let chunk = RowIDs.Chunk(list: viewList,
                                     listAttribute: viewListAttribite?.value,
                                     transform: transform,
                                     start: start,
                                     count: count,
                                     lowerBound: pendingChunkIDCount)
            self.pendingChunks.append(chunk)
            self.pendingChunkIDCount &+= count
            self.viewCount &+= count
            return true
        case .sublist(let subList):
            var viewListSubList = subList
            transform.apply(sublist: &viewListSubList)
            let subListCount = viewListSubList.count
            let subListID = viewListSubList.id
            let elementsCollection = subListID.elementIDs(count: subListCount)
            let ids = RowIDs.IDs.sublist(elementsCollection)
            let chunk = RowIDs.Chunk(ids: ids, count: subListCount, lownerBound: self.pendingChunkIDCount)
            self.pendingChunks.append(chunk)
            self.pendingChunkIDCount &+= subListCount
            self.viewCount &+= subListCount
            return true
        case .group(let viewListGroup):
            let lists = viewListGroup.lists
            guard !lists.isEmpty else {
                return true
            }
            
            for listTuple in lists {
                let shouldContinue = self.apply(start: &start, 
                                                style: style,
                                                node: .list(listTuple), 
                                                transform: &transform,
                                                includeEmptySection: includeEmptySection)
                if !shouldContinue {
                    break
                }
            }
            return false
        case .section(let viewListSection):
            if viewCount > lastExplicitSectionEnd {
                self.appendImplicitSection()
            }
            
            let viewListCount = viewListSection.count
            guard viewListCount > 0 || includeEmptySection() else {
                self.viewCount = self.lastExplicitSectionEnd
                return true
            }
            
            let content = viewListSection.content
            let contentListCount = content.list.count
            let chunk = RowIDs.Chunk(list: content.list, 
                                     listAttribute: content.attribute,
                                     transform: .init(),
                                     start: 0,
                                     count: contentListCount,
                                     lowerBound: 0)
            let headerCount = viewListSection.header.list.count
            let footerCount = viewListSection.footer.list.count
            let sectionID = viewListSection.id
            let item = Item(features: .zero, list: content.list,
                            contentSubgraph: self.contentSubgraph,
                            sectionList: viewListSection,
                            transform: transform,
                            ids: .init(chunks: [chunk]),
                            headerCount: headerCount,
                            footerCount: footerCount,
                            id: sectionID,
                            start: 0)
            self.items.append(item)
            let totalCount = self.viewCount + viewListCount
            self.viewCount = totalCount
            self.lastExplicitSectionEnd = totalCount
            return true
        }
    }
    
    fileprivate mutating func appendImplicitSection() {
        guard let list else {
            fatalError("view list is nil.")
        }
     
        let ids = SectionAccumulator.RowIDs(chunks: self.pendingChunks)
        let implictItem = Item(features: .implicit, list: list,
                               contentSubgraph: self.contentSubgraph,
                               sectionList: nil,
                               transform: .init(),
                               ids: ids,
                               headerCount: 0, footerCount: 0,
                               id: UInt32(items.count),
                               start: self.lastExplicitSectionEnd)
        self.items.append(implictItem)
        self.pendingChunks = []
        self.pendingChunkIDCount = 0
    }
    
    internal struct Item {
        
        internal var features: Features
        
        internal var list: ViewList
        
        internal var contentSubgraph: DGSubgraphRef?
        
        internal var sectionList: _ViewList_Section?
        
        internal var transform: _ViewList_SublistTransform
        
        internal var ids: SectionAccumulator.RowIDs
        
        internal var headerCount: Int
        
        internal var footerCount: Int
        
        internal var id: UInt32
        
        internal var start: Int
        
        internal init(features: Features, 
                      list: ViewList,
                      contentSubgraph: DGSubgraphRef?, 
                      sectionList: _ViewList_Section?,
                      transform: _ViewList_SublistTransform,
                      ids: SectionAccumulator.RowIDs,
                      headerCount: Int,
                      footerCount: Int,
                      id: UInt32, 
                      start: Int) {
            self.features = features
            self.list = list
            self.contentSubgraph = contentSubgraph
            self.sectionList = sectionList
            self.transform = transform
            self.ids = ids
            self.headerCount = headerCount
            self.footerCount = footerCount
            self.id = id
            self.start = start
        }
        
        internal static func implicitSentinel(_ viewList: ViewList, contentSubgraph: DGSubgraphRef?) -> Item {
            let viewCount = Update.perform {
                viewList.count
            }
            
            let itemTransform = _ViewList_SublistTransform()
            let itemChunk = RowIDs.Chunk(list: viewList, listAttribute: nil, 
                                         transform: _ViewList_SublistTransform(),
                                         start: 0,
                                         count: viewCount,
                                         lowerBound: 0)
            let rowIDs = RowIDs(chunks: [itemChunk])
            return Item(features: .implicit,
                        list: viewList,
                        contentSubgraph: contentSubgraph, 
                        sectionList: nil,
                        transform: itemTransform,
                        ids: rowIDs,
                        headerCount: 0,
                        footerCount: 0,
                        id: 0,
                        start: 0)
        }
        
        internal var count: Int {
            ids.count
        }
        
        internal var hasRows: Bool {
            count > 0
        }
        
        internal struct Features: OptionSet {
            
            internal let rawValue: UInt8
            
            internal static let implicit: Features = .init(rawValue: 0x1)
            
            internal static let zero: Features = .init(rawValue: 0x0)
        }
    }
    
    internal struct RowIDs: RandomAccessCollection {
        
        internal var chunks: [Chunk]
        
        internal subscript(position: Int) -> _ViewList_ID.Canonical {
            guard let targetChunk = chunks.first(where: { position > $0.count + $0.lowerBound }) else {
                fatalError("Can not find target Chunks.")
            }
            
            let index = position &- targetChunk.lowerBound
            switch targetChunk.ids {
            case .viewListIDs(let views):
                return .init(id: views[index])
            case .idArray(let array):
                guard index < array.count else {
                    fatalError("Index beyond idArray count.")
                }
                return .init(id: array[index])
            case .sublist(let elementCollection):
                return .init(id: elementCollection[index])
            }
        }
        
        internal var startIndex: Int {
            chunks.first?.lowerBound ?? 0
        }
        
        internal var endIndex: Int {
            guard let lastChunk = chunks.last else {
                return 0
            }
            return lastChunk.count &+ lastChunk.lowerBound
        }
        
        internal typealias Index = Int
        
        internal typealias SubSequence = Slice<RowIDs>
        
        internal typealias Indices = Range<Int>
        
        internal typealias Element = _ViewList_ID.Canonical
        
        internal typealias Iterator = IndexingIterator<RowIDs>
        
        internal enum IDs {
            case viewListIDs(_ViewList_ID.Views)
            
            case idArray([_ViewList_ID])
            
            case sublist(_ViewList_ID.ElementCollection)
        }
        
        internal struct Chunk {
            internal var ids: IDs
            
            internal var count: Int
            
            internal var lowerBound: Int
            
            internal init(ids: IDs, count: Int, lownerBound: Int) {
                self.ids = ids
                self.count = count
                self.lowerBound = lownerBound
            }
            
            internal init(list: ViewList,
                          listAttribute: Attribute<ViewList>?,
                          transform: _ViewList_SublistTransform,
                          start: Int,
                          count: Int,
                          lowerBound: Int) {
                var countValue = count
                if let viewIDs = list.viewIDs {
                    if transform.items.isEmpty {
                        self.ids = .viewListIDs(viewIDs)
                    } else {
                        let transformedIDs = TransformedIDs(base: viewIDs, transform: transform)
                        let viewListIDView = _ViewList_ID._Views(transformedIDs, isDataDependent: true)
                        self.ids = .viewListIDs(viewListIDView)
                    }
                } else {
                    var viewListIDs: [_ViewList_ID] = []
                    var startValue = start
                    let _ = list.applyIDs(from: &startValue, 
                                          listAttribute: listAttribute,
                                          transform: transform) { id in
                        viewListIDs.append(id)
                        countValue &-= 1
                        return countValue != 0
                    }
                    self.ids = .idArray(viewListIDs)
                }
                self.count = countValue
                self.lowerBound = lowerBound
            }
        }
    }
    
    internal struct TransformedIDs: RandomAccessCollection, Equatable {
        
        internal var base : _ViewList_ID.Views
        
        internal var transform: _ViewList_SublistTransform
        
        internal subscript(position: Int) -> _ViewList_ID {
            let viewListID = base[position]
            var viewListSubList = _ViewList_Sublist(start: 0, count: 1, id: viewListID, elements: EmptyViewListElements(), traits: ViewTraitCollection(), list: nil, fromForEach: false)
            self.transform.apply(sublist: &viewListSubList)
            return viewListSubList.id
        }
        
        internal var startIndex: Int {
            base.startIndex
        }
        
        internal var endIndex: Int {
            base.endIndex
        }
        
        internal static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.base == rhs.base &&
            lhs.transform.items.count == rhs.transform.items.count
        }
        
        internal typealias Element = _ViewList_ID
        
        internal typealias Index = Int
        
        internal typealias SubSequence = Slice<TransformedIDs>
        
        internal typealias Indices = Range<Int>
        
        internal typealias Iterator = IndexingIterator<TransformedIDs>
    }
}

@available(iOS 13.0, *)
extension ViewList {
    internal func applyIDs(from: inout Int,
                           style: _ViewList_IteratorStyle = .default,
                           listAttribute: Attribute<ViewList>?,
                           transform: _ViewList_SublistTransform,
                           to: (_ViewList_ID) -> Bool) -> Bool {
//        guard style == .default,
//              let viewIDs else {
//            var listGraphValue: _GraphValue<ViewList>? = listAttribute.map({ _GraphValue<ViewList>($0) })
//            return applyNodes(from: &from,
//                              style: style,
//                              list: listGraphValue,
//                              transform: &transform) { indexValue, iteratorStyle, listNode, subListTransfrom in
//                switch listNode {
//                case .list((let viewList, let viewListGraphValue)):
//                    return viewList.applyIDs(from: &indexValue, style: iteratorStyle, listAttribute: viewListGraphValue?.value, transform: subListTransfrom, to: to)
//                case .sublist(let viewListSubList):
//                    
//                case .group(let viewListGroup):
//                    guard !viewListGroup.lists.isEmpty else {
//                        return true
//                    }
//                case .section(let viewListSection):
//                    
//                }
//            }
//        }
//        
        true
    }
}
