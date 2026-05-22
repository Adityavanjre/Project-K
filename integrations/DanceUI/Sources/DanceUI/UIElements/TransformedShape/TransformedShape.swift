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

/// A shape with an affine transform applied to it.
@frozen
@available(iOS 13.0, *)
public struct TransformedShape<Content>: Shape where Content: Shape {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = Content.AnimatableData
    
    /// The type of view representing the body of this view.
    public typealias Body = _ShapeView<TransformedShape<Content>, ForegroundStyle>
    
    // 0x0
    public var shape: Content
    
    // metadata + 0x24
    public var transform: CGAffineTransform
    
    @inlinable
    public init(shape: Content, transform: CGAffineTransform) {
        self.shape = shape
        self.transform = transform
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
        shape.path(in: rect).applying(transform)
    }
    
    /// The data to animate.
    public var animatableData: AnimatableData {
        
        get {
            shape.animatableData
        }
        
        set {
            shape.animatableData = newValue
        }
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Applies an affine transform to this shape.
    ///
    /// Affine transforms present a mathematical approach to applying
    /// combinations of rotation, scaling, translation, and skew to shapes.
    ///
    /// - Parameter transform: The affine transformation matrix to apply to this
    ///   shape.
    ///
    /// - Returns: A transformed shape, based on its matrix values.
    @inlinable
    public func transform(_ transform: CGAffineTransform) -> TransformedShape<Self> {
        TransformedShape(shape: self, transform: transform)
    }
}
