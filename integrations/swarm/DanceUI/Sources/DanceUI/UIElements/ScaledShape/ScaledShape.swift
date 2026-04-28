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

/// A shape with a scale transform applied to it.
@frozen
@available(iOS 13.0, *)
public struct ScaledShape<Content>: Shape where Content: Shape {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = AnimatablePair<Content.AnimatableData, AnimatablePair<AnimatablePair<CGFloat, CGFloat>, UnitPoint.AnimatableData>>
    
    /// The type of view representing the body of this view.
    public typealias Body = _ShapeView<ScaledShape<Content>, ForegroundStyle>
    
    // 0x0
    public var shape: Content
    
    // metadata + 0x24
    public var scale: CGSize
    
    // metadata + 0x28
    public var anchor: UnitPoint
    
    @inlinable
    public init(shape: Content, scale: CGSize, anchor: UnitPoint = .center) {
        self.shape = shape
        self.scale = scale
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
        
        let rectWidth = rect.width
        
        let rectHeight = rect.height
        
        let rectX = rect.origin.x
        
        let rectY = rect.origin.y
        
        let translationX = anchor.x * rectWidth + rectX
        
        let translationY = anchor.y * rectHeight + rectY
        
        let transform = CGAffineTransform.init(translationX: -translationX, y: -translationY)
        
        let scaledTransform = CGAffineTransform.init(scaleX: scale.width, y: scale.height)
        
        let concatTransform = transform.concatenating(scaledTransform)
        
        let newTransform = CGAffineTransform(translationX: translationX, y: translationY)
        
        let newConcatTransform = concatTransform.concatenating(newTransform)
        
        let shapePath = shape.path(in: rect)
        
        return shapePath.applying(newConcatTransform)
    }
    
    /// The data to animate.
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(shape.animatableData,
                           AnimatablePair(AnimatablePair(scale.width,
                                                         scale.height),
                                          anchor.animatableData))
        }
        
        set {
            shape.animatableData = newValue.first
            scale = CGSize(width: newValue.second.first.first, height: newValue.second.first.second)
            anchor.animatableData = newValue.second.second
        }
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Scales this shape without changing its bounding frame.
    ///
    /// Both the `x` and `y` multiplication factors halve their respective
    /// dimension's size when set to `0.5`, maintain their existing size when
    /// set to `1`, double their size when set to `2`, and so forth.
    ///
    /// - Parameters:
    ///   - x: The multiplication factor used to resize this shape along its
    ///     x-axis.
    ///   - y: The multiplication factor used to resize this shape along its
    ///     y-axis.
    ///
    /// - Returns: A scaled form of this shape.
    @inlinable
    public func scale(x: CGFloat = 1,
                      y: CGFloat = 1,
                      anchor: UnitPoint = .center) -> ScaledShape<Self> {
        ScaledShape(shape: self,
                    scale: CGSize(width: x, height: y),
                    anchor: anchor)
    }
    
    /// Scales this shape without changing its bounding frame.
    ///
    /// - Parameter scale: The multiplication factor used to resize this shape.
    ///   A value of `0` scales the shape to have no size, `0.5` scales to half
    ///   size in both dimensions, `2` scales to twice the regular size, and so
    ///   on.
    ///
    /// - Returns: A scaled form of this shape.
    @inlinable
    public func scale(_ scale: CGFloat,
                      anchor: UnitPoint = .center) -> ScaledShape<Self> {
        self.scale(x: scale,
                   y: scale,
                   anchor: anchor)
    }
}
