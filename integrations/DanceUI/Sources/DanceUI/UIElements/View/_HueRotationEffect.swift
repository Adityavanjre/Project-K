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
public struct _HueRotationEffect: Equatable, RendererEffect {
    
    public typealias AnimatableData = Angle.AnimatableData
    
    public var angle: Angle
    
    @inlinable
    public init(angle: Angle) {
        self.angle = angle
    }
    
    public var animatableData: Angle.AnimatableData {
        
        get {
            angle.animatableData
        }
        
        set {
            angle.animatableData = newValue
        }
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .filter(.hueRotation(angle))
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Applies a hue rotation effect to this view.
    ///
    /// Use hue rotation effect to shift all of the colors in a view according
    /// to the angle you specify.
    ///
    /// The example below shows a series of squares filled with a linear
    /// gradient. Each square shows the effect of a 36˚ hueRotation (a total of
    /// 180˚ across the 5 squares) on the gradient:
    ///
    ///     struct HueRotation: View {
    ///         var body: some View {
    ///             HStack {
    ///                 ForEach(0..<6) {
    ///                     Rectangle()
    ///                         .fill(.linearGradient(
    ///                             colors: [.blue, .red, .green],
    ///                             startPoint: .top, endPoint: .bottom))
    ///                         .hueRotation((.degrees(Double($0 * 36))))
    ///                         .frame(width: 60, height: 60, alignment: .center)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    ///
    /// - Parameter angle: The hue rotation angle to apply to the colors in this
    ///   view.
    ///
    /// - Returns: A view that applies a hue rotation effect to this view.
    @inlinable
    public func hueRotation(_ angle: Angle) -> some View {
        modifier(_HueRotationEffect(angle: angle))
    }
}
