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
public struct ProjectionTransform: Equatable {

    public var m11: CGFloat = 1.0, m12: CGFloat = 0.0, m13: CGFloat = 0.0
    public var m21: CGFloat = 0.0, m22: CGFloat = 1.0, m23: CGFloat = 0.0
    public var m31: CGFloat = 0.0, m32: CGFloat = 0.0, m33: CGFloat = 1.0
    
    @inlinable
    public init() {
        self.init(m11: 1.0, m12: 0, m13: 0, m21: 0, m22: 1.0, m23: 0, m31: 0, m32: 0, m33: 1.0)
    }
    
    @inlinable
    internal init(m11: CGFloat, m12: CGFloat, m13: CGFloat, m21: CGFloat, m22: CGFloat, m23: CGFloat, m31: CGFloat, m32: CGFloat, m33: CGFloat) {
        self.m11 = m11
        self.m12 = m12
        self.m13 = m13
        self.m21 = m21
        self.m22 = m22
        self.m23 = m23
        self.m31 = m31
        self.m32 = m32
        self.m33 = m33
    }
    
    @inlinable
    public init(_ m: CGAffineTransform) {
        self.m11 = m.a
        self.m12 = m.b
        self.m21 = m.c
        self.m22 = m.d
        self.m31 = m.tx
        self.m32 = m.ty
    }
    
    @inlinable
    public init(_ m: CATransform3D) {
        self.m11 = m.m11
        self.m12 = m.m12
        self.m13 = m.m14
        self.m21 = m.m21
        self.m22 = m.m22
        self.m23 = m.m24
        self.m31 = m.m41
        self.m32 = m.m42
        self.m33 = m.m44
    }
    
    @inlinable
    public var isAffine: Bool {
        m13 == 0 && m23 == 0 && m33 == 1
    }
    
    @inlinable
    public var isIdentity: Bool {
        self == ProjectionTransform()
    }
    
    internal var affineTransformValue: CGAffineTransform {
        .init(a: m11, b: m12, c: m21, d: m22, tx: m31, ty: m32)
    }
    
    @usableFromInline
    internal var transform3DValue: CATransform3D {
        var transform3D = CATransform3DIdentity
        transform3D.m11 = m11
        transform3D.m12 = m12
        transform3D.m14 = m13
        transform3D.m21 = m21
        transform3D.m22 = m22
        transform3D.m24 = m23
        transform3D.m41 = m31
        transform3D.m42 = m32
        transform3D.m44 = m33
        return transform3D
    }
    
    internal var isInvertible: Bool {
        
        let determinant = m11 * m22 * m33 +
                          m12 * m23 * m31 +
                          m13 * m21 * m32 -
                          m13 * m22 * m31 -
                          m11 * m23 * m32 -
                          m12 * m21 * m33
        
        return determinant != 0
    }
}

@available(iOS 13.0, *)
extension ProjectionTransform {
    
    @inline(__always)
    @inlinable
    internal func dot(_ a: (CGFloat, CGFloat, CGFloat), _ b: (CGFloat, CGFloat, CGFloat)) -> CGFloat {
        return a.0 * b.0 + a.1 * b.1 + a.2 * b.2
    }
    
    @inlinable
    public func concatenating(_ rhs: ProjectionTransform) -> ProjectionTransform {
        var m = ProjectionTransform()
        m.m11 = dot((m11, m12, m13), (rhs.m11, rhs.m21, rhs.m31))
        m.m12 = dot((m11, m12, m13), (rhs.m12, rhs.m22, rhs.m32))
        m.m13 = dot((m11, m12, m13), (rhs.m13, rhs.m23, rhs.m33))
        m.m21 = dot((m21, m22, m23), (rhs.m11, rhs.m21, rhs.m31))
        m.m22 = dot((m21, m22, m23), (rhs.m12, rhs.m22, rhs.m32))
        m.m23 = dot((m21, m22, m23), (rhs.m13, rhs.m23, rhs.m33))
        m.m31 = dot((m31, m32, m33), (rhs.m11, rhs.m21, rhs.m31))
        m.m32 = dot((m31, m32, m33), (rhs.m12, rhs.m22, rhs.m32))
        m.m33 = dot((m31, m32, m33), (rhs.m13, rhs.m23, rhs.m33))
        return m
    }
}
