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

import CoreGraphics

@_spi(DanceUICompose) import DanceUI

@available(iOS 13.0, *)
internal final class ComposeImage: NSObject, ComposeImageBitmap {

    internal let type: ComposeImageBitmapType = .uiImage
    
    internal var image: Image
    
    internal var width: Int = 0
    
    internal var height: Int = 0
    
    internal var colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    
    internal var hasAlpha: Bool = true
    
    internal var config: ComposeImageBitmapConfig = .ARGB8888
    
    internal init(_ image: UIImage) {
        let id = Signpost.compose.tracePoiBegin("Image:initWithUIImage", [])
        self.image = Image(uiImage: image)
        if let cgImage = image.cgImage {
            self.width = cgImage.width
            self.height = cgImage.height
            self.colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            self.hasAlpha = cgImage.alphaInfo != .none
            self.config = .init(cgImage)
        }
        Signpost.compose.tracePoiEnd(id: id, "Image:initWithUIImage", [])
    }
    
    internal init(_ image: Image) {
        let id = Signpost.compose.tracePoiBegin("Image:initWithDanceUIImage", [])
        self.image = image
        if let cgImage = image.uiImage?.cgImage {
            self.width = cgImage.width
            self.height = cgImage.height
            self.colorSpace = cgImage.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            self.hasAlpha = cgImage.alphaInfo != .none
            self.config = .init(cgImage)
        }
        Signpost.compose.tracePoiEnd(id: id, "Image:initWithDanceUIImage", [])
    }
    
    internal func setup(with config: ComposeAnimatedImageConfig) {
        let configuration = Image.AnimatableConfiguration(
            playState: config.playState.imagePlayState,
            autoPlay: config.autoPlay,
            autoStop: config.autoStop,
            infinityLoop: config.infinityLoop,
            customLoop: config.customLoop,
            animationType: config.animationType.imageAnimationType,
            onImageAnimateStart: config.onImageAnimateStart,
            onImageAnimateEnd: config.onImageAnimateEnd
        )
        image = image.animatable(configuration)
    }
    
    internal func content(_ paint: any ComposePaint, in environmentValues: EnvironmentValues, seed: DisplayList.Seed) -> DisplayList.Item.Value? {
        var graphicsImage = image.resolve(in: environmentValues, style: nil).image
        
        guard graphicsImage.contents != nil else {
            return nil
        }
        graphicsImage.isAntialiased = paint.isAntiAlias
        graphicsImage.interpolation = paint.filterQuality.interpolation
        let content: DisplayList.Content.Value = graphicsImage.animatedResolved == nil ? .image(graphicsImage) : .animatedImage(graphicsImage)
        return .content(.init(value: content, seed: seed))
    }
}

@available(iOS 13.0, *)
internal final class ComposeAnimatedImageConfiguration: NSObject, ComposeAnimatedImageConfig {
    internal var playState: ComposeAnimatedImageState
    
    internal var autoPlay: Bool
    
    internal var autoStop: Bool
    
    internal var infinityLoop: Bool
    
    internal var customLoop: UInt
    
    internal var animationType: ComposeAnimatedImagePlayType
    
    internal var onImageAnimateStart: (() -> Void)?
    
    internal var onImageAnimateEnd: (() -> Void)?
    
    internal init(playState: ComposeAnimatedImageState = .play, 
                  autoPlay: Bool = true,
                  autoStop: Bool = false,
                  infinityLoop: Bool = false,
                  customLoop: UInt = 0,
                  animationType: ComposeAnimatedImagePlayType = .order,
                  onImageAnimateStart: (() -> Void)? = nil,
                  onImageAnimateEnd: (() -> Void)? = nil) {
        self.playState = playState
        self.autoPlay = autoPlay
        self.autoStop = autoStop
        self.infinityLoop = infinityLoop
        self.customLoop = customLoop
        self.animationType = animationType
        self.onImageAnimateStart = onImageAnimateStart
        self.onImageAnimateEnd = onImageAnimateEnd
    }
}

@available(iOS 13.0, *)
extension ComposeImageBitmapConfig {
    internal init(_ image: CGImage) {
        switch image.pixelFormatInfo {
        case .RGB565:
            self = .RGB565
        default:
            if image.alphaInfo == .alphaOnly {
                self = .alpha8
            } else {
                self = .ARGB8888
            }
        }
    }
}

@available(iOS 13.0, *)
extension ComposeAnimatedImageState {
    fileprivate var imagePlayState: Image.AnimatableConfiguration.State {
        switch self {
        case .play:
                .play
        case .pause:
                .pause
        case .stop:
                .stop
        @unknown default:
                .play
        }
    }
}

@available(iOS 13.0, *)
extension ComposeAnimatedImagePlayType {
    fileprivate var imageAnimationType: Image.AnimatableConfiguration.AnimationType {
        switch self {
        case .order:
                .order
        case .reciprocating:
                .reciprocating
        @unknown default:
                .order
        }
    }
}
