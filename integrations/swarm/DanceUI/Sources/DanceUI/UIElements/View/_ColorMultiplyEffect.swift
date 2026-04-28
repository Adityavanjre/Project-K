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
public struct _ColorMultiplyEffect: EnvironmentalModifier, Equatable {
    
    public typealias ResolvedModifier = _Resolved
    
    public var color: Color
    
    @inlinable
    public init(color: Color) {
        self.color = color
    }
    
    public func resolve(in environment: EnvironmentValues) -> _Resolved {
        _Resolved(color: color.resolvePaint(in: environment))
    }
    
    public struct _Resolved: RendererEffect {
        
        public typealias AnimatableData = AnimatablePair<Float, AnimatablePair<Float, AnimatablePair<Float, Float>>>
        
        internal var color: Color.Resolved
        
        public var animatableData: _ColorMultiplyEffect._Resolved.AnimatableData {
            get {
                color.animatableData
            }
            
            set {
                color.animatableData = newValue
            }
        }
        
        internal func effectValue(size: CGSize) -> DisplayList.Effect {
            .filter(.colorMultiply(color))
        }
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Adds a color multiplication effect to this view.
    ///
    /// The following example shows two versions of the same image side by side;
    /// at left is the original, and at right is a duplicate with the
    /// `colorMultiply(_:)` modifier applied with ``ShapeStyle/purple``.
    ///
    ///     struct InnerCircleView: View {
    ///         var body: some View {
    ///             Circle()
    ///                 .fill(Color.green)
    ///                 .frame(width: 40, height: 40, alignment: .center)
    ///         }
    ///     }
    ///
    ///     struct ColorMultiply: View {
    ///         var body: some View {
    ///             HStack {
    ///                 Color.red.frame(width: 100, height: 100, alignment: .center)
    ///                     .overlay(InnerCircleView(), alignment: .center)
    ///                     .overlay(Text("Normal")
    ///                                  .font(.callout),
    ///                              alignment: .bottom)
    ///                     .border(Color.gray)
    ///
    ///                 Spacer()
    ///
    ///                 Color.red.frame(width: 100, height: 100, alignment: .center)
    ///                     .overlay(InnerCircleView(), alignment: .center)
    ///                     .colorMultiply(Color.purple)
    ///                     .overlay(Text("Multiply")
    ///                                 .font(.callout),
    ///                              alignment: .bottom)
    ///                     .border(Color.gray)
    ///             }
    ///             .padding(50)
    ///         }
    ///     }
    ///
    ///
    /// - Parameter color: The color to bias this view toward.
    ///
    /// - Returns: A view with a color multiplication effect.
    @inlinable
    public func colorMultiply(_ color: Color) -> some View {
        modifier(_ColorMultiplyEffect(color: color))
    }
    
}
