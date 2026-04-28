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
internal struct ViewOrigin: Equatable {

    @usableFromInline
    internal var value: CGPoint

    static let zero: ViewOrigin = .init(value: .zero)

    @inline(__always)
    internal mutating func apply(_ translation: CGPoint) {
        value.apply(CGSize(width: translation.x, height: translation.y))
    }

}

@available(iOS 13.0, *)
extension ViewOrigin: Animatable {

    public typealias AnimatableData = AnimatablePair<CGFloat, CGFloat>

    @inlinable
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(value.x, value.y)
        }

        set {
            value.x = newValue.first
            value.y = newValue.second
        }
    }
}
