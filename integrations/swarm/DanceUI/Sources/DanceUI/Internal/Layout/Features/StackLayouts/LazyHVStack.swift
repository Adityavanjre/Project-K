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
internal protocol LazyHVStack: IncrementalStack {
    
    associatedtype Base: HVStack
    
    var base: Base {get set}
    
}

@available(iOS 13.0, *)
extension LazyHVStack where MinorGeometry == CGFloat {
    
    @inlinable
    internal static var majorAxis: Axis {
        Base.majorAxis
    }
    
    @inlinable
    internal func minorGeometry(updatingSize: inout CGFloat) -> (count: Int, data: CGFloat) {
        (0x1, updatingSize)
    }
    
    private var anchor: UnitPoint {
        let fraction = base.alignment.fraction
        return .point(with: 0.5, y: fraction, axis: Self.majorAxis)
    }
    
    private func anchor(for kind: _IncrementalLayout_Child.Kind) -> UnitPoint {
        switch kind {
        case .header, .footer:
            return anchor
        case .unknown:
            return .center
        }
    }
    
    @inlinable
    internal func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, minorGeometry: CGFloat) -> (length: CGFloat, spacing: CGFloat) {
        let child = children[0]
        var proposal = _ProposedSize()
        proposal.setValue(minorGeometry, for: Self.majorAxis.minor)
        return child.lengthAndSpacing(size: proposal, axis: Self.majorAxis, predecessor: predecessors?.first, uniformSpacing: spacing)
    }
    
    @inlinable
    internal func lengthAndSpacing(children: [_IncrementalLayout_Child], predecessors: [_IncrementalLayout_Child]?, size: CGFloat, axis: Axis) -> (length: CGFloat, spacing: CGFloat) {
        return children[0].lengthAndSpacing(size: _ProposedSize(size: size, axis: axis.minor),
                                            axis: axis,
                                            predecessor: predecessors?.first,
                                            uniformSpacing: spacing)
    }
    
    @inlinable
    internal func place(children: [_IncrementalLayout_Child], length: CGFloat, minorGeometry: CGFloat, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> ()) {
        let child = children[0]
        var size = CGSize.zero
        
        size.setValue(length, for: Self.majorAxis)
        size.setValue(minorGeometry, for: Self.majorAxis.minor)

        let rect = CGRect(origin: .zero, size: size)
        emit(child, rect, anchor)
    }
    
    @inlinable
    internal func place(child: _IncrementalLayout_Child, kind: _IncrementalLayout_Child.Kind, position: CGFloat, length: CGFloat, minorSize: CGFloat, emit: (_IncrementalLayout_Child, CGRect, UnitPoint) -> ()) {
        var size = CGSize.zero
        size.setValue(length, for: Self.majorAxis)
        size.setValue(minorSize, for: Self.majorAxis.minor)
        let rect = CGRect(origin: origin(forPosition: position, axis: Self.majorAxis), size: size)
        emit(child, rect, anchor(for: kind))
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
    
    internal static func hasMultipleViewsInAxis(_ axis: Axis) -> Bool {
        Base.majorAxis == axis
    }
    
}
