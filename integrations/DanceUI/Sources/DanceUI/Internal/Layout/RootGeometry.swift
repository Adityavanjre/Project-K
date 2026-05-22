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
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct RootGeometry: Rule {

    internal typealias Value = ViewGeometry

    @OptionalAttribute
    internal var layoutDirection: LayoutDirection?

    @Attribute
    internal var proposedSize: ViewSize

    @OptionalAttribute
    internal var safeAreaInsets: _SafeAreaInsetsModifier?

    @OptionalAttribute
    internal var childLayoutComputer: LayoutComputer?

    internal var value: ViewGeometry {
        let layoutComputer = childLayoutComputer ?? .defaultValue
        let safeAreaInsetsModifier = self.safeAreaInsets
        let insets = safeAreaInsetsModifier?.insets ?? .zero
        let proposedSize = self.proposedSize.value
        let proposal = proposedSize.inset(by: insets)
        let fittingSize = layoutComputer.engine.sizeThatFits(_ProposedSize(size: proposal))
        let viewGraph: ViewGraph = ViewGraph.current
        var x: CGFloat = 0
        var y: CGFloat = 0
        if viewGraph.centersRootView {
            x = (proposal.width - fittingSize.width) * 0.5 + insets.leading
            y = (proposal.height - fittingSize.height) * 0.5 + insets.top
        } else {
            x = insets.leading
            y = insets.top
        }
        let layoutDirection = self.layoutDirection ?? .leftToRight
        switch layoutDirection {
        case .leftToRight:
            break
        case .rightToLeft:
            let rect = CGRect(x: x, y: y, width: fittingSize.width, height: fittingSize.height)
            x = proposedSize.width - rect.maxX
        }

        return ViewGeometry(origin: ViewOrigin(value: CGPoint(x: x, y: y)),
                            dimensions: ViewDimensions(guideComputer: layoutComputer,
                                                       size: ViewSize(value: fittingSize, _proposal: proposal)))
    }

}
