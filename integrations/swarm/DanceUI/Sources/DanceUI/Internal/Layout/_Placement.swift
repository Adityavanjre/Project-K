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
public struct _Placement: Equatable {

    public var proposedSize: CGSize {
        get {
            CGSize(width: proposedSize_.width ?? 10,
                   height: proposedSize_.height ?? 10)
        }
        set {
            proposedSize_ = _ProposedSize(size: newValue)
        }
    }

    internal var proposedSize_: _ProposedSize

    public var anchor: UnitPoint

    public var anchorPosition: CGPoint

    public init(proposedSize: CGSize, anchor: UnitPoint = .topLeading, at anchorPosition: CGPoint) {
        self.init(proposedSize: _ProposedSize(size: proposedSize), anchor: anchor, at: anchorPosition)
    }

    @inline(__always)
    internal init(proposedSize: _ProposedSize, anchor: UnitPoint, at anchorPosition: CGPoint) {
        self.proposedSize_ = proposedSize
        self.anchor = anchor
        self.anchorPosition = anchorPosition
    }

    @inline(__always)
    internal var rect: CGRect {
        let x = anchorPosition.x - (proposedSize_.width ?? 0) * anchor.x
        let y = anchorPosition.y - (proposedSize_.height ?? 0) * anchor.y
        return CGRect(origin: CGPoint(x: x, y: y), size: proposedSize_.size)
    }
}
