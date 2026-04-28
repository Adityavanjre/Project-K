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

import QuartzCore
import MyShims

@usableFromInline
@available(iOS 13.0, *)
internal final class ImageLayer: CALayer {
    
    fileprivate var lastResolvedImage: GraphicsImage? = nil

    fileprivate var lastResolvedSize: CGSize? = nil
    
    internal override init() {
        super.init()
    }
    
    internal required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    internal override init(layer: Any) {
        super.init(layer: layer)
    }
    
    internal func update(resolvedImage: GraphicsImage, size: CGSize) {
        let sizeEquals = lastResolvedSize == size
        let imageEquals = lastResolvedImage == resolvedImage
        
        guard !sizeEquals || !imageEquals else {
            return
        }
        
        if !sizeEquals {
            self.lastResolvedSize = size
            self.setNeedsLayout()
        }
        if !imageEquals {
            self.lastResolvedImage = resolvedImage
            switch resolvedImage.contents {
            case .cgImage(let content):
                if resolvedImage.maskColor != nil {
                    self.contents = content.alphaMask
                } else {
                    self.contents = content
                }
                self.backgroundColor = nil
            case .color(let color):
                self.contents = nil
                self.backgroundColor = color.cgColor
            default:
                self.contents = nil
                self.backgroundColor = nil
            }
            
            self.allowsEdgeAntialiasing = resolvedImage.isAntialiased
            self.contentsScale = resolvedImage.scale
            
            if let maskColor = resolvedImage.maskColor {
                let cgMaskColor = maskColor.cgColor
                self.my_contentsMultiplyColor = cgMaskColor
            } else {
                self.my_contentsMultiplyColor = nil
            }
            
            let (center, tiled) = resolvedImage.layerStretchInPixels(size: size)
            contentsCenter = center
            my_contentsScaling = tiled ? MyCAContentsScalingRepeat : MyCAContentsScalingStretch
            switch resolvedImage.interpolation {
            case .none:
                minificationFilter = .nearest
                magnificationFilter = .nearest
            case .low, .medium:
                minificationFilter = .linear
                magnificationFilter = .linear
            case .high:
                minificationFilter = .box
                magnificationFilter = .linear
            }
        }
    }
}

@available(iOS 13.0, *)
extension GraphicsImage {
    fileprivate func layerStretchInPixels(size: CGSize) -> (center: CGRect, tiled: Bool) {
        let flag = !orientation.isRotated
        
        let orientationSize = flag ? size : CGSize(width: size.height, height: size.width)
        guard slicesAndTiles(at: orientationSize) != nil else {
            return (CGRect(x: 0, y: 0, width: 1, height: 1), false)
        }
        let shouldTile = isTiledWhenStretchedToSize(orientationSize)
        
        let ei = resizingInfo?.capInsets ?? EdgeInsets.zero
        let imageSize = flag ? unrotatedPixelSize : CGSize(width: unrotatedPixelSize.height, height: unrotatedPixelSize.width)
        
        var imageRect = CGRect(origin: .zero, size: imageSize)
            .inset(by: EdgeInsets(top: ei.top * scale,
                                  leading: ei.leading * scale,
                                  bottom: ei.bottom * scale,
                                  trailing: ei.trailing * scale))
        imageRect = imageRect.unapply(orientation, in: imageSize)
        
        let rect = adjustedContentStretchInPixels(imageRect.isNull ? .zero : imageRect, contentSize: unrotatedPixelSize, shouldTile: shouldTile)
        return (rect, shouldTile)
    }
    
    internal func slicesAndTiles(at size: CGSize?) -> Image.ResizingInfo? {
        var sizeEqual = true
        if let size = size {
            let pixelSize: CGSize
            if orientation.isRotated {
                pixelSize = CGSize(width: unrotatedPixelSize.height / scale, height: unrotatedPixelSize.width / scale)
            } else {
                pixelSize = CGSize(width: unrotatedPixelSize.width / scale, height: unrotatedPixelSize.height / scale)
            }
            sizeEqual = size.equalTo(pixelSize)
        }
        
        guard !sizeEqual, let resizingInfo = resizingInfo else {
            return nil
        }
        if resizingInfo.capInsets != .zero || resizingInfo.mode == .tile {
            return resizingInfo
        }
        return nil
    }
    
    fileprivate func isTiledWhenStretchedToSize(_ size: CGSize) -> Bool {
        guard let resizingInfo = resizingInfo, resizingInfo.mode == .tile else {
            return false
        }
        let width: CGFloat
        let height: CGFloat
        if orientation.isRotated {
            width = unrotatedPixelSize.height / scale
            height = unrotatedPixelSize.width / scale
        } else {
            width = unrotatedPixelSize.width / scale
            height = unrotatedPixelSize.height / scale
        }
        
        if width != size.width, width - resizingInfo.capInsets.leading - resizingInfo.capInsets.trailing > 1 {
            return true
        }
        if height != size.height, height - resizingInfo.capInsets.top - resizingInfo.capInsets.bottom > 1 {
            return true
        }
        return false
    }
}

@available(iOS 13.0, *)
fileprivate func adjustedContentStretchInPixels(_ rect: CGRect, contentSize: CGSize, shouldTile: Bool) -> CGRect {
    func adjustDimension(stretchOrigin: inout CGFloat, stretchSize: inout CGFloat, contentSize: CGFloat) {
        guard stretchOrigin != 0 || stretchSize != contentSize else {
            stretchSize = 1.0
            return
        }
        var origin = stretchOrigin
        if !shouldTile {
            stretchSize = abs(stretchSize - 1)
            origin = stretchOrigin + 0.5
        }
        stretchOrigin = origin / contentSize
        if stretchSize > 1 || shouldTile {
            stretchSize = stretchSize / contentSize
        } else {
            stretchOrigin = stretchOrigin - 0.01 / contentSize
            stretchSize = 0.02 / contentSize
        }
    }
    
    var x = rect.origin.x
    var y = rect.origin.y
    var w = rect.size.width
    var h = rect.size.height
    
    adjustDimension(stretchOrigin: &x, stretchSize: &w, contentSize: contentSize.width)
    adjustDimension(stretchOrigin: &y, stretchSize: &h, contentSize: contentSize.height)
    
    return CGRect(x: x, y: y, width: w, height: h)
}

@_silgen_name("CGBitmapContextCreate")
@available(iOS 13.0, *)
fileprivate func _CGBitmapContextCreate(data: UnsafeMutableRawPointer?,
                                              width: Int,
                                              height: Int,
                                              bitsPerComponent: Int,
                                              bytesPerRow: Int,
                                              space: CGColorSpace?,
                                              bitmapInfo: UInt32) -> CGContext?
@available(iOS 13.0, *)
extension CGImage {
     
    internal var alphaMask: CGImage? {
        guard !isMask else {
            return self
        }
    
        guard let context = _CGBitmapContextCreate(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: nil, bitmapInfo: CGImageAlphaInfo.alphaOnly.rawValue) else {
            return self
        }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        context.clear(rect)
        context.setBlendMode(.copy)
        context.draw(self, in: rect)
        return context.makeImage()
    }
}

extension CALayerContentsFilter {
    /// Or use Private QuartzCore API kCAFilterBox
    public static let box: CALayerContentsFilter = .init(rawValue: "box")
}
