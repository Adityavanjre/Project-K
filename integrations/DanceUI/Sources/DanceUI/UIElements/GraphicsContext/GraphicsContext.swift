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

@frozen
@available(iOS 13.0, *)
public struct GraphicsContext {
    
    @usableFromInline
    final internal class Storage {
        
        fileprivate final class Shared {
            
//            let list: RBDisplayList
            
//            var symbols: GraphicsContextSymbols?
            
//            let shape: RBShape
            
//            let fill: RBFill
            
            let environment: EnvironmentValues
            
//            var _textProperties: IndirectOptional<TextLayoutProperties>
            
//            var _keyColorPredicate: RBDisplayListPredicate?
            
//            var _sharedTransform: RBDisplayListTransform?
            
            fileprivate init(environments: EnvironmentValues) {
                self.environment = environments
            }
            
            deinit {
                
            }
        }
        
        fileprivate let shared: Shared
        
//        let state: RBDrawingState
        
        internal var opacity: Float
        
//        var blendMode: RBBlendMode
        
        internal let ownsState: Bool
        
//        let colorSpace: RBColorSpace
        
        internal var cgContextWapper: RenderBoxWarpper
        
        fileprivate init(cgContext: CGContext, environments: EnvironmentValues) {
            self.shared = Shared(environments: environments)
            self.opacity = 1
            self.ownsState = false
            self.cgContextWapper = RenderBoxWarpper(cgContext: cgContext,
                                                    environments: environments)
        }
        
        deinit {
            
        }
    }
    
    internal var storage: Storage
    
    internal init(cgContext: CGContext, environments: EnvironmentValues) {
        self.storage = Storage(cgContext: cgContext, environments: environments)
    }
    
    static internal func renderingTo(cgContext: CGContext,
                                     environment: EnvironmentValues,
                                     content: (inout GraphicsContext) -> ()) {
        var graphicsContext = GraphicsContext(cgContext: cgContext, environments: environment)
        content(&graphicsContext)
    }
    
    /// The ways that a graphics context combines new content with background
    /// content.
    ///
    /// Use one of these values to set the
    /// ``GraphicsContext/blendMode-swift.property`` property of a
    /// ``GraphicsContext``. The value that you set affects how content
    /// that you draw replaces or combines with content that you
    /// previously drew into the context.
    ///
    @frozen
    public struct BlendMode: RawRepresentable, Equatable {
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = Int32
        
        /// The corresponding value of the raw type.
        ///
        /// A new instance initialized with `rawValue` will be equivalent to this
        /// instance. For example:
        ///
        ///     enum PaperSize: String {
        ///         case A4, A5, Letter, Legal
        ///     }
        ///
        ///     let selectedSize = PaperSize.Letter
        ///     print(selectedSize.rawValue)
        ///     // Prints "Letter"
        ///
        ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
        ///     // Prints "true"
        public let rawValue: Int32
        
        /// Creates a new instance with the specified raw value.
        ///
        /// If there is no value of the type that corresponds with the specified raw
        /// value, this initializer returns `nil`. For example:
        ///
        ///     enum PaperSize: String {
        ///         case A4, A5, Letter, Legal
        ///     }
        ///
        ///     print(PaperSize(rawValue: "Legal"))
        ///     // Prints "Optional("PaperSize.Legal")"
        ///
        ///     print(PaperSize(rawValue: "Tabloid"))
        ///     // Prints "nil"
        ///
        /// - Parameter rawValue: The raw value to use for the new instance.
        @inlinable
        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        @_spi(DanceUICompose)
        public init(blendMode: DanceUI.BlendMode) {
            switch blendMode {
            case .normal:
                self = .normal
            case .multiply:
                self = .multiply
            case .screen:
                self = .screen
            case .overlay:
                self = .overlay
            case .darken:
                self = .darken
            case .lighten:
                self = .lighten
            case .colorDodge:
                self = .colorDodge
            case .colorBurn:
                self = .colorBurn
            case .softLight:
                self = .softLight
            case .hardLight:
                self = .hardLight
            case .difference:
                self = .difference
            case .exclusion:
                self = .exclusion
            case .hue:
                self = .hue
            case .saturation:
                self = .saturation
            case .color:
                self = .color
            case .luminosity:
                self = .luminosity
            case .sourceAtop:
                self = .sourceAtop
            case .destinationOver:
                self = .destinationOver
            case .destinationOut:
                self = .destinationOut
            case .plusDarker:
                self = .plusDarker
            case .plusLighter:
                self = .plusLighter
            }
        }
        
        /// A mode that paints source image samples over the background image
        /// samples.
        ///
        /// This is the default blend mode.
        @inlinable
        public static var normal: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.normal.rawValue)
            }
        }
        
        /// A mode that multiplies the source image samples with the background
        /// image samples.
        ///
        /// Drawing in this mode results in colors that are at least as
        /// dark as either of the two contributing sample colors.
        @inlinable
        public static var multiply: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.multiply.rawValue)
            }
        }
        
        /// A mode that multiplies the inverse of the source image samples with
        /// the inverse of the background image samples.
        ///
        /// Drawing in this mode results in colors that are at least as light
        /// as either of the two contributing sample colors.
        @inlinable
        public static var screen: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.screen.rawValue)
            }
        }
        
        /// A mode that either multiplies or screens the source image samples
        /// with the background image samples, depending on the background
        /// color.
        ///
        /// Drawing in this mode overlays the existing image samples
        /// while preserving the highlights and shadows of the
        /// background. The background color mixes with the source
        /// image to reflect the lightness or darkness of the
        /// background.
        @inlinable
        public static var overlay: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.overlay.rawValue)
            }
        }
        
        /// A mode that creates composite image samples by choosing the darker
        /// samples from either the source image or the background.
        ///
        /// When you draw in this mode, source image samples that are darker
        /// than the background replace the background.
        /// Otherwise, the background image samples remain unchanged.
        @inlinable
        public static var darken: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.darken.rawValue)
            }
        }
        
        /// A mode that creates composite image samples by choosing the lighter
        /// samples from either the source image or the background.
        ///
        /// When you draw in this mode, source image samples that are lighter
        /// than the background replace the background.
        /// Otherwise, the background image samples remain unchanged.
        @inlinable
        public static var lighten: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.lighten.rawValue)
            }
        }
        
        /// A mode that brightens the background image samples to reflect the
        /// source image samples.
        ///
        /// Source image sample values that
        /// specify black do not produce a change.
        @inlinable
        public static var colorDodge: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.colorDodge.rawValue)
            }
        }
        
        /// A mode that darkens background image samples to reflect the source
        /// image samples.
        ///
        /// Source image sample values that specify
        /// white do not produce a change.
        @inlinable
        public static var colorBurn: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.colorBurn.rawValue)
            }
        }
        
        /// A mode that either darkens or lightens colors, depending on the
        /// source image sample color.
        ///
        /// If the source image sample color is
        /// lighter than 50% gray, the background is lightened, similar
        /// to dodging. If the source image sample color is darker than
        /// 50% gray, the background is darkened, similar to burning.
        /// If the source image sample color is equal to 50% gray, the
        /// background is not changed. Image samples that are equal to
        /// pure black or pure white produce darker or lighter areas,
        /// but do not result in pure black or white. The overall
        /// effect is similar to what you'd achieve by shining a
        /// diffuse spotlight on the source image. Use this to add
        /// highlights to a scene.
        @inlinable
        public static var softLight: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.softLight.rawValue)
            }
        }
        
        /// A mode that either multiplies or screens colors, depending on the
        /// source image sample color.
        ///
        /// If the source image sample color
        /// is lighter than 50% gray, the background is lightened,
        /// similar to screening. If the source image sample color is
        /// darker than 50% gray, the background is darkened, similar
        /// to multiplying. If the source image sample color is equal
        /// to 50% gray, the source image is not changed. Image samples
        /// that are equal to pure black or pure white result in pure
        /// black or white. The overall effect is similar to what you'd
        /// achieve by shining a harsh spotlight on the source image.
        /// Use this to add highlights to a scene.
        @inlinable
        public static var hardLight: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.hardLight.rawValue)
            }
        }
        
        /// A mode that subtracts the brighter of the source image sample color
        /// or the background image sample color from the other.
        ///
        /// Source image sample values that are black produce no change; white
        /// inverts the background color values.
        @inlinable
        public static var difference: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.difference.rawValue)
            }
        }
        
        /// A mode that produces an effect similar to that produced by the
        /// difference blend mode, but with lower contrast.
        ///
        /// Source image sample values that are black don't produce a change;
        /// white inverts the background color values.
        @inlinable
        public static var exclusion: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.exclusion.rawValue)
            }
        }
        
        /// A mode that uses the luminance and saturation values of the
        /// background with the hue of the source image.
        @inlinable
        public static var hue: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.hue.rawValue)
            }
        }
        
        /// A mode that uses the luminance and hue values of the background with
        /// the saturation of the source image.
        ///
        /// Areas of the background that have no saturation --- namely,
        /// pure gray areas --- don't produce a change.
        @inlinable
        public static var saturation: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.saturation.rawValue)
            }
        }
        
        /// A mode that uses the luminance values of the background with the hue
        /// and saturation values of the source image.
        ///
        /// This mode preserves the gray levels in the image. You can use this
        /// mode to color monochrome images or to tint color images.
        @inlinable
        public static var color: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.color.rawValue)
            }
        }
        
        /// A mode that uses the hue and saturation of the background with the
        /// luminance of the source image.
        ///
        /// This mode creates an effect that is inverse to the effect created
        /// by the ``GraphicsContext/BlendMode-swift.struct/color`` mode.
        @inlinable
        public static var luminosity: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.luminosity.rawValue)
            }
        }
        
        /// A mode that clears any pixels that the source image overwrites.
        ///
        /// With this mode, you can use the source image like an eraser.
        ///
        /// This mode implements the equation `R = 0` where
        /// `R` is the composite image.
        @inlinable
        public static var clear: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.clear.rawValue)
            }
        }
        
        /// A mode that replaces background image samples with source image
        /// samples.
        ///
        /// Unlike the ``GraphicsContext/BlendMode-swift.struct/normal`` mode, the source image completely replaces
        /// the background, so that even transparent pixels in the source image
        /// replace opaque pixels in the background, rather than letting the
        /// background show through.
        ///
        /// This mode implements the equation `R = S` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        @inlinable
        public static var copy: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.copy.rawValue)
            }
        }
        
        /// A mode that you use to paint the source image, including
        /// its transparency, onto the opaque parts of the background.
        ///
        /// This mode implements the equation `R = S*Da` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var sourceIn: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.sourceIn.rawValue)
            }
        }
        
        /// A mode that you use to paint the source image onto the
        /// transparent parts of the background, while erasing the background.
        ///
        /// This mode implements the equation `R = S*(1 - Da)` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var sourceOut: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.sourceOut.rawValue)
            }
        }
        
        /// A mode that you use to paint the opaque parts of the
        /// source image onto the opaque parts of the background.
        ///
        /// This mode implements the equation `R = S*Da + D*(1 - Sa)` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        /// * `Sa` is the source image's alpha value.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var sourceAtop: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.sourceAtop.rawValue)
            }
        }
        
        /// A mode that you use to paint the source image under
        /// the background.
        ///
        /// This mode implements the equation `R = S*(1 - Da) + D` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var destinationOver: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.destinationOver.rawValue)
            }
        }
        
        /// A mode that you use to erase any of the background that
        /// isn't covered by opaque source pixels.
        ///
        /// This mode implements the equation `R = D*Sa` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var destinationIn: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.destinationIn.rawValue)
            }
        }
        
        /// A mode that you use to erase any of the background that
        /// is covered by opaque source pixels.
        ///
        /// This mode implements the equation `R = D*(1 - Sa)` where
        /// * `R` is the composite image.
        /// * `D` is the background.
        /// * `Sa` is the source image's alpha value.
        @inlinable
        public static var destinationOut: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.destinationOut.rawValue)
            }
        }
        
        /// A mode that you use to paint the source image under
        /// the background, while erasing any of the background not matched
        /// by opaque pixels from the source image.
        ///
        /// This mode implements the equation `R = S*(1 - Da) + D*Sa` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        /// * `Sa` is the source image's alpha value.
        /// * `Da` is the source background's alpha value.
        @inlinable
        public static var destinationAtop: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.destinationAtop.rawValue)
            }
        }
        
        /// A mode that you use to clear pixels where both the source and
        /// background images are opaque.
        ///
        /// This mode implements the equation `R = S*(1 - Da) + D*(1 - Sa)` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        /// * `Sa` is the source image's alpha value.
        /// * `Da` is the source background's alpha value.
        ///
        /// This XOR mode is only nominally related to the classical bitmap
        /// XOR operation, which DanceUI doesn't support.
        @inlinable
        public static var xor: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.xor.rawValue)
            }
        }
        
        /// A mode that adds the inverse of the color components of the source
        /// and background images, and then inverts the result, producing
        /// a darkened composite.
        ///
        /// This mode implements the equation `R = MAX(0, 1 - ((1 - D) + (1 - S)))` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        @inlinable
        public static var plusDarker: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.plusDarker.rawValue)
            }
        }
        
        /// A mode that adds the components of the source and background images,
        /// resulting in a lightened composite.
        ///
        /// This mode implements the equation `R = MIN(1, S + D)` where
        /// * `R` is the composite image.
        /// * `S` is the source image.
        /// * `D` is the background.
        @inlinable
        public static var plusLighter: BlendMode {
            get {
                self.init(rawValue: CGBlendMode.plusLighter.rawValue)
            }
        }
    }
    
    /// The opacity of drawing operations in the context.
    ///
    /// Set this value to affect the opacity of content that you subsequently
    /// draw into the context. Changing this value has no impact on the
    /// content you previously drew into the context.
    public var opacity: Double {
        get {
            Double(storage.opacity)
        }
        
        set {
            storage.opacity = Float(newValue)
        }
    }
    
    /// The blend mode used by drawing operations in the context.
    ///
    /// Set this value to affect how any content that you subsequently draw
    /// into the context blends with content that's already in the context.
    /// Use one of the ``GraphicsContext/BlendMode-swift.struct`` values.
    public var blendMode: BlendMode {
        get {
            storage.cgContextWapper.blendMode
        }
        
        set{
            storage.cgContextWapper.blendMode = newValue
        }
    }
    
    /// The environment associated with the graphics context.
    ///
    /// DanceUI initially sets this to the environment of the context's
    /// enclosing view. The context uses values like display
    /// resolution and the color scheme from the environment to resolve types
    /// like ``Image`` and ``Color``. You can also access values stored in the
    /// environment for your own purposes.
    public var environment: EnvironmentValues {
        storage.shared.environment
    }
    
    /// The current transform matrix, defining user space coordinates.
    ///
    /// Modify this matrix to transform content that you subsequently
    /// draw into the context. Changes that you make don't affect
    /// existing content.
    public var transform: CGAffineTransform {
        get {
            storage.cgContextWapper.transform
        }
        
        set {
            storage.cgContextWapper.transform = newValue
        }
    }
    
    /// Scales subsequent drawing operations by an amount in each dimension.
    ///
    /// Calling this method is equivalent to updating the context's
    /// ``GraphicsContext/transform`` directly using the given scale factors:
    ///
    ///     transform = transform.scaledBy(x: x, y: y)
    ///
    /// - Parameters:
    ///   - x: The amount to scale in the horizontal direction.
    ///   - y: The amount to scale in the vertical direction.
    public mutating func scaleBy(x: CGFloat, y: CGFloat) {
        storage.cgContextWapper.scaleBy(x: x, y: y)
    }
    
    /// Moves subsequent drawing operations by an amount in each dimension.
    ///
    /// Calling this method is equivalent to updating the context's
    /// ``GraphicsContext/transform`` directly using the given translation amount:
    ///
    ///     transform = transform.translatedBy(x: x, y: y)
    ///
    /// - Parameters:
    ///   - x: The amount to move in the horizontal direction.
    ///   - y: The amount to move in the vertical direction.
    public mutating func translateBy(x: CGFloat, y: CGFloat) {
        storage.cgContextWapper.translateBy(x: x, y: y)
    }
    
    /// Rotates subsequent drawing operations by an angle.
    ///
    /// Calling this method is equivalent to updating the context's
    /// ``GraphicsContext/transform`` directly using the `angle` parameter:
    ///
    ///     transform = transform.rotated(by: angle.radians)
    ///
    /// - Parameters:
    ///   - angle: The amount to rotate.
    public mutating func rotate(by angle: Angle) {
        storage.cgContextWapper.rotate(by: angle)
    }
    
    /// Appends the given transform to the context's existing transform.
    ///
    /// Calling this method is equivalent to updating the context's
    /// ``GraphicsContext/transform`` directly using the `matrix` parameter:
    ///
    ///     transform = matrix.concatenating(transform)
    ///
    /// - Parameter matrix: A transform to append to the existing transform.
    public mutating func concatenate(_ matrix: CGAffineTransform) {
        storage.cgContextWapper.concatenate(matrix)
    }
    
    /// Options that affect the use of clip shapes.
    ///
    /// Use these options to affect how DanceUI interprets a clip shape
    /// when you call ``GraphicsContext/clip(to:style:options:)`` to add a path to the array of
    /// clip shapes, or when you call ``GraphicsContext/clipToLayer(opacity:options:content:)``
    /// to add a clipping layer.
    @frozen
    public struct ClipOptions: OptionSet {
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = ClipOptions
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = ClipOptions
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt32
        
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An option to invert the shape or layer alpha as the clip mask.
        ///
        /// When you use this option, DanceUI uses `1 - alpha` instead of
        /// `alpha` for the given clip shape.
        @inlinable
        public static var inverse: ClipOptions {
            get {
                Self(rawValue: 1 << 0)
            }
        }
    }
    
    /// The bounding rectangle of the intersection of all current clip
    /// shapes in the current user space.
    public var clipBoundingRect: CGRect {
        storage.cgContextWapper.clipBoundingRect
    }
    
    /// Adds a path to the context's array of clip shapes.
    ///
    /// Call this method to add a shape to the array of clip shapes that
    /// the context uses to define a clipping mask. Shapes that you add
    /// affect only subsequent drawing operations.
    ///
    /// - Parameters:
    ///   - path: A ``Path`` that defines the shape of the clipping mask.
    ///   - style: A ``FillStyle`` that defines how to rasterize the shape.
    ///   - options: Clip options that tell DanceUI how to interpret the `path`
    ///     as a clip shape. For example, you can invert the clip
    ///     shape by setting the ``GraphicsContext/ClipOptions/inverse`` option.
    public mutating func clip(to path: Path,
                              style: FillStyle = FillStyle(),
                              options: ClipOptions = ClipOptions()) {
        storage.cgContextWapper.clip(to: path,
                                     style: style,
                                     options: options)
    }
    
    /// A type that applies image processing operations to rendered content.
    ///
    /// Create and configure a filter that produces an image processing effect,
    /// like adding a drop shadow or a blur effect, by calling one of the
    /// factory methods defined by the ``GraphicsContext/Filter`` structure. Call the
    /// ``GraphicsContext/addFilter(_:options:)`` method to add the filter to a
    /// ``GraphicsContext``. The filter only affects content that you draw
    /// into the context after adding the filter.
    public struct Filter {
        
        internal var storage: Storage
        
        internal enum Storage {
            
            case projection(ProjectionTransform)
            
            case shadow((Color, CGFloat, CGSize, BlendMode, ShadowOptions))
            
            case shadowResolved((Color.Resolved, CGFloat, CGSize, BlendMode, ShadowOptions))
            
            case colorMultiply(Color)
            
            case colorMultiplyResolved(Color.Resolved)
            
            case colorMatrixArray(Array<Float>)
            
            case colorMatrix(_ColorMatrix)
            
            case hueRotate(Angle)
            
            case saturate(Float)
            
            case brightness(Float)
            
            case contrast(Float)
            
            case invert(Float)
            
            case grayscale(Float)
            
            /*
             case blur((CGFloat, RBBlurFlags))
             */
            case blur(CGFloat)
            
            case alphaThreshold((Float, Float, Color))
            
            case alphaGradient(Gradient)
            
            case colorMonochrome(GraphicsFilter.ColorMonochrome)
            
            case luminanceCurve(GraphicsFilter.LuminanceCurve)
            
            case luminanceToAlpha
        }
        
        /// Returns a filter that that transforms the rasterized form
        /// of subsequent graphics primitives.
        ///
        /// - Parameters:
        ///   - matrix: A projection transform to apply to the rasterized
        ///     form of graphics primitives.
        /// - Returns: A filter that applies a transform.
        public static func projectionTransform(_ matrix: ProjectionTransform) -> Filter {
            Filter(storage: .projection(matrix))
        }
        
        /// Returns a filter that adds a shadow.
        ///
        /// DanceUI produces the shadow by blurring the alpha channel of the
        /// object receiving the shadow, multiplying the result by a color,
        /// optionally translating the shadow by an amount,
        /// and then blending the resulting shadow into a new layer below the
        /// source primitive. You can customize some of these steps by adding
        /// one or more shadow options.
        ///
        /// - Parameters:
        ///   - color: A ``Color`` that tints the shadow.
        ///   - radius: A measure of how far the shadow extends from the edges
        ///     of the content receiving the shadow.
        ///   - x: An amount to translate the shadow horizontally.
        ///   - y: An amount to translate the shadow vertically.
        ///   - blendMode: The ``GraphicsContext/BlendMode-swift.struct`` to use
        ///     when blending the shadow into the background layer.
        ///   - options: A set of options that you can use to customize the
        ///     process of adding the shadow. Use one or more of the options
        ///     in ``GraphicsContext/ShadowOptions``.
        /// - Returns: A filter that adds a shadow style.
        public static func shadow(color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33),
                                  radius: CGFloat,
                                  x: CGFloat = 0,
                                  y: CGFloat = 0,
                                  blendMode: BlendMode = .normal,
                                  options: ShadowOptions = ShadowOptions()) -> Filter {
            Filter(storage: .shadow((color, radius, CGSize(width: x, height: y), blendMode, options)))
        }
        
        /// Returns a filter that multiplies each color component by
        /// the matching component of a given color.
        ///
        /// - Parameters:
        ///   - color: The color that the filter uses for the multiplication
        ///     operation.
        /// - Returns: A filter that multiplies color components.
        public static func colorMultiply(_ color: Color) -> Filter {
            Filter(storage: .colorMultiply(color))
        }
        
        /// Returns a filter that multiplies by a given color matrix.
        ///
        /// This filter is equivalent to the `feColorMatrix` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// The filter creates the output color `[R', G', B', A']` at each pixel
        /// from an input color `[R, G, B, A]` by multiplying the input color by
        /// the square matrix formed by the first four columns of the
        /// ``ColorMatrix``, then adding the fifth column to the result:
        ///
        ///     R' = r1 ✕ R + r2 ✕ G + r3 ✕ B + r4 ✕ A + r5
        ///     G' = g1 ✕ R + g2 ✕ G + g3 ✕ B + g4 ✕ A + g5
        ///     B' = b1 ✕ R + b2 ✕ G + b3 ✕ B + b4 ✕ A + b5
        ///     A' = a1 ✕ R + a2 ✕ G + a3 ✕ B + a4 ✕ A + a5
        ///
        /// - Parameters:
        ///   - matrix: A ``ColorMatrix`` instance used by the filter.
        /// - Returns: A filter that transforms color using the given matrix.
        public static func colorMatrix(_ matrix: ColorMatrix) -> Filter {
            Filter(storage: .colorMatrix(matrix.getInternalColorMatrix()))
        }
        
        /// Returns a filter that applies a hue rotation adjustment.
        ///
        /// This filter is equivalent to the `hue-rotate` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// - Parameters:
        ///   - angle: The amount by which to rotate the hue value of each
        ///     pixel.
        /// - Returns: A filter that applies a hue rotation adjustment.
        public static func hueRotation(_ angle: Angle) -> Filter {
            Filter(storage: .hueRotate(angle))
        }
        
        /// Returns a filter that applies a saturation adjustment.
        ///
        /// This filter is equivalent to the `saturate` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// - Parameters:
        ///   - amount: The amount of the saturation adjustment. A value
        ///     of zero to completely desaturates each pixel, while a value of
        ///     one makes no change. You can use values greater than one.
        /// - Returns: A filter that applies a saturation adjustment.
        public static func saturation(_ amount: Double) -> Filter {
            Filter(storage: .saturate(Float(amount)))
        }
        
        /// Returns a filter that applies a brightness adjustment.
        ///
        /// This filter is different than `brightness` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        /// You can obtain an effect like that filter using a ``GraphicsContext/Filter/grayscale(_:)``
        /// color multiply. However, this filter does match the
        /// [CIColorControls]<https://developer.apple.com/documentation/CoreImage/CIColorControls>
        /// filter's brightness adjustment.
        ///
        /// - Parameters:
        ///   - amount: An amount to add to the pixel's color components.
        /// - Returns: A filter that applies a brightness adjustment.
        public static func brightness(_ amount: Double) -> Filter {
            Filter(storage: .brightness(Float(amount)))
        }
        
        /// Returns a filter that applies a contrast adjustment.
        ///
        /// This filter is equivalent to the `contrast` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// - Parameters:
        ///   - amount: An amount to adjust the contrast. A value of
        ///     zero leaves the result completely gray. A value of one leaves
        ///     the result unchanged. You can use values greater than one.
        /// - Returns: A filter that applies a contrast adjustment.
        public static func contrast(_ amount: Double) -> Filter {
            Filter(storage: .contrast(Float(amount)))
        }
        
        /// Returns a filter that inverts the color of their results.
        ///
        /// This filter is equivalent to the `invert` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// - Parameters:
        ///   - amount: The inversion amount. A value of one results in total
        ///     inversion, while a value of zero leaves the result unchanged.
        ///     Other values apply a linear multiplier effect.
        /// - Returns: A filter that applies a color inversion.
        public static func colorInvert(_ amount: Double = 1) -> Filter {
            Filter(storage: .invert(Float(amount)))
        }
        
        /// Returns a filter that applies a grayscale adjustment.
        ///
        /// This filter is equivalent to the `grayscale` filter primitive
        /// defined by the Scalable Vector Graphics (SVG) specification.
        ///
        /// - Parameters:
        ///   - amount: An amount that controls the effect. A value of one
        ///     makes the image completely gray. A value of zero leaves the
        ///     result unchanged. Other values apply a linear multiplier effect.
        /// - Returns: A filter that applies a grayscale adjustment.
        public static func grayscale(_ amount: Double) -> Filter {
            Filter(storage: .grayscale(Float(amount)))
        }
        
        /// Returns a filter that sets the opacity of each pixel based on its
        /// luminance.
        ///
        /// The filter computes the luminance of each pixel
        /// and uses it to define the opacity of the result, combined
        /// with black (zero) color components.
        ///
        /// - Returns: A filter that applies a luminance to alpha transformation.
        public static var luminanceToAlpha: Filter {
            Filter(storage: .luminanceToAlpha)
        }
        
        /// Returns a filter that applies a Gaussian blur.
        ///
        /// - Parameters:
        ///   - radius: The standard deviation of the Gaussian blur.
        ///   - options: A set of options controlling the application of the
        ///     effect.
        /// - Returns: A filter that applies Gaussian blur.
        public static func blur(radius: CGFloat, options: BlurOptions = BlurOptions()) -> Filter {
            Filter(storage: .blur(radius))
        }
        
        /// Returns a filter that replaces each pixel with alpha components
        /// within a range by a constant color, or transparency otherwise.
        ///
        /// - Parameters:
        ///   - min: The minimum alpha threshold. Pixels whose alpha
        ///     component is less than this value will render as
        ///     transparent. Results are undefined unless `min < max`.
        ///   - max: The maximum alpha threshold. Pixels whose alpha
        ///     component is greater than this value will render
        ///     as transparent. Results are undefined unless `min < max`.
        ///   - color: The color that is output for pixels with an alpha
        ///     component between the two threshold values.
        /// - Returns: A filter that applies a threshold to alpha values.
        public static func alphaThreshold(min: Double,
                                          max: Double = 1,
                                          color: Color = .black) -> Filter {
            Filter(storage: .alphaThreshold((Float(min), Float(max), color)))
        }
    }
    
    /// Options that configure the graphics context filter that creates shadows.
    ///
    /// You can use a set of these options when you call
    /// ``GraphicsContext/Filter/shadow(color:radius:x:y:blendMode:options:)`` to create a
    /// ``GraphicsContext/Filter`` that adds a drop shadow to an object that you draw into a
    /// ``GraphicsContext``.
    @frozen
    public struct ShadowOptions: OptionSet {
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = ShadowOptions
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = ShadowOptions
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt32
        
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An option that causes the filter to draw the shadow above the
        /// object, rather than below it.
        @inlinable
        public static var shadowAbove: ShadowOptions {
            get {
                Self(rawValue: 1 << 0)
            }
        }
        
        /// An option that causes the filter to draw only the shadow, and
        /// omit the source object.
        @inlinable
        public static var shadowOnly: ShadowOptions {
            get {
                Self(rawValue: 1 << 1)
            }
        }
        
        /// An option that causes the filter to invert the alpha of the shadow.
        ///
        /// You can create an "inner shadow" effect by combining this option
        /// with ``GraphicsContext/ShadowOptions/shadowAbove`` and using the
        /// ``GraphicsContext/BlendMode-swift.struct/sourceAtop`` blend mode.
        @inlinable
        public static var invertsAlpha: ShadowOptions {
            get {
                Self(rawValue: 1 << 2)
            }
        }
        
        /// An option that causes the filter to composite the object and its
        /// shadow separately in the current layer.
        @inlinable
        public static var disablesGroup: ShadowOptions {
            get {
                Self(rawValue: 1 << 3)
            }
        }
    }
    
    /// Options that configure the graphics context filter that creates blur.
    ///
    /// You can use a set of these options when you call
    /// ``GraphicsContext/Filter/blur(radius:options:)`` to create a ``GraphicsContext/Filter`` that adds
    /// blur to an object that you draw into a ``GraphicsContext``.
    @frozen
    public struct BlurOptions: OptionSet {
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = BlurOptions
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = BlurOptions
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt32
        
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An option that causes the filter to ensure the result is completely
        /// opaque.
        ///
        /// The filter ensure opacity by dividing each pixel by its alpha
        /// value. The result may be undefined if the input to the filter
        /// isn't also completely opaque.
        @inlinable
        public static var opaque: BlurOptions {
            get { Self(rawValue: 1 << 0) }
        }
        
        /// An option that causes the filter to dither the result, to reduce
        /// banding.
        @inlinable
        public static var dithersResult: BlurOptions {
            get { Self(rawValue: 1 << 1) }
        }
    }
    
    /// Options that configure a filter that you add to a graphics context.
    ///
    /// You can use filter options to configure a ``GraphicsContext/Filter`` that you apply
    /// to a ``GraphicsContext`` with the ``GraphicsContext/addFilter(_:options:)`` method.
    @frozen
    public struct FilterOptions: OptionSet {
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = FilterOptions
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = FilterOptions
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt32
        
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An option that causes the filter to perform calculations in a
        /// linear color space.
        @inlinable
        public static var linearColor: FilterOptions {
            get { Self(rawValue: 1 << 0) }
        }
    }
    
    /// Adds a filter that applies to subsequent drawing operations.
    ///
    /// To draw with filtering, DanceUI:
    ///
    /// - Rasterizes the drawing operation to an implicit transparency layer
    ///   without blending, adjusting opacity, or applying any clipping.
    /// - Applies the filter to the layer containing the rasterized image.
    /// - Composites the layer onto the background, using the context's
    ///   current blend mode, opacity setting, and clip shapes.
    ///
    /// When DanceUI draws with a filter, the blend mode might apply to regions
    /// outside the drawing operation's intrinsic shape, but inside its clip
    /// shape. That might result in unexpected behavior for certain blend
    /// modes like ``GraphicsContext/BlendMode-swift.struct/copy``, where
    /// the drawing operation completely overwrites the background even if
    /// the source alpha is zero.
    ///
    /// - Parameters:
    ///   - filter: A graphics context filter that you create by calling one
    ///     of the ``GraphicsContext/Filter`` factory methods.
    ///   - options: A set of options from ``GraphicsContext/FilterOptions`` that you can use to
    ///     configure filter operations.
    public mutating func addFilter(_ filter: Filter, options: FilterOptions = FilterOptions()) {
        storage.cgContextWapper.addFilter(filter, options: options)
    }
    
    internal mutating func addFilter(_ filter :GraphicsFilter, in rect :CGRect) {
        storage.cgContextWapper.addFilter(filter, in: rect)
    }
    
    /// A color or pattern that you can use to outline or fill a path.
    ///
    /// Use a shading instance to describe the color or pattern of a path that
    /// you outline with a method like ``GraphicsContext/stroke(_:with:style:)``, or of the
    /// interior of a region that you fill with the ``GraphicsContext/fill(_:with:style:)``
    /// method. Get a shading instance by calling one of the `Shading`
    /// structure's factory methods. You can base shading on:
    /// - A ``Color``.
    /// - A ``Gradient``.
    /// - Any type that conforms to ``ShapeStyle``.
    /// - An ``Image``.
    /// - What you've already drawn into the context.
    /// - A collection of other shading instances.
    public struct Shading {
        
        internal enum Storage {
            
            case backdrop(Color.Resolved)
            
            case color(Color)
            
            /*
             case sRGBColor(RBColor)
             */
            case sRGBColor
            
            case style(AnyShapeStyle)
            
            case gradient((Gradient, geometry: GradientGeometry, options: GradientOptions))
            
            case tiledImage((Image, origin: CGPoint, sourceRect: CGRect, scale: CGFloat))
            
            case levels([Shading])
        }
        
        internal var storage: Storage
        
        /// A shading instance that draws a copy of the current background.
        public static var backdrop: Shading {
            Shading(storage: .backdrop(Color.Resolved()))
        }
        
        /// Returns a multilevel shading instance constructed from an
        /// array of shading instances.
        ///
        /// - Parameter array: An array of shading instances. The array must
        ///   contain at least one element.
        /// - Returns: A shading instance composed from the given instances.
        public static func palette(_ array: [Shading]) -> Shading {
            guard !array.isEmpty else {
                _danceuiFatalError("palette shading array is empty")
            }
            
            return Shading(storage: .levels(array))
        }
        
        /// Returns a shading instance that fills with a color.
        ///
        /// - Parameter color: A ``Color`` instance that defines the color
        ///   of the shading.
        /// - Returns: A shading instance filled with a color.
        public static func color(_ color: Color) -> Shading {
            Shading(storage: .color(color))
        }
        
        /// Returns a shading instance that fills with a color in the given
        /// color space.
        ///
        /// - Parameters:
        ///   - colorSpace: The RGB color space used to define the color. The
        ///     default is ``Color/RGBColorSpace/sRGB``.
        ///   - red: The red component of the color.
        ///   - green: The green component of the color.
        ///   - blue: The blue component of the color.
        ///   - opacity: The opacity of the color. The default is `1`, which
        ///     means fully opaque.
        /// - Returns: A shading instance filled with a color.
        public static func color(_ colorSpace: Color.RGBColorSpace = .sRGB,
                                 red: Double, green: Double,
                                 blue: Double,
                                 opacity: Double = 1) -> Shading {
             Shading(storage: .sRGBColor)
        }
        
        /// Returns a shading instance that fills with a monochrome color in
        /// the given color space.
        ///
        /// - Parameters:
        ///   - colorSpace: The RGB color space used to define the color. The
        ///     default is ``Color/RGBColorSpace/sRGB``.
        ///   - white: The value to use for each of the red, green, and blue
        ///     components of the color.
        ///   - opacity: The opacity of the color. The default is `1`, which
        ///     means fully opaque.
        /// - Returns: A shading instance filled with a color.
        public static func color(_ colorSpace: Color.RGBColorSpace = .sRGB,
                                 white: Double,
                                 opacity: Double = 1) -> Shading {
            Shading(storage: .sRGBColor)
        }
        
        /// Returns a shading instance that fills with the given shape style.
        ///
        /// Styles with geometry defined in a unit coordinate space
        /// map that space to the rectangle associated with the drawn
        /// object. You can adjust that using the ``ShapeStyle/in(_:)``
        /// method. The shape style might affect the blend mode and opacity
        /// of the drawn object.
        ///
        /// - Parameter style: A ``ShapeStyle`` instance to draw with.
        /// - Returns: A shading instance filled with a shape style.
        public static func style<S>(_ style: S) -> Shading where S : ShapeStyle {
            Shading(storage: .style(AnyShapeStyle(style)))
        }
        
        /// Returns a shading instance that fills a linear (axial) gradient.
        ///
        /// The shading instance defines an axis from `startPoint` to `endPoint`
        /// in the current user space and maps colors from `gradient`
        /// to lines perpendicular to the axis.
        ///
        /// - Parameters:
        ///   - gradient: A ``Gradient`` instance that defines the colors
        ///     of the gradient.
        ///   - startPoint: The start point of the gradient axis.
        ///   - endPoint: The end point of the gradient axis.
        ///   - options: Options that you use to configure the gradient.
        /// - Returns: A shading instance filled with a linear gradient.
        public static func linearGradient(_ gradient: Gradient,
                                          startPoint: CGPoint,
                                          endPoint: CGPoint,
                                          options: GradientOptions = GradientOptions()) -> Shading {
            Shading(storage: .gradient((gradient,
                                        geometry: .axial((startPoint, endPoint)),
                                        options: options)))
        }
        
        /// Returns a shading instance that fills a radial gradient.
        ///
        /// - Parameters:
        ///   - gradient: A ``Gradient`` instance that defines the colors
        ///     of the gradient.
        ///   - center: The point in the current user space on which DanceUI
        ///     centers the gradient.
        ///   - startRadius: The distance from the center where the gradient
        ///     starts.
        ///   - endRadius:The distance from the center where the gradient ends.
        ///   - options: Options that you use to configure the gradient.
        /// - Returns: A shading instance filled with a radial gradient.
        public static func radialGradient(_ gradient: Gradient,
                                          center: CGPoint,
                                          startRadius: CGFloat,
                                          endRadius: CGFloat,
                                          options: GradientOptions = GradientOptions()) -> Shading {
            Shading(storage: .gradient((gradient,
                                        geometry: .radial((center, startRadius, endRadius)),
                                        options: options)))
        }
        
        /// Returns a shading instance that fills a conic (angular) gradient.
        ///
        /// - Parameters:
        ///   - gradient: A ``Gradient`` instance that defines the colors
        ///     of the gradient.
        ///   - center: The point in the current user space on which DanceUI
        ///     centers the gradient.
        ///   - angle: The angle about the center that DanceUI uses to start and
        ///     finish the gradient. The gradient sweeps all the way around the
        ///     center.
        ///   - options: Options that you use to configure the gradient.
        /// - Returns: A shading instance filled with a conic gradient.
        public static func conicGradient(_ gradient: Gradient,
                                         center: CGPoint,
                                         angle: Angle = Angle(),
                                         options: GradientOptions = GradientOptions()) -> Shading {
            Shading(storage: .gradient((gradient,
                                        geometry: .conic((center, angle)),
                                        options: options)))
        }
        
        /// Returns a shading instance that tiles an image across the infinite
        /// plane.
        ///
        /// - Parameters:
        ///   - image: An ``Image`` to use as fill.
        ///   - origin: The point in the current user space where DanceUI
        ///     places the bottom left corner of the part of the image
        ///     defined by `sourceRect`. The image repeats as needed.
        ///   - sourceRect: A unit space subregion of the image. The default
        ///     is a unit rectangle, which selects the whole image.
        ///   - scale: A factor that you can use to control the image size.
        /// - Returns: A shading instance filled with a tiled image.
        public static func tiledImage(_ image: Image,
                                      origin: CGPoint = .zero,
                                      sourceRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
                                      scale: CGFloat = 1) -> Shading {
            Shading(storage: .tiledImage((image,
                                          origin: origin,
                                          sourceRect: sourceRect,
                                          scale: scale)))
        }
    }
    
    /// Options that affect the rendering of color gradients.
    ///
    /// Use these options to affect how DanceUI manages a gradient that you
    /// create for a ``GraphicsContext/Shading`` instance for use in a ``GraphicsContext``.
    @frozen
    public struct GradientOptions: OptionSet {
        
        /// The type of the elements of an array literal.
        public typealias ArrayLiteralElement = GradientOptions
        
        /// The element type of the option set.
        ///
        /// To inherit all the default implementations from the `OptionSet` protocol,
        /// the `Element` type must be `Self`, the default.
        public typealias Element = GradientOptions
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt32
        
        public let rawValue: UInt32
        
        @inlinable
        public init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        /// An option that repeats the gradient outside its nominal range.
        ///
        /// Use this option to cause the gradient to repeat its pattern in
        /// areas that exceed the bounds of its start and end points.
        /// The repetitions use the same start and end value for each
        /// repetition.
        ///
        /// Without this option or ``GraphicsContext/GradientOptions/mirror``, the gradient stops at
        /// the end of its range. The ``GraphicsContext/GradientOptions/mirror`` option takes precendence if
        /// you set both this one and that one.
        @inlinable
        public static var `repeat`: GradientOptions {
            get { Self(rawValue: 1 << 0) }
        }
        
        /// An option that repeats the gradient outside its nominal range,
        /// reflecting every other instance.
        ///
        /// Use this option to cause the gradient to repeat its pattern in
        /// areas that exceed the bounds of its start and end points.
        /// The repetitions alternately reverse the start and end points,
        /// producing a pattern like `0 -> 1`, `1 -> 0`, `0 -> 1`, and so on.
        ///
        /// Without either this option or ``GraphicsContext/GradientOptions/repeat``, the gradient stops at
        /// the end of its range. This option takes precendence if
        /// you set both this one and ``GraphicsContext/GradientOptions/repeat``.
        @inlinable
        public static var mirror: GradientOptions {
            get { Self(rawValue: 1 << 1) }
        }
        
        /// An option that interpolates between colors in a linear color space.
        @inlinable
        public static var linearColor: GradientOptions {
            get { Self(rawValue: 1 << 2) }
        }
    }
    
    /// An image resolved to a particular environment.
    ///
    /// You resolve an ``Image`` in preparation for drawing it into a context,
    /// either manually by calling ``GraphicsContext/resolve(_:)-9lm48``, or automatically
    /// when calling ``GraphicsContext/draw(_:in:style:)-150qf`` or ``GraphicsContext/draw(_:at:anchor:)-30qle``.
    /// The resolved image takes into account environment values like the
    /// display resolution and current color scheme.
    public struct ResolvedImage {
        
        /// The distance from the top of the image to its baseline.
        ///
        /// If the image has no baseline, this value is equivalent to the
        /// image's height.
        public let baseline: CGFloat
        
        /// An optional shading to fill the image with.
        ///
        /// The value of this property defaults to
        /// ``GraphicsContext/Shading/foreground`` for template images, and
        /// to `nil` otherwise.
        public var shading: Shading?
    }
    
    /// A text view resolved to a particular environment.
    ///
    /// You resolve a ``Text`` view in preparation for drawing it into a context,
    /// either manually by calling ``GraphicsContext/resolve(_:)-3dz10`` or automatically
    /// when calling ``GraphicsContext/draw(_:in:)-1oozi`` or ``GraphicsContext/draw(_:at:anchor:)-1q8i4``.
    /// The resolved text view takes into account environment values like the
    /// display resolution and current color scheme.
    public struct ResolvedText {
        
        /// The shading to fill uncolored text regions with.
        ///
        /// This value defaults to the ``GraphicsContext/Shading/foreground``
        /// shading.
        public var shading: Shading
    }
    
    /// A static sequence of drawing operations that may be drawn
    /// multiple times, preserving their resolution independence.
    ///
    /// You resolve a child view in preparation for drawing it into a context
    /// by calling ``GraphicsContext/resolveSymbol(id:)``. The resolved view takes into account
    /// environment values like the display resolution and current color scheme.
    public struct ResolvedSymbol {
        
    }
    
    /// Provides a Core Graphics context that you can use as a proxy to draw
    /// into this context.
    ///
    /// Use this method to use existing drawing code that relies on
    /// Core Graphics primitives.
    ///
    /// - Parameter content: A closure that receives a
    ///   [CGContext]<https://developer.apple.com/documentation/CoreGraphics/CGContext>
    ///   that you use to perform drawing operations, just like you draw into a
    ///   ``GraphicsContext`` instance. Any filters, blend mode settings, clip
    ///   masks, and other state set before calling `withCGContext(content:)`
    ///   apply to drawing operations in the Core Graphics context as well. Any
    ///   state you set on the Core Graphics context is lost when the closure
    ///   returns. Accessing the Core Graphics context after the closure
    ///   returns produces undefined behavior.
    public func withCGContext(content: (CGContext) throws -> Void) rethrows {
        try storage.cgContextWapper.withCGContext(content: content)
    }
}

@available(iOS 13.0, *)
extension GraphicsContext {
    
    internal enum GradientGeometry {
        
        case axial((CGPoint, CGPoint))
        
        case radial((CGPoint, CGFloat, CGFloat))
        
        case elliptical((CGRect, CGFloat, CGFloat))
        
        case conic((CGPoint, Angle))
    }
    
    internal enum ResolvedShading {
        
        // TODO: _notImplemented enum-case GraphicsContext.ResolvedShading.backdrop
//        case backdrop(Color.Resolved)
        
        case color(Color.Resolved)
        
        /*
         case sRGBColor(RBColor)
         */
        // TODO: _notImplemented enum-case GraphicsContext.ResolvedShading.sRGBColor
//        case sRGBColor
        
        // TODO: _notImplemented enum-case GraphicsContext.ResolvedShading.style
//        case style(_ShapeStyle_Shape.ResolvedStyle)
        
        case gradient((ResolvedGradient, GradientGeometry, GradientOptions))
        
        // TODO: _notImplemented enum-case GraphicsContext.ResolvedShading.tiledImage
//        case tiledImage((GraphicsImage, origin: CGPoint, sourceRect: CGRect, scale: CGFloat))
        
        // TODO: _notImplemented enum-case GraphicsContext.ResolvedShading.levels
//        case levels([ResolvedShading])
    }
}

@available(iOS 13.0, *)
/*
 internal method
 */
extension GraphicsContext {
    
    internal func withPlatformContext(content: () -> ()) -> () {
        storage.cgContextWapper.withPlatformContext(content: content)
    }
    
    internal func fill(_ path: Path, with resolvedShading: ResolvedShading, style: FillStyle = FillStyle()) {
        storage.cgContextWapper.fill(path, with: resolvedShading, style: style)
    }
}
