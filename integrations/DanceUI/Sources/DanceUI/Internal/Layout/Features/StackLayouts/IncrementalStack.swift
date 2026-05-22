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
internal protocol IncrementalStack: IncrementalLayout {
    
    associatedtype MinorGeometry: Equatable

    static var majorAxis: Axis { get }

    func minorGeometry(updatingSize: inout CGFloat) -> (count: Int, data: MinorGeometry)

    var spacing: CGFloat? { get }

    func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, minorGeometry: MinorGeometry) -> (length: CGFloat, spacing: CGFloat)

    func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, size: CGFloat, axis: Axis) -> (length: CGFloat, spacing: CGFloat)

    func place(children: [_IncrementalLayout_Child], length: CGFloat, minorGeometry: MinorGeometry, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> ())

    func place(child: _IncrementalLayout_Child, kind: _IncrementalLayout_Child.Kind, position: CGFloat, length: CGFloat, minorSize: CGFloat, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> Void)
    
}

@available(iOS 13.0, *)
extension IncrementalStack where State == _IncrementalStack_State<Self> {
    
    internal static var initialState: _IncrementalStack_State<Self> {
        return .zero
    }
    
    internal var pinnedAxes: Axis.Set {
        .init(axis: Self.majorAxis)
    }
    
    internal func sizeThatFits(proposedSize: _ProposedSize, children: _IncrementalLayout_Children, context: SizeAndSpacingContext, state: inout _IncrementalStack_State<Self>) -> CGSize {
        let proposedMinorAxisDimension: CGFloat? = proposedSize.value(for: Self.majorAxis.minor)
        var resolvedMinorAxisDimension: CGFloat = proposedMinorAxisDimension ?? resolveFlexibleMinorSize(children: children)
        guard resolvedMinorAxisDimension > 0 else {
            return .zero
        }
        
        var needsCalculateEndIndex = 0
        var needsCalculateEstimatedLength = false
        let endIndex: Int
        var fitMajorAxisDimension: CGFloat = 0.0
        var skipFirst = false
        var startIndex = 0
        let minorGeometry = self.minorGeometry(updatingSize: &resolvedMinorAxisDimension)
        guard minorGeometry.count > 0 else {
            return .zero
        }
        if state.placedIndices.startIndex == state.placedIndices.endIndex ||
            state.minorCount != minorGeometry.count ||
            resolvedMinorAxisDimension != state.minorSize ||
            state.minorGeometry == nil ||
            minorGeometry.data != state.minorGeometry {
            if state.estimatedLength >= 0 {
                needsCalculateEstimatedLength = false
                endIndex = 0
            } else {
                needsCalculateEstimatedLength = true
                endIndex = minorGeometry.count * 2
            }
            startIndex = 0
        } else {
            needsCalculateEstimatedLength = false
            needsCalculateEndIndex = state.placedIndices.startIndex
            fitMajorAxisDimension = state.placedExtent.lowerBound
            if state.placedIndices.startIndex <= 0 {
                endIndex = state.placedIndices.endIndex
                startIndex = state.placedIndices.startIndex
            } else {
                skipFirst = true
                needsCalculateEndIndex = state.placedIndices.startIndex - minorGeometry.count
                endIndex = state.placedIndices.endIndex
                startIndex = state.placedIndices.startIndex - minorGeometry.count
            }
        }
        let style = _ViewList_IteratorStyle(multiplier: minorGeometry.count)
        var stateCopy = state
        if startIndex < endIndex {
            let count = minorGeometry.count
            var minorGroupChildren: [_IncrementalLayout_Child] = []
            var predecessorsGroupChildren: [_IncrementalLayout_Child]? = nil
            var accumulatedLength: (value: CGFloat, count: Int) = (0, 0)
            var accumulatedSpacing: (value: CGFloat, count: Int) = (0, 0)
            func flushMinorGroup() {
                guard !minorGroupChildren.isEmpty else {
                    return
                }
                if !skipFirst {
                    let info = lengthAndSpacing(children: minorGroupChildren, predecessors: predecessorsGroupChildren, minorGeometry: minorGeometry.data)
                    fitMajorAxisDimension += info.length + info.spacing
                    accumulatedLength.value += info.length
                    accumulatedLength.count &+= 1
                    if predecessorsGroupChildren != nil {
                        accumulatedSpacing.value += info.spacing
                        accumulatedSpacing.count &+= 1
                    }
                } else {
                    skipFirst = false
                }
                needsCalculateEndIndex &+= count
                swapChildren(&predecessorsGroupChildren, &minorGroupChildren)
            }
            var index = startIndex
            children.forEachChild(from: &index, style: style) { (child: _IncrementalLayout_Child, stop) in
                if child.data.section.isHeader || child.data.section.isFooter {
                    flushMinorGroup()
                    if !skipFirst {
                        var proposal = _ProposedSize()
                        proposal.setValue(resolvedMinorAxisDimension, for: Self.majorAxis.minor)
                        let info = child.lengthAndSpacing(size: proposal, axis: Self.majorAxis, predecessor: predecessorsGroupChildren?.first, uniformSpacing: spacing)
                        fitMajorAxisDimension += info.length + info.spacing
                    } else {
                        skipFirst = false
                    }
                    needsCalculateEndIndex &+= count
                    assert(count >= 0)
                    for _ in 0..<count {
                        minorGroupChildren.append(child)
                    }
                    swapChildren(&predecessorsGroupChildren, &minorGroupChildren)
                } else {
                    minorGroupChildren.append(child)
                    if minorGroupChildren.count == count {
                        flushMinorGroup()
                    }
                }
                stop = endIndex < needsCalculateEndIndex
            }
            flushMinorGroup()
            if needsCalculateEstimatedLength {
                var estimatedLength: CGFloat = 0
                var estimatedLengthChanged = false
                if accumulatedLength.count > 0 {
                    estimatedLength = accumulatedLength.value / CGFloat(accumulatedLength.count)
                    estimatedLengthChanged = true
                }
                
                var estimatedSpacing: CGFloat = 0
                var estimatedSpacingChanged = false
                if accumulatedSpacing.count > 0 {
                    estimatedSpacing = accumulatedSpacing.value / CGFloat(accumulatedSpacing.count)
                    estimatedSpacingChanged = true
                }
                
                if estimatedLengthChanged {
                    let oldestimatedLength = stateCopy.estimatedLength
                    stateCopy.estimatedLength -= estimatedLength
                    stateCopy.estimatedLength *= 0.9
                    stateCopy.estimatedLength += estimatedLength
                    stateCopy.estimatedLength = oldestimatedLength < 0 ? estimatedLength : stateCopy.estimatedLength
                }
                
                if estimatedSpacingChanged {
                    let oldestimatedSpacing = stateCopy.estimatedSpacing
                    stateCopy.estimatedSpacing -= estimatedSpacing
                    stateCopy.estimatedSpacing *= 0.9
                    stateCopy.estimatedSpacing += estimatedSpacing
                    stateCopy.estimatedSpacing = oldestimatedSpacing < 0 ? estimatedSpacing : stateCopy.estimatedSpacing
                }
            }
        }
        
        let uncalculatedEstimatedCount = (children.node.estimatedCount(style) &- needsCalculateEndIndex) / minorGeometry.count
        let uncalculatedEstimatedSize = stateCopy.estimatedSize * (uncalculatedEstimatedCount >= 0 ? CGFloat(uncalculatedEstimatedCount) : 0)
        fitMajorAxisDimension += uncalculatedEstimatedSize
        if uncalculatedEstimatedCount > 0 {
            if needsCalculateEndIndex == 0 {
                fitMajorAxisDimension -= stateCopy.estimatedSpacing
            }
        }
        var minorAxisDimension = proposedMinorAxisDimension ?? 0
        minorAxisDimension = .maximum(minorAxisDimension, resolvedMinorAxisDimension)
        let majorAxisDimension = ceil(fitMajorAxisDimension)
        let size = CGSize.size(for: Self.majorAxis, majorAxisDimension, minorAxisDimension)
        return size
    }
    
    internal func firstIndex<Index: Hashable>(of index: Index,
                                              children: _IncrementalLayout_Children,
                                              context: _IncrementalLayout_PlacementContext) -> Int? {
        var minorDimension = context.size.value.value(for: Self.majorAxis.minor)
        let (count, _) = self.minorGeometry(updatingSize: &minorDimension)
        
        guard count > 0 else {
            return nil
        }
        
        guard minorDimension > 0 else {
            return nil
        }
        
        return children.firstIndex(id: index, style: .init(multiplier: count))
    }
    
    internal func initialPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasInserted: Bool, context: _IncrementalLayout_PlacementContext, oldPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        
        guard !wasInserted else {
            return placedChildren[index].placement
        }
        let scrolledGeometry = context.scrolledGeometry
        let majorAxis = Self.majorAxis
        let placement = oldPlacedChildren.synthesizedPlacement(of: index, in: placedChildren, avoiding: scrolledGeometry.visibleRect) { (lhs, rhs) -> CGFloat in
            let lhsOriginValue: CGFloat = lhs.origin.value(for: majorAxis)
            let rhsOriginValue: CGFloat = rhs.origin.value(for: majorAxis)
            let lhsSizeValue: CGFloat = lhs.size.value(for: majorAxis) * 0.5
            let rhsSizeValue: CGFloat = rhs.size.value(for: majorAxis) * 0.5
            
            let lhsEndValue = lhsOriginValue + lhsSizeValue
            let rhsEndValue = rhsOriginValue + rhsSizeValue
            return abs(rhsEndValue - lhsEndValue) - (lhsSizeValue + rhsSizeValue)
            
        }
        guard placement == nil else {
            return placement!
        }
        
        return placedChildren.externalPlacement(of: index, avoiding: scrolledGeometry.visibleRect, in: majorAxis)
    }
    
    internal func finalPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasRemoved: Bool, context: _IncrementalLayout_PlacementContext, newPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement {
        guard !wasRemoved else {
            return placedChildren[index].placement
        }
        let scrolledGeometry = context.scrolledGeometry
        let majorAxis = Self.majorAxis
        let placement = newPlacedChildren.synthesizedPlacement(of: index, in: placedChildren, avoiding: scrolledGeometry.visibleRect) { (lhs, rhs) -> CGFloat in
            let lhsOriginValue: CGFloat = lhs.origin.value(for: majorAxis)
            let rhsOriginValue: CGFloat = rhs.origin.value(for: majorAxis)
            let lhsSizeValue: CGFloat = lhs.size.value(for: majorAxis) * 0.5
            let rhsSizeValue: CGFloat = rhs.size.value(for: majorAxis) * 0.5
            
            let lhsEndValue = lhsOriginValue + lhsSizeValue
            let rhsEndValue = rhsOriginValue + rhsSizeValue
            return abs(rhsEndValue - lhsEndValue) - (lhsSizeValue + rhsSizeValue)
        }
        
        guard placement == nil else {
            return placement!
        }
        
        return placedChildren.externalPlacement(of: index, avoiding: scrolledGeometry.visibleRect, in: majorAxis)
    }
    
    internal func boundingRect(at index: Int, children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, state: inout _IncrementalStack_State<Self>) -> CGRect? {
        let size = context.size.value
        var minorDimension = size.value(for: Self.majorAxis.minor)
        let majorAxis = Self.majorAxis
        let minorGeometry = self.minorGeometry(updatingSize: &minorDimension)
        let style = _ViewList_IteratorStyle(multiplier: minorGeometry.count)
        guard minorDimension > 0 && minorGeometry.count > 0 else {
            return nil
        }
        let row = Int(index / minorGeometry.count)
        let estimatedSize = state.estimatedSize
        var rect: CGRect = CGRect(origin: .zero, size: size)
        var originValue = CGFloat(row) * state.estimatedSize
        if row > 0 {
            originValue -= state.estimatedSpacing
        }
        var dimension: CGFloat = 0
        if state.placedIndices.startIndex != state.placedIndices.endIndex &&
            state.minorCount == minorGeometry.count &&
            state.minorSize == minorDimension &&
            state.minorGeometry != nil &&
            state.minorGeometry! == minorGeometry.data {
            let unplacedCount = index - state.placedIndices.startIndex
            let estimatedSize = state.estimatedSize
            let absCount = abs((unplacedCount / minorGeometry.count) / minorGeometry.count)
            var newOriginValue = CGFloat(unplacedCount / minorGeometry.count) * estimatedSize
            newOriginValue += state.placedExtent.lowerBound
            originValue = newOriginValue >= 0 ? newOriginValue : originValue
            dimension = CGFloat(absCount) * estimatedSize
            let visibleLength = (state.visibleExtent.upperBound - state.visibleExtent.lowerBound) * 3.0
            if dimension < visibleLength {
                var stackPlacement = StackPlacement<Self>(stack: self,
                                                          axis: majorAxis,
                                                          minorSize: minorDimension,
                                                          minorCount: minorGeometry.count,
                                                          minorGeometry: minorGeometry.data,
                                                          visible: CGFloat.infinity...CGFloat.infinity,
                                                          pinnedViews: .init(rawValue: 0),
                                                          queriedIndex: index,
                                                          index: 0,
                                                          skipFirst: false,
                                                          position: 0,
                                                          stoppingCondition: .init(value: nil))
                
                if unplacedCount < 0 {
                    let collectedChildren = collectBackwards(from: index, to: state.placedIndices.startIndex, children: children, style: style)
                    stackPlacement.measureBackwards(children: collectedChildren, lastIndex: state.placedIndices.startIndex, lastPosition: state.placedExtent.lowerBound, firstChild: index == 0)
                    _ = stackPlacement.place(children: children, from: stackPlacement.index, position: stackPlacement.position, stopping: .init(value: index), style: style)
                } else {
                    _ = stackPlacement.place(children: children, from: state.placedIndices.startIndex, position: state.placedExtent.lowerBound, stopping: .init(value: index), style: style)
                }
                if stackPlacement.placedQuery.max > stackPlacement.placedQuery.min {
                    if stackPlacement.placedQuery.min >= 0 {
                        dimension = stackPlacement.placedQuery.max - stackPlacement.placedQuery.min
                        originValue = stackPlacement.placedQuery.min
                    } else {
                        dimension = -1
                    }
                } else {
                    dimension = -1
                }
            } else {
                dimension = -1
            }
            
            if state.placedIndices.startIndex > index {
                let visibleLength = state.visibleExtent.upperBound - state.visibleExtent.lowerBound
                _danceuiPrecondition(visibleLength >= 0)
                var stackPlacement = StackPlacement<Self>(stack: self,
                                                          axis: majorAxis,
                                                          minorSize: minorDimension,
                                                          minorCount: minorGeometry.count,
                                                          minorGeometry: minorGeometry.data,
                                                          visible: 0...visibleLength,
                                                          pinnedViews: PinnedScrollableViews(rawValue: 0),
                                                          queriedIndex: index,
                                                          index: 0,
                                                          skipFirst: false,
                                                          position: 0,
                                                          stoppingCondition: .init(value: nil))
                _ = stackPlacement.place(children: children, from: 0, position: 0, stopping: .init(value: nil), style: style)
                if stackPlacement.placedQuery.max > stackPlacement.placedQuery.min {
                    dimension = stackPlacement.placedQuery.max - stackPlacement.placedQuery.min
                    originValue = stackPlacement.placedQuery.min
                }
            }
            if dimension < 0 {
                dimension = state.estimatedLength >= 0 ? state.estimatedLength : 0
            }
        } else {
            dimension = state.estimatedLength >= 0 ? state.estimatedLength : 0
        }
        rect.origin.setValue(originValue, for: majorAxis)
        rect.origin.setValue(0, for: majorAxis.minor)
        rect.size.setValue(dimension, for: majorAxis)
        return rect
    }
    
    internal func place(children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, state: inout State, in placement: inout _IncrementalLayout_Placements) {
        let scrollLayout = context.scrolledGeometry

        let scrollLayoutVisibleRange = scrollLayout.visibleRect[Self.majorAxis]
        guard let visibleRange = scrollLayoutVisibleRange.intersection(0...CGFloat.infinity) else {
            return
        }
        var minorDimension = context.size.value.value(for: Self.majorAxis.minor)
        guard minorDimension > 0 else {
            return
        }
        let minorGeometry = self.minorGeometry(updatingSize: &minorDimension)
        if minorDimension != state.minorSize ||
            state.minorCount != minorGeometry.count ||
            state.minorGeometry == nil ||
            state.minorGeometry! != minorGeometry.data {
            state = .zero
        }
        var stackPlacement = StackPlacement<Self>(stack: self,
                                                  axis: Self.majorAxis,
                                                  minorSize: minorDimension,
                                                  minorCount: minorGeometry.count,
                                                  minorGeometry: minorGeometry.data,
                                                  visible: visibleRange,
                                                  pinnedViews: context.pinnedViews,
                                                  queriedIndex: nil,
                                                  index: 0,
                                                  skipFirst: false,
                                                  position: 0,
                                                  stoppingCondition: .init(value: nil))
        
        let fromIndex: Int
        let position: CGFloat
        let style = _ViewList_IteratorStyle(multiplier: minorGeometry.count)
        if state.minorCount != minorGeometry.count ||
            minorDimension != state.minorSize ||
            state.minorGeometry == nil ||
            state.minorGeometry! != minorGeometry.data {
            let info = _calculateFromIndexAndPosition1(children: children,
                                                       context: context,
                                                       state: &state,
                                                       in: &placement,
                                                       visibleRange: visibleRange,
                                                       style: style)
            fromIndex = info.fromIndex
            position = info.position
        } else if state.placedExtent.contains(visibleRange)  {
            fromIndex = state.placedIndices.startIndex
            position = state.placedExtent.lowerBound
        } else {
            let majorLayoutSize = scrollLayout.size.value(for: Self.majorAxis)
            let unplacedLength = visibleRange.lowerBound - state.placedExtent.upperBound
            if unplacedLength + 0.01 > 0 && majorLayoutSize * 2 > unplacedLength {
                fromIndex = state.placedIndices.endIndex
                position = state.placedExtent.upperBound
            } else {
                let placedVisibleLength = visibleRange.lowerBound - state.placedExtent.lowerBound
                if placedVisibleLength + 0.01 > 0 && majorLayoutSize * 2 > placedVisibleLength {
                    fromIndex = state.placedIndices.startIndex
                    position = state.placedExtent.lowerBound
                } else {
                    let lowerBoundDeltaFromPlacedStart = visibleRange.lowerBound - state.placedExtent.lowerBound
                    let lowerBoundDeltaFromPlacedEnd = visibleRange.lowerBound - state.placedExtent.upperBound
                    
                    let selectedOffset: CGFloat
                    
                    if 0 <= lowerBoundDeltaFromPlacedStart {
                        selectedOffset = lowerBoundDeltaFromPlacedEnd
                    } else if 0 <= lowerBoundDeltaFromPlacedEnd {
                        selectedOffset = lowerBoundDeltaFromPlacedStart
                    } else if lowerBoundDeltaFromPlacedEnd >= lowerBoundDeltaFromPlacedStart {
                        selectedOffset = lowerBoundDeltaFromPlacedEnd
                    } else {
                        selectedOffset = lowerBoundDeltaFromPlacedStart
                    }
                    
                    if 0 <= selectedOffset || majorLayoutSize * 3 <= -selectedOffset {
                        let info = _calculateFromIndexAndPosition2(children: children,
                                                                   context: context,
                                                                   state: &state,
                                                                   in: &placement,
                                                                   visibleRange: visibleRange,
                                                                   style: style)
                        fromIndex = info.fromIndex
                        position = info.position
                    } else {
                        let info = _calculateFromIndexAndPosition3(children: children,
                                                                   context: context,
                                                                   state: &state,
                                                                   in: &placement,
                                                                   visibleRange: visibleRange,
                                                                   scrolledGeometry: scrollLayout,
                                                                   stackPlacement: &stackPlacement,
                                                                   style: style)
                        fromIndex = info.fromIndex
                        position = info.position
                    }
                }
            }
        }
        
        let result = stackPlacement.place(children: children, from: fromIndex, position: position, stopping: .init(value: nil), style: style)
        _update(state: &state,
                placement: &placement,
                with: stackPlacement,
                placeReslut: result,
                children: children,
                context: context,
                scrollLayoutVisibleRange: scrollLayoutVisibleRange,
                minorDimension: minorDimension,
                minorGeometry: minorGeometry,
                style: style)
    }
    
    @inline(__always)
    private func _calculateFromIndexAndPosition1(children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, state: inout State, in placement: inout _IncrementalLayout_Placements, visibleRange: ClosedRange<CGFloat>, style: _ViewList_IteratorStyle) -> (fromIndex: Int, position: CGFloat) {
        let estimatedCount = children.node.estimatedCount(style)
        let dimensionValue = context.size.value.value(for: Self.majorAxis)
        var visibleRangePercent: CGFloat = 0
        if dimensionValue > 0 {
            visibleRangePercent = visibleRange.lowerBound / dimensionValue
            visibleRangePercent = .minimum(.maximum(0, visibleRangePercent), 1)
        }
        
        var index = CGFloat(estimatedCount) * visibleRangePercent
        index += 0.5
        _danceuiPrecondition(index != .infinity && index != .nan)
        var fromIndex = Int(index)
        let position = fromIndex == 0 ? 0 : visibleRange.lowerBound
        fromIndex = fromIndex > 0 ? fromIndex : 0
        
        return (fromIndex, position)
    }
    
    @inline(__always)
    private func _calculateFromIndexAndPosition2(children: _IncrementalLayout_Children,
                                                 context: _IncrementalLayout_PlacementContext,
                                                 state: inout State,
                                                 in placement: inout _IncrementalLayout_Placements,
                                                 visibleRange: ClosedRange<CGFloat>,
                                                 style: _ViewList_IteratorStyle) -> (fromIndex: Int, position: CGFloat) {
        var estimatedCount = children.node.estimatedCount(style)
        estimatedCount -= 1
        
        let estimatedSize = state.estimatedSize
        let rangeDiffLow = visibleRange.lowerBound - state.placedExtent.lowerBound
        let count = round(rangeDiffLow / estimatedSize)
        _danceuiPrecondition(count != .infinity && count != .nan)
        estimatedCount = min(estimatedCount / state.minorCount, Int(count))
        estimatedCount = estimatedCount >= 0 ? estimatedCount : 0
        var placeIndex = state.placedIndices.startIndex + estimatedCount
        let position = CGFloat(estimatedCount) * estimatedSize + state.placedExtent.lowerBound
        if position + 0.01 < 0 || visibleRange.lowerBound < position - 0.01 {
            return _calculateFromIndexAndPosition1(children: children,
                                                   context: context,
                                                   state: &state,
                                                   in: &placement,
                                                   visibleRange: visibleRange,
                                                   style: style)
        }
        placeIndex = placeIndex >= 0 ? placeIndex : 0
        
        return (placeIndex, position)
    }
    
    @inline(__always)
    private func _calculateFromIndexAndPosition3(children: _IncrementalLayout_Children,
                                                 context: _IncrementalLayout_PlacementContext,
                                                 state: inout State,
                                                 in placement: inout _IncrementalLayout_Placements,
                                                 visibleRange: ClosedRange<CGFloat>,
                                                 scrolledGeometry: _ScrollLayout,
                                                 stackPlacement: inout StackPlacement<Self>,
                                                 style: _ViewList_IteratorStyle) -> (fromIndex: Int, position: CGFloat) {
        var placedIndexCount = state.placedIndices.endIndex - state.placedIndices.startIndex
        let dimensionValue = scrolledGeometry.size.value(for: Self.majorAxis)
        let count = ceil(dimensionValue / state.estimatedSize)
        _danceuiPrecondition(count != .infinity && count != .nan)
        placedIndexCount = placedIndexCount >= Int(count) ? placedIndexCount : Int(count)
        let unplacedRange = visibleRange.lowerBound - state.placedExtent.lowerBound
        let lastIndex = unplacedRange >= 0 ? state.placedIndices.endIndex : state.placedIndices.startIndex
        let lastPosition = unplacedRange >= 0 ? state.placedExtent.upperBound : state.placedExtent.lowerBound
        var idx = 0x2
        while idx < 0x10 {
            let index = lastIndex - placedIndexCount * idx
            let backwards = collectBackwards(from: index >= 0 ? index : 0, to: lastIndex, children: children, style: style)
            stackPlacement.measureBackwards(children: backwards, lastIndex: lastIndex, lastPosition: lastPosition, firstChild: index <= 0)
            if visibleRange.lowerBound + 0.01 >= stackPlacement.position {
                return (stackPlacement.index, stackPlacement.position)
            } else {
                if index <= 0 {
                    return _calculateFromIndexAndPosition2(children: children,
                                                           context: context,
                                                           state: &state,
                                                           in: &placement,
                                                           visibleRange: visibleRange,
                                                           style: style)
                }
            }
            idx *= 2
        }
        let result = _calculateFromIndexAndPosition2(children: children,
                                                     context: context,
                                                     state: &state,
                                                     in: &placement,
                                                     visibleRange: visibleRange,
                                                     style: style)
        return result
    }
    
    @inline(__always)
    private func _update(state: inout State, placement: inout _IncrementalLayout_Placements, with stackPlacement: StackPlacement<Self>, placeReslut: Bool, children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, scrollLayoutVisibleRange: ClosedRange<CGFloat>, minorDimension: CGFloat, minorGeometry: (count: Int, data: MinorGeometry?), style: _ViewList_IteratorStyle) {
        var silFlag = false
        if placeReslut {
            silFlag = 0.01 > abs(stackPlacement.position - stackPlacement.placedPosition.max)
        } else {
            silFlag = false
        }
        placement.placedChildren = stackPlacement.placedChildren

        if stackPlacement.placedPosition.max > stackPlacement.placedPosition.min {
            placement.rect = .zero
            placement.rect?.origin.setValue(stackPlacement.placedPosition.min, for: Self.majorAxis)
            placement.rect?.origin.setValue(0, for: Self.majorAxis.minor)
            placement.rect?.size.setValue(stackPlacement.placedPosition.max - stackPlacement.placedPosition.min, for: Self.majorAxis)
            placement.rect?.size.setValue(stackPlacement.minorSize, for: Self.majorAxis.minor)
        } else {
            placement.rect = .zero
        }
        state.minorSize = minorDimension
        state.minorCount = minorGeometry.count
        state.minorGeometry = minorGeometry.data
        state.visibleExtent = scrollLayoutVisibleRange
        
        if state.shouldUpdatePlacedExtent(with: stackPlacement) {
            let (minNextPlacedIndex, maxNextPlacedIndex) = stackPlacement.nextPlacedIndex
            state.placedIndices = minNextPlacedIndex..<maxNextPlacedIndex
            let (minNextPlacedPosition, maxNextPlacedPosition) = stackPlacement.nextPlacedPosition
            state.placedExtent = minNextPlacedPosition...maxNextPlacedPosition
        }
        
        var length: CGFloat? = nil
        if stackPlacement.measuredLength.samples != 0 {
            length = stackPlacement.measuredLength.total / CGFloat(stackPlacement.measuredLength.samples)
        }
        
        var spacing: CGFloat? = nil
        if stackPlacement.measuredSpacing.samples != 0 {
            spacing = stackPlacement.measuredSpacing.total / CGFloat(stackPlacement.measuredSpacing.samples)
        }
        state.addMeasurements(length: length, spacing: spacing)
        
        var appliedOffset: CGFloat = 0
        if state.placedIndices.startIndex == 0 {
            appliedOffset = abs(state.placedExtent.lowerBound) <= 0.01 ? 0 : -state.placedExtent.lowerBound
        } else {
            appliedOffset = 0.01 <= state.placedExtent.lowerBound ? 0 : state.estimatedSize * CGFloat(state.placedIndices.startIndex)
        }
        
        if abs(appliedOffset) > 0.01 {
            state.placedExtent.apply(appliedOffset)
            placement.setOffset(appliedOffset, for: Self.majorAxis)
            for index in 0..<placement.placedChildren.count {
                let value = placement.placedChildren[index].placement.anchorPosition.value(for: Self.majorAxis)
                placement.placedChildren[index].placement.anchorPosition.setValue(value + appliedOffset, for: Self.majorAxis)
            }
        }
        var layoutEndPosition: CGFloat = stackPlacement.placedPosition.max
        if stackPlacement.placedPosition.max <= stackPlacement.placedPosition.min {
            layoutEndPosition = stackPlacement.position
        }
        var index = stackPlacement.placedIndex.max
        if stackPlacement.placedIndex.max >= stackPlacement.placedIndex.min {
            index += 1
        } else {
            index = stackPlacement.index
        }
        layoutEndPosition = ceil(layoutEndPosition)
        
        let dimension = context.size.value.value(for: Self.majorAxis)
        guard !silFlag else {
            if abs(layoutEndPosition - dimension) >= 1 {
                placement.rect = nil
            }
            return
        }
        guard layoutEndPosition <= dimension + 0.01 else {
            placement.rect = nil
            return
        }
        var estimatedCount = children.node.estimatedCount(style)
        estimatedCount -= index
        estimatedCount = estimatedCount >= 0 ? estimatedCount : 0
        let estimatedSize = state.estimatedSize
        var estimatedRemainingExtent: CGFloat = CGFloat(estimatedCount) * estimatedSize
        estimatedRemainingExtent += layoutEndPosition
        var value: CGFloat = .minimum(estimatedRemainingExtent, dimension)
        let originRangeDiff = scrollLayoutVisibleRange.upperBound - scrollLayoutVisibleRange.lowerBound
        value *= 0.1
        value = .maximum(value, originRangeDiff)
        if abs(dimension - estimatedRemainingExtent) > value {
            placement.rect = nil
        }
    }
    
    private func resolveFlexibleMinorSize(children: _IncrementalLayout_Children) -> CGFloat {
        var index: Int = 0
        var minorSize: CGFloat = 0
        _ = children.apply(from: &index, style: .default) { (child, stop) in
            let fittingSize = child.layout.layoutComputer.engine.sizeThatFits(_ProposedSize())
            minorSize = fittingSize.value(for: Self.majorAxis.minor)
            stop = true
        }
        return minorSize
    }
    
    private func collectBackwards(from startIndex: Int, to endIndex: Int, children: _IncrementalLayout_Children, style: _ViewList_IteratorStyle) -> [_IncrementalLayout_Child] {
        var collectedEndIndex: Int = startIndex
        var sectionId: UInt32? = nil
        var collectedChildren: [_IncrementalLayout_Child] = []
        var index = startIndex
        _ = children.apply(from: &index, style: style) { (child, stop) in
            
            let shouldCollect: Bool
            
            if !child.isSectionHeaderOrFooter || sectionId != child.data.section.id {
                sectionId = child.data.section.id
                let childBackwardIndex = style.backward(from: collectedEndIndex)
                collectedEndIndex = childBackwardIndex
                shouldCollect = childBackwardIndex < endIndex
                stop = collectedEndIndex >= childBackwardIndex
                collectedEndIndex = childBackwardIndex + style.multiplier
            } else {
                shouldCollect = true
                collectedEndIndex = collectedEndIndex + 1
            }
            
            if shouldCollect {
                collectedChildren.append(child)
                stop = collectedEndIndex >= endIndex
            }
        }
        return collectedChildren
    }
}

@available(iOS 13.0, *)
internal func swapChildren(_ lhs: inout [_IncrementalLayout_Child]?, _ rhs: inout [_IncrementalLayout_Child]) {
    lhs = rhs
    rhs.removeAll()
}

@available(iOS 13.0, *)
extension ClosedRange {
    
    @inline(__always)
    internal func intersection(_ range: ClosedRange<Bound>) -> ClosedRange<Bound>? {
        let lowerBound = Swift.max(range.lowerBound, lowerBound)
        let upperBound = Swift.min(range.upperBound, upperBound)
        guard lowerBound < upperBound else {
            return nil
        }
        return lowerBound...upperBound
    }
    
    @inline(__always)
    internal func contains(_ range: ClosedRange<Bound>) -> Bool {
        return lowerBound <= range.lowerBound && upperBound >= range.upperBound
    }
}

@available(iOS 13.0, *)
extension ClosedRange where Bound == CGFloat {
    
    @usableFromInline
    internal mutating func apply(_ value: Bound) {
        self = (lowerBound + value)...(upperBound + value)
    }
    
}
