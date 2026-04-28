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

@available(iOS 13.0, *)
internal struct IncrementalLayoutComputer<Layout: IncrementalLayout>: StatefulRule {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var layout: Layout

    @Attribute
    internal var environment: EnvironmentValues

    internal var cache: ViewCache?

    internal mutating func updateValue() {
        let engine = Engine(layout: layout, context: SizeAndSpacingContext(environment: _environment), cache: cache!, sizeCache: Cache3<_ProposedSize, CGSize>())
        update(to: engine)
    }

    fileprivate struct Engine: LayoutEngine {

        internal var layout: Layout

        internal var context: SizeAndSpacingContext

        internal var cache: ViewCache

        internal var sizeCache: Cache3<_ProposedSize, CGSize>

        internal func spacing() -> Spacing {
            let children = cache.children(context: context.context)
            return cache.withMutableState(type: Layout.State.self) { (state) -> Spacing in
                layout.spacing(children: children, context: context, state: &state)
            }
        }

        internal func requiresSpacingProjection() -> Bool {
            false
        }

        internal mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize {
            if let fittingSize = sizeCache[size] {
                return fittingSize
            }
            let children = cache.children(context: context.context)
            let fittingSize = cache.withMutableState(type: Layout.State.self) { (state) -> CGSize in
                return layout.sizeThatFits(proposedSize: size, children: children, context: context, state: &state)
            }
            sizeCache[size] = fittingSize
            return fittingSize
        }

        internal mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
            nil
        }

    }
}
