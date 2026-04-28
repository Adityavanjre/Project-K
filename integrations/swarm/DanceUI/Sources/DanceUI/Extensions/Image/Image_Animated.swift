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

internal import DanceUIGraph
internal import Resolver
internal import DanceUIRuntime

@available(iOS 13.0, *)
extension Image {
    
    @_spi(DanceUICompose)
    public struct AnimatedResolved: Equatable {
        
        internal let imageView: (AnimatableConfiguration) -> UIImageView
        
        internal let update: (UIView, AnimatableConfiguration) -> Void
        
        private let identifier: ObjectIdentifier
        
        internal init<Container: _AnimatedImageContainer>(_ container: Container) {
            self.imageView = container.createImageView
            self.update = container.updateImageView
            self.identifier = ObjectIdentifier(container.animatedImage)
        }
        
        public static func == (lhs: Image.AnimatedResolved, rhs: Image.AnimatedResolved) -> Bool {
            lhs.identifier == rhs.identifier
        }
    }
    
    fileprivate struct AnimatableProvider: _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var animatedResolved: AnimatedResolved
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            return DanceUIFeature.enableAnimatedImage.call {
                resolved.image.contents = .animated(animatedResolved)
                return resolved
            } disabled: {
                resolved
            }
        }
        
        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    @_spi(DanceUIExtension)
    public init<AnimatableContainer: _AnimatedImageContainer>(animatable: AnimatableContainer) {
        let uiImage = animatable.animatedImage
        let image = Image(uiImage: uiImage)
        self.provider = ImageProviderBox(AnimatableProvider(base: image, animatedResolved: .init(animatable)))
    }
    
    public struct AnimatableConfiguration: Equatable {
        
        public let playState: State
        
        public let autoPlay: Bool
        
        public let autoStop: Bool

        public let infinityLoop: Bool
        
        public let customLoop: UInt
        
        public let animationType: AnimationType
        
        public let onImageAnimateStart: (() -> Void)?
        
        public let onImageAnimateEnd: (() -> Void)?
                
        public init(playState: State = .play,
                    autoPlay: Bool = true,
                    autoStop: Bool = false,
                    infinityLoop: Bool = false,
                    customLoop: UInt = 0,
                    animationType: AnimationType = .order,
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
        
        public static func == (lhs: Image.AnimatableConfiguration, rhs: Image.AnimatableConfiguration) -> Bool {
            return lhs.playState == rhs.playState
            && lhs.autoPlay == rhs.autoPlay
            && lhs.autoStop == rhs.autoStop
            && lhs.infinityLoop == rhs.infinityLoop
            && lhs.customLoop == rhs.customLoop
            && lhs.animationType == rhs.animationType
            && DGCompareValues(lhs: lhs.onImageAnimateStart, rhs: rhs.onImageAnimateStart)
            && DGCompareValues(lhs: lhs.onImageAnimateEnd, rhs: rhs.onImageAnimateEnd)
        }
        
        @frozen
        public enum AnimationType: Int {
            case order
            case reciprocating
        }
        
        @frozen
        public enum State {
            case play
            case pause
            case stop
        }
    }
    
    fileprivate struct AnimatableConfigurationProvider: _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var configuration: AnimatableConfiguration
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            if case .animated(_) = resolved.image.contents {
                resolved.image.animatableConfiguration = configuration
            }
            return resolved
        }
        
        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    public func animatable(_ configuration: AnimatableConfiguration) -> Image {
        Image(provider: ImageProviderBox(AnimatableConfigurationProvider(base: self, configuration: configuration)))
    }
}

@available(iOS 13.0, *)
@_spi(DanceUIExtension)
public protocol _AnimatedImageContainer {
    
    associatedtype ImageView: UIImageView
    
    associatedtype AnimatedImage: UIImage
    
    var animatedImage: AnimatedImage { get }
    
    func createImageView(_ config: Image.AnimatableConfiguration) -> ImageView
    
    func updateImageView(_ view: ImageView, config: Image.AnimatableConfiguration)
}

@available(iOS 13.0, *)
extension _AnimatedImageContainer {
    
    internal func updateImageView(_ view: UIView, config: Image.AnimatableConfiguration) {
        if let imageView = view as? ImageView {
            updateImageView(imageView, config: config)
        }
    }
}

@available(iOS 13.0, *)
internal struct ImageLayerContainer {
    
    internal static func createImageView(_ image: GraphicsImage) -> UIView {
        guard let resolved = image.animatedResolved else {
            return _UIGraphicsView.my_view(with: ImageLayer())
        }
        return resolved.imageView(image.animatableConfiguration)
    }
    
    internal static func update(_ imageView: UIView, image: GraphicsImage, size: CGSize) {
        guard let resolved = image.animatedResolved else {
            let imageLayer = imageView.layer as! ImageLayer
            imageLayer.update(resolvedImage: image, size: size)
            return
        }
        resolved.update(imageView, image.animatableConfiguration)
        imageView.layer.update(with: image)
    }
}

@available(iOS 13.0, *)
extension CALayer {
    internal func update(with image: GraphicsImage) {
        self.allowsEdgeAntialiasing = image.isAntialiased
        self.contentsScale = image.scale
        
        if let maskColor = image.maskColor {
            let cgMaskColor = maskColor.cgColor
            self.my_contentsMultiplyColor = cgMaskColor
        } else {
            self.my_contentsMultiplyColor = nil
        }
        
        self.minificationFilter = .linear
        self.magnificationFilter = .linear
    }
}

@available(iOS 13.0, *)
extension GraphicsImage {
    @_spi(DanceUICompose)
    public var animatedResolved: Image.AnimatedResolved? {
        switch contents {
        case .animated(let animatedResolved):
            animatedResolved
        default:
            nil
        }
    }
}
