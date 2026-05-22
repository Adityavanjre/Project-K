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
internal struct _IncrementalLayout_Children {

    internal var cache: ViewCache

    internal var context: DanceUIGraph.AnyRuleContext

    internal var node: _ViewList_Node

    internal var transform: _ViewList_SublistTransform

    internal var section: ViewCache.Section

    @inline(__always)
    internal func forEachChild(from index: inout Int, style: _ViewList_IteratorStyle, to body: (_IncrementalLayout_Child, inout Bool) -> ()) {
        _ = apply(from: &index, style: style, to: body)
    }

    internal func apply(from index: inout Int, style: _ViewList_IteratorStyle, to body: (_IncrementalLayout_Child, inout Bool) -> ()) -> Bool {

        func applyNode(start: inout Int, style: _ViewList_IteratorStyle, node: _ViewList_Node, transform: inout _ViewList_SublistTransform, section: ViewCache.Section) -> Bool {
            switch node {
            case .list:
                _danceuiFatalError()
            case .sublist(var sublist):
                for item in transform.items.reversed() {
                    item.apply(sublist: &sublist)
                }
                
                guard sublist.start < sublist.count else {
                    return true
                }

                var start = sublist.start
                while start < sublist.count {
                    var listID = sublist.id
                    listID._index = numericCast(start)
                    let child = _IncrementalLayout_Child(cache: cache, context: context, data: _IncrementalLayout_Child.Data(elements: sublist.elements, id: listID, traits: sublist.traits, list: sublist.list, section: section))
                    var result = false
                    body(child, &result)
                    guard !result else {
                        return false
                    }
                    start &+= 1
                }
                return true
            case .group(let group):
                return group.applyNodes(from: &start, style: style, transform: &transform) { (idx, style, node, subTransform) -> Bool in
                    applyNode(start: &idx, style: style, node: node, transform: &subTransform, section: section)
                }
            case .section(let section):
                return section.applyNodes(from: &start, style: style, transform: &transform) { idx, style, node, sectionInfo, subTransfrom in
                    applyNode(start: &idx, style: style, node: node, transform: &subTransfrom, section: .init(id: sectionInfo.id, isHeader: sectionInfo.isHeader, isFooter: sectionInfo.isFooter))
                }
            }
        }
        var transformValue = transform
        return node.applyNodes(from: &index, style: style, transform: &transformValue) { (index, style, node, transform) -> Bool in
            applyNode(start: &index, style: style, node: node, transform: &transform, section: section)
        }
    }

    internal func firstIndex<Index: Hashable>(id: Index, style: _ViewList_IteratorStyle) -> Int? {
        node.firstOffset(forID: id, style: style)
    }

    internal func firstIndex(of canonical: _ViewList_ID.Canonical, style: _ViewList_IteratorStyle) -> Int? {
        var index = 0
        var idx = 0
        let result = apply(from: &idx, style: style) { child, stop in
            guard canonical != .init(id: child.data.id) else {
                stop = true
                return
            }
            index += 1
        }
        return result ? nil : index
    }

    internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, to body: (inout Int, Node, inout Bool) -> ()) -> Bool {
        func applyNode(start: inout Int, style: _ViewList_IteratorStyle, node: _ViewList_Node, transform: inout _ViewList_SublistTransform) -> Bool {
            switch node {
            case .list:
                _danceuiFatalError()
            case .sublist:
                var result = false
                body(&start, .children(_IncrementalLayout_Children(cache: cache, context: context, node: node, transform: transform, section: section)), &result)
                return !result
            case .group(let group):
                return group.applyNodes(from: &start, style: style, transform: &transform) { (idx, style, node, subTransform) -> Bool in
                    applyNode(start: &idx, style: style, node: node, transform: &subTransform)
                }
            case .section(let section):
                var result = false
                body(&start, .section(_IncrementalLayout_Section(base: section, transform: transform, cache: cache, context: context)), &result)
                return !result
            }
        }
        var transformValue = transform
        return node.applyNodes(from: &index, style: style, transform: &transformValue) { (index, style, node, transform) -> Bool in
            applyNode(start: &index, style: style, node: node, transform: &transform)
        }
    }

}

@available(iOS 13.0, *)
extension _IncrementalLayout_Children {

    internal enum Node {

        case children(_IncrementalLayout_Children)

        case section(_IncrementalLayout_Section)

    }
}

@available(iOS 13.0, *)
public struct _ScrollLayout: Equatable {

    public var contentOffset: CGPoint

    public var size: CGSize

    public var visibleRect: CGRect

    @inline(__always)
    internal var contentRect: CGRect {
        CGRect(origin: contentOffset, size: size)
    }

    public init(contentOffset: CGPoint, size: CGSize, visibleRect: CGRect) {
        self.contentOffset = contentOffset
        self.size = size
        self.visibleRect = visibleRect
    }

}

@available(iOS 13.0, *)
internal struct _IncrementalLayout_PlacementContext {

    @Attribute
    internal var placedChildren: [_IncrementalLayout_PlacedChild]

    @Attribute
    internal var environment: EnvironmentValues

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    internal var pinnedViews: PinnedScrollableViews

    @Attribute
    internal var accessibilityEnabled: Bool

    internal var scrolledGeometry: _ScrollLayout {
        var transform = self.transform

        transform.appendViewOrigin(self.position)
        let size = self.size.value
        var scrollLayout: _ScrollLayout
        if let layout = transform.containingScrollLayout {
            scrollLayout = layout
        } else {
            scrollLayout = .init(contentOffset: .zero, size: size, visibleRect: .init(origin: .zero, size: size))
        }
        guard self.accessibilityEnabled else {
            return scrollLayout
        }

        if size.width > scrollLayout.size.width {
            var clampedOriginX = scrollLayout.visibleRect.origin.x - scrollLayout.size.width
            clampedOriginX = clampedOriginX > 0 ? clampedOriginX : 0
            clampedOriginX = .minimum(clampedOriginX, scrollLayout.visibleRect.origin.x)
            let extendedVisibleRight = scrollLayout.visibleRect.size.width + (scrollLayout.visibleRect.origin.x - clampedOriginX)
            var maxVisibleWidth = size.width - clampedOriginX
            var candidateVisibleRight = scrollLayout.size.width + extendedVisibleRight
            candidateVisibleRight = .minimum(candidateVisibleRight, maxVisibleWidth)
            
            let finalVisibleWidth: CGFloat = .maximum(candidateVisibleRight, extendedVisibleRight)

            scrollLayout.visibleRect.origin.x = clampedOriginX
            scrollLayout.visibleRect.size.width = finalVisibleWidth
        }

        if size.height > scrollLayout.size.height {
            var clampedOriginY = scrollLayout.visibleRect.origin.y - scrollLayout.size.height
            clampedOriginY = clampedOriginY > 0 ? clampedOriginY : 0
            clampedOriginY = .minimum(clampedOriginY, scrollLayout.visibleRect.origin.y)

            let originYOffset =
                scrollLayout.visibleRect.origin.y - clampedOriginY

            let extendedVisibleBottom =
                scrollLayout.visibleRect.size.height + originYOffset

            var maxVisibleHeight = size.height - clampedOriginY

            var candidateVisibleBottom = scrollLayout.size.height + extendedVisibleBottom
            candidateVisibleBottom = .minimum(candidateVisibleBottom, maxVisibleHeight)

            let finalVisibleHeight: CGFloat = .maximum(extendedVisibleBottom, candidateVisibleBottom)

            scrollLayout.visibleRect.origin.y = clampedOriginY
            scrollLayout.visibleRect.size.height = finalVisibleHeight
        }
        return scrollLayout
    }
}

@available(iOS 13.0, *)
internal struct _IncrementalLayout_Placements {

    internal var placedChildren: [_IncrementalLayout_PlacedChild] = []

    internal var rect: CGRect? = .null

    @usableFromInline
    internal var offset: CGSize = .zero

    @inlinable
    internal mutating func setOffset(_ value: CGFloat, for axis: Axis) {
        switch axis {
        case .horizontal:
            offset.width = value
        case .vertical:
            offset.height = value
        }
    }

}
