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
internal struct ViewSize: Animatable, Equatable {
    
    internal static let zero: ViewSize = ViewSize(value: .zero, _proposal: .zero)
    
    internal var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            value.animatableData
        }
        
        set {
            value.animatableData = newValue
        }
    }
    
    internal var value: CGSize

    internal var _proposal: CGSize
    
    @inline(__always)
    internal init(value: CGSize, proposal: _ProposedSize) {
        self.value = value
        self._proposal = CGSize(width: proposal.width ?? .nan, height: proposal.height ?? .nan)
    }
    
    @inline(__always)
    internal init(value: CGSize, _proposal: CGSize) {
        self.value = value
        self._proposal = _proposal
    }
    
    @inlinable
    internal func proposalWhenPlacing(by axis: Axis) -> _ProposedSize {
        let proposedWidth: CGFloat? = _proposal.width.isNaN ? nil : _proposal.width
        let proposedHeight: CGFloat? = _proposal.height.isNaN ? nil : _proposal.height

        if axis == .horizontal {
            return _ProposedSize(major: proposedWidth, axis: axis, minor: proposedHeight ?? value.height)
        } else {
            return _ProposedSize(major: proposedHeight, axis: axis, minor: proposedWidth ?? value.width)
        }
    }

}
