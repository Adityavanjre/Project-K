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
public struct _CompositingGroupEffect: Equatable, RendererEffect {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    @inlinable
    public init() {
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .compositingGroup
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Wraps this view in a compositing group.
    ///
    /// A compositing group makes compositing effects in this view's ancestor
    /// views, such as opacity and the blend mode, take effect before this view
    /// is rendered.
    ///
    /// Use `compositingGroup()` to apply effects to a parent view before
    /// applying effects to this view.
    ///
    /// In the example below the `compositingGroup()` modifier separates the
    /// application of effects into stages. It applies the ``View/opacity(_:)``
    /// effect to the VStack before the `blur(radius:)` effect is applied to the
    /// views inside the enclosed ``ZStack``. This limits the scope of the
    /// opacity change to the outermost view.
    ///
    ///     VStack {
    ///         ZStack {
    ///             Text("CompositingGroup")
    ///                 .foregroundColor(.black)
    ///                 .padding(20)
    ///                 .background(Color.red)
    ///             Text("CompositingGroup")
    ///                 .blur(radius: 2)
    ///         }
    ///         .font(.largeTitle)
    ///         .compositingGroup()
    ///         .opacity(0.9)
    ///     }
    ///
    ///
    /// - Returns: A view that wraps this view in a compositing group.
    @inlinable
    public func compositingGroup() -> some View {
        modifier(_CompositingGroupEffect())
    }
}

@available(iOS 13.0, *)
internal struct GeometryGroupEffect: Equatable, RendererEffect {
    
    internal typealias AnimatableData = EmptyAnimatableData
    
    @inlinable
    internal init() {
    }
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .geometryGroup
    }
}
