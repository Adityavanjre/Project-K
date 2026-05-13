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

@frozen
@available(iOS 13.0, *)
public struct _Rotation3DEffect: GeometryEffect, Equatable {
    
    public typealias AnimatableData = AnimatablePair<Double, AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>>>>>
    
    // 0x00
    public var angle: Angle
    
    // 0x08
    public var axis: (x: CGFloat, y: CGFloat, z: CGFloat)
    
    // 0x20
    public var anchor: UnitPoint
    
    // 0x30
    public var anchorZ: CGFloat
    
    // 0x38
    public var perspective: CGFloat
    
    @inlinable
    public init(angle: Angle,
                axis: (x: CGFloat, y: CGFloat, z: CGFloat),
                anchor: UnitPoint = .center,
                anchorZ: CGFloat = 0,
                perspective: CGFloat = 1) {
        self.angle = angle
        self.axis = axis
        self.anchor = anchor
        self.anchorZ = anchorZ
        self.perspective = perspective
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        
        var transform3DValue = CATransform3DIdentity
        
        let translateX = anchor.x * size.width
        
        let translateY = anchor.y * size.height
        
        let transform3DTranslate = CATransform3DTranslate(transform3DValue,
                                                          translateX,
                                                          translateY,
                                                          anchorZ)
        
        let m34 = -perspective / max(size.width, size.height)
        
        transform3DValue.m34 = m34
        
        let newTransform3D = CATransform3DConcat(transform3DValue,
                                                 transform3DTranslate)
        
        let rotateTransform = CATransform3DRotate(newTransform3D,
                                                  angle.radians,
                                                  axis.x,
                                                  axis.y,
                                                  axis.z)
        
        let rotateTranslate = CATransform3DTranslate(rotateTransform,
                                                     -translateX,
                                                     -translateY,
                                                     -anchorZ)
        
        return ProjectionTransform(rotateTranslate)
    }
    
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(angle.animatableData, AnimatablePair(axis.x * 128.0, AnimatablePair(axis.y * 128.0, AnimatablePair(axis.z * 128.0, AnimatablePair(anchor.animatableData, AnimatablePair(anchorZ, perspective * 128.0))))))
        }
        
        set {
            angle.animatableData = newValue.first
            axis.x = newValue.second.first / 128.0
            axis.y = newValue.second.second.first / 128.0
            axis.z = newValue.second.second.second.first / 128.0
            anchor.animatableData = newValue.second.second.second.second.first
            anchorZ = newValue.second.second.second.second.second.first
            perspective = newValue.second.second.second.second.second.second / 128.0
        }
    }
    
    public static func == (lhs: _Rotation3DEffect, rhs: _Rotation3DEffect) -> Bool {
        lhs.angle == rhs.angle &&
        lhs.axis.x == rhs.axis.x &&
        lhs.axis.y == rhs.axis.y &&
        lhs.axis.z == rhs.axis.z &&
        lhs.anchor == rhs.anchor &&
        lhs.anchorZ == rhs.anchorZ &&
        lhs.perspective == rhs.perspective
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Rotates this view's rendered output in three dimensions around the given
    /// axis of rotation.
    ///
    /// Use `rotation3DEffect(_:axis:anchor:anchorZ:perspective:)` to rotate the
    /// view in three dimensions around the given axis of rotation, and
    /// optionally, position the view at a custom display order and perspective.
    ///
    /// In the example below, the text is rotated 45˚ about the `y` axis,
    /// front-most (the default `zIndex`) and default `perspective` (`1`):
    ///
    ///     Text("Rotation by passing an angle in degrees")
    ///         .rotation3DEffect(.degrees(45), axis: (x: 0.0, y: 1.0, z: 0.0))
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - angle: The angle at which to rotate the view.
    ///   - axis: The `x`, `y` and `z` elements that specify the axis of
    ///     rotation.
    ///   - anchor: The location with a default of ``UnitPoint/center`` that
    ///     defines a point in 3D space about which the rotation is anchored.
    ///   - anchorZ: The location with a default of `0` that defines a point in
    ///     3D space about which the rotation is anchored.
    ///   - perspective: The relative vanishing point with a default of `1` for
    ///     this rotation.
    @inlinable public func rotation3DEffect(_ angle: Angle,
                                            axis: (x: CGFloat, y: CGFloat, z: CGFloat),
                                            anchor: UnitPoint = .center,
                                            anchorZ: CGFloat = 0,
                                            perspective: CGFloat = 1) -> some View {
        modifier(_Rotation3DEffect(
            angle: angle,
            axis: axis,
            anchor: anchor,
            anchorZ: anchorZ,
            perspective: perspective
        ))
    }
    
}
