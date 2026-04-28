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

@available(iOS 13.0, *)
extension StackLayout {
    
    internal struct UnmanagedImplementation {
        
        private let layout: UnsafeMutablePointer<StackLayout>
        
        private let children: UnsafeMutableBufferPointer<StackLayout.Child>
        
        internal init(layout: UnsafeMutablePointer<StackLayout>, 
                      children: UnsafeMutableBufferPointer<StackLayout.Child>) {
            self.layout = layout
            self.children = children
        }
        
        internal var header: StackLayout.Header {
            get {
                layout.pointee.header
            }
            
            nonmutating set {
                layout.pointee.header = newValue
            }
        }
        
        @usableFromInline
        internal func placeChildren(in size: _ProposedSize) {
            guard header.findFittingSize(size) == nil else {
                return
            }
            guard !children.isEmpty else {
                return
            }
            guard header.lastProposedSize == nil || header.lastProposedSize != size else {
                return
            }
    #if DEBUG
            if size.width?.isNaN == true || size.height?.isNaN == true {
                _danceuiFatalError("Stack Layout can not place in a Nan Size")
            }
    #endif
            _placeChildren(in: size)
            
            header.lastProposedSize = size
            header.cacheFittingSizeInfo(size, fittingSize: header.stackSize)
        }
        
        internal func placeChildren1(in size: _ProposedSize, minorProposalForChild: (StackLayout.Child) -> CGFloat?) {
            let axis: Axis = header.majorAxis
            sizeChildren(in: size, minorProposalForChild: minorProposalForChild)
            var maxValue: CGFloat = 0
            var minValue: CGFloat = 0
            for child in children {
                let min: CGFloat = child.geometry.rect.minOriginValue(for: axis.minor)
                var max: CGFloat
                if child.geometry.rect.sizeValue(for: axis.minor) < .infinity {
                    max = child.geometry.rect.maxOriginValue(for: axis.minor)
                } else {
                    max = .infinity
                }
                //                _danceuiPrecondition(min <= max)
                minValue = .minimum(min, minValue)
                maxValue = .maximum(max, maxValue)
                _danceuiPrecondition(minValue <= maxValue)
            }
            
            var offset: CGFloat = 0
            for (index, child) in children.enumerated() {
                guard child.geometry.sizeValue(for: axis) > 0 ||
                        child.geometry.sizeValue(for: axis.minor) > 0 else {
                    // ignore child major axis dimension is zero
                    continue
                }
                offset += child.distanceToPrevious
                var otherAxisValue: CGFloat = child.geometry.originValue(for: axis.minor)
                if !offset.isNaN {
                    children[index].geometry.origin.value.setValue(offset, for: axis)
                }
                
                otherAxisValue -= minValue
                if !otherAxisValue.isNaN {
                    children[index].geometry.origin.value.setValue(otherAxisValue, for: axis.minor)
                }
                offset += child.geometry.sizeValue(for: axis)
            }
            let stackSize: CGSize
            let dimension: CGFloat = maxValue - minValue
            if header.majorAxis == .horizontal {
                stackSize = CGSize(width: offset, height: dimension)
            } else {
                stackSize = CGSize(width: dimension, height: offset)
            }
            header.stackSize = stackSize
        }
        
        private func _placeChildren(in size: _ProposedSize) {
            let axis: Axis = header.majorAxis
            
            placeChildren1(in: size) { (child) -> CGFloat? in
                size.value(for: axis.minor)
            }
            
            if header.resizeChildrenWithTrailingOverflow {
                // only _FromHVStack use
                resizeAnyChildrenWithTrailingOverflow(in: size)
            }
        }
        
        internal func sizeChildren(in size: _ProposedSize, minorProposalForChild: (StackLayout.Child) -> CGFloat?) {
            let axis: Axis = header.majorAxis
            if size.hasRequiredValue(for: axis)  {
                sizeChildrenGenerallyWithConcreteMajorProposal(in: size, minorProposalForChild: minorProposalForChild)
            } else {
                sizeChildrenIdeally(in: size, minorProposalForChild: minorProposalForChild)
            }
        }
        
        internal func sizeChildrenGenerallyWithConcreteMajorProposal(in size: _ProposedSize, minorProposalForChild: (StackLayout.Child) -> CGFloat?)  {
            let axis: Axis = header.majorAxis
            let hasNeededValue: Bool = size.hasRequiredValue(for: axis)
            _danceuiPrecondition(hasNeededValue)
            var reaminMajorAxisRange: CGFloat = size.value(for: axis)!
            reaminMajorAxisRange -= header.internalSpacing
            prioritize(proposedSize: size)
            
            guard !children.isEmpty else {
                // child == nil
                return
            }
            var index: Int = 0
            let count = children.count
            while index < count {
                let fittingOrder: Int = children[index].fittingOrder
                let fittingChild = children[fittingOrder]
                
                var firstLayoutPriorityNotEqualIndex: Int = count
                var flagCL: Bool = true
                if !fittingChild.layoutPriority.isNaN {
                    if let findIndex: Int = children.find(index + 1, endIndex: count, condition: { (findChild) -> Bool in
                        let fittingOrder: Int = findChild.fittingOrder
                        return children[fittingOrder].layoutPriority != fittingChild.layoutPriority
                    })?.index {
                        firstLayoutPriorityNotEqualIndex = findIndex
                        flagCL = false
                    }
                } else {
                    flagCL = false
                    firstLayoutPriorityNotEqualIndex = index
                }
                
                if children[0].fittingOrder == fittingOrder {
                    var otherLayoutPrioityTotalMinRange: CGFloat = 0
                    if !flagCL {
                        assert(firstLayoutPriorityNotEqualIndex < count)
                        otherLayoutPrioityTotalMinRange = CGFloat(children.reduce(0, startIndex: firstLayoutPriorityNotEqualIndex, endIndex: count, { (result, child) -> CGFloat in
                            let fittingChild = children[child.fittingOrder]
                            return result + fittingChild.majorAxisRangeCache.min!
                        }))
                    }
                    reaminMajorAxisRange -= otherLayoutPrioityTotalMinRange
                } else {
                    assert(index < firstLayoutPriorityNotEqualIndex)
                    var currentLayoutPrioityTotalMinRange: CGFloat = 0
                    if index != firstLayoutPriorityNotEqualIndex {
                        currentLayoutPrioityTotalMinRange = children.reduce(0, startIndex: index, endIndex: firstLayoutPriorityNotEqualIndex, { (result, child) -> CGFloat in
                            let fittingChild = children[child.fittingOrder]
                            return result + fittingChild.majorAxisRangeCache.min!
                        })
                    }
                    reaminMajorAxisRange += currentLayoutPrioityTotalMinRange
                }
                
                if index != firstLayoutPriorityNotEqualIndex {
                    let currentLayoutPriorityChildCount: Int = firstLayoutPriorityNotEqualIndex - index
                    var subIndex: Int = index
                    for remaingChildCount in (0..<currentLayoutPriorityChildCount).reversed() {
                        var evenlySplitRange: CGFloat = reaminMajorAxisRange / CGFloat(remaingChildCount &+ 1)
                        evenlySplitRange = evenlySplitRange <= 0 ? 0 : evenlySplitRange
                        let child: Child = children[subIndex]
                        let fittingOrder: Int = child.fittingOrder
                        let minor: CGFloat? = minorProposalForChild(child)
                        var proposedSize = _ProposedSize(width: 0, height: 0)
                        proposedSize.setValue(evenlySplitRange, for: axis)
                        proposedSize.setValue(minor, for: axis.minor)
                        
                        let layoutComputer: LayoutComputer = header.proxies[fittingOrder].proxy.layoutComputer
                        resize(&children[fittingOrder], at: fittingOrder, proposal: proposedSize, childLayoutComputer: layoutComputer)
                        
                        let value: CGFloat = children[fittingOrder].geometry.sizeValue(for: axis)
                        var deltaValue: CGFloat = reaminMajorAxisRange - value
                        if deltaValue.isNaN && deltaValue != .infinity {
                            deltaValue = reaminMajorAxisRange
                        }
                        subIndex &+= 1
                        reaminMajorAxisRange = deltaValue
                    }
                }
                index = firstLayoutPriorityNotEqualIndex
            }
        }
        
        internal func sizeChildrenIdeally(in: _ProposedSize, minorProposalForChild: (StackLayout.Child) -> CGFloat?) {
            guard !children.isEmpty else {
                return
            }
            let axis: Axis = header.majorAxis
            for (index, child) in children.enumerated() {
                let minorProposal: CGFloat? = minorProposalForChild(child)
                var proposal: _ProposedSize = .init()
                proposal.setValue(minorProposal, for: axis.minor)
                let layoutComputer = header.proxies[child.fittingOrder].proxy.layoutComputer
                resize(&children[index], at: index, proposal: proposal, childLayoutComputer: layoutComputer)
            }
        }
        
        internal func resizeAnyChildrenWithTrailingOverflow(in size: _ProposedSize) {
            let axis: Axis = header.majorAxis
            let proposedHeight: CGFloat = size.value(for: axis.minor) ?? .infinity
            let stackHeight: CGFloat = header.stackSize.height
            guard proposedHeight < stackHeight else {
                return
            }
            guard !children.contains(where: { $0.geometry.sizeValue(for: axis.minor) == stackHeight }) else {
                return
            }
            placeChildren1(in: size) { (child) -> CGFloat? in
                let rect: CGRect = child.geometry.rect
                let min: CGFloat = rect.minOriginValue(for: axis.minor)
                let sizeValue: CGFloat = rect.size.value(for: axis.minor)
                
                var max: CGFloat = .infinity
                if sizeValue < .infinity {
                    max = rect.maxOriginValue(for: axis.minor)
                }
                assert(max >= min)
                
                var result: CGFloat = max - proposedHeight
                result = result < 0 ? 0 : result
                result = proposedHeight - result
                return result
            }
        }
        
        internal func prioritize(proposedSize: _ProposedSize) {
            
            let axis: Axis = header.majorAxis
            
            if let lastProposedSize = header.lastProposedSize,
               let lastSizeValue: CGFloat = lastProposedSize.value(for: axis.minor),
               let proposedSizeValue: CGFloat = proposedSize.value(for: axis.minor) {
                if lastSizeValue == proposedSizeValue && lastProposedSize.value(for: axis) != nil {
                    return
                }
            }
            
            for index in (0..<children.count) {
                children[index].cleanMajorAxisRangeCache()
            }
            
            var sortedChildFittingOrder: [Int] = [Int](0..<children.count)
            
            sortedChildFittingOrder.sort { (lhs, rhs) -> Bool in
                let lhsFittingChild: Child = children[lhs]
                let rhsFittingChild: Child = children[rhs]
                
                if lhsFittingChild.layoutPriority != rhsFittingChild.layoutPriority {
                    return lhsFittingChild.layoutPriority > rhsFittingChild.layoutPriority
                }
                
                let rhsMinRange: CGFloat = header.minMajorAxisRange(for: rhsFittingChild, index: rhs, proposedSize: proposedSize)
                children[rhs].majorAxisRangeCache.min = rhsMinRange
                
                let rhsMaxRange: CGFloat = header.maxMajorAxisRange(for: rhsFittingChild, index: rhs, proposedSize: proposedSize)
                children[rhs].majorAxisRangeCache.max = rhsMaxRange
                
                
                let lhsMinRange: CGFloat = header.minMajorAxisRange(for: lhsFittingChild, index: lhs, proposedSize: proposedSize)
                children[lhs].majorAxisRangeCache.min = lhsMinRange
                
                let lhsMaxRange: CGFloat = header.maxMajorAxisRange(for: lhsFittingChild, index: lhs, proposedSize: proposedSize)
                children[lhs].majorAxisRangeCache.max = lhsMaxRange
                
                let rhsRangeDiff: CGFloat = rhsMaxRange - rhsMinRange
                let rhsRangeDiffFixed = rhsRangeDiff >= .infinity ? -rhsMinRange : 0
                
                let lhsRangeDiff: CGFloat = lhsMaxRange - lhsMinRange
                let lhsRangeDiffFixed = rhsRangeDiff >= .infinity ? -lhsMinRange : 0
                
                let needSwap: Bool = lhsRangeDiff != rhsRangeDiff ? lhsRangeDiff <= rhsRangeDiff : lhsRangeDiffFixed < rhsRangeDiffFixed
                return needSwap
            }
            
            for index in 0..<children.count {
                children[index].fittingOrder = Swift.max(0, sortedChildFittingOrder[index])
            }
            
            let firstFittingOrder: Int = children[0].fittingOrder
            
            for index in (0..<children.count).reversed() {
                let child = children[index]
                let fittingOrder: Int = child.fittingOrder
                let fitChild = children[fittingOrder]
                guard fitChild.layoutPriority != children[firstFittingOrder].layoutPriority else {
                    continue
                }
                guard fitChild.majorAxisRangeCache.min == nil else {
                    continue
                }
                var proposal: _ProposedSize = proposedSize
                proposal.setValue(0, for: axis)
                let min: CGFloat = header.proxies[fittingOrder].lengthThatFits(proposal, in: axis)
                children[child.fittingOrder].majorAxisRangeCache.min = min
            }
        }
        
        
        private func resize(_ child: inout Child, at index: Int, proposal: _ProposedSize, childLayoutComputer: LayoutComputer) {
            let axis: Axis = header.majorAxis
            child.offer = proposal
            let fittingSize: CGSize = resizeChildIfNeeded(&child, at: index, proposal: proposal, childLayoutComputer: childLayoutComputer)
            let alignment: AlignmentKey = header.minorAxisAlignment
            let dimension = ViewDimensions(guideComputer: childLayoutComputer, size: ViewSize(value: fittingSize, proposal: proposal))
            var explicitAlignment: CGFloat = dimension[alignment]
            explicitAlignment = .minimum(.maximum(explicitAlignment, -.infinity), .infinity)
            explicitAlignment = -explicitAlignment
            var newGeometry: ViewGeometry = child.geometry
            newGeometry.setOriginValue(0, for: axis)
            newGeometry.setOriginValue(explicitAlignment, for: axis.minor)
            newGeometry.dimensions = dimension
            child.geometry = newGeometry
        }
        
        private func resizeChildIfNeeded(_ child: inout Child, at index: Int, proposal: _ProposedSize, childLayoutComputer: LayoutComputer) -> CGSize {
            let lastProposedSize = child.lastProposedSize
            child.lastProposedSize = proposal
            let childSize = child.geometry.dimensions.size.value
            
            if let lastProposal = lastProposedSize, proposal.contains(lastProposal), !childSize.canOutOfSize(lastProposal) {
                return childSize
            }
            
            return childLayoutComputer.engine.sizeThatFits(proposal)
        }
        
        @inlinable
        internal func proposalWhenPlacing(in size: ViewSize) -> _ProposedSize {
            let proposedWidth: CGFloat? = size._proposal.width.isNaN ? nil : size._proposal.width
            let proposedHeight: CGFloat? = size._proposal.height.isNaN ? nil : size._proposal.height
            let axis = header.majorAxis
            if axis == .horizontal {
                return _ProposedSize(major: proposedWidth, axis: axis, minor: proposedHeight ?? size.value.height)
            } else {
                return _ProposedSize(major: proposedHeight, axis: axis, minor: proposedWidth ?? size.value.width)
            }
        }
    }
    
}
