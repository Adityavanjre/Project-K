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
public struct FixedRoundedRect: Equatable {
    
    public var rect: CGRect
    
    public let cornerSize: CGSize
    
    public let style: RoundedCornerStyle
    
    internal func contains(otherRect: FixedRoundedRect) -> Bool {
        
        guard self.rect.contains(otherRect.rect) else {
            return false
        }
        guard otherRect.cornerSize.width < cornerSize.width ||
                otherRect.cornerSize.height < cornerSize.height else {
            return true
        }
        
        let cosinus = cos(45 * Double.pi / 180)
        
        let minCornerWidth: CGFloat = abs(.minimum(rect.size.width * 0.5, cornerSize.width))
        let minCornerHeight: CGFloat = abs(.minimum(rect.size.height * 0.5, cornerSize.height))
        let dx: CGFloat = minCornerWidth * CGFloat(cosinus)
        let dy: CGFloat = minCornerHeight * CGFloat(cosinus)
        
        let inscribedRect: CGRect = rect.insetBy(dx: dx, dy: dy)
        
        return inscribedRect.contains(otherRect.rect)
    }
    
}

@available(iOS 13.0, *)
extension FixedRoundedRect: PathValuable {
    internal var cgPath: CGPath {
        let halfWidth = abs(rect.size.width) * 0.5
        let halfHeight = abs(rect.size.height) * 0.5
        let minLengthOfSide = min(halfHeight, halfWidth)
        let cornerRadiusWidth = min(cornerSize.width, minLengthOfSide)
        let cornerRadiusHeight = min(cornerSize.height, minLengthOfSide)
        return _CGPathCreateRoundedRect(rect, cornerWidth: cornerRadiusWidth, cornerHeight: cornerRadiusHeight)
    }
}

@available(iOS 13.0, *)
private func _CGPathCreateRoundedRect(_ rect: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat) -> CGPath {
    var cornerW = max(0, cornerWidth)
    var cornerH = max(0, cornerHeight)
    guard cornerW > 0,
          cornerH > 0,
          !rect.isEmpty else {
        return CGPath(rect: rect, transform: nil)
    }
    
    let rectWidth = rect.width
    let rectHeight = rect.height
    if cornerW * 2 > rectWidth {
        cornerW = nextafter(rectWidth * 0.5, 0)
    }
    
    if cornerH * 2 > rectHeight {
        cornerH = nextafter(rectHeight * 0.5, 0)
    }
    
    guard cornerW * 2 <= rectWidth,
          cornerH * 2 <= rectHeight else {
        return CGPath(rect: rect, transform: nil)
    }
    
    return CGPath(roundedRect: rect, cornerWidth: cornerW, cornerHeight: cornerH, transform: nil)
}
