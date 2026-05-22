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
internal struct SpacerLayoutComputer<Spacer: PrimitiveSpacer>: StatefulRule {

    internal typealias Value = LayoutComputer

    @Attribute
    internal var spacer: Spacer

    internal var orientation: Axis?

    @OptionalAttribute
    internal var adaptiveOrientation: Axis?

    internal mutating func updateValue() {
        update(to: _LayoutEngine(spacer: spacer, orientation: orientation ?? self.adaptiveOrientation))
    }
}

@available(iOS 13.0, *)
extension SpacerLayoutComputer {

    internal struct _LayoutEngine: LayoutEngine {

        internal let spacer: Spacer

        internal let orientation: Axis?

        internal func layoutPriority() -> Double {
            -.infinity
        }

        internal func spacing() -> Spacing {
            guard let axis = orientation else {
                return .zero
            }
            switch axis {
                case .horizontal:
                    return .zeroHorizontal
                case .vertical:
                    return .zeroVertical
            }
        }

        internal func requiresSpacingProjection() -> Bool {
            true
        }

        func sizeThatFits(_ size: _ProposedSize) -> CGSize {
            let minLength: CGFloat = spacer.minLength ?? 8
            var fitWidth: CGFloat = 0
            if orientation != .vertical {
                let width: CGFloat = size.width ?? -.infinity
                fitWidth = .maximum(width, minLength)
            }

            var fitHeight: CGFloat = 0
            if orientation != .horizontal {
                let height: CGFloat = size.height ?? -.infinity
                fitHeight = .maximum(height, minLength)
            }

            return CGSize(width: fitWidth, height: fitHeight)
        }

        mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
            nil
        }
    }

}
