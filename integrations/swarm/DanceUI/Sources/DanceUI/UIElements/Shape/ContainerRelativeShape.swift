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

/// A shape that is replaced by an inset version of the current
/// container shape. If no container shape was defined, is replaced by
/// a rectangle.
public struct ContainerRelativeShape: Shape {

    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
    
    /// The type of view representing the body of this view.
    public typealias Body = _ShapeView<Self, ForegroundStyle>

    @inlinable
    public init() {
        
    }
    
    /// Describes this shape as a path within a rectangular frame of reference.
    ///
    /// - Parameter rect: The frame of reference for describing this shape.
    ///
    /// - Returns: A path that describes this shape.
    public func path(in rect: CGRect) -> Path {
        guard let proxyData = _threadGeometryProxyData() else {
            return rect.validPath
        }
        
        let pointer = proxyData.assumingMemoryBound(to: GeometryProxy.self)
        let geoProxy = pointer.pointee
        let containerShapeData = geoProxy.environment.containerShapeData
        let shapeType = containerShapeData.type
        let path = shapeType.path(in: rect,
                                  proxy: geoProxy,
                                  shape: containerShapeData.shape,
                                  size: containerShapeData.size,
                                  id: containerShapeData.id)
        return path
    }
}

@available(iOS 13.0, *)
extension ContainerRelativeShape: InsettableShape {

    /// Returns `self` inset by `amount`.
    @inlinable
    public func inset(by amount: CGFloat) -> some InsettableShape {
        _Inset(amount: amount)
    }

    @usableFromInline
    @frozen
    internal struct _Inset: InsettableShape {

        @usableFromInline
        internal typealias AnimatableData = CGFloat

        @usableFromInline
        internal typealias Body = _ShapeView<Self, ForegroundStyle>

        @usableFromInline
        internal typealias InsetShape = ContainerRelativeShape._Inset

        @usableFromInline
        internal var amount: CGFloat

        @inlinable
        internal init(amount: CGFloat) {
            self.amount = amount
        }

        @usableFromInline
        internal func path(in rect: CGRect) -> Path {
            let insetRect = rect.insetBy(dx: amount, dy: amount)
            return ContainerRelativeShape().path(in: insetRect)
        }

        @usableFromInline
        internal var animatableData: CGFloat {
            get {
                amount
            }

            set {
                self.amount = newValue
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
