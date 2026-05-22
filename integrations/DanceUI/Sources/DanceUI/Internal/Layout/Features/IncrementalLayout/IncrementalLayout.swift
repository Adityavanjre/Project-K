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
internal protocol IncrementalLayout: _VariadicView_UnaryViewRoot, Animatable {

    associatedtype State

    static var initialState: State { get }

    func sizeThatFits(proposedSize: _ProposedSize, children: _IncrementalLayout_Children, context: SizeAndSpacingContext, state: inout State) -> CGSize

    func spacing(children: _IncrementalLayout_Children, context: SizeAndSpacingContext, state: inout State) -> Spacing

    func place(children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, state: inout State, in: inout _IncrementalLayout_Placements)

    func initialPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasInserted: Bool, context: _IncrementalLayout_PlacementContext, oldPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement

    func finalPlacement(at index: Int, in placedChildren: [_IncrementalLayout_PlacedChild], wasRemoved: Bool, context: _IncrementalLayout_PlacementContext, newPlacedChildren: [_IncrementalLayout_PlacedChild]) -> _Placement

    func firstIndex<Index: Hashable>(of index: Index, children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext) -> Int?

    func boundingRect(at index: Int, children: _IncrementalLayout_Children, context: _IncrementalLayout_PlacementContext, state: inout State) -> CGRect?

    static func hasMultipleViewsInAxis(_ axis: Axis) -> Bool

    var pinnedViews: PinnedScrollableViews { get }

    var pinnedAxes: Axis.Set { get }

    static var majorAxis: Axis { get }
}

@available(iOS 13.0, *)
extension IncrementalLayout {

    internal func spacing(children: _IncrementalLayout_Children, context: SizeAndSpacingContext, state: inout State) -> Spacing {
        .zeroText
    }

    public static var _viewListOptions: _ViewListInputs.Options {
        .requiresSections
    }

    public static func _makeView(root: _GraphValue<Self>, inputs: _ViewInputs, body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.hasMajorAxis = true
        newInputs.majorAxis = majorAxis
        let listOutputs = body(_Graph(), newInputs)
        let listInputs = _ViewListInputs(base: inputs.base, implicitID: 0, options: _ViewListInputs.Options(), traits: .init(nil), traitKeys: ViewTraitKeys())
        let viewList = listOutputs.makeAttribute(inputs: listInputs)

        let requiresAccessibilityNodes = newInputs.preferences.requiresAccessibilityNodes
        if requiresAccessibilityNodes && !newInputs.preferences.requiresScrollable {
            newInputs.preferences.requiresScrollable = true
        }

        let viewCache = _ViewCache<Self>(layout: root.value, list: viewList, inputs: newInputs)
        var outputs = viewCache.outputs

        if requiresAccessibilityNodes {
            if let incrementalLayoutTransform = makeAccessibilityIncrementalLayoutTransform(role: .stack, inputs: inputs, outputs: outputs) {
                outputs.accessibilityNodes = incrementalLayoutTransform
            }

            if let scrollable = outputs.scrollable {
                let modifier = AccessibilityIncrementalLayoutScrollViewModifier(scrollables: scrollable)
                outputs.accessibilityNodes = AccessibilityIncrementalLayoutScrollViewModifier.makeAccessibilityTransform(modifier: _GraphValue(value: modifier), inputs: inputs, outputs: outputs)
            }
        }

        return outputs
    }

    internal static func hasMultipleViewsInAxis(_ axis: Axis) -> Bool {
        true
    }
}
