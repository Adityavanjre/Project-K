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
public struct _SizedShape<S>: Shape where S: Shape {
    
    public typealias Body = _ShapeView<_SizedShape<S>, ForegroundStyle>
    
    public typealias AnimatableData = AnimatablePair<S.AnimatableData, AnimatablePair<CGFloat, CGFloat>>
    
    // 0x0
    public var shape: S
    
    // metadata + 0x24
    public var size: CGSize
    
    @inlinable
    public init(shape: S, size: CGSize) {
        self.shape = shape
        self.size = size
    }
    
    public static var role: ShapeRole {
        S.role
    }
    
    public func path(in rect: CGRect) -> Path {
        let newRect = CGRect(origin: rect.origin, size: size)
        return shape.path(in: newRect)
    }
    
    public var animatableData: AnimatableData {
        
        get {
            AnimatableData(shape.animatableData, AnimatablePair(size.width, size.height))
        }
        
        set {
            shape.animatableData = newValue.first
            size = CGSize(width: newValue.second.first, height: newValue.second.second)
        }
    }
}

@available(iOS 13.0, *)
extension Shape {
    
    /// Returns a new version of self representing the same shape, but
    /// that will ask it to create its path from a rect of `size`. This
    /// does not affect the layout properties of any views created from
    /// the shape (e.g. by filling it).
    @inlinable
    public func size(_ size: CGSize) -> some Shape {
        _SizedShape(shape: self, size: size)
    }
    
    /// Returns a new version of self representing the same shape, but
    /// that will ask it to create its path from a rect of size
    /// `(width, height)`. This does not affect the layout properties
    /// of any views created from the shape (e.g. by filling it).
    @inlinable
    public func size(width: CGFloat, height: CGFloat) -> some Shape {
        size(.init(width: width, height: height))
    }
}
