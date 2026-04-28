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
public struct OffsetShape<Content>: Shape where Content: Shape {
    
    /// The type of view representing the body of this view.
    public typealias Body = _ShapeView<OffsetShape<Content>, ForegroundStyle>
    
    /// The type defining the data to animate.
    public typealias AnimatableData = AnimatablePair<Content.AnimatableData, AnimatablePair<CGFloat, CGFloat>>
    
    // 0x0
    public var shape: Content
    
    // metadata + 0x24
    public var offset: CGSize
    
    @inlinable
    public init(shape: Content, offset: CGSize) {
        self.shape = shape
        self.offset = offset
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
        let shapePath = shape.path(in: rect)
        
        guard offset != .zero else {
            return shapePath
        }
        
        let transform = CGAffineTransform.init(translationX: offset.width, y: offset.height)
        
        return shapePath.applying(transform)
    }
    
    /// The data to animate.
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(shape.animatableData, AnimatablePair(offset.width, offset.height))
        }
        
        set {
            shape.animatableData = newValue.first
            offset = CGSize(width: newValue.second.first, height: newValue.second.second)
        }
    }
}

@available(iOS 13.0, *)
extension OffsetShape: InsettableShape where Content: InsettableShape {
    
    /// The type of the inset shape.
    public typealias InsetShape = OffsetShape<Content.InsetShape>
    
    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> OffsetShape<Content.InsetShape> {
        return shape.inset(by: amount).offset(offset)
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Changes the relative position of this shape using the specified size.
    ///
    /// The following example renders two circles. It places one circle at its
    /// default position. The second circle is outlined with a stroke,
    /// positioned on top of the first circle and offset by 100 points to the
    /// left and 50 points below.
    ///
    ///     Circle()
    ///     .overlay(
    ///         Circle()
    ///         .offset(CGSize(width: -100, height: 50))
    ///         .stroke()
    ///     )
    ///
    /// - Parameter offset: The amount, in points, by which you offset the
    ///   shape. Negative numbers are to the left and up; positive numbers are
    ///   to the right and down.
    ///
    /// - Returns: A shape offset by the specified amount.
    @inlinable
    public func offset(_ offset: CGSize) -> OffsetShape<Self> {
        OffsetShape(shape: self, offset: offset)
    }
    
    
    /// Changes the relative position of this shape using the specified point.
    ///
    /// The following example renders two circles. It places one circle at its
    /// default position. The second circle is outlined with a stroke,
    /// positioned on top of the first circle and offset by 100 points to the
    /// left and 50 points below.
    ///
    ///     Circle()
    ///     .overlay(
    ///         Circle()
    ///         .offset(CGPoint(x: -100, y: 50))
    ///         .stroke()
    ///     )
    ///
    /// - Parameter offset: The amount, in points, by which you offset the
    ///   shape. Negative numbers are to the left and up; positive numbers are
    ///   to the right and down.
    ///
    /// - Returns: A shape offset by the specified amount.
    @inlinable
    public func offset(_ offset: CGPoint) -> OffsetShape<Self> {
        OffsetShape(
            shape: self, offset: CGSize(width: offset.x, height: offset.y))
    }
    
    
    /// Changes the relative position of this shape using the specified point.
    ///
    /// The following example renders two circles. It places one circle at its
    /// default position. The second circle is outlined with a stroke,
    /// positioned on top of the first circle and offset by 100 points to the
    /// left and 50 points below.
    ///
    ///     Circle()
    ///     .overlay(
    ///         Circle()
    ///         .offset(x: -100, y: 50)
    ///         .stroke()
    ///     )
    ///
    /// - Parameters:
    ///   - x: The horizontal amount, in points, by which you offset the shape.
    ///     Negative numbers are to the left and positive numbers are to the
    ///     right.
    ///   - y: The vertical amount, in points, by which you offset the shape.
    ///     Negative numbers are up and positive numbers are down.
    ///
    /// - Returns: A shape offset by the specified amount.
    @inlinable
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> OffsetShape<Self> {
        OffsetShape(shape: self, offset: .init(width: x, height: y))
    }
}
