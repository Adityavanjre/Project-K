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
public struct _StrokedShape<S>: Shape, Animatable where S: Shape {
    
    public typealias AnimatableData = AnimatablePair<S.AnimatableData, StrokeStyle.AnimatableData>
    
    public typealias Body = _ShapeView<_StrokedShape<S>, ForegroundStyle>
    
    //0x00
    public var shape: S
    
    //0x08
    public var style: StrokeStyle
    
    @inlinable
    public init(shape: S, style: StrokeStyle) {
          self.shape = shape
          self.style = style
      }
    
    public var animatableData: AnimatableData {
        get {
            AnimatableData(shape.animatableData, style.animatableData)
        }
        
        set {
            shape.animatableData = newValue.first
            style.animatableData = newValue.second
        }
    }
    
    public static var role: ShapeRole {
        S.role
    }
    
    public func path(in rect: CGRect) -> Path {
        let path = self.shape.path(in: rect)
        guard !path.isEmpty else {
            return path
        }
        var strokedPath = Path()
        strokedPath.storage = .stroked(StrokedPath(path: path, style: self.style))
        return strokedPath
    }
    
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Returns a new shape that is a stroked copy of `self` with
    /// line-width defined by `lineWidth` and all other properties of
    /// `StrokeStyle` having their default values.
    @inlinable
    public func stroke(style: StrokeStyle) -> some Shape {
          return _StrokedShape(shape: self, style: style)
      }
    
    /// Returns a new shape that is a stroked copy of `self`, using the
    /// contents of `style` to define the stroke characteristics.
    @inlinable
    public func stroke(lineWidth: CGFloat = 1) -> some Shape {
          return stroke(style: StrokeStyle(lineWidth: lineWidth))
      }
    
    /// Traces the outline of this shape with a color or gradient.
    ///
    /// The following example adds a dashed purple stroke to a `Capsule`:
    ///
    ///     Capsule()
    ///     .stroke(
    ///         Color.purple,
    ///         style: StrokeStyle(
    ///             lineWidth: 5,
    ///             lineCap: .round,
    ///             lineJoin: .miter,
    ///             miterLimit: 0,
    ///             dash: [5, 10],
    ///             dashPhase: 0
    ///         )
    ///     )
    ///
    /// - Parameters:
    ///   - content: The color or gradient with which to stroke this shape.
    ///   - style: The stroke characteristics --- such as the line's width and
    ///     whether the stroke is dashed --- that determine how to render this
    ///     shape.
    /// - Returns: A stroked shape.
    @inlinable
    public func stroke<S: ShapeStyle>(_ content: S, style: StrokeStyle) -> some View {
          return stroke(style: style).fill(content)
      }
    
    /// Traces the outline of this shape with a color or gradient.
    ///
    /// The following example draws a circle with a purple stroke:
    ///
    ///     Circle().stroke(Color.purple, lineWidth: 5)
    ///
    /// - Parameters:
    ///   - content: The color or gradient with which to stroke this shape.
    ///   - lineWidth: The width of the stroke that outlines this shape.
    /// - Returns: A stroked shape.
    @inlinable
    public func stroke<S: ShapeStyle>(_ content: S, lineWidth: CoreGraphics.CGFloat = 1) -> some View {
          return stroke(content, style: StrokeStyle(lineWidth: lineWidth))
      }
    
}
