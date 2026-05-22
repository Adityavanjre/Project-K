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
@_spi(DanceUICompose)
public struct GraphicsImage : Equatable {

    @_spi(DanceUICompose)
    public var contents: Contents?

    @_spi(DanceUICompose)
    public var scale: CGFloat

    @_spi(DanceUICompose)
    public var unrotatedPixelSize: CGSize

    internal var orientation: Image.Orientation

    internal var maskColor: Color.Resolved?

    internal var resizingInfo: Image.ResizingInfo?

    @_spi(DanceUICompose)
    public var isAntialiased: Bool

    @_spi(DanceUICompose)
    public var interpolation: Image.Interpolation
    
    internal var animatableConfiguration: Image.AnimatableConfiguration = .init()
    
    internal init() {
        contents = nil
        scale = 1
        unrotatedPixelSize = .zero
        orientation = .up
        maskColor = nil
        resizingInfo = nil
        isAntialiased = false
        interpolation = .none
    }
    
    internal init(contents: GraphicsImage.Contents?,
                  scale: CGFloat,
                  unrotatedPixelSize: CGSize,
                  orientation: Image.Orientation,
                  maskColor: Color.Resolved?,
                  resizingInfo: Image.ResizingInfo?,
                  isAntialiased: Bool,
                  interpolation: Image.Interpolation) {
        self.contents = contents
        self.scale = scale
        self.unrotatedPixelSize = unrotatedPixelSize
        self.orientation = orientation
        self.maskColor = maskColor
        self.resizingInfo = resizingInfo
        self.isAntialiased = isAntialiased
        self.interpolation = interpolation
    }
    
    @_spi(DanceUICompose)
    public enum Contents : Equatable {

        case cgImage(CGImage) // 0x0

        // TODO: _notImplemented Contents.ioSurface
//        case ioSurface(IOSurfaceRef) // 0x1

        // TODO: _notImplemented Contents.vectorGlyph
//        indirect case vectorGlyph(ResolvedVectorGlyph)

        indirect case color(Color.Resolved)
        
        indirect case animated(Image.AnimatedResolved)
    }

    fileprivate enum Error {

        case invalidImage

    }
}

@available(iOS 13.0, *)
internal struct ColorResolver : Equatable {
    
    fileprivate enum CodingKeys {

        case resolvedTintColor

        case resolvedAccentColor

        case colorScheme

        case colorSchemeContrast

    }

    internal let resolvedTintColor: Color.Resolved

    internal let resolvedAccentColor: Color.Resolved

    internal var _colorScheme: CodableCaseIterable<ColorScheme>

    internal var _colorSchemeContrast: CodableCaseIterable<ColorSchemeContrast>

}

@available(iOS 13.0, *)

extension GraphicsImage {
    
    internal func makePlatformImage(fixedSymbolConfiguration: Bool, flattenMaskColor: Bool) -> UIImage? {
        
        let cgImage = self.render(in: CGRect(x: 0, y: 0, width: 0, height: 0))
        guard let cgImage = cgImage else {
            return nil
        }
        var uiImage = UIImage(cgImage: cgImage, scale: scale, orientation: UIImage.Orientation(self.orientation))
        if maskColor == nil {
            uiImage = uiImage.withRenderingMode(.alwaysOriginal)
        }
        else {
            uiImage = uiImage.withRenderingMode(.alwaysTemplate)
        }
        if let maskColor = maskColor, flattenMaskColor {
            let tintColor = maskColor.uiColor
            if #available(iOS 13.0, *) {
                uiImage = uiImage.withTintColor(tintColor)
            }
            // Fallback without tintColor
        }
        
        return uiImage
    }
    
    internal func render(in rect: CGRect?) -> CGImage? {
        var width = unrotatedPixelSize.width
        var height = unrotatedPixelSize.height
        if maskColor == nil {
            if orientation.isRotated {
                swap(&width, &height)
            }
            width = width / scale
            height = height / scale
        }
    
        switch contents {
        case .cgImage(let cgImage):
            return cgImage
        // TODO: _notImplemented Contents.vectorGlyph
//        case .vectorGlyph(let _):
//            _notImplemented()
//        case .ioSurface, .color, nil: 
//            _notImplemented()
        case .color, .animated, nil:
            return nil
        }
    }
}

@available(iOS 13.0, *)
extension UIImage.Orientation {
    internal init(_ orientation: Image.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .down:
            self = .down
        case .left:
            self = .left
        case .right:
            self = .right
        case .upMirrored:
            self = .upMirrored
        case .downMirrored:
            self = .downMirrored
        case .leftMirrored:
            self = .leftMirrored
        case .rightMirrored:
            self = .rightMirrored
        default:
            self = .up
        }
    }
}
