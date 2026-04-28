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
internal struct GeometryReaderLayout: _Layout {
    
    internal typealias AnimatableData = EmptyAnimatableData
    
    internal typealias Body = Never
    
    internal typealias PlacementContextType = PlacementContext
        
    internal static let isDefaultEmptyLayout: Bool = false
    
    internal static let isIdentityUnaryLayout: Bool = false
    
    internal func placement(of collection: LayoutProxyCollection, in context: PlacementContext) -> [_Placement] {
        let count = collection.count
        let placement = _Placement(proposedSize: context.size, anchor: .topLeading, at: .zero)
        return Array(repeating: placement, count: count)
    }

    internal func sizeThatFits(in size: _ProposedSize, context: SizeAndSpacingContext, children: LayoutProxyCollection) -> CGSize {
        CGSize(width: size.width ?? 0, height: size.height ?? 0)
    }
    
    func layoutPriority(children: LayoutProxyCollection) -> Double {
        if (children.isEmpty && GeometryReaderLayout.isDefaultEmptyLayout) {
            return -.infinity
        } else {
            return 0.0
        }
    }
}
