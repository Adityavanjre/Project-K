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

/// A rectangular shape with rounded corners, aligned inside the frame of the
/// view containing it.
@frozen
@available(iOS 13.0, *)
public struct RoundedRectangle : Shape, Animatable {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = AnimatablePair<CGFloat, CGFloat>
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = _ShapeView<RoundedRectangle, ForegroundStyle>
    
    /// The data to animate.
    public var animatableData: AnimatableData {
        
        get {
            .init(cornerSize.width, cornerSize.height)
        }
        
        set {
            cornerSize.width = newValue.first
            cornerSize.height = newValue.second
        }
    }
    
    /// The width and height of the rounded rectangle's corners.
    public var cornerSize: CGSize
    
    /// The style of corners drawn by the rounded rectangle.
    public var style: RoundedCornerStyle
    
    /// Creates a new rounded rectangle shape.
    ///
    /// - Parameters:
    ///   - cornerSize: the width and height of the rounded corners.
    ///   - style: the style of corners drawn by the shape.
    @inlinable
    public init(cornerSize: CGSize, style: RoundedCornerStyle = .circular) {
        self.cornerSize = cornerSize
        self.style = style
    }
    
    /// Creates a new rounded rectangle shape.
    ///
    /// - Parameters:
    ///   - cornerRadius: the radius of the rounded corners.
    ///   - style: the style of corners drawn by the shape.
    @inlinable
    public init(cornerRadius: CGFloat, style: RoundedCornerStyle = .circular) {
        let cornerSize = CGSize(width: cornerRadius, height: cornerRadius)
        self.init(cornerSize: cornerSize, style: style)
    }
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        
        Path(roundedRect: rect, cornerSize: cornerSize, style: style)
    }
  
}

@available(iOS 13.0, *)
extension RoundedRectangle : InsettableShape {
    
    @inlinable
    public func inset(by amount: CGFloat) -> some InsettableShape {
        _Inset(base: self, amount: amount)
    }
    
    @frozen
    @usableFromInline
    internal struct _Inset : InsettableShape, Animatable {
        
        @usableFromInline
        internal typealias InsetShape = RoundedRectangle._Inset
        
        @usableFromInline
        internal typealias AnimatableData = AnimatablePair<RoundedRectangle.AnimatableData, CGFloat>
        
        @usableFromInline
        internal typealias Body = _ShapeView<RoundedRectangle._Inset, ForegroundStyle>
        
        @usableFromInline
        internal var base: RoundedRectangle
        
        @usableFromInline
        internal var amount: CGFloat
        
        @usableFromInline
        internal var animatableData: AnimatablePair<RoundedRectangle.AnimatableData, CGFloat> {
            
            get {
                .init(base.animatableData, amount)
            }
            
            set {
                base.animatableData = newValue.first
                amount = newValue.second
            }
        }
        
        
        @usableFromInline
        internal init(base: RoundedRectangle, amount: CGFloat) {
            
            (self.base, self.amount) = (base, amount)
        }
        
        @usableFromInline
        internal func path(in rect: CGRect) -> Path {
            
            let insetRect = rect.insetBy(dx: amount, dy: amount)
            
            guard !insetRect.isEmpty else {
                return Path()
            }
            
            let insetCornerWidth = max(0, base.cornerSize.width - amount)
            
            let insetCornerHeight = max(0, base.cornerSize.height - amount)
            
            guard !insetRect.isInfinite else {
                return Path(insetRect)
            }
            
            return Path(roundedRect: insetRect,
                        cornerSize: CGSize(width: insetCornerWidth,
                                           height: insetCornerHeight),
                        style: base.style)
        }
        
        
        @usableFromInline
        internal func inset(by amount: CGFloat) -> RoundedRectangle._Inset {
            var copy = self
            copy.amount += amount
            return copy
        }
    }
}
