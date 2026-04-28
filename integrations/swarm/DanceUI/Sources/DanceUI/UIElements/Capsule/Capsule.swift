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
public struct Capsule: Shape {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = _ShapeView<Capsule, ForegroundStyle>
    
    public var style: RoundedCornerStyle
    
    /// Creates a new capsule shape.
    ///
    /// - Parameters:
    ///   - style: the style of corners drawn by the shape.
    @inlinable
    public init(style: RoundedCornerStyle = .circular) {
        self.style = style
    }
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in r: CGRect) -> Path {
        
        guard !r.isNull else {
            return Path()
        }
        
        let base = (style == .circular) ? 0.5 : 0.437
        
        let minSide = min(r.width, r.height)
        
        let radius = minSide * base
        
        guard radius > 0 && !r.isInfinite else {
            return Path(r)
        }
        
        return Path(roundedRect: r,
                    cornerSize: CGSize(width: radius, height: radius),
                    style: style)
    }
}

@available(iOS 13.0, *)
extension Capsule: InsettableShape {
    
    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> some InsettableShape {
        _Inset(amount: amount)
    }
    
    @frozen
    @usableFromInline
    internal struct _Inset: InsettableShape {
        
        @usableFromInline
        internal typealias AnimatableData = CGFloat
        
        @usableFromInline
        internal typealias Body = _ShapeView<_Inset, ForegroundStyle>
        
        @usableFromInline
        internal typealias InsetShape = _Inset
        
        @usableFromInline
        internal var amount: CGFloat
        
        @inlinable
        internal init(amount: CGFloat) {
            self.amount = amount
        }
        
        @usableFromInline
        internal func path(in rect: CGRect) -> Path {
            let insetRect = rect.insetBy(dx: amount, dy: amount)
            return Capsule().path(in: insetRect)
        }
        
        @usableFromInline
        internal var animatableData: CGFloat {
            get {
                amount
            }
            
            set {
                amount = newValue
            }
        }
        
        @inlinable
        internal func inset(by amount: CGFloat) -> _Inset {
            var copy = self
            copy.amount += amount
            return copy
        }
    }
}
