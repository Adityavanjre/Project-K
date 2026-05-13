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
internal let minScale = CGSize(width: 0.00001, height: 0.00001)
@available(iOS 13.0, *)
internal let identityScale = CGSize(width: 1, height: 1)

@frozen
@available(iOS 13.0, *)
public struct _ScaleEffect: GeometryEffect, Equatable {
    
    public typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
    
    // 0x0
    public var scale: CGSize

    // 0x10
    public var anchor: UnitPoint
    
    @inlinable
    public init(scale: CGSize, anchor: UnitPoint = .center) {
        self.scale = scale
        self.anchor = anchor
    }
    
    public var animatableData: AnimatableData {
        get {
            .init(scale.animatableData, anchor.animatableData)
        }
        
        set {
            scale.animatableData = newValue.first
            anchor.animatableData = newValue.second
        }
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        let minScale = 2.11e-154
        var scale = scale
        if scale.width.isZero {
            scale.width = minScale
        }
        if scale.height.isZero {
            scale.height = minScale
        }
        let x = size.width * anchor.x
        let y = size.height * anchor.y
        let translation = CGAffineTransform(translationX: -x, y: -y)
        
        let scaledTransform = CGAffineTransform(scaleX: scale.width, y: scale.height)
        let concatedTransform = translation.concatenating(scaledTransform)
        
        let result = concatedTransform.concatenating(CGAffineTransform(translationX: x, y: y))
        
        return ProjectionTransform(result)
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Scales this view's rendered output by the given vertical and horizontal
    /// size amounts, relative to an anchor point.
    ///
    /// Use `scaleEffect(_:anchor:)` to scale a view by applying a scaling
    /// transform of a specific size, specified by `scale`.
    ///
    ///     Image(systemName: "envelope.badge.fill")
    ///         .resizable()
    ///         .frame(width: 100, height: 100, alignment: .center)
    ///         .foregroundColor(Color.red)
    ///         .scaleEffect(CGSize(x: 0.9, y: 1.3), anchor: .leading)
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - scale: A <doc://com.apple.documentation/documentation/CoreGraphics/CGSize> that
    ///     represents the horizontal and vertical amount to scale the view.
    ///   - anchor: The point with a default of ``UnitPoint/center`` that
    ///     defines the location within the view from which to apply the
    ///     transformation.
    @inlinable
    public func scaleEffect(_ scale: CGSize, anchor: UnitPoint = .center) -> some View {
        modifier(_ScaleEffect(scale: scale, anchor: anchor))
    }
    
    /// Scales this view's rendered output by the given amount in both the
    /// horizontal and vertical directions, relative to an anchor point.
    ///
    /// Use `scaleEffect(_:anchor:)` to apply a horizontally and vertically
    /// scaling transform to a view.
    ///
    ///     Image(systemName: "envelope.badge.fill")
    ///         .resizable()
    ///         .frame(width: 100, height: 100, alignment: .center)
    ///         .foregroundColor(Color.red)
    ///         .scaleEffect(2, anchor: .leading)
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - s: The amount to scale the view in the view in both the horizontal
    ///     and vertical directions.
    ///   - anchor: The anchor point with a default of ``UnitPoint/center`` that
    ///     indicates the starting position for the scale operation.
    @inlinable
    public func scaleEffect(_ s: CGFloat, anchor: UnitPoint = .center) -> some View {
        scaleEffect(CGSize(width: s, height: s), anchor: anchor)
    }
    
    /// Scales this view's rendered output by the given horizontal and vertical
    /// amounts, relative to an anchor point.
    ///
    /// Use `scaleEffect(x:y:anchor:)` to apply a scaling transform to a view by
    /// a specific horizontal and vertical amount.
    ///
    ///     Image(systemName: "envelope.badge.fill")
    ///         .resizable()
    ///         .frame(width: 100, height: 100, alignment: .center)
    ///         .foregroundColor(Color.red)
    ///         .scaleEffect(x: 0.5, y: 0.5, anchor: .bottomTrailing)
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - x: An amount that represents the horizontal amount to scale the
    ///     view. The default value is `1.0`.
    ///   - y: An amount that represents the vertical amount to scale the view.
    ///     The default value is `1.0`.
    ///   - anchor: The anchor point that indicates the starting position for
    ///     the scale operation.
    @inlinable
    public func scaleEffect(x: CGFloat = 1.0, y: CGFloat = 1.0, anchor: UnitPoint = .center) -> some View {
        scaleEffect(CGSize(width: x, height: y), anchor: anchor)
    }
}
