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
let scale = 128

@available(iOS 13.0, *)
internal struct UnitRect: Equatable, Hashable {

    internal var x: CGFloat

    internal var y: CGFloat

    internal var width: CGFloat

    internal var height: CGFloat
}

@available(iOS 13.0, *)
extension UnitRect: Animatable {

    internal typealias AnimatableData = AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>>

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>> {
        get {
            var origin = AnimatablePair(x, AnimatablePair(y, AnimatablePair(width, height)))
            origin.scale(by: Double(scale))
            return origin
        }

        set {
            let floatScale = CGFloat(scale)
            self.x = newValue.first / floatScale
            self.y = newValue.second.first / floatScale
            self.width = newValue.second.second.first / floatScale
            self.height = newValue.second.second.second / floatScale
        }
    }
}

@available(iOS 13.0, *)
extension UnitRect: AnchorProtocol {

    internal typealias AnchorValue = CGRect

    internal static let defaultAnchor: CGRect = .zero

    internal func prepare(size: CGSize, transform: ViewTransform) -> CGRect {
        let newRect = CGRect(x: self.x * size.width,
                             y: self.y * size.height,
                             width: self.width * size.width,
                             height: self.height * size.height)

        guard newRect.isValid else {
            return newRect
        }

        var cornerPoints = newRect.cornerPoints
        cornerPoints.convert(to: .global, transform: transform)
        assert(cornerPoints.count == 4, "incorrect count")

        return .init(cornerPoints: cornerPoints[..<4])
    }

    internal static func valueIsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
        lhs.equalTo(rhs)
    }
}
