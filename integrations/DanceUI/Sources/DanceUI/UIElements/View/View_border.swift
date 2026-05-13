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
    
    /// Adds a border to this view with the specified style and width.
    ///
    /// Use `border(_:width:)` to draw a border of a specified width around the
    /// view's frame. By default, the border appears inside the bounds of this
    /// view. In this example, the four-point wide border covers the text:
    ///
    ///     Text("Purple border inside the view bounds")
    ///         .border(Color.purple, width: 4)
    ///
    ///
    /// To place a border around the outside of this view, apply padding of the
    /// same width before adding the border:
    ///
    ///     Text("Purple border outside the view bounds.")
    ///         .padding(4)
    ///         .border(Color.purple, width: 4)
    ///
    /// - Parameters:
    ///   - content: The border style.
    ///   - width: The thickness of the border; if not provided, the default is
    ///     1 pixel.
    ///
    /// - Returns: A view that adds a border with the specified style and width
    ///   to this view.
    
    @inlinable
    public func border<S: ShapeStyle>(_ content: S, width: CGFloat = 1) -> some View {
        let shape = Rectangle().strokeBorder(content, lineWidth: width)
        return self.overlay(shape)
    }
}
