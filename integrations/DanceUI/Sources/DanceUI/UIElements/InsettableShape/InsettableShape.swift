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

import CoreGraphics

/// A shape type that is able to inset itself to produce another shape.
@available(iOS 13.0, *)
public protocol InsettableShape: Shape {

    /// The type of the inset shape.
    associatedtype InsetShape: InsettableShape

    func inset(by amount: CGFloat) -> Self.InsetShape
    
}

@available(iOS 13.0, *)
extension InsettableShape {

    /// Returns a view that is the result of insetting `self` by
    /// `style.lineWidth / 2`, stroking the resulting shape with
    /// `style`, and then filling with `content`.
    @inlinable
    public func strokeBorder<S: ShapeStyle>(_ content: S, style: StrokeStyle, antialiased: Bool = true) -> some View {
        
        let insetShape = self.inset(by: style.lineWidth * 0.5)
        let strokedShape = insetShape.stroke(style: style)
        
        let fillStyle = FillStyle(eoFill: false, antialiased: antialiased)
        return strokedShape.fill(content, style: fillStyle)
    }

    /// Returns a view that is the result of insetting `self` by
    /// `style.lineWidth / 2`, stroking the resulting shape with
    /// `style`, and then filling with the foreground color.
    @inlinable
    public func strokeBorder(style: StrokeStyle, antialiased: Bool = true) -> some View {
        let insetShape = self.inset(by: style.lineWidth * 0.5)
        let strokedShape = insetShape.stroke(style: style)
        
        let fillStyle = FillStyle(eoFill: false, antialiased: antialiased)
        return strokedShape.fill(style: fillStyle)
    }

    /// Returns a view that is the result of filling the `width`-sized
    /// border (aka inner stroke) of `self` with `content`. This is
    /// equivalent to insetting `self` by `width / 2` and stroking the
    /// resulting shape with `width` as the line-width.
    @inlinable
    public func strokeBorder<S: ShapeStyle>(_ content: S, lineWidth: CGFloat = 1, antialiased: Bool = true) -> some View {
        var style = StrokeStyle()
        style.lineWidth = lineWidth
        return strokeBorder(content, style: style, antialiased: antialiased)
    }

    /// Returns a view that is the result of filling the `width`-sized
    /// border (aka inner stroke) of `self` with the foreground color.
    /// This is equivalent to insetting `self` by `width / 2` and
    /// stroking the resulting shape with `width` as the line-width.
    @inlinable
    public func strokeBorder(lineWidth: CGFloat = 1, antialiased: Bool = true) -> some View {
        var style = StrokeStyle()
        style.lineWidth = lineWidth
        return strokeBorder(style: style, antialiased: antialiased)
    }

}
