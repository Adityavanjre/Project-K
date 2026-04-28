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
internal protocol UnaryLayout: Animatable, MultiViewModifier, PrimitiveViewModifier {

    associatedtype PlacementContextType: _FinalPlacementContext

    func placement(of child: LayoutProxy, in context: PlacementContextType) -> _Placement

    func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize

    func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing

    func layoutPriority(child: LayoutProxy) -> Double

    func ignoresAutomaticPadding(child: LayoutProxy) -> Bool

    static func makeViewImpl(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs
}

@available(iOS 13.0, *)
extension UnaryLayout {

    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        makeViewImpl(modifier: modifier, inputs: inputs, body: body)
    }

    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        child.layoutComputer.engine.spacing()
    }

    internal func layoutPriority(child: LayoutProxy) -> Double {
        0
    }

    internal func ignoresAutomaticPadding(child: LayoutProxy) -> Bool {
        false
    }

}
