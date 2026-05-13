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
public struct _TransformEffect: GeometryEffect, Equatable {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public var transform: CGAffineTransform
    
    @inlinable
    public init(transform: CGAffineTransform) {
        self.transform = transform
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(transform)
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Applies an affine transformation to this view's rendered output.
    ///
    /// Use `transformEffect(_:)` to rotate, scale, translate, or skew the
    /// output of the view according to the provided
    /// <https://developer.apple.com/documentation/CoreGraphics/CGAffineTransform>.
    ///
    /// In the example below, the text is rotated at -30˚ on the `y` axis.
    ///
    ///     let transform = CGAffineTransform(rotationAngle: -30 * (.pi / 180))
    ///
    ///     Text("Projection effect using transforms")
    ///         .transformEffect(transform)
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameter transform: A
    /// <https://developer.apple.com/documentation/CoreGraphics/CGAffineTransform> to
    /// apply to the view.
    @inlinable
    public func transformEffect(_ transform: CGAffineTransform) -> some View {
        modifier(_TransformEffect(transform: transform))
    }
}
