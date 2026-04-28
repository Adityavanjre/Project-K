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
internal protocol HVGrid: IncrementalStack where MinorGeometry == [HVGridGeometry] {

    var items: [GridItem] { get }

    var alignmentID: AlignmentID.Type { get }

    var alignmentFraction: CGFloat { get }
}

@available(iOS 13.0, *)
internal struct HVGridGeometry: Equatable {
    internal var position: CGFloat

    internal var size: CGFloat

    internal var anchor: UnitPoint
}

@available(iOS 13.0, *)
extension HVGrid {

    internal func minorGeometry(updatingSize: inout CGFloat) -> (count: Int, data: [HVGridGeometry]) {

        guard !items.isEmpty && !updatingSize.isInfinite else {
            return (0, [])
        }

        var estimatedRowCount = 0
        var estimatedTotalSize = updatingSize
        for (index, item) in items.enumerated() {
            switch item.size {
            case .fixed(let size):
                estimatedTotalSize -= size
            default:
                estimatedRowCount &+= 1
            }
            if index != items.count - 1 {
                estimatedTotalSize -= item.spacing ?? 8
            }
        }

        let dimensions = ViewDimensions(guideComputer: LayoutComputer(), size: ViewSize(value: CGSize(width: 1, height: 1), _proposal: CGSize(width: 1, height: 1)))
        var geometries: [HVGridGeometry] = []
        var position: CGFloat = 0
        for (index, item) in items.enumerated() {
            let spacing = item.spacing ?? 8
            let hAlignmentValue: CGFloat
            let vAlignmentValue: CGFloat
            if let alignment = item.alignment {
                hAlignmentValue = alignment.horizontal.id.defaultValue(in: dimensions)
                vAlignmentValue = alignment.vertical.id.defaultValue(in: dimensions)
            } else {
                let alignmentValue = alignmentID.defaultValue(in: dimensions)
                hAlignmentValue = Self.majorAxis == .horizontal ? alignmentValue : 0.5
                vAlignmentValue = Self.majorAxis == .horizontal ? 0.5 : alignmentValue
            }

            switch item.size {
            case .fixed(let size):
                geometries.append(HVGridGeometry(position: position, size: size, anchor: UnitPoint(x: vAlignmentValue, y: hAlignmentValue)))
                position += size
            case .flexible(let minimum, let maximum):
                _danceuiPrecondition(maximum >= minimum)
                var estimatedSize = (estimatedTotalSize >= 0 ? estimatedTotalSize : 0) / CGFloat(estimatedRowCount)
                estimatedSize = .maximum(.minimum(estimatedSize, maximum), minimum)
                geometries.append(HVGridGeometry(position: position, size: estimatedSize, anchor: UnitPoint(x: vAlignmentValue, y: hAlignmentValue)))
                estimatedTotalSize -= estimatedSize
                estimatedRowCount &-= 1
                position += estimatedSize
            case .adaptive(let minimum, let maximum):
                let estimatedSizeForMutiElements = (estimatedTotalSize >= 0 ? estimatedTotalSize : 0) / CGFloat(estimatedRowCount)
                var estimatedElementCount = floor((estimatedSizeForMutiElements - minimum) / (minimum + spacing))
                estimatedElementCount = estimatedElementCount >= 0 ? estimatedElementCount : 0
                estimatedElementCount += 1
                _danceuiPrecondition(!estimatedElementCount.isInfinite)
                let elementCount = Int(estimatedElementCount)
                let estimatedSize = (estimatedSizeForMutiElements - (CGFloat(elementCount - 1) * spacing)) / CGFloat(elementCount)
                let size = CGFloat.minimum(estimatedSize, maximum)

                var distance = 0.0
                for index in 0..<elementCount {
                    geometries.append(HVGridGeometry(position: position + distance, size: size, anchor: UnitPoint(x: vAlignmentValue, y: hAlignmentValue)))
                    distance += size
                    if index != elementCount - 1 {
                        distance += spacing
                    }
                    estimatedRowCount &-= 1
                }
                estimatedTotalSize -= distance
                position += distance
            }
            if index != items.count - 1 {
                position += spacing
            }
        }
        guard position < updatingSize else {
            updatingSize = position
            return (geometries.count, geometries)
        }

        let offset = alignmentFraction * (updatingSize - position)
        guard offset != 0 else {
            return (geometries.count, geometries)
        }

        for index in 0..<geometries.count {
            geometries[index].position += offset
        }

        return (geometries.count, geometries)
    }

    @inlinable
    internal func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, size: CGFloat, axis: Axis) -> (length: CGFloat, spacing: CGFloat) {
        var length = 0.0
        var spacing = 0.0
        guard !children.isEmpty else {
            return (length, spacing)
        }
        let predecessorsCount = predecessors?.count ?? 0
        var predecessor: _IncrementalLayout_Child? = nil
        for (index, child) in children.enumerated() {
            if index < predecessorsCount {
                predecessor = predecessors![index]
            }
            let info = child.lengthAndSpacing(size: _ProposedSize(major: nil, axis: Self.majorAxis, minor: size), axis: Self.majorAxis, predecessor: predecessor, uniformSpacing: self.spacing)
            length = .maximum(length, info.length)
            spacing = .maximum(spacing, info.spacing)
        }
        return (length, spacing)
    }

    internal func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, minorGeometry: [HVGridGeometry]) -> (length: CGFloat, spacing: CGFloat) {
        var length = 0.0
        var spacing = 0.0
        guard !children.isEmpty else {
            return (length, spacing)
        }
        let predecessorsCount = predecessors?.count ?? 0
        var childIndex = 0
        var predecessor: _IncrementalLayout_Child? = nil
        for (index, geometry) in minorGeometry.enumerated() {
            guard index < children.count else {
                break
            }
            if index < predecessorsCount {
                predecessor = predecessors![childIndex]
                childIndex = index
            }
            let child = children[childIndex]
            let info = child.lengthAndSpacing(size: _ProposedSize(major: nil, axis: Self.majorAxis, minor: geometry.size), axis: Self.majorAxis, predecessor: predecessor, uniformSpacing: self.spacing)
            length = .maximum(length, info.length)
            spacing = .maximum(spacing, info.spacing)
            childIndex &+= 1
            guard index < children.count - 1 else {
                break
            }
        }

        return (length, spacing)

    }

    internal func place(children: [_IncrementalLayout_Child], length: CGFloat, minorGeometry: MinorGeometry, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> ()) {

        guard !children.isEmpty else {
            return
        }

        for (index, geometry) in minorGeometry.enumerated() {
            guard index < children.count else {
                break
            }
            emit(children[index], CGRect(origin: .point(for: Self.majorAxis, 0, geometry.position), size: .size(for: Self.majorAxis, length, geometry.size)), geometry.anchor)
        }
    }

    @inlinable
    internal func place(child: _IncrementalLayout_Child, kind: _IncrementalLayout_Child.Kind, position: CGFloat, length: CGFloat, minorSize: CGFloat, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> Void) {
        var size = CGSize.zero
        size.setValue(length, for: Self.majorAxis)
        size.setValue(minorSize, for: Self.majorAxis.minor)
        let rect = CGRect(origin: origin(forPosition: position, axis: Self.majorAxis), size: size)
        emit(child, rect, headerAnchor)
    }

    @inline(__always)
    private func origin(forPosition position: CGFloat, axis: Axis) -> CGPoint {
        switch axis {
        case .vertical:
            return CGPoint(x: 0, y: position)
        case .horizontal:
            return CGPoint(x: position, y: 0)
        }
    }

    internal var headerAnchor: UnitPoint {
        .point(with: 0.5, y: alignmentFraction, axis: Self.majorAxis)
    }
}
