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
internal struct MoveTransition: Transition {

    typealias TransitionModifier = MoveLayout

    internal var edge: Edge

    func transitionModifier(phase: TransitionPhase) -> MoveLayout {
        MoveLayout(edge: phase != .normal ? edge : nil)
    }

}

@available(iOS 13.0, *)
extension MoveTransition {

    internal struct MoveLayout: ViewModifier, Animatable, UnaryLayout {

        internal typealias Body = Never

        internal typealias AnimatableData = EmptyAnimatableData

        internal typealias PlacementContextType = PlacementContext

        internal let edge: Edge?

        internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
            var point = CGPoint.zero
            let size = context.size
            if let edge1 = edge {
                switch edge1 {
                case .top:
                    point = CGPoint(x: 0.0, y: -size.height)
                case .leading:
                    point = CGPoint(x: -size.width, y: 0.0)
                case .bottom:
                    point = CGPoint(x: 0.0, y: size.height)
                case .trailing:
                    point = CGPoint(x: size.width, y: 0.0)
                }
            }

            return _Placement(proposedSize: size, anchor: .topLeading, at: point)
        }

        internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
            child.layoutComputer.engine.sizeThatFits(proposedSize)
        }
    }
}
