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
internal struct _IncrementalLayout_PlacedChild {

    internal let item: ViewCacheItem

    internal var placement: _Placement

    fileprivate static func orderedForDisplay(lhs: _IncrementalLayout_PlacedChild, rhs: _IncrementalLayout_PlacedChild) -> Bool {
        guard lhs.item.zIndex == rhs.item.zIndex else {
            return rhs.item.zIndex > lhs.item.zIndex
        }
        let lhsIsSectionHeaderOrFooter = lhs.item.section.isSectionHeaderOrFooter

        var sholdContinue = false
        if rhs.item.section.isHeader {
            sholdContinue = lhsIsSectionHeaderOrFooter
        } else {
            sholdContinue = lhsIsSectionHeaderOrFooter ? rhs.item.section.isFooter : !rhs.item.section.isFooter
        }

        guard sholdContinue else {
            return !lhsIsSectionHeaderOrFooter
        }

        guard lhs.item.removedSeed == rhs.item.removedSeed else {
            return lhs.item.removedSeed < rhs.item.removedSeed
        }

        return lhs.item.displayIndex! < rhs.item.displayIndex!
    }

}

@available(iOS 13.0, *)
extension Array where Element == _IncrementalLayout_PlacedChild {

    internal func synthesizedPlacement(of index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], avoiding: CGRect, distance: (CGRect, CGRect) -> CGFloat) -> _Placement? {
        guard let result = placedChildren.motionVectors(closestTo: index, in: self, avoiding: avoiding, distance: distance) else {
            return nil
        }
        let child = placedChildren[index]
        let proposal = CGSize(width: child.placement.proposedSize_.width ?? 10.0,
                              height: child.placement.proposedSize_.height ?? 10.0)
        let newProposedSize = CGSize(width: proposal.width * result.scale.width,
                                     height: proposal.height * result.scale.height)
        let origin = CGSize(width: proposal.width * child.placement.anchor.x,
                            height: proposal.height * child.placement.anchor.y)



        var anchorPosition = child.placement.anchorPosition
        anchorPosition.x -= origin.width
        anchorPosition.y -= origin.height
        anchorPosition.apply(result.translation)
        anchorPosition.x += newProposedSize.width * child.placement.anchor.x
        anchorPosition.y += newProposedSize.height * child.placement.anchor.y

        return _Placement(proposedSize: newProposedSize, anchor: child.placement.anchor, at: anchorPosition)
    }

    internal func motionVectors(closestTo index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], avoiding: CGRect, distance: (CGRect, CGRect) -> CGFloat) -> (translation: CGSize, scale: CGSize)? {
        var dic: [_ViewList_ID.Canonical: Int] = [:]
        for (index, child) in placedChildren.enumerated() {
            dic[.init(id: child.item.id)] = index
        }
        guard !self.isEmpty else {
            return nil
        }
        let child = self[index]
        let fromRect = child.placement.rect
        var notIntersectionDistanceValue: CGFloat = 0
        var resultIsNil: Bool = true
        var translation: CGSize = .zero
        var scale: CGSize = .zero

        for (idx, child) in self.enumerated() {
            guard idx != index else {
                continue
            }
            let key = _ViewList_ID.Canonical(id: child.item.id)
            guard let matchIndex = dic[key] else {
                continue
            }
            let toRect = child.placement.rect
            let distanceValue = distance(fromRect, toRect)
            guard distanceValue > notIntersectionDistanceValue ||  resultIsNil else {
                resultIsNil = false
                continue
            }
            let matchChild = placedChildren[matchIndex]
            let matchChildRect = matchChild.placement.rect
            guard !toRect.isEmpty && !matchChildRect.isEmpty else {
                continue
            }
            translation.width = matchChildRect.origin.x - toRect.origin.x
            translation.height = matchChildRect.origin.y - toRect.origin.y

            scale.width = matchChildRect.size.width / toRect.size.width
            scale.height = matchChildRect.size.height / toRect.size.height
            let x = fromRect.origin.x + translation.width
            let y = fromRect.origin.y + translation.height
            let width = fromRect.width * scale.width
            let height = fromRect.height * scale.height
            let rect = CGRect(x: x, y: y, width: width, height: height).intersection(avoiding)
            if rect.isEmpty {
                notIntersectionDistanceValue = distanceValue
                resultIsNil = false
            }
        }
        return resultIsNil ? nil : (translation, scale)
    }

    internal func externalPlacement(of index: Int, avoiding: CGRect, in axis: Axis) -> _Placement {
        let child = self[index]
        let range = avoiding[axis]

        let proposalDimension = child.placement.proposedSize_.value(for: axis) ?? 0x10
        let anchor = child.placement.anchor.value(for: axis)
        let anchorValue = child.placement.anchorPosition.value(for: axis)

        let anchorPositionValue = CGFloat.maximum((proposalDimension * anchor) + range.upperBound, proposalDimension + anchorValue)
        var placement = child.placement
        placement.anchorPosition.setValue(anchorPositionValue, for: axis)
        return placement
    }

    internal mutating func sortForDisplay() {
        sortForDisplayLarge()
    }

    internal mutating func sortForDisplayLarge() {
        sort { (lhs, rhs) -> Bool in
            _IncrementalLayout_PlacedChild.orderedForDisplay(lhs: lhs, rhs: rhs)
        }
        for (idx, child) in self.enumerated() {
            child.item.displayIndex = idx
        }
    }

    internal mutating func pinSectionHeadersAndFooters(in scrollLayout: _ScrollLayout, headerAxes: Axis.Set, footerAxes: Axis.Set) {
        typealias PinnedSectionDict = [UInt32 : PinnedSection]
        func updateSection(_ pinnedSection: inout PinnedSection, section: ViewCache.Section, childIndex: Int, frame: CGRect) {
            if section.isHeader {
                pinnedSection.headerIndex = pinnedSection.headerIndex ?? childIndex
            } else {
                pinnedSection.x0 = pinnedSection.x0 == .infinity ? frame.minX : Swift.min(frame.minX, pinnedSection.x0)
                pinnedSection.y0 = pinnedSection.y0 == .infinity ? frame.minY : Swift.min(frame.minY, pinnedSection.y0)
            }
            if section.isFooter {
                pinnedSection.footerIndex = pinnedSection.footerIndex ?? childIndex
            } else {
                pinnedSection.x1 = pinnedSection.x1 == .infinity ? frame.maxX : Swift.max(frame.maxX, pinnedSection.x1)
                pinnedSection.y1 = pinnedSection.y1 == .infinity ? frame.maxY : Swift.max(frame.maxY, pinnedSection.y1)
            }
        }
        func commitSection(_ pinnedSection: PinnedSection) {
            if !headerAxes.isEmpty, let headerIndex = pinnedSection.headerIndex {
                let header = self[headerIndex]
                let proposedSize = header.placement.proposedSize
                let anchorPosition = pinnedSection.headerAnchorPosition(forPlacementIn: scrollLayout,
                                                                        with: headerAxes,
                                                                        proposedSize: proposedSize,
                                                                        anchor: header.placement.anchor,
                                                                        anchorPosition: header.placement.anchorPosition)
                self[headerIndex].placement.proposedSize = proposedSize
                self[headerIndex].placement.anchorPosition = anchorPosition
            }
            if !footerAxes.isEmpty, let footerIndex = pinnedSection.footerIndex {
                let footer = self[footerIndex]
                let proposedSize = footer.placement.proposedSize
                let anchorPosition = pinnedSection.footerAnchorPosition(forPlacementIn: scrollLayout,
                                                                        with: footerAxes,
                                                                        proposedSize: proposedSize,
                                                                        anchor: footer.placement.anchor,
                                                                        anchorPosition: footer.placement.anchorPosition)
                self[footerIndex].placement.proposedSize = proposedSize
                self[footerIndex].placement.anchorPosition = anchorPosition
            }
        }
        enumerated()
            .reduce(PinnedSectionDict()) { pinnedSections, indexedPlacedChild in
                let (index, eachPlacedChild) = indexedPlacedChild
                guard let id = eachPlacedChild.item.section.id else {
                    return pinnedSections
                }
                var updatedPinnedSections = pinnedSections
                let size = eachPlacedChild.placement.proposedSize
                let origin = CGPoint(
                    x: eachPlacedChild.placement.anchorPosition.x - size.width * eachPlacedChild.placement.anchor.x,
                    y: eachPlacedChild.placement.anchorPosition.y - size.height * eachPlacedChild.placement.anchor.y
                )
                let frame = CGRect(origin: origin, size: size)
                updateSection(&updatedPinnedSections[id, default: PinnedSection()],
                              section: eachPlacedChild.item.section,
                              childIndex: index,
                              frame: frame)
                return updatedPinnedSections
            }
            .values
            .forEach(commitSection)
    }


}

@available(iOS 13.0, *)
fileprivate struct PinnedSection {

    fileprivate var x0: CGFloat

    fileprivate var x1: CGFloat

    fileprivate var y0: CGFloat

    fileprivate var y1: CGFloat

    fileprivate var headerIndex: Int?

    fileprivate var footerIndex: Int?

    @inline(__always)
    fileprivate init() {
        x0 = .infinity
        x1 = .infinity
        y0 = .infinity
        y1 = .infinity
        headerIndex = nil
        footerIndex = nil
    }

    @inline(__always)
    fileprivate func headerAnchorPosition(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGPoint {
        CGPoint(x: headerX(forPlacementIn: scrollLayout, with: axes, proposedSize: proposedSize, anchor: anchor, anchorPosition: anchorPosition),
                y: headerY(forPlacementIn: scrollLayout, with: axes, proposedSize: proposedSize, anchor: anchor, anchorPosition: anchorPosition))
    }

    @inline(__always)
    fileprivate func footerAnchorPosition(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGPoint {
        CGPoint(x: footerX(forPlacementIn: scrollLayout, with: axes, proposedSize: proposedSize, anchor: anchor, anchorPosition: anchorPosition),
                y: footerY(forPlacementIn: scrollLayout, with: axes, proposedSize: proposedSize, anchor: anchor, anchorPosition: anchorPosition))
    }

    @inline(__always)
    fileprivate func headerX(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGFloat {
        if axes.contains(.horizontal) && x1 != .infinity {
            let anchoredX = anchorPosition.x
            let maxPinnedX = x1 - ((1 - anchor.x) * proposedSize.width)
            let idealPinnedX = anchor.x * proposedSize.width + scrollLayout.contentRect.minX
            return min(max(idealPinnedX, anchoredX), maxPinnedX)
        }

        return anchorPosition.x
    }

    @inline(__always)
    fileprivate func headerY(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGFloat {
        if axes.contains(.vertical) && y1 != .infinity {
            let anchoredY = anchorPosition.y
            let maxPinnedY = y1 - ((1 - anchor.y) * proposedSize.height)
            let idealPinnedY = anchor.y * proposedSize.height + scrollLayout.contentRect.minY
            return min(max(idealPinnedY, anchoredY), maxPinnedY)
        }

        return anchorPosition.y
    }

    @inline(__always)
    fileprivate func footerX(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGFloat {
        if axes.contains(.horizontal) && x0 != .infinity {
            let anchoredX = anchorPosition.x
            let minPinnedX = x0 + anchor.x * proposedSize.width
            let idealPinnedX = scrollLayout.contentRect.maxX - (1 - anchor.x) * proposedSize.width
            return max(min(idealPinnedX, anchoredX), minPinnedX)
        }

        return anchorPosition.x
    }

    @inline(__always)
    fileprivate func footerY(forPlacementIn scrollLayout: _ScrollLayout, with axes: Axis.Set, proposedSize: CGSize, anchor: UnitPoint, anchorPosition: CGPoint) -> CGFloat {
        if axes.contains(.vertical) && y0 != .infinity {
            let anchoredY = anchorPosition.y
            let minPinnedY = y0 + anchor.y * proposedSize.height
            let idealPinnedY = scrollLayout.contentRect.maxY - (1 - anchor.y) * proposedSize.height
            return max(min(idealPinnedY, anchoredY), minPinnedY)
        }

        return anchorPosition.y
    }

}
