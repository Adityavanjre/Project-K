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

internal import DanceUIGraph
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal struct AlignmentModifiedLayoutComputer: StatefulRule {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var modifier: _AlignmentWritingModifier

    @OptionalAttribute
    internal var childLayoutComputer: LayoutComputer?

    internal var oldModifier: _AlignmentWritingModifier?

    internal mutating func updateValue() {
        let (layoutComputer, isLayoutComputerChanged) = $childLayoutComputer?.changedValue() ?? (.defaultValue, false)
        let (modifier, isModifierChanged) = $modifier.changedValue()
        defer {
            oldModifier = modifier
        }
        func modifierNeedsUpdate() -> Bool {
            guard isModifierChanged else {
                return false
            }
            guard let old = oldModifier else {
                return true
            }
            return !DGCompareValues(lhs: modifier, rhs: old)
        }

        guard isLayoutComputerChanged || !context.hasValue || modifierNeedsUpdate() else {
            return
        }
        let engine = Engine(modifier: modifier,
                            childLayoutComputer: layoutComputer)
        update(to: engine)
    }

    internal struct Engine: LayoutEngine {

        internal var modifier: _AlignmentWritingModifier

        internal var childLayoutComputer: LayoutComputer

        internal func spacing() -> Spacing {
            childLayoutComputer.engine.spacing()
        }

        internal func requiresSpacingProjection() -> Bool {
            childLayoutComputer.engine.requiresSpacingProjection()
        }

        internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
            childLayoutComputer.engine.sizeThatFits(size)
        }

        internal mutating func explicitAlignment(_ key: AlignmentKey,
                                                 at size: ViewSize) -> CGFloat? {
            let dimension = ViewDimensions(guideComputer: childLayoutComputer,
                                           size: size)
            guard modifier.key == key else {
                return dimension[explicit: key]
            }
            return modifier.computeValue(dimension)
        }
    }
}
