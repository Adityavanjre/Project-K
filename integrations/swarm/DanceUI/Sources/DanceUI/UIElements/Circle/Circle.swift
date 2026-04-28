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

import CoreGraphics

/// A circle centered on the frame of the view containing it. The
/// radius is chosen as half the length of the rectangle's smallest
/// edge.
@frozen
@available(iOS 13.0, *)
public struct Circle: Shape {
    
    /// The type defining the data to be animated.
    public typealias AnimatableData = EmptyAnimatableData
    
    public var animatableData: AnimatableData {
        AnimatableData()
    }
    
    // The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = _ShapeView<Circle, ForegroundStyle>
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !rect.isNull else {
            path.storage = .empty
            return path
        }
        
        guard !rect.isInfinite else {
            path.storage = .rect(rect)
            return path
        }
        
        var newRect = rect
        var delta = rect.width - rect.height
        if delta < 0 {
            delta *= -0.5
            newRect.origin.y = rect.origin.y + delta
            newRect.size.height = rect.size.width
        } else if delta > 0 {
            delta *= 0.5
            newRect.origin.x = rect.origin.x + delta
            newRect.size.width = rect.size.height
        }
        
        guard !newRect.isNull else {
            path.storage = .empty
            return path
        }
        
        guard !newRect.isInfinite else {
            path.storage = .rect(rect)
            return path
        }
        
        path.storage = .ellipse(newRect)
        return path
    }
    
    /// Creates a new circle shape.
    @inlinable
    public init() {
        
    }
}

@available(iOS 13.0, *)
extension Circle {
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        let fittingWidth: CGFloat
        let fittingHeight: CGFloat
        if let width = proposal.width, let height = proposal.height {
            fittingWidth = .minimum(width, height)
            fittingHeight = fittingWidth
        } else {
            if let width = proposal.width {
                fittingWidth = width
                fittingHeight = width
            } else if let height = proposal.height {
                fittingWidth = height
                fittingHeight = height
            } else {
                fittingWidth = 10
                fittingHeight = 10
            }
        }
        return CGSize(width: fittingWidth, height: fittingHeight)
    }
}

@available(iOS 13.0, *)
extension Circle: InsettableShape {
    
    @usableFromInline
    @frozen
    internal struct _Inset: InsettableShape {
        
        @usableFromInline
        internal typealias InsetShape = Self
        
        @usableFromInline
        internal typealias AnimatableData = CGFloat
        
        @usableFromInline
        internal typealias Body = _ShapeView<Self, ForegroundStyle>
        
        @usableFromInline
        internal var animatableData: AnimatableData {
            get {
                amount
            }
            
            set {
                amount = newValue
            }
        }
        
        @usableFromInline
        internal var amount: CGFloat
        
        @usableFromInline
        internal init(_ amount: CGFloat) {
            self.amount = amount
        }
        
        @inlinable
        internal func inset(by amount: CGFloat) -> _Inset {
            _Inset(self.amount + amount)
        }
        
        @usableFromInline
        internal func path(in rect: CGRect) -> Path {
            let r = rect.inset(by: .init(top: amount, leading: amount, bottom: amount, trailing: amount))
            let radius = min(r.width, r.height) / 2.0
            return Path { (path) in
                path.addArc(center: .init(x: r.midX, y: r.midY), radius: radius, startAngle: .radians(0), endAngle: .radians(.pi * 2.0), clockwise: true)
            }
        }
        
    }
    
    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> some InsettableShape {
        _Inset(amount)
    }
}
