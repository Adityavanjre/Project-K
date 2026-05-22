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
internal struct _IncrementalStack_State<Stack: IncrementalStack> {

    internal var minorSize: CGFloat

    internal var minorCount: Int

    internal var minorGeometry: Stack.MinorGeometry?

    internal var placedIndices: Range<Int>

    internal func shouldUpdatePlacedExtent(with placement: StackPlacement<Stack>) -> Bool {
        if placedIndices.startIndex != placedIndices.endIndex {
            return true
        }
        let (maxPlacedIndex, minPlacedIndex) = placement.nextPlacedIndex
        return minPlacedIndex != maxPlacedIndex
    }

    internal var placedExtent: ClosedRange<CGFloat>

    internal var visibleExtent: ClosedRange<CGFloat>

    internal var estimatedLength: CGFloat

    internal var estimatedSpacing: CGFloat

    @usableFromInline
    internal static var zero: _IncrementalStack_State<Stack> {
        .init(minorSize: 0, minorCount: 0, minorGeometry: nil, placedIndices: 0..<0, placedExtent: 0...0, visibleExtent: 0...0, estimatedLength: -1, estimatedSpacing: -1)
    }

    @usableFromInline
    internal var estimatedSize: CGFloat {
        let length: CGFloat = estimatedLength >= 0 ? estimatedLength : 32
        return estimatedSpacing > 0 ? length + estimatedSpacing : length
    }

    internal mutating func addMeasurements(length: CGFloat?, spacing: CGFloat?) {
        if let length = length {
            var newLength = (estimatedLength - length) * 0.9 + length
            newLength = estimatedLength < 0 ? length : newLength
            estimatedLength = newLength
        }

        if let spacing = spacing {
            var newSpacing = (estimatedSpacing - spacing) * 0.9 + spacing
            newSpacing = estimatedSpacing < 0 ? spacing : newSpacing
            estimatedSpacing = newSpacing
        }
    }

}
