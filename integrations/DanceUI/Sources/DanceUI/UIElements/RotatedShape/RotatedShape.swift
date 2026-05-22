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
public struct RotatedShape<Content>: Shape where Content: Shape {
    
    /// The type of view representing the body of this view.
    public typealias Body = _ShapeView<RotatedShape<Content>, ForegroundStyle>
    
    /// The type defining the data to animate.
    public typealias AnimatableData = AnimatablePair<Content.AnimatableData, AnimatablePair<Angle.AnimatableData, UnitPoint.AnimatableData>>
    
    public var shape: Content
    
    public var angle: Angle
    
    public var anchor: UnitPoint
    
    @inlinable
    public init(shape: Content, angle: Angle, anchor: UnitPoint = .center) {
        self.shape = shape
        self.angle = angle
        self.anchor = anchor
    }
    
    /// An indication of how to style a shape.
    ///
    /// DanceUI looks at a shape's role when deciding how to apply a
    /// ``ShapeStyle`` at render time. The ``Shape`` protocol provides a
    /// default implementation with a value of ``ShapeRole/fill``. If you
    /// create a composite shape, you can provide an override of this property
    /// to return another value, if appropriate.
    public static var role: ShapeRole {
        Content.role
    }
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        
        let translationX = anchor.x * rect.width + rect.origin.x
        
        let translationY = anchor.y * rect.height + rect.origin.y
        
        let transform = CGAffineTransform.init(translationX: -translationX, y: -translationY)
        
        let angleTransform = CGAffineTransform.init(rotation: angle)
        
        let concatTransform = transform.concatenating(angleTransform)
        
        let newTransform = CGAffineTransform(translationX: translationX, y: translationY)
        
        let newConcatTransform = concatTransform.concatenating(newTransform)
        
        let shapePath = shape.path(in: rect)
        
        return shapePath.applying(newConcatTransform)
    }
    
    /// The data to animate.
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(shape.animatableData, AnimatablePair(angle.animatableData, anchor.animatableData))
        }
        
        set {
            shape.animatableData = newValue.first
            angle.animatableData = newValue.second.first
            anchor.animatableData = newValue.second.second
        }
    }
}

@available(iOS 13.0, *)
extension RotatedShape: InsettableShape where Content: InsettableShape {
    
    /// The type of the inset shape.
    public typealias InsetShape = RotatedShape<Content.InsetShape>
    
    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> RotatedShape<Content.InsetShape> {
        return shape.inset(by: amount).rotation(angle, anchor: anchor)
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Rotates this shape around an anchor point at the angle you specify.
    ///
    /// The following example rotates a square by 45 degrees to the right to
    /// create a diamond shape:
    ///
    ///     RoundedRectangle(cornerRadius: 10)
    ///     .rotation(Angle(degrees: 45))
    ///     .aspectRatio(1.0, contentMode: .fit)
    ///
    /// - Parameters:
    ///   - angle: The angle of rotation to apply. Positive angles rotate
    ///     clockwise; negative angles rotate counterclockwise.
    ///   - anchor: The point to rotate the shape around.
    ///
    /// - Returns: A rotated shape.
    @inlinable
    public func rotation(_ angle: Angle, anchor: UnitPoint = .center) -> RotatedShape<Self> {
        RotatedShape(shape: self, angle: angle, anchor: anchor)
    }
}
