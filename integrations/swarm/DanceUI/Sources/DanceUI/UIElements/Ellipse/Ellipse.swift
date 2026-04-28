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

/// An ellipse aligned inside the frame of the view containing it.
@frozen
@available(iOS 13.0, *)
public struct Ellipse : Shape {

    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        .init(ellipseIn: rect)
    }

    /// Creates a new ellipse shape.
    @inlinable
    public init() {
    }

    /// The type defining the data to be animated.
    public typealias AnimatableData = EmptyAnimatableData
    
    public var animatableData: AnimatableData {
        AnimatableData()
    }
    
}

@available(iOS 13.0, *)
extension Ellipse : InsettableShape {

    @usableFromInline
    @frozen
    struct _Inset: InsettableShape {
        
        @usableFromInline
        internal typealias InsetShape = _Inset
        
        @usableFromInline
        internal typealias AnimatableData = CGFloat
        
        @usableFromInline
        internal typealias Body = _ShapeView<_Inset, ForegroundStyle>
        
        @usableFromInline
        internal var animatableData: CGFloat {
            get {
                amount
            }
            
            set {
                amount = newValue
            }
        }
        
        internal var amount: CGFloat
        
        @usableFromInline
        init(_ amount: CGFloat) {
            self.amount = amount
        }
        
        @usableFromInline
        internal func inset(by amount: CGFloat) -> _Inset {
            _Inset(self.amount + amount)
        }
        
        @usableFromInline
        internal func path(in rect: CGRect) -> Path {
            .init(ellipseIn: rect.inset(by: .init(top: amount, leading: amount, bottom: amount, trailing: amount)))
        }
    }
    
    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> some InsettableShape {
        _Inset(amount)
    }

}
