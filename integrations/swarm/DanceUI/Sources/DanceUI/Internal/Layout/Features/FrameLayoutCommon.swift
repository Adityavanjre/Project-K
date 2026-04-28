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
protocol FrameLayoutCommon {
    var alignment: Alignment {get set}
}

@available(iOS 13.0, *)
extension FrameLayoutCommon {

    internal func commonPlacement(of child: LayoutProxy, in context: PlacementContext, childProposal: _ProposedSize) -> _Placement {
        let size: CGSize = context.size
        let computer: LayoutComputer = child.layoutComputer
        let fittingSize: CGSize = computer.engine.sizeThatFits(childProposal)
        let hAlignmentID = alignment.horizontal.id
        let vAlignmentID = alignment.vertical.id

        let dimensions: ViewDimensions = .init(guideComputer: LayoutComputer.defaultValue, size: ViewSize(value: size, _proposal: size))
        let hAlignmentDefaultValue: CGFloat = hAlignmentID.defaultValue(in: dimensions)
        let vAlignmentDefaultValue: CGFloat = vAlignmentID.defaultValue(in: dimensions)

        let explicitDimension = ViewDimensions(guideComputer: computer, size: ViewSize(value: fittingSize, proposal: childProposal))

        let hAlignmentExplicitValue: CGFloat = explicitDimension[alignment.horizontal]

        let vAlignmentExplicitValue: CGFloat = explicitDimension[alignment.vertical]

        let x = hAlignmentDefaultValue - hAlignmentExplicitValue
        let y = vAlignmentDefaultValue - vAlignmentExplicitValue

        let placement = _Placement(proposedSize: childProposal, anchor: .topLeading, at: CGPoint(x: x, y: y))
        return placement
    }
}
