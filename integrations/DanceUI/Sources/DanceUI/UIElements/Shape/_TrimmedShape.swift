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
public struct _TrimmedShape<S>: Shape, Animatable where S: Shape {
    
    public typealias AnimatableData = AnimatablePair<S.AnimatableData, AnimatablePair<CGFloat, CGFloat>>
    
    public typealias Body = _ShapeView<_TrimmedShape<S>, ForegroundStyle>
    
    // 0x00
    public var shape: S
    
    // 0x28
    public var startFraction: CGFloat
    
    // 0x30
    public var endFraction: CGFloat
    
    @inlinable
    public init(shape: S, startFraction: CGFloat = 0, endFraction: CGFloat = 1) {
        self.shape = shape
        self.startFraction = startFraction
        self.endFraction = endFraction
    }
    
    public static var role: ShapeRole {
        S.role
    }
    
    public func path(in rect: CGRect) -> Path {
        shape.path(in: rect).trimmedPath(from: startFraction, to: endFraction)
    }
    
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(shape.animatableData,
                           AnimatablePair(startFraction * 128.0, endFraction * 128.0))
        }
        
        set {
            shape.animatableData = newValue.first
            startFraction = newValue.second.first / 128.0
            endFraction = newValue.second.second / 128.0
        }
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Trims this shape by a fractional amount based on its representation as a
    /// path.
    ///
    /// To create a `Shape` instance, you define the shape's path using lines and
    /// curves. Use the `trim(from:to:)` method to draw a portion of a shape by
    /// ignoring portions of the beginning and ending of the shape's path.
    ///
    /// For example, if you're drawing a figure eight or infinity symbol (∞)
    /// starting from its center, setting the `startFraction` and `endFraction`
    /// to different values determines the parts of the overall shape.
    ///
    /// The following example shows a simplified infinity symbol that draws
    /// only three quarters of the full shape. That is, of the two lobes of the
    /// symbol, one lobe is complete and the other is half complete.
    ///
    ///     Path { path in
    ///         path.addLines([
    ///             .init(x: 2, y: 1),
    ///             .init(x: 1, y: 0),
    ///             .init(x: 0, y: 1),
    ///             .init(x: 1, y: 2),
    ///             .init(x: 3, y: 0),
    ///             .init(x: 4, y: 1),
    ///             .init(x: 3, y: 2),
    ///             .init(x: 2, y: 1)
    ///         ])
    ///     }
    ///     .trim(from: 0.25, to: 1.0)
    ///     .scale(50, anchor: .topLeading)
    ///     .stroke(Color.black, lineWidth: 3)
    ///
    /// Changing the parameters of `trim(from:to:)` to
    /// `.trim(from: 0, to: 1)` draws the full infinity symbol, while
    /// `.trim(from: 0, to: 0.5)` draws only the left lobe of the symbol.
    ///
    /// - Parameters:
    ///   - startFraction: The fraction of the way through drawing this shape
    ///     where drawing starts.
    ///   - endFraction: The fraction of the way through drawing this shape
    ///     where drawing ends.
    /// - Returns: A shape built by capturing a portion of this shape's path.
    @inlinable public func trim(from startFraction: CGFloat = 0, to endFraction: CGFloat = 1) -> some Shape {
        _TrimmedShape(shape: self,
                      startFraction: startFraction,
                      endFraction: endFraction)
    }
}
