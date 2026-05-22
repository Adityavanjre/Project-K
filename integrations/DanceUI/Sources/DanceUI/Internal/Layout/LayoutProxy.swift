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
internal struct LayoutProxy: Equatable {

    internal var context: AnyRuleContext

    internal private(set) var attributes : LayoutProxyAttributes

    internal init(context: DanceUIGraph.AnyRuleContext,
                  attributes: LayoutProxyAttributes = LayoutProxyAttributes(_layoutComputer: .init(nil), _traitsList: .init(nil))) {
        self.context = context
        self.attributes = attributes
    }

    @inlinable
    internal var layoutComputer: LayoutComputer {
        _read {
            yield context[attributes._layoutComputer] ?? .defaultValue
        }
    }

    internal func finallyPlaced(at placement: _Placement, in size: CGSize, layoutDirection: LayoutDirection) -> ViewGeometry {
        let layoutComputer = self.layoutComputer
        let fittingSize = layoutComputer.engine.sizeThatFits(placement.proposedSize_)
        let origin = CGPoint(x: placement.anchorPosition.x - fittingSize.width * placement.anchor.x,
                             y: placement.anchorPosition.y - fittingSize.height * placement.anchor.y)
        var viewOrigin = ViewOrigin(value: origin)
        let viewDimensions = ViewDimensions(guideComputer: layoutComputer, size: ViewSize(value: fittingSize, proposal: placement.proposedSize_))
        switch layoutDirection {
        case .leftToRight:
            return ViewGeometry(origin: viewOrigin, dimensions: viewDimensions)
        case .rightToLeft:
            viewOrigin.value.x = size.width - CGRect(origin: origin, size: fittingSize).maxX
            return ViewGeometry(origin: viewOrigin, dimensions: viewDimensions)
        }
    }

    internal func distance(toSuccessor successor: Self, along axis: Axis) -> CGFloat {

        let currentSpacing = layoutComputer.engine.spacing()
        let successorSpacing = successor.layoutComputer.engine.spacing()

        return currentSpacing.distanceToSuccessorView(along: axis, preferring: successorSpacing) ?? 8
    }

    static func == (lhs: LayoutProxy, rhs: LayoutProxy) -> Bool {
        lhs.context.attribute.rawValue == rhs.context.attribute.rawValue &&
        lhs.attributes == rhs.attributes
    }
}

@available(iOS 13.0, *)
extension View {

    /// Sets the priority by which a parent layout should apportion space to
    /// this child.
    ///
    /// Views typically have a default priority of `0` which causes space to be
    /// apportioned evenly to all sibling views. Raising a view's layout
    /// priority encourages the higher priority view to shrink later when the
    /// group is shrunk and stretch sooner when the group is stretched.
    ///
    ///     HStack {
    ///         Text("This is a moderately long string.")
    ///             .font(.largeTitle)
    ///             .border(Color.gray)
    ///
    ///         Spacer()
    ///
    ///         Text("This is a higher priority string.")
    ///             .font(.largeTitle)
    ///             .layoutPriority(1)
    ///             .border(Color.gray)
    ///     }
    ///
    /// In the example above, the first ``Text`` element has the default
    /// priority `0` which causes its view to shrink dramatically due to the
    /// higher priority of the second ``Text`` element, even though all of their
    /// other attributes (font, font size and character count) are the same.
    ///
    ///
    /// A parent layout offers the child views with the highest layout priority
    /// all the space offered to the parent minus the minimum space required for
    /// all its lower-priority children.
    ///
    /// - Parameter value: The priority by which a parent layout apportions
    ///   space to the child.
    @inlinable
    public func layoutPriority(_ value: Double) -> some View {
        _trait(LayoutPriorityTraitKey.self, value)
    }

}

@available(iOS 13.0, *)
internal struct LayoutProxyAttributes: Equatable {

    internal var _layoutComputer : OptionalAttribute<LayoutComputer>

    internal var _traitsList : OptionalAttribute<ViewList>


}
