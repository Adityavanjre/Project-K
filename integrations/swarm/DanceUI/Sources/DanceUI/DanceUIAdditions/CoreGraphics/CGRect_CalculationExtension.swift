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
extension CGRect {
    
    internal func mapCorners(f: ((inout [CGPoint]) -> Void)) -> CGRect {
        guard isValid else {
            return self
        }
        
        var cornerPointValue = self.cornerPoints
        f(&cornerPointValue)
        
        guard cornerPointValue.count == 4 else {
            fatalError("corner point count error!")
        }
        
        return .init(cornerPoints: ArraySlice(cornerPointValue))
    }
    
    @inlinable
    public var isValid: Bool {
        !isNull && !isInfinite
    }
    
    /// Returns the top-left, top-right, bottom-right and bottom-left
    /// point of the `CGRect`.
    internal var cornerPoints: [CGPoint] {
        [
            CGPoint(x: origin.x, y: origin.y),
            CGPoint(x: origin.x + size.width, y: origin.y),
            CGPoint(x: origin.x + size.width, y: origin.y + size.height),
            CGPoint(x: origin.x, y: origin.y + size.height)
        ]
    }
    
    internal init(cornerPoints: ArraySlice<CGPoint>) {
        let point0 = cornerPoints[cornerPoints.startIndex + 0]
        let point1 = cornerPoints[cornerPoints.startIndex + 1]
        let point2 = cornerPoints[cornerPoints.startIndex + 2]
        let point3 = cornerPoints[cornerPoints.startIndex + 3]
        
        let x = min(point0.x, point1.x, point2.x, point3.x)
        let y = min(point0.y, point1.y, point2.y, point3.y)
        
        let width = max(point0.x, point1.x, point2.x, point3.x) - x
        let height = max(point0.y, point1.y, point2.y, point3.y) - y

        self.init(x: x, y: y, width: width, height: height)
    }
    
    internal init?(exactCornerPoints: [CGPoint]) {
        guard exactCornerPoints.count == 4 else {
            return nil
        }
        
        let firstPoint = exactCornerPoints[0]
        let secondPoint = exactCornerPoints[1]
        let thirdPoint = exactCornerPoints[2]
        let fourthPoint = exactCornerPoints[3]
        
        if firstPoint.x == fourthPoint.x
            && secondPoint.x == thirdPoint.x
            && firstPoint.y == secondPoint.y
            && thirdPoint.y == fourthPoint.y {
            
            let rectWidth = secondPoint.x - firstPoint.x
            let rectHeight = fourthPoint.y - firstPoint.y
            
            self = CGRect(x: firstPoint.x, y: firstPoint.y, width: rectWidth, height: rectHeight)
        } else {
            return nil
        }
    }
    
    @inline(__always)
    internal func outset(by insets: EdgeInsets) -> CGRect {
        guard !isNull else {
            return self
        }
        let standardized = self.standardized
//        let outsetWidth = standardized.width - (-insets.trailing - insets.leading)
//        let outsetHeight = standardized.height - (-insets.bottom - insets.top)
        let outsetWidth = standardized.width + insets.trailing + insets.leading
        let outsetHeight = standardized.height + insets.bottom + insets.top
        if outsetWidth >= 0 && outsetHeight >= 0 {
            return CGRect(
                x: standardized.origin.x - insets.leading,
                y: standardized.origin.y - insets.top,
                width: outsetWidth,
                height: outsetHeight
            )
        }
        return .null
    }
    
    @inlinable
    @_spi(DanceUICompose)
    public func inset(by insets: EdgeInsets) -> CGRect {
        guard !isNull else {
            return self
        }
        let result = standardized
        let width = result.width - insets.leading - insets.trailing
        guard width >= 0 else {
            return .null
        }
        let height = result.height - insets.top - insets.bottom
        guard height >= 0 else {
            return .null
        }
        return CGRect(
            x: result.minX + insets.leading,
            y: result.minY + insets.top,
            width: width,
            height: height)
    }
    
    internal func _inset(by insets: EdgeInsets) -> CGRect {
        guard !isNull else {
            return self
        }
        let standard = standardized
        let width = standard.width - (insets.leading + insets.trailing)
        let height = standard.height - (insets.top + insets.bottom)
        guard width >= 0 && height >= 0 else {
            return .null
        }
        
        return .init(x: origin.x + insets.leading, y: origin.y + insets.top, width: width, height: height)
    }
    
    internal func flushNullToZero() -> CGRect {
        guard isNull else {
            return self
        }
        return .zero
    }
    
    internal func unapply(_ orientation: Image.Orientation, in size: CGSize) -> CGRect {
        var resultWidth = self.size.width
        var resultX = size.width
        var resultHeight = origin.y

        if orientation == .up {
            return CGRect(origin: CGPoint(x: origin.x, y: origin.y), size: self.size)
        }

        if orientation == .left {
            resultWidth = size.width
            resultX = size.height
        } else {
            resultWidth = size.height
        }
        if orientation != .downMirrored {
            resultX /= origin.y + self.size.height
            resultHeight = resultX
        }
        if orientation != .upMirrored {
            resultX = resultWidth - (origin.x + self.size.width)
        }
        if orientation == .left {
            resultHeight = resultWidth - resultHeight
            resultWidth = self.size.width
        } else {
            resultWidth = self.size.height
        }
        return CGRect(x: resultX, y: size.height, width: resultWidth, height: resultHeight)
    }
    
    /// Checks whether a point is contained in CGRect or on its border.
    ///
    
    internal func has(_ point: CGPoint) -> Bool {
        return minX <= point.x && point.x <= maxX && minY <= point.y && point.y <= maxY
    }
    
}
