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

@available(iOS 13.0, *)
protocol AnchorProtocol {
    
    associatedtype AnchorValue: ViewTransformable
    
    static var defaultAnchor: AnchorValue { get }
    
    func prepare(size: CGSize, transform: ViewTransform) -> AnchorValue
    
    static func valueIsEqual(lhs: AnchorValue, rhs: AnchorValue) -> Bool
}

@available(iOS 13.0, *)
extension CGRect: AnchorProtocol {
    
    internal typealias AnchorValue = CGRect
    
    internal static let defaultAnchor: CGRect = .zero
    
    internal func prepare(size: CGSize, transform: ViewTransform) -> CGRect {
        guard isValid else {
            return self
        }
        
        var cornerPoints = self.cornerPoints
        cornerPoints.convert(to: .global, transform: transform)
        assert(cornerPoints.count == 4, "incorrect count")
        
        return .init(cornerPoints: cornerPoints[..<4])
    }
    
    internal static func valueIsEqual(lhs: CGRect, rhs: CGRect) -> Bool {
        lhs.equalTo(rhs)
    }
}

@available(iOS 13.0, *)
extension CGPoint: AnchorProtocol {
    
    internal typealias AnchorValue = CGPoint
    
    internal static let defaultAnchor: AnchorValue = .zero
    
    internal func prepare(size: CGSize, transform: ViewTransform) -> CGPoint {
        var copiedSelf = self
        copiedSelf.convert(to: .global, transform: transform)
        return copiedSelf
    }
    
    internal static func valueIsEqual(lhs: CGPoint, rhs: CGPoint) -> Bool {
        lhs.equalTo(rhs)
    }
}
