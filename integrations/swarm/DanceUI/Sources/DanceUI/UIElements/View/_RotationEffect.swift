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

@frozen
@available(iOS 13.0, *)
public struct _RotationEffect : GeometryEffect, Equatable {
    
    public typealias AnimatableData = AnimatablePair<Angle.AnimatableData, UnitPoint.AnimatableData>
    
    public typealias Body = Never
    
    public var angle: Angle
    
    public var anchor: UnitPoint
    
    @inlinable
    public init(angle: Angle, anchor: UnitPoint = .center) {
        self.angle = angle
        self.anchor = anchor
    }
    
    public var animatableData: _RotationEffect.AnimatableData {
        get {
            .init(
                angle.animatableData,
                anchor.animatableData
            )
        }
        set {
            angle.animatableData = newValue.first
            anchor.animatableData = newValue.second
        }
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        let transform = CGAffineTransform(
            translationX: -(size.width * anchor.x),
            y: -(size.height * anchor.y)
        )
        .concatenating(.init(rotation: angle))
        .concatenating(.init(translationX: size.width * anchor.x, y: size.height * anchor.y))
        
        return ProjectionTransform(transform)
    }


}

@available(iOS 13.0, *)
extension CGAffineTransform {
    
    @_spi(DanceUICompose)
    public init(rotation angle: Angle) {
        let sincos = __sincos_stret(angle.radians)
        self.init(
            a: CGFloat(sincos.__cosval),
            b: CGFloat(sincos.__sinval),
            c: CGFloat(-sincos.__sinval),
            d: CGFloat(sincos.__cosval),
            tx: 0.0,
            ty: 0.0
        )
    }
    
}

@available(iOS 13.0, *)
extension View {

    /// Rotates this view's rendered output around the specified point.
    ///
    /// Use `rotationEffect(_:anchor:)` to rotate the view by a specific amount.
    ///
    /// In the example below, the text is rotated by 22˚.
    ///
    ///     Text("Rotation by passing an angle in degrees")
    ///         .rotationEffect(.degrees(22))
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - angle: The angle at which to rotate the view.
    ///   - anchor: The location with a default of ``UnitPoint/center`` that
    ///     defines a point at which the rotation is anchored.
    public func rotationEffect(_ angle: Angle, anchor: UnitPoint = .center) -> some View {
#if DEBUG || DANCE_UI_INHOUSE
        if angle.radians.isInfinite {
            runtimeIssue(type: .error, "Angle init with an infinite value, This may cause potential runtime crashes")
        }
#endif
        return modifier(_RotationEffect(angle: angle, anchor: anchor))
    }

}
