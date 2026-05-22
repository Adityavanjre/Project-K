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
internal protocol LayoutEngine: CustomDebugStringConvertible {

    func layoutPriority() -> Double

    func ignoresAutomaticPadding() -> Bool

    mutating func spacing() -> Spacing

    func requiresSpacingProjection() -> Bool

    mutating func sizeThatFits(_ size: _ProposedSize) -> CGSize

    mutating func childGeometries(at: ViewSize, origin: CGPoint) -> [ViewGeometry]

    mutating func explicitAlignment(_ key: AlignmentKey,
                                    at size: ViewSize) -> CGFloat?
    mutating func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat
}

@available(iOS 13.0, *)
extension LayoutEngine {

    internal func ignoresAutomaticPadding() -> Bool {
        false
    }

}

@available(iOS 13.0, *)
extension LayoutEngine {

    internal var debugDescription: String {
        "\(Self.self)"
    }

    internal func spacing() -> Spacing {
        .zeroText
    }

    internal func requiresSpacingProjection() -> Bool {
        false
    }

    internal func childGeometries(at: ViewSize, origin: CGPoint) -> [ViewGeometry] {
#if DEBUG
        _danceuiFatalError()
#else
        return []
#endif
    }

    internal func layoutPriority() -> Double {
        0
    }

    mutating func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        nil
    }

    mutating func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat {
        let size = sizeThatFits(proposedSize)
        return axis == .horizontal ? size.width : size.height
    }
}

@available(iOS 13.0, *)
extension StatefulRule where Value == LayoutComputer {

    internal mutating func update<Engine: LayoutEngine>(to engine: Engine) {
        LayoutEngineBox<Engine>.update(&self, inPlace: { (engineDelegate) in
            engineDelegate.engine = engine
        }) { () in
            LayoutEngineBox<Engine>(engine: engine)
        }
    }

}
