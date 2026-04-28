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
extension View {
    
    /// Sets a clipping shape for this view.
    ///
    /// Use `clipShape(_:style:)` to clip the view to the provided shape. By
    /// applying a clipping shape to a view, you preserve the parts of the view
    /// covered by the shape, while eliminating other parts of the view. The
    /// clipping shape itself isn't visible.
    ///
    /// For example, this code applies a circular clipping shape to a `Text`
    /// view:
    ///
    ///     Text("Clipped text in a circle")
    ///         .frame(width: 175, height: 100)
    ///         .foregroundColor(Color.white)
    ///         .background(Color.black)
    ///         .clipShape(Circle())
    ///
    /// The resulting view shows only the portion of the text that lies within
    /// the bounds of the circle.
    ///
    ///
    /// - Parameters:
    ///   - shape: The clipping shape to use for this view. The `shape` fills
    ///     the view's frame, while maintaining its aspect ratio.
    ///   - style: The fill style to use when rasterizing `shape`.
    ///
    /// - Returns: A view that clips this view to `shape`, using `style` to
    ///   define the shape's rasterization.
    @inlinable
    public func clipShape<S>(_ shape: S, style: FillStyle = FillStyle()) -> some View where S: Shape {
        let effect = _ClipEffect(shape: shape, style: style)
        return modifier(effect)
    }
    
    /// Clips this view to its bounding rectangular frame.
    ///
    /// Use the `clipped(antialiased:)` modifier to hide any content that
    /// extends beyond the layout bounds of the shape.
    ///
    /// By default, a view's bounding frame is used only for layout, so any
    /// content that extends beyond the edges of the frame is still visible.
    ///
    ///     Text("This long text string is clipped")
    ///         .fixedSize()
    ///         .frame(width: 175, height: 100)
    ///         .clipped()
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameter antialiased: A Boolean value that indicates whether the
    ///   rendering system applies smoothing to the edges of the clipping
    ///   rectangle.
    ///
    /// - Returns: A view that clips this view to its bounding frame.
    @inlinable
    public func clipped(antialiased: Bool = false) -> some View {
          return clipShape(Rectangle(),
              style: FillStyle(antialiased: antialiased))
      }
    
}

@frozen
@available(iOS 13.0, *)
public struct _ClipEffect<ClipShape: Shape>: RendererEffect {
    
    public typealias Body = Never
    
    public typealias AnimatableData = ClipShape.AnimatableData
    
    public var shape: ClipShape
    
    public var style: FillStyle
    
    @inlinable
    public init(shape: ClipShape, style: FillStyle = FillStyle()) {
        self.shape = shape
        self.style = style
    }
    
    public var animatableData: ClipShape.AnimatableData {
        
        get {
            shape.animatableData
        }
        
        set {
            shape.animatableData = newValue
        }
    }
    
    func effectValue(size: CGSize) -> DisplayList.Effect {
        let path: Path = shape.path(in: .init(origin: .zero, size: size))
        return .clip(path, style)
    }
}
