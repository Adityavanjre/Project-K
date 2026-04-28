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

@available(iOS 13.0, *)
extension CGSize {
    
    @inline(__always)
    internal func outset(by edgeInsets: EdgeInsets) -> CGSize {
        let outsetHeight = height + edgeInsets.top + edgeInsets.bottom
        let outsetWidth = width + edgeInsets.leading + edgeInsets.trailing
        
        return CGSize(width: max(outsetWidth, 0), height: max(outsetHeight, 0))
    }
    
}

@inline(__always)
@available(iOS 13.0, *)
internal func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}

@inline(__always)
@available(iOS 13.0, *)
internal func - (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
}

@inline(__always)
@available(iOS 13.0, *)
internal func -= (lhs: inout CGSize, rhs: CGSize) {
    lhs = lhs - rhs
}

@inline(__always)
@available(iOS 13.0, *)
internal func += (lhs: inout CGSize, rhs: CGSize) {
    lhs = lhs + rhs
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func * (lhs: CGFloat, rhs: CGSize) -> CGSize {
    CGSize(width: rhs.width * lhs, height: rhs.height * lhs)
}

@inline(__always)
@available(iOS 13.0, *)
@_spi(DanceUICompose)
public func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
    CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
}
