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
public struct _BlurEffect: RendererEffect, Equatable {
    
    public typealias AnimatableData = CGFloat
    
    // 0x0
    public var radius: CGFloat

    // 0x08
    public var isOpaque: Bool
    
    @inlinable
    public init(radius: CGFloat, opaque: Bool) {
        self.radius = radius
        self.isOpaque = opaque
    }
    
    public var animatableData: CGFloat {
        
        set {
            radius = newValue
        }
        
        get {
            radius
        }
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .filter(.blur(BlurStyle(radius: radius, isOpaque: isOpaque, dither: false)))
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Applies a Gaussian blur to this view.
    ///
    /// Use `blur(radius:opaque:)` to apply a gaussian blur effect to the
    /// rendering of this view.
    ///
    /// The example below shows two ``Text`` views, the first with no blur
    /// effects, the second with `blur(radius:opaque:)` applied with the
    /// `radius` set to `2`. The larger the radius, the more diffuse the
    /// effect.
    ///
    ///     struct Blur: View {
    ///         var body: some View {
    ///             VStack {
    ///                 Text("This is some text.")
    ///                     .padding()
    ///                 Text("This is some blurry text.")
    ///                     .blur(radius: 2.0)
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameters:
    ///   - radius: The radial size of the blur. A blur is more diffuse when its
    ///     radius is large.
    ///   - opaque: A Boolean value that indicates whether the blur renderer
    ///     permits transparency in the blur output. Set to `true` to create an
    ///     opaque blur, or set to `false` to permit transparency.
    @inlinable
    public func blur(radius: CGFloat, opaque: Bool = false) -> some View {
        return modifier(_BlurEffect(radius: radius, opaque: opaque))
    }
}
