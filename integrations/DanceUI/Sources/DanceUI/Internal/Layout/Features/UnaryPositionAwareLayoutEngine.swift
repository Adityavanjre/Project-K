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
internal struct UnaryPositionAwareLayoutEngine<Layout: UnaryLayout>: LayoutEngine {

    internal let layout: Layout

    internal let layoutContext: SizeAndSpacingContext

    internal let child: LayoutProxy

    internal var cache: Cache3<_ProposedSize, CGSize>

    internal init(layout: Layout, layoutContext: SizeAndSpacingContext, child: LayoutProxy) {
        self.layout = layout
        self.layoutContext = layoutContext
        self.child = child
        self.cache = .init()
    }

    internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {

        if let value = cache[size] {
            return value
        } else {
            let fitSize = layout.sizeThatFits(in: size, context: layoutContext, child: child)
            cache[size] = fitSize
            return fitSize
        }
    }

    internal func layoutPriority() -> Double {
        layout.layoutPriority(child: child)
    }

    internal func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        nil
    }

    internal func requiresSpacingProjection() -> Bool {
        false
    }

    internal func ignoresAutomaticPadding() -> Bool {
        false
    }

}
