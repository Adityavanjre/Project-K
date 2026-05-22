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
internal struct _IncrementalLayout_Child {

    internal var cache: ViewCache

    internal var context: DanceUIGraph.AnyRuleContext

    internal var data: Data

    @inlinable
    internal var isSectionHeaderOrFooter: Bool {
        data.section.isHeader || data.section.isFooter
    }

    @inlinable
    internal var layout: LayoutProxy {
        LayoutProxy(context: context, attributes: LayoutProxyAttributes(_layoutComputer: .init(cache.item(data: data).outputs.layout.attribute), _traitsList: .init(nil)))
    }

    @inlinable
    internal var layoutComputer: LayoutComputer {
        layout.layoutComputer
    }

    @inlinable
    internal func lengthAndSpacing(size: _ProposedSize, axis: Axis, predecessor: _IncrementalLayout_Child?, uniformSpacing: CGFloat?) -> (length: CGFloat, spacing: CGFloat) {
        let fitLength = layoutComputer.engine.lengthThatFits(size, in: axis)
        let spacing: CGFloat = predecessor.map { (precedessor) -> CGFloat in
            if let uniformSpacing = uniformSpacing {
                return uniformSpacing
            }
            let precedessorSpacing = precedessor.layoutComputer.engine.spacing()
            let successorSpacing = layoutComputer.engine.spacing()
            return precedessorSpacing.distanceToSuccessorView(along: axis, preferring: successorSpacing) ?? 8
        } ?? 0
        return (fitLength, spacing)
    }

}

@available(iOS 13.0, *)
extension _IncrementalLayout_Child {

    internal struct Data {

        internal var elements: _ViewList_Elements

        internal var id: _ViewList_ID

        internal var traits: ViewTraitCollection

        internal var list: Attribute<ViewList>?

        internal var section: ViewCache.Section

    }

    internal enum Kind {
        case unknown
        case header
        case footer
    }
}
