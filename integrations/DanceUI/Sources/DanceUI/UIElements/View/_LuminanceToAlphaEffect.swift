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
public struct _LuminanceToAlphaEffect: Equatable, RendererEffect {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    @inlinable
    public init() {
        
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .filter(.luminanceToAlpha)
    }
}

@available(iOS 13.0, *)
extension View {

    /// Adds a luminance to alpha effect to this view.
    ///
    /// Use this modifier to create a semitransparent mask, with the opacity of
    /// each part of the modified view controlled by the luminance of the
    /// corresponding part of the original view. Regions of lower luminance
    /// become more transparent, while higher luminance yields greater
    /// opacity.
    ///
    /// In particular, the modifier maps the red, green, and blue components of
    /// each input pixel's color to a grayscale value, and that value becomes
    /// the alpha component of a black pixel in the output. This modifier
    /// produces an effect that's equivalent to using the `feColorMatrix`
    /// filter primitive with the `luminanceToAlpha` type attribute, as defined
    /// by the [Scalable Vector Graphics (SVG) 2](https://www.w3.org/TR/SVG2/)
    /// specification.
    ///
    /// The example below defines a `Palette` view as a series of rectangles,
    /// each composed as a ``Color`` with a particular white value,
    /// and then displays two versions of the palette over a blue background:
    ///
    ///     struct Palette: View {
    ///         var body: some View {
    ///             HStack(spacing: 0) {
    ///                 ForEach(0..<10) { index in
    ///                     Color(white: Double(index) / Double(9))
    ///                         .frame(width: 20, height: 40)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    ///     struct LuminanceToAlphaExample: View {
    ///         var body: some View {
    ///             VStack(spacing: 20) {
    ///                 Palette()
    ///
    ///                 Palette()
    ///                     .luminanceToAlpha()
    ///             }
    ///             .padding()
    ///             .background(.blue)
    ///         }
    ///     }
    ///
    /// The unmodified version of the palette contains rectangles that range
    /// from solid black to solid white, thus with increasing luminance. The
    /// second version of the palette, which has the `luminanceToAlpha()`
    /// modifier applied, allows the background to show through in an amount
    /// that corresponds inversely to the luminance of the input.
    ///
    ///
    /// - Returns: A view with the luminance to alpha effect applied.
    @inlinable
    public func luminanceToAlpha() -> some View {
        modifier(_LuminanceToAlphaEffect())
    }

}
