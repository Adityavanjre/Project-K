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
internal struct StackPlacement<Layout: IncrementalStack> {

    internal let stack: Layout

    internal let axis: Axis

    internal let minorSize: CGFloat

    internal let minorCount: Int

    internal let minorGeometry: Layout.MinorGeometry

    internal let visible: ClosedRange<CGFloat>

    internal let pinnedViews: PinnedScrollableViews

    internal let queriedIndex: Int?

    internal var index: Int = 0

    internal var skipFirst: Bool = false

    internal var position: CGFloat

    internal var stoppingCondition: StoppingCondition

    internal var currentChildren: [_IncrementalLayout_Child] = []

    internal var lastChildren: [_IncrementalLayout_Child]? = nil

    internal var pendingHeader: _IncrementalLayout_Child? = nil

    internal var placedChildren: [_IncrementalLayout_PlacedChild] = []

    internal var placedIndex: (min: Int, max: Int) = (min: .max, max: .min)

    internal var placedPosition: (min: CGFloat, max: CGFloat) = (min: .infinity, max: -.infinity)

    internal var placedQuery: (min: CGFloat, max: CGFloat) = (min: .infinity, max: -.infinity)

    internal var measuredLength: (total: CGFloat, samples: Int) = (total: 0, samples: 0)

    internal var measuredSpacing: (total: CGFloat, samples: Int) = (total: 0, samples: 0)
    
    @inlinable
    internal var nextPlacedIndex: (min: Int, max: Int) {
        if placedIndex.max >= placedIndex.min {
            return (placedIndex.min, placedIndex.max + 1)
        } else {
            return (index, index)
        }
    }
    
    @inlinable
    internal var nextPlacedPosition: (min: CGFloat, max: CGFloat) {
        if placedPosition.max <= placedPosition.min {
            return (position, position)
        } else {
            return (placedPosition.min, placedPosition.max)
        }
    }
    
    internal mutating func reset(index: Int, position: CGFloat, stoppingCondition: StoppingCondition, skipFirst: Bool) {
        self.index = index
        self.position = position
        self.skipFirst = skipFirst
        self.stoppingCondition = stoppingCondition
        currentChildren.removeAll()
        lastChildren = nil
        pendingHeader = nil
        placedChildren.removeAll()
        placedIndex = (.max, .min)
        placedPosition = (.infinity, -.infinity)
        placedQuery = (.infinity, -.infinity)
        measuredLength = (0, 0)
        measuredSpacing = (0, 0)
    }
    
    @usableFromInline
    internal mutating func place(children: _IncrementalLayout_Children, from index: Int, position: CGFloat, stopping: StoppingCondition, style: _ViewList_IteratorStyle) -> Bool {
        reset(index: index, position: position, stoppingCondition: stopping, skipFirst: false)
        if self.index >= minorCount {
            skipFirst = true
            self.index = self.index - minorCount
        }
        var inoutIndex = self.index
        let result = children.applyNodes(from: &inoutIndex, style: style) { (subIndex, node, stop) in
            switch node {
            case .children(let childrenNode):
                _ = childrenNode.apply(from: &subIndex, style: style) { (child, stop) in
                    placeBody(child: child)
                    stop = needsStop
                }
            case .section(let section):
                placeSection(section, from: &subIndex)
            }
            stop = needsStop
        }
        flushMinorGroup()
        return result
    }
    
    internal mutating func placeBody(child: _IncrementalLayout_Child) {
        currentChildren.append(child)
        guard currentChildren.count == minorCount else {
            return
        }
        flushMinorGroup()
    }
    
    internal mutating func placeSection(_ section: _IncrementalLayout_Section, from index: inout Int) {
        pendingHeader = nil
        flushMinorGroup()
        guard !needsStop else {
            return
        }
        var headerStart: Int = 0
        section.header.forEachChild(from: &headerStart, style: .default) { child, stop in
            placeHeaderOrFooter(start: &index, child: child, kind: .header)
            stop = needsStop
        }
        guard !needsStop else {
            return
        }
        section.content.forEachChild(from: &index, style: .default) { child, stop in
            placeBody(child: child)
            stop = needsStop
        }
        let absMinorCount = abs(self.minorCount)
        if index != 0 && absMinorCount != 1 {
            index = index/absMinorCount
        }
        flushMinorGroup()
        guard !needsStop || pinnedViews.contains(.sectionFooters) else {
            return
        }
        var footerStart: Int = 0
        section.footer.forEachChild(from: &footerStart, style: .default) { child, stop in
            placeHeaderOrFooter(start: &index, child: child, kind: .footer)
            stop = needsStop
        }
        
    }
    
    internal mutating func flushMinorGroup() {
        guard !currentChildren.isEmpty else {
            return
        }
        guard !skipFirst else {
            skipFirst = false
            index += minorCount
            swapChildren(&lastChildren, &currentChildren)
            return
        }
        let info = stack.lengthAndSpacing(children: currentChildren, predecessors: lastChildren, minorGeometry: minorGeometry)
        let length = info.length
        let spacing = info.spacing
        addMeasurements(length: length, spacing: lastChildren == nil ? nil : spacing)
        position += spacing
        if isVisible(length: length) {
            addVisibleChild(length: length, spacing: spacing)
            flushPendingHeader()
            stack.place(children: currentChildren, length: length, minorGeometry: minorGeometry) { (child, rect, anchor) in
                let originValue = rect.origin.value(for: axis)
                var newRect = rect
                newRect.origin.setValue(originValue + position, for: axis)
                emit(child, in: newRect, anchor: anchor)
            }
        }
        position += length
        index += minorCount
        swapChildren(&lastChildren, &currentChildren)
    }
    
    internal mutating func addMeasurements(length: CGFloat, spacing: CGFloat?) {
        measuredLength.total += length
        measuredLength.samples += 1
        guard let spacing = spacing else {
            return
        }
        measuredSpacing.total += spacing
        measuredSpacing.samples += 1
    }
    
    internal func isVisible(length: CGFloat) -> Bool {
        if let conditionValue = stoppingCondition.value {
            let endIndex = index + minorCount
            _danceuiPrecondition(endIndex >= index)
            return conditionValue >= index && conditionValue < endIndex
        } else {
            let visibleLow: CGFloat = .maximum(visible.lowerBound, position)
            let visibleUpper: CGFloat = .minimum(visible.upperBound, length + position)
            return visibleUpper >= visibleLow
        }
    }
    
    internal mutating func addVisibleChild(length: CGFloat, spacing: CGFloat) {
        placedIndex.min = index <= placedIndex.min ? index : placedIndex.min
        let sumIndex = index + minorCount
        let maxIndex = sumIndex - 1
        placedIndex.max = max(maxIndex, placedIndex.max)
        placedPosition.min = .minimum(position - spacing, placedPosition.min)
        placedPosition.max = .maximum(position + length, placedPosition.max)
        assert(placedIndex.min < .max && placedIndex.max > .min)
        guard placedIndex.min < .max && placedIndex.max > .min else {
            return
        }
        
        guard let queriedIndex = queriedIndex else {
            return
        }
        _danceuiPrecondition(sumIndex >= index)
        guard queriedIndex >= index && queriedIndex < sumIndex else {
            return
        }
        placedQuery.min = .minimum(placedQuery.min, position)
        placedQuery.max = .maximum(placedQuery.max, length + position)
    }
    
    internal mutating func placeHeaderOrFooter(start: inout Int, child: _IncrementalLayout_Child, kind: _IncrementalLayout_Child.Kind) {
        guard start == 0 else {
            start = start - minorCount
            
            if kind == .header {
                if pendingHeader == nil {
                    pendingHeader = child
                }
            }
            
            return
        }
        
        if skipFirst {
            skipFirst = false
            if kind == .header {
                pendingHeader = child
            }
        } else {
            let (var38_length, var30_spacing) = stack.lengthAndSpacing(children: [child], predecessors: lastChildren, size: minorSize, axis: axis)
            addMeasurements(length: var38_length, spacing: lastChildren != nil ? var30_spacing : nil)
            self.position += var30_spacing
            if isVisible(length: var38_length) {
                addVisibleChild(length: var38_length, spacing: var30_spacing)
                flushPendingHeader()
                stack.place(child: child, kind: kind, position: position, length: var38_length, minorSize: minorSize) {
                    emit($0, in: $1, anchor: $2)
                }
            } else {
                if kind == .footer && pinnedViews.contains(.sectionFooters) {
                    if placedIndex.min < placedIndex.max {
                        flushPendingHeader()
                        stack.place(child: child, kind: kind, position: position, length: var38_length, minorSize: minorSize) {
                            emit($0, in: $1, anchor: $2)
                        }
                    }
                } else if kind == .header {
                    pendingHeader = child
                }
            }
            self.position += var38_length
        }
        
        self.index = self.index + self.minorCount
        
        var count = minorCount
        while count > 0 {
            self.currentChildren.append(child)
            count -= 1
        }
        
        swapChildren(&lastChildren, &currentChildren)
    }
    
    internal mutating func flushPendingHeader() {
        guard let var140_header = pendingHeader,
              pinnedViews.contains(.sectionHeaders),
              stoppingCondition.value == nil else {
            return
        }
        let (length, _) = stack.lengthAndSpacing(children: [var140_header], predecessors: nil, size: minorSize, axis: axis)
        stack.place(child: var140_header, kind: .header, position: -length, length: length, minorSize: minorSize) { (child, rect, anchor) in
            emit(child, in: rect, anchor: anchor)
        }
        pendingHeader = nil
    }
    
    internal mutating func emit(_ child: _IncrementalLayout_Child, in rect: CGRect, anchor: UnitPoint) {
        let item = child.cache.item(data: child.data)
        item.willPlace()
        let anchorPosition = CGPoint(x: rect.width * anchor.x + rect.origin.x, y: rect.height * anchor.y + rect.origin.y)
        let placedChild = _IncrementalLayout_PlacedChild(item: item, placement: .init(proposedSize: rect.size, anchor: anchor, at: anchorPosition))
        placedChildren.append(placedChild)
    }
    
    internal mutating func measureBackwards(children: [_IncrementalLayout_Child], lastIndex: Int, lastPosition: CGFloat, firstChild: Bool) {
        reset(index: lastIndex, position: lastPosition, stoppingCondition: .init(value: nil), skipFirst: true)
        for child in children.reversed() {
            if child.isSectionHeaderOrFooter {
                flushBackwards(includeEmpty: false)
                currentChildren.append(child)
                flushBackwards(includeEmpty: false)
            } else {
                currentChildren.append(child)
                if currentChildren.count == minorCount {
                    flushBackwards(includeEmpty: false)
                }
            }
            if visible.lowerBound >= position {
                return
            }
        }
        flushBackwards(includeEmpty: firstChild)
    }
    
    internal mutating func flushBackwards(includeEmpty: Bool) {
        let hasCurrentChildren = !currentChildren.isEmpty
        guard hasCurrentChildren || includeEmpty else {
            return
        }
        currentChildren.reverse()
        guard !skipFirst else {
            skipFirst = false
            swapChildren(&lastChildren, &currentChildren)
            return
        }
        let lastChildren = self.lastChildren!
        let lastChild = lastChildren[0]
        let predecessors: [_IncrementalLayout_Child]? = hasCurrentChildren ? currentChildren : nil
        let length: CGFloat
        let spacing: CGFloat
        if lastChild.isSectionHeaderOrFooter {
            (length, spacing) = stack.lengthAndSpacing(children: lastChildren, predecessors: predecessors, size: minorSize, axis: axis)
        } else {
            (length, spacing) = stack.lengthAndSpacing(children: lastChildren, predecessors: predecessors, minorGeometry: minorGeometry)
        }
        position -= length + spacing
        index -= minorCount
        swapChildren(&self.lastChildren, &currentChildren)
    }
    
    private var needsStop: Bool {
        let stop: Bool
        if let conditionValue = stoppingCondition.value {
            stop = conditionValue < index
        } else {
            stop = position >= visible.upperBound
        }
        return stop
    }
}

@available(iOS 13.0, *)
extension StackPlacement {
    
    internal struct StoppingCondition {
        internal var value: Int?
    }
}
