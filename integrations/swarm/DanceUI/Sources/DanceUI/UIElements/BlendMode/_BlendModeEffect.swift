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

@frozen
@available(iOS 13.0, *)
public struct _BlendModeEffect: RendererEffect, Equatable {
    
    public typealias AnimatableData = EmptyAnimatableData
    
    public var blendMode: BlendMode
    
    @inlinable
    public init(blendMode: BlendMode) {
        self.blendMode = blendMode
    }
    
    
    internal func effectValue(size: CGSize) -> DisplayList.Effect {
        .blendMode(.blendMode(GraphicsContext.BlendMode(blendMode: self.blendMode)))
    }
}

@available(iOS 13.0, *)
extension View {

    /// Sets the blend mode for compositing this view with overlapping views.
    ///
    /// Use `blendMode(_:)` to combine overlapping views and use a different
    /// visual effect to produce the result. The ``BlendMode`` enumeration
    /// defines many possible effects.
    ///
    /// In the example below, the two overlapping rectangles have a
    /// ``BlendMode/colorBurn`` effect applied, which effectively removes the
    /// non-overlapping portion of the second image:
    ///
    ///     HStack {
    ///         Color.yellow.frame(width: 50, height: 50, alignment: .center)
    ///
    ///         Color.red.frame(width: 50, height: 50, alignment: .center)
    ///             .rotationEffect(.degrees(45))
    ///             .padding(-20)
    ///             .blendMode(.colorBurn)
    ///     }
    ///
    /// - Parameter blendMode: The ``BlendMode`` for compositing this view.
    ///
    /// - Returns: A view that applies `blendMode` to this view.
    @inlinable
    public func blendMode(_ blendMode: BlendMode) -> some View {
        self.modifier(_BlendModeEffect(blendMode: blendMode))
    }
}
