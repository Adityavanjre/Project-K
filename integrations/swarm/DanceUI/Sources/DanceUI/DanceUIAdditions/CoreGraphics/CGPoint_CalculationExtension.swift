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

@inline(__always)
@available(iOS 13.0, *)
internal prefix func - (p: CGPoint) -> CGPoint {
    CGPoint(x: -p.x, y: -p.y)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
    CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func -= (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs - rhs
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func += (lhs: inout CGPoint, rhs: CGPoint) {
    lhs = lhs + rhs
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
    CGPoint(x: rhs.x * lhs, y: rhs.y * lhs)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
}

@available(iOS 13.0, *)
extension CGPoint {
    
    @inline(__always)
    internal func distance(to p2: CGPoint) -> CGFloat {
        return sqrt(pow(self.y - p2.y, 2) + pow(self.x - p2.x, 2))
    }

    @inline(__always)
    internal func cross(_ p2 : CGPoint) -> CGFloat {
        return self.x * p2.y - self.y * p2.x
    }

    @inline(__always)
    internal func dot(_ v2: CGPoint) -> CGFloat {
        return (self.x * v2.x) + (self.y * v2.y)
    }

    @inline(__always)
    internal func isDifferentDirection(to v2: CGPoint) -> Bool {
        let dotProduct = dot(v2)
        return !(dotProduct > 0)
    }
    
}
