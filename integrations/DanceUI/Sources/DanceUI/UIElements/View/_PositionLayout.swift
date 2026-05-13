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
public struct _PositionLayout: UnaryLayout {

    public typealias Body = Never
    public typealias Content = Void
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = PlacementContext

    @usableFromInline
    let position: CGPoint

    @usableFromInline init(position: CoreGraphics.CGPoint) {
        self.position = position
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
        _Placement(proposedSize: context.size,
                   anchor: .center,
                   at: position)
    }

    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        if let width = proposedSize.width, let height = proposedSize.height {
            return CGSize(width: width, height: height)
        }
        
        var size = child.layoutComputer.engine.sizeThatFits(proposedSize)
        if let width = proposedSize.width {
            size.width = width
        }
        if let height = proposedSize.height {
            size.height = height
        }
        
        return size
    }
    
    internal func spacing(in context: SizeAndSpacingContext, child: LayoutProxy) -> Spacing {
        #warning("Semantics")
        return .zeroText
    }
}

@available(iOS 13.0, *)
extension View {

    /// Positions the center of this view at the specified point in its parent's
    /// coordinate space.
    ///
    /// Use the `position(_:)` modifier to place the center of a view at a
    /// specific coordinate in the parent view using a
    /// <https://developer.apple.com/documentation/CoreGraphics/CGPoint> to specify the `x`
    /// and `y` offset.
    ///
    ///     Text("Position by passing a CGPoint()")
    ///         .position(CGPoint(x: 175, y: 100))
    ///         .border(Color.gray)
    ///
    /// - Parameter position: The point at which to place the center of this
    ///   view.
    ///
    /// - Returns: A view that fixes the center of this view at `position`.
    @inlinable
    public func position(_ position: CGPoint) -> some View {
        modifier(_PositionLayout(position: position))
    }

    /// Positions the center of this view at the specified coordinates in its
    /// parent's coordinate space.
    ///
    /// Use the `position(x:y:)` modifier to place the center of a view at a
    /// specific coordinate in the parent view using an `x` and `y` offset.
    ///
    ///     Text("Position by passing the x and y coordinates")
    ///         .position(x: 175, y: 100)
    ///         .border(Color.gray)
    ///
    /// - Parameters:
    ///   - x: The x-coordinate at which to place the center of this view.
    ///   - y: The y-coordinate at which to place the center of this view.
    ///
    /// - Returns: A view that fixes the center of this view at `x` and `y`.
    @inlinable
    public func position(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        position(CGPoint(x: x, y: y))
    }
}
