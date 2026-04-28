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
@_spi(DanceUICompose) import DanceUI

internal final class ComposeScreenScaleManager {
    internal static private(set) var scale = UIScreen.main.scale
    
    internal static func updateScale(_ scale: Double = ComposeScreenScaleManager.scale) {
        self.scale = scale
    }
}

protocol Pixel2PointProtocol {
    var px2pt: Self { get }
}

protocol Point2PixelProtocol {
    var pt2px: Self { get }
}

@available(iOS 13, *)
extension Pixel2PointProtocol where Self: _VectorMath {
    var px2pt: Self {
        self / ComposeScreenScaleManager.scale
    }
}

@available(iOS 13, *)
extension Point2PixelProtocol where Self: _VectorMath {
    var pt2px: Self {
        self * ComposeScreenScaleManager.scale
    }
}

extension Pixel2PointProtocol {
    mutating func mutatePx2pt() { self = px2pt }
}

extension Point2PixelProtocol {
    mutating func mutatePt2px() { self = pt2px }
}

extension Int: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self { self / Int(ComposeScreenScaleManager.scale) }
    var pt2px: Self { self * Int(ComposeScreenScaleManager.scale) }
}

extension CGFloat: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self { self / ComposeScreenScaleManager.scale }
    var pt2px: Self { self * ComposeScreenScaleManager.scale }
}

extension Double: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self { self / ComposeScreenScaleManager.scale }
    var pt2px: Self { self * ComposeScreenScaleManager.scale }
}

@available(iOS 13, *)
extension CGPoint: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self { self / ComposeScreenScaleManager.scale }
    var pt2px: Self { self * ComposeScreenScaleManager.scale }
}

@available(iOS 13, *)
extension CGSize: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self { self / ComposeScreenScaleManager.scale }
    var pt2px: Self { self * ComposeScreenScaleManager.scale }
}

@available(iOS 13, *)
extension CGRect: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self {
        CGRect(origin: origin.px2pt, size: size.px2pt)
    }
    
    var pt2px: Self {
        CGRect(origin: origin.pt2px, size: size.pt2px)
    }
}

extension CGPath {
    
    internal var px2pt: CGPath {
        let transform = CGAffineTransform(scaleX: 1.0 / ComposeScreenScaleManager.scale, y: 1.0 / ComposeScreenScaleManager.scale)
        let path = CGMutablePath()
        path.addPath(self, transform: transform)
        return path
    }
    
    internal var pt2px: CGPath {
        let transform = CGAffineTransform(scaleX: ComposeScreenScaleManager.scale, y: ComposeScreenScaleManager.scale)
        let path = CGMutablePath()
        path.addPath(self, transform: transform)
        return path
    }
}

extension CATransform3D: Pixel2PointProtocol, Point2PixelProtocol {
    var px2pt: Self {
        var new = self
        new.m41.mutatePx2pt()
        new.m42.mutatePx2pt()
        new.m43.mutatePx2pt()
        return new
    }
    
    var pt2px: Self {
        var new = self
        new.m41.mutatePt2px()
        new.m42.mutatePt2px()
        new.m43.mutatePt2px()
        return new
    }
}
