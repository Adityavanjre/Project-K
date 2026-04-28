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

//@frozen
//public struct __SetFrameLayout: UnaryLayout {
//
//    public typealias Content = Void
//    public typealias Body = Never
//    public typealias AnimatableData = EmptyAnimatableData
//
//    internal typealias PlacementContextType = PlacementContext
//
//    @usableFromInline
//    internal var frame: CGRect
//
//    @inlinable
//    public init(_ frame: CGRect) {
//        self.frame = frame
//    }
//
//    internal func placement(of child: LayoutProxy, in context: PlacementContextType) -> _Placement {
//        _Placement(proposedSize: frame.size, anchor: .topLeading, at: frame.origin)
//    }
//
//    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
//        frame.size
//    }
//}
