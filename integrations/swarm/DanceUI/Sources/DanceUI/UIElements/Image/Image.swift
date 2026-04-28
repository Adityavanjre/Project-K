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
internal import DanceUIGraph

/// A view that displays an image.
///
/// Use an `Image` instance when you want to add images to your DanceUI app.
/// You can create images from many sources:
///
/// * Image files in your app's asset library or bundle. Supported types include
/// PNG, JPEG, HEIC, and more.
/// * Instances of platform-specific image types, like
/// [UIImage](https://developer.apple.com/documentation/UIKit/UIImage) and
/// [NSImage](https://developer.apple.com/documentation/AppKit/NSImage).
/// * A bitmap stored in a Core Graphics
///  [cgimage](https://developer.apple.com/documentation/coregraphics/cgimage)
///  instance.
/// * System graphics from the SF Symbols set.
///
/// The following example shows how to load an image from the app's asset
/// library or bundle and scale it to fit within its container:
///
///     Image("Landscape_4")
///         .resizable()
///         .aspectRatio(contentMode: .fit)
///     Text("Water wheel")
///
/// ![An image of a water wheel and its adjoining building, resized to fit the
/// width of an iPhone display. The words Water wheel appear under this
/// image.](Image-1.png)
///
/// You can use methods on the `Image` type as well as
/// standard view modifiers to adjust the size of the image to fit your app's
/// interface. Here, the `Image` type's
/// ``Image/resizable(capInsets:resizingMode:)`` method scales the image to fit
/// the current view. Then, the
/// ``View/aspectRatio(_:contentMode:)-771ow`` view modifier adjusts
/// this resizing behavior to maintain the image's original aspect ratio, rather
/// than scaling the x- and y-axes independently to fill all four sides of the
/// view. The article
/// <doc:Fitting-Images-into-Available-Space> shows how to apply scaling,
/// clipping, and tiling to `Image` instances of different sizes.
///
/// An `Image` is a late-binding token; the system resolves its actual value
/// only when it's about to use the image in an environment.
///
/// ### Making images accessible
///
/// To use an image as a control, use one of the initializers that takes a
/// `label` parameter. This allows the system's accessibility frameworks to use
/// the label as the name of the control for users who use features like
/// VoiceOver. For images that are only present for aesthetic reasons, use an
/// initializer with the `decorative` parameter; the accessibility systems
/// ignore these images.
@frozen
@available(iOS 13.0, *)
public struct Image : Equatable {
    
    @_spi(DanceUICompose)
    public struct Resolved : Equatable {
        
        // 0x0
        @_spi(DanceUICompose)
        public var image: GraphicsImage
        
        internal var label: String?
        
        internal var platformItemImage: UIImage?
        
        internal var decorative: Bool
        
        internal init() {
            image = GraphicsImage()
            label = nil
            platformItemImage = nil
            decorative = false
        }
        
        internal init(image: GraphicsImage, label: String?, platformItemImage: UIImage?, decorative: Bool) {
            self.image = image
            self.label = label
            self.platformItemImage = platformItemImage
            self.decorative = decorative
        }
        
        internal var uiImage: UIImage? {
            if case let .cgImage(cgImage) = image.contents {
                var uiImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: UIImage.Orientation(image.orientation))
                uiImage = uiImage.withRenderingMode(image.maskColor == nil ? .alwaysOriginal : .alwaysTemplate)
                uiImage = uiImage.withAlignmentRectInsets(UIEdgeInsets.zero)
                return uiImage
            }
            return nil
        }
        
        fileprivate struct PlatformRepresentation : Rule {
            
            @Attribute
            fileprivate var image: Resolved
            
            fileprivate typealias Value = PlatformItemList
            
            fileprivate var value: PlatformItemList {
                PlatformItemList(items: [PlatformItemList.Item(text: nil,
                                                               image: image,
                                                               selectionBehavior: PlatformItemList.Item.SelectionBehavior(isMomentary: false,
                                                                                                                          isContainerSelection: false,
                                                                                                                          visualStyle: .plain,
                                                                                                                          keyboardShortcut: nil,
                                                                                                                          onSelect: nil,
                                                                                                                          onDeselect: nil,
                                                                                                                          platformSelector: nil),
                                                               accessibility: nil)])
                
            }
        }
        
    }
    
    internal var provider: AnyImageProviderBox
    
    @_spi(DanceUICompose)
    public func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
        provider.resolve(in: environment, style: style)
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: Image, rhs: Image) -> Bool {
        if lhs.provider === rhs.provider {
            return true
        }
        return lhs.provider.isEqual(to: rhs.provider)
    }
}


@available(iOS 13.0, *)
extension Image: EnvironmentalView {
    
    internal func body(environment: EnvironmentValues) -> some View {
        let resolved = provider.resolve(in: environment, style: nil)
        
        let view = resolved.decodeFeature()
        
        guard !resolved.decorative else {
            return view.accessibility() // empty accessibility
        }
        
        let accessibilityView = view.accessibilityAddTraits(.isImage)
        if let label = resolved.label {
            return accessibilityView.accessibilityLabel(label)
        } else {
            return accessibilityView
        }
    }
}


@available(iOS 13.0, *)
extension Image.Resolved : SizeDependentLeafView {
    
    internal static var animatesSize: Bool { true }
    
    internal func sizeThatFits(in size: _ProposedSize) -> CGSize {
        guard let resizingInfo = image.resizingInfo else {
            if image.orientation.isRotated {
                return CGSize(width: image.unrotatedPixelSize.height / image.scale,
                              height: image.unrotatedPixelSize.width / image.scale)
                
            } else {
                return CGSize(width: image.unrotatedPixelSize.width / image.scale,
                              height: image.unrotatedPixelSize.height / image.scale)
            }
        }
        
        let width: CGFloat = {
            guard let value = size.width else {
                let width = image.orientation.isRotated ? image.unrotatedPixelSize.height : image.unrotatedPixelSize.width
                return width / image.scale
            }
            return max(value,
                       resizingInfo.capInsets.leading + resizingInfo.capInsets.trailing)
        }()
        let height: CGFloat = {
            guard let value = size.height else {
                let height = image.orientation.isRotated ? image.unrotatedPixelSize.width : image.unrotatedPixelSize.height
                return height / image.scale
            }
            return max(value,
                       resizingInfo.capInsets.top + resizingInfo.capInsets.bottom)
        }()
        
        return CGSize(width: width, height: height)
    }
    
    internal func frame(in size: CGSize) -> CGRect {
        if image.resizingInfo != nil {
            return CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        }
        // TODO: _notImplemented GraphicsImage.Contents.vectorGlyph
        if image.orientation.isRotated {
            return CGRect(x: 0,
                          y: 0,
                          width: image.unrotatedPixelSize.height / image.scale,
                          height: image.unrotatedPixelSize.width / image.scale)
        } else {
            return CGRect(x: 0,
                          y: 0,
                          width: image.unrotatedPixelSize.width / image.scale,
                          height: image.unrotatedPixelSize.height / image.scale)
        }
    }
    
    internal func content(size: CGSize) -> (DisplayList.Content.Value, CGRect) {
        (image.animatedResolved == nil ? .image(image) : .animatedImage(image), frame(in: size))
    }
    
    internal func contains(points: [CGPoint], size: CGSize, edgeInsets: EdgeInsets) -> BitVector64 {
        let rect = frame(in: size).inset(by: edgeInsets)
        return BitVector64().contained(points: points, predicate: rect.contains)
    }
    
    @_spi(DanceUICompose)
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        let layoutComputer = Attribute(ResolvedImageLayoutComputer(image: view.value))
        let geometry = Attribute(ResolvedImageChildGeometry(parentSize: inputs.size, childLayoutComputer: layoutComputer))
        
        var newInputs = inputs
        newInputs.size = geometry.size()
        
        let layoutPositionQuery = Attribute(LayoutPositionQuery(parentPosition: inputs.position, localPosition: geometry.origin()))
        newInputs.position = layoutPositionQuery
        
        var outputs = _makeLeafView(view: view, inputs: newInputs)
        outputs.setLayout(inputs) {
            layoutComputer
        }

        newInputs.preferences.requiresPlatformItemList = false
        if newInputs.preferences.requiresPlatformItemList {
            outputs.platformItemList = Attribute(PlatformRepresentation(image: view.value))
        }
        
        return outputs
    }
}

@available(iOS 13.0, *)
internal struct ResolvedImageLayoutEngine: LayoutEngine {
    
    var image: Image.Resolved
    
    init(image: Image.Resolved) {
        self.image = image
    }
    
    func spacing() -> Spacing {
        let edgeBelowText = Spacing.Category.edgeBelowText
        let edgeAboveText = Spacing.Category.edgeAboveText
        
        let minima: [Spacing.Key : CGFloat] = [
            .init(category: edgeBelowText, edge: .top) : 0,
            .init(category: edgeAboveText, edge: .bottom) : 0,
        ]
        return Spacing(minima: minima)
    }
    
    func sizeThatFits(_ size: _ProposedSize) -> CGSize {
        image.sizeThatFits(in: size)
    }
    
    func explicitAlignment(_ key: AlignmentKey, at size: ViewSize) -> CGFloat? {
        let graphicsImage = image.image
        let size = size.value
        guard graphicsImage.resizingInfo == nil else {
            return nil
        }
        if key == VerticalAlignment.lastTextBaseline.key || key == VerticalAlignment.firstTextBaseline.key {
            return size.height
        }
        if key == VerticalAlignment.firstTextLineCenter.key {
            if graphicsImage.orientation.isRotated {
                return size.height + graphicsImage.unrotatedPixelSize.width / graphicsImage.scale * 0.5
            } else {
                return size.height + graphicsImage.unrotatedPixelSize.height / graphicsImage.scale * 0.5
            }
        }
        return nil
    }
    
}

@available(iOS 13.0, *)
private struct ResolvedImageLayoutComputer : StatefulRule {
    
    @Attribute
    fileprivate var image: Image.Resolved

    typealias Value = LayoutComputer
    
    mutating func updateValue() {
        update(to: ResolvedImageLayoutEngine(image: image))
    }
    
}

@available(iOS 13.0, *)
private struct ResolvedImageChildGeometry : Rule {
    
    @Attribute
    fileprivate var parentSize: ViewSize
    
    @Attribute
    fileprivate var childLayoutComputer: LayoutComputer
    
    typealias Value = ViewGeometry
    
    fileprivate var value: ViewGeometry {
        let image = (childLayoutComputer.engine as! LayoutEngineBox<ResolvedImageLayoutEngine>).engine.image
        let parentSize = parentSize
        let frame = image.frame(in: parentSize.value)
        
        return ViewGeometry(origin: .zero,
                            dimensions: ViewDimensions(guideComputer: LayoutComputer.defaultValue,
                                                       size: ViewSize(value: frame.size, _proposal: parentSize.value)))
    }
    
}


@available(iOS 13.0, *)
extension Image {
    
    /// The orientation of an image.
    ///
    /// Many image formats such as JPEG include orientation metadata in the
    /// image data. In other cases, you can specify image orientation
    /// in code. Properly specifying orientation is often important both for
    /// displaying the image and for certain kinds of image processing.
    ///
    /// In DanceUI, you provide an orientation value when initializing an
    /// ``Image`` from an existing
    /// [cgimage](https://developer.apple.com/documentation/coregraphics/cgimage).
    @frozen
    public enum Orientation : UInt8, CaseIterable, Hashable {
        
        /// A value that indicates the original pixel data matches the image's
        /// intended display orientation.
        case up = 0
        
        /// A value that indicates a horizontal flip of the image from the
        /// orientation of its original pixel data.
        case upMirrored = 2
        
        /// A value that indicates a 180° rotation of the image from the
        /// orientation of its original pixel data.
        case down = 6
        
        /// A value that indicates a vertical flip of the image from the
        /// orientation of its original pixel data.
        case downMirrored = 4
        
        /// A value that indicates a 90° counterclockwise rotation from the
        /// orientation of its original pixel data.
        case left = 1
        
        /// A value that indicates a 90° clockwise rotation and horizontal
        /// flip of the image from the orientation of its original pixel
        /// data.
        case leftMirrored = 3
        
        /// A value that indicates a 90° clockwise rotation of the image from
        /// the orientation of its original pixel data.
        case right = 7
        
        /// A value that indicates a 90° counterclockwise rotation and
        /// horizontal flip from the orientation of its original pixel data.
        case rightMirrored = 5
        
        /// A type that can represent a collection of all values of this type.
        public typealias AllCases = [Image.Orientation]
        
        /// The raw type that can be used to represent all values of the conforming
        /// type.
        ///
        /// Every distinct value of the conforming type has a corresponding unique
        /// value of the `RawValue` type, but there may be values of the `RawValue`
        /// type that don't have a corresponding value of the conforming type.
        public typealias RawValue = UInt8
        
        /// A collection of all values of this type.
        public static var allCases: [Image.Orientation] {
            [.up, .upMirrored, .down, .downMirrored,
             .left, .leftMirrored, .right, .rightMirrored]
        }
        
        @inline(__always)
        public var isRotated: Bool {
            switch self {
            case .up, .upMirrored, .down, .downMirrored:
                return false
            case .left, .leftMirrored, .right, .rightMirrored:
                return true
            }
        }
        
        public init(_ mode: UIImage.Orientation) {
            switch mode {
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
}

@available(iOS 13.0, *)
extension Image.Orientation : RawRepresentable {
    
    internal var mirrored: Image.Orientation {
        self
    }
    
    internal init?(exifValue: Int) {
        switch exifValue {
        case 1: self = .up
        case 2: self = .upMirrored
        case 3: self = .down
        case 4: self = .downMirrored
        case 5: self = .leftMirrored
        case 6: self = .right
        case 7: self = .rightMirrored
        case 8: self = .left
        default: return nil
        }
    }
}


@available(iOS 13.0, *)
extension Image {
    
    /// A type that indicates how DanceUI renders images.
    public enum TemplateRenderingMode : Hashable {
        
        /// A mode that renders all non-transparent pixels as the foreground
        /// color.
        case template
        
        /// A mode that renders pixels of bitmap images as-is.
        ///
        /// For system images created from the SF Symbol set, multicolor symbols
        /// respect the current foreground and accent colors.
        case original
        
        @usableFromInline
        internal init(_ mode: UIImage.RenderingMode) {
            switch (mode) {
            case .alwaysTemplate:
                self = .template
            case .alwaysOriginal:
                self = .original
            case .automatic:
                self = .original
            @unknown default:
                self = .original
            }
        }
    }
    
    /// A scale to apply to vector images relative to text.
    ///
    /// Use this type with the ``View/imageScale(_:)`` modifier, or the
    /// ``EnvironmentValues/imageScale`` environment key, to set the image scale.
    ///
    /// The following example shows the three `Scale` values as applied to
    /// a system symbol image, each set against a text view:
    ///
    ///     HStack { Image(systemName: "swift").imageScale(.small); Text("Small") }
    ///     HStack { Image(systemName: "swift").imageScale(.medium); Text("Medium") }
    ///     HStack { Image(systemName: "swift").imageScale(.large); Text("Large") }
    ///
    /// ![Vertically arranged text views that read Small, Medium, and
    /// Large. On the left of each view is a system image that uses the Swift symbol.
    /// The image next to the Small text is slightly smaller than the text.
    /// The image next to the Medium text matches the size of the text. The
    /// image next to the Large text is larger than the
    /// text.](DanceUI-EnvironmentAdditions-Image-scale.png)
    ///
    @available(macOS 11.0, *)
    public enum Scale : Hashable {
        
        /// A scale that produces small images.
        case small
        
        /// A scale that produces medium-sized images.
        case medium
        
        /// A scale that produces large images.
        case large
    }
}

@available(iOS 13.0, *)
extension Image {
    
    /// The level of quality for rendering an image that requires interpolation,
    /// such as a scaled image.
    ///
    /// The ``Image/interpolation(_:)`` modifier specifies the interpolation
    /// behavior when using the ``Image/resizable(capInsets:resizingMode:)``
    /// modifier on an ``Image``. Use this behavior to prioritize rendering
    /// performance or image quality.
    public enum Interpolation : Hashable {
        
        /// A value that indicates DanceUI doesn't interpolate image data.
        case none

        /// A value that indicates a low level of interpolation quality, which may
        /// speed up image rendering.
        case low

        /// A value that indicates a medium level of interpolation quality,
        /// between the low- and high-quality values.
        case medium

        /// A value that indicates a high level of interpolation quality, which
        /// may slow down image rendering.
        case high
        
        @usableFromInline
        internal init?(_ interpolation: CGInterpolationQuality) {
            switch interpolation {
            case .low:
                self = .low
            case .medium:
                self = .medium
            case .high:
                self = .high
            case .none:
                self = .none
            case .default:
                return nil
            @unknown default:
                return nil
            }
        }
        
        var interpolationQuality: CGInterpolationQuality {
            switch self {
            case .low:
                return .low
            case .medium:
                return .medium
            case .high:
                return .high
            case .none:
                return .none
            }
        }
    }
}

@available(iOS 13.0, *)
extension Image {
    
    fileprivate struct InterpolationProvider : _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var interpolation: Interpolation
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            resolved.image.interpolation = interpolation
            return resolved
        }
        
        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    fileprivate struct AntialiasedProvider : _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var isAntialiased: Bool
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            resolved.image.isAntialiased = isAntialiased
            return resolved
        }
        
        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    /// Specifies the current level of quality for rendering an
    /// image that requires interpolation.
    ///
    /// See the article <doc:Fitting-Images-into-Available-Space> for examples
    /// of using `interpolation(_:)` when scaling an ``Image``.
    /// - Parameter interpolation: The quality level, expressed as a value of
    /// the `Interpolation` type, that DanceUI applies when interpolating
    /// an image.
    /// - Returns: An image with the given interpolation value set.
    public func interpolation(_ interpolation: Interpolation) -> Image {
        Image(provider: ImageProviderBox(InterpolationProvider(base: self,
                                                               interpolation: interpolation)))
    }
    
    /// Specifies whether DanceUI applies antialiasing when rendering
    /// the image.
    /// - Parameter isAntialiased: A Boolean value that specifies whether to
    /// allow antialiasing. Pass `true` to allow antialising, `false` otherwise.
    /// - Returns: An image with the antialiasing behavior set.
    public func antialiased(_ isAntialiased: Bool) -> Image {
        Image(provider: ImageProviderBox(AntialiasedProvider(base: self,
                                                             isAntialiased: isAntialiased)))
    }
}

@available(iOS 13.0, *)
extension Image {
    
    fileprivate struct RenderingModeProvider : _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var renderingMode: TemplateRenderingMode?
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            resolved.image.maskColor = environment.imageMaskColor(renderingMode: renderingMode)
            return resolved
        }

        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    /// Indicates whether DanceUI renders an image as-is, or
    /// by using a different mode.
    ///
    /// The ``TemplateRenderingMode`` enumeration has two cases:
    /// ``TemplateRenderingMode/original`` and ``TemplateRenderingMode/template``.
    /// The original mode renders pixels as they appear in the original source
    /// image. Template mode renders all nontransparent pixels as the
    /// foreground color, which you can use for purposes like creating image
    /// masks.
    ///
    /// The following example shows both rendering modes, as applied to an icon
    /// image of a green circle with darker green border:
    ///
    ///     Image("dot_green")
    ///         .renderingMode(.original)
    ///     Image("dot_green")
    ///         .renderingMode(.template)
    ///
    /// ![Two identically-sized circle images. The circle on top is green
    /// with a darker green border. The circle at the bottom is a solid color,
    /// either white on a black background, or black on a white background,
    /// depending on the system's current dark mode
    /// setting.](DanceUI-Image-TemplateRenderingMode-dots.png)
    ///
    /// You also use `renderingMode` to produce multicolored system graphics
    /// from the SF Symbols set. Use the ``TemplateRenderingMode/original``
    /// mode to apply a foreground color to all parts of the symbol except
    /// those that have a distinct color in the graphic. The following
    /// example shows three uses of the `person.crop.circle.badge.plus` symbol
    /// to achieve different effects:
    ///
    /// * A default appearance with no foreground color or template rendering
    /// mode specified. The symbol appears all black in light mode, and all
    /// white in Dark Mode.
    /// * The multicolor behavior achieved by using `original` template
    /// rendering mode, along with a blue foreground color. This mode causes the
    /// graphic to override the foreground color for distinctive parts of the
    /// image, in this case the plus icon.
    /// * A single-color template behavior achieved by using `template`
    /// rendering mode with a blue foreground color. This mode applies the
    /// foreground color to the entire image, regardless of the user's Appearance preferences.
    ///
    ///```swift
    ///HStack {
    ///    Image(systemName: "person.crop.circle.badge.plus")
    ///    Image(systemName: "person.crop.circle.badge.plus")
    ///        .renderingMode(.original)
    ///        .foregroundColor(.blue)
    ///    Image(systemName: "person.crop.circle.badge.plus")
    ///        .renderingMode(.template)
    ///        .foregroundColor(.blue)
    ///}
    ///.font(.largeTitle)
    ///```
    ///
    /// ![A horizontal layout of three versions of the same symbol: a person
    /// icon in a circle with a plus icon overlaid at the bottom left. Each
    /// applies a diffent set of colors based on its rendering mode, as
    /// described in the preceding
    /// list.](DanceUI-Image-TemplateRenderingMode-sfsymbols.png)
    ///
    /// Use the SF Symbols app to find system images that offer the multicolor
    /// feature. Keep in mind that some multicolor symbols use both the
    /// foreground and accent colors.
    ///
    /// - Parameter renderingMode: The mode DanceUI uses to render images.
    /// - Returns: A modified ``Image``.
    public func renderingMode(_ renderingMode: TemplateRenderingMode?) -> Image {
        .init(provider: ImageProviderBox(RenderingModeProvider(base: self, renderingMode: renderingMode)))
    }
}

@available(iOS 13.0, *)
extension Image {
    
    /// Creates a DanceUI image from a UIKit image instance.
    /// - Parameter uiImage: The UIKit image to wrap with a DanceUI ``Image``
    /// instance.
    public init(uiImage: UIImage) {
        provider = ImageProviderBox(uiImage)
    }
}

@available(iOS 13.0, *)
extension UIImage: _ImageProvider {
    
    private var resizingInfo: Image.ResizingInfo? {
        guard capInsets != .zero else {
            return nil
        }
        return Image.ResizingInfo(capInsets: EdgeInsets(capInsets),
                                  mode: Image.ResizingMode(self.resizingMode))
    }
    
    internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
        let contents: GraphicsImage.Contents?
        
        if let cgImage = self.cgImage {
            contents = .cgImage(cgImage)
        } else {
            contents = .none
        } // io surface is missing
        
        let resizingInfo = self.resizingInfo
        let renderingMode = Image.TemplateRenderingMode(self.renderingMode)
        let maskColor = environment.imageMaskColor(renderingMode: renderingMode)
        let orientation = Image.Orientation(imageOrientation)
        let size = orientation.isRotated ? CGSize(width: self.size.height, height: self.size.width) : self.size
        let resolved = Image.Resolved(image: GraphicsImage(contents: contents,
                                                           scale: self.scale,
                                                           unrotatedPixelSize: CGSize(width: size.width * self.scale,
                                                                                      height: size.height * self.scale),
                                                           orientation: orientation,
                                                           maskColor: maskColor,
                                                           resizingInfo: resizingInfo,
                                                           isAntialiased: true,
                                                           interpolation: .high),
                                      label: self.accessibilityLabel,
                                      platformItemImage: self,
                                      decorative: true)
        return Image.RedactedImageProvider(resolved: resolved).resolve(in: environment, style: style)
    }
    
    internal var staticImage: UIImage? {
        self
    }
    
}

@available(iOS 13.0, *)
extension Image {
    
    fileprivate struct CGImageProvider: _ImageProvider {
        
        fileprivate var image: CGImage
        
        fileprivate var scale: CGFloat
        
        fileprivate var orientation: Orientation
        
        fileprivate var label: Text?
        
        fileprivate var decorative: Bool
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            let labelString = label?.resolveText(in: environment)
            let size = CGSize(width: image.width, height: image.height)
            let maskColor = environment.imageMaskColor(renderingMode: nil)
            let resolved = Resolved(image: GraphicsImage(contents: .cgImage(image),
                                                         scale: scale,
                                                         unrotatedPixelSize: CGSize(width: size.width,
                                                                                    height: size.height),
                                                         orientation: orientation,
                                                         maskColor: maskColor,
                                                         resizingInfo: nil,
                                                         isAntialiased: true,
                                                         interpolation: .high),
                                    label: labelString,
                                    platformItemImage: nil,
                                    decorative: decorative)
            return RedactedImageProvider(resolved: resolved).resolve(in: environment, style: style)
        }
        
        internal var staticImage: UIImage? {
            UIImage(cgImage: self.image, scale: scale, orientation: .init(orientation))
        }
    }
    
    /// Creates a labeled image based on a Core Graphics image instance, usable
    /// as content for controls.
    ///
    /// - Parameters:
    ///   - cgImage: The base graphical image.
    ///   - scale: The scale factor for the image,
    ///     with a value like `1.0`, `2.0`, or `3.0`.
    ///   - orientation: The orientation of the image. The default is
    ///     ``Image/Orientation/up``.
    ///   - label: The label associated with the image. DanceUI uses the label
    ///     for accessibility.
    public init(_ cgImage: CGImage, scale: CGFloat, orientation: Orientation = .up, label: Text) {
        provider = ImageProviderBox(CGImageProvider(image: cgImage,
                                                    scale: scale,
                                                    orientation: orientation,
                                                    label: label,
                                                    decorative: false))
    }
    
    /// Creates an unlabeled, decorative image based on a Core Graphics image
    /// instance.
    ///
    /// DanceUI ignores this image for accessibility purposes.
    ///
    /// - Parameters:
    ///   - cgImage: The base graphical image.
    ///   - scale: The scale factor for the image,
    ///     with a value like `1.0`, `2.0`, or `3.0`.
    ///   - orientation: The orientation of the image. The default is
    ///     ``Image/Orientation/up``.
    public init(decorative cgImage: CGImage, scale: CGFloat, orientation: Orientation = .up) {
        provider = ImageProviderBox(CGImageProvider(image: cgImage,
                                                    scale: scale,
                                                    orientation: orientation,
                                                    label: nil,
                                                    decorative: true))
    }
}

@available(iOS 13.0, *)
extension Image {
    
    // The modes that DanceUI uses to resize an image to fit within
    /// its containing view.
    public enum ResizingMode : Hashable {
        
        // 0
        /// A mode to repeat the image at its original size, as many
        /// times as necessary to fill the available space.
        case tile
        
        // 1
        /// A mode to enlarge or reduce the size of an image so that it
        /// fills the available space.
        case stretch
        
        @usableFromInline
        internal init(_ mode: UIImage.ResizingMode) {
            switch mode {
            case .tile:
                self = .tile
            case .stretch:
                self = .stretch
            @unknown default:
                _danceuiFatalError()
            }
        }
    }
    
    internal struct ResizingInfo: Equatable {
        
        @ProxyCodable
        internal var capInsets: EdgeInsets
        
        @ProxyCodable
        internal var mode: ResizingMode
        
        internal init(capInsets: EdgeInsets, mode: ResizingMode) {
            self.capInsets = capInsets
            self.mode = mode
        }
        
        internal static func == (lhs: Image.ResizingInfo, rhs: Image.ResizingInfo) -> Bool {
            lhs.capInsets == rhs.capInsets &&
            lhs.mode == rhs.mode
        }
        
        internal static var resizable: ResizingInfo {
            .init(capInsets: EdgeInsets.zero, mode: .stretch)
        }
    }
    
    fileprivate struct ResizableProvider : _ImageProvider {
        
        fileprivate var base: Image
        
        fileprivate var capInsets: EdgeInsets
        
        fileprivate var resizingMode: ResizingMode
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            var resolved = base.provider.resolve(in: environment, style: style)
            resolved.image.resizingInfo = ResizingInfo(capInsets: capInsets, mode: resizingMode)
            return resolved
        }

        internal var staticImage: UIImage? {
            base.provider.staticImage
        }
    }
    
    /// Sets the mode by which DanceUI resizes an image to fit its space.
    /// - Parameters:
    ///   - capInsets: Inset values that indicate a portion of the image that
    ///   DanceUI doesn't resize.
    ///   - resizingMode: The mode by which DanceUI resizes the image.
    /// - Returns: An image, with the new resizing behavior set.
    public func resizable(capInsets: EdgeInsets = EdgeInsets(), resizingMode: ResizingMode = .stretch) -> Image {
        Image(provider: ImageProviderBox(ResizableProvider(base: self,
                                                           capInsets: capInsets,
                                                           resizingMode: resizingMode)))
    }
}

@available(iOS 13.0, *)
private struct ImageCacheKey: Hashable {
    
    fileprivate var name: String
    
    fileprivate var scale: CGFloat
    
    fileprivate var layoutDirection: LayoutDirection
    
    fileprivate var colorScheme: ColorScheme
    
    fileprivate var contrast: ColorSchemeContrast
    
    fileprivate var gamut: DisplayGamut
    
    fileprivate var location: Image.Location
    
}

@available(iOS 13.0, *)
fileprivate struct NamedImageInfo {
    
    fileprivate var cgImage: CGImage
    
    fileprivate var scale: CGFloat
    
    fileprivate var orientation: Image.Orientation
    
    fileprivate var unrotatedPixelSize: CGSize
    
    fileprivate var renderingMode: Image.TemplateRenderingMode?
    
    fileprivate var resizingInfo: Image.ResizingInfo?
    
}

@available(iOS 13.0, *)
fileprivate struct VectorCacheKey {
    
    fileprivate var name: String
    
    fileprivate var scale: CGFloat
    
    fileprivate var layoutDirection: LayoutDirection
    
    fileprivate var colorScheme: ColorScheme
    
    fileprivate let colorSchemeContrast: ColorSchemeContrast
    
    fileprivate var weight: Font.Weight
    
    
    fileprivate var pointSize: CGFloat
    
    fileprivate var location: Image.Location
    
}

@available(iOS 13.0, *)
fileprivate struct VectorImageInfo {
    
    
    fileprivate var orientation: Image.Orientation
    
}

@available(iOS 13.0, *)
extension Image {
    
    public static var _mainNamedBundle: Bundle?
    
    @inline(__always)
    internal static var mainBundle: Bundle { _mainNamedBundle ?? Bundle.main }
    
    internal enum Location : Hashable {
        
        case bundle(Bundle)
        
        case system
        
        case privateSystem
        
        @inlinable
        internal var bundleOrNil: Bundle? {
            guard case let .bundle(bundle) = self else {
                return nil
            }
            return bundle
        }
        
    }
    
    fileprivate struct NamedImageProvider : _ImageProvider {
        
        fileprivate var name: String
        
        fileprivate var location: Location
        
        fileprivate var backupLocation: Location?
        
        fileprivate var label: Text?
        
        fileprivate var decorative: Bool
        
        internal func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            
            let bundle = location.bundleOrNil ?? Image._mainNamedBundle
            
            let location: Location = bundle.map {
                return .bundle($0)
            } ?? .system
            
            let cacheKey = ImageCacheKey(name: name, 
                                         scale: environment.displayScale,
                                         layoutDirection: environment.layoutDirection,
                                         colorScheme: environment.colorScheme,
                                         contrast: environment.colorSchemeContrast,
                                         gamut: environment.displayGamut, location: location)
            
            func getUIImage(name: String, bundle: Bundle?, key: ImageCacheKey) -> UIImage {
                
                struct Static {
                    
                    static var cache: LRUCache<ImageCacheKey, UIImage> = LRUCache(totalWeight: 20)
                }
                                
                if let cached = Static.cache.value(forKey: key) {
                    return cached
                }
                
                guard let uiImage = UIImage(named: name, in: bundle, compatibleWith: nil) else {
                    // Error Log: 这里报 error 的话没办法体现在源码上，所以把检查逻辑放到了 Image.init 里面
                    return resolveError(in: environment)
                }
                Static.cache.insertValue(uiImage, forKey: key)
                
                return uiImage
            }
            
            let uiImage = getUIImage(name: name, bundle: bundle, key: cacheKey)
            
            var resolved = uiImage.resolve(in: environment, style: style)
            
            resolved.label = label?.resolveText(in: environment)
            resolved.decorative = decorative
            
            return RedactedImageProvider(resolved: resolved).resolve(in: environment, style: style)
//            if environment.shouldRedactContent {
//                var redacted = RedactedImageProvider(resolved: resolved).resolve(in: environment, style: style)
//                redacted.image.unrotatedPixelSize = resolved.image.unrotatedPixelSize
//                redacted.image.scale = resolved.image.scale
//                redacted.image.resizingInfo = resolved.image.resizingInfo
//                redacted.label = label?.resolveText(in: environment)
//                redacted.decorative = decorative
//                return redacted
//            }
//            return resolved
        }
        
        fileprivate func resolveError(in: EnvironmentValues) -> UIImage {
            // 这里和汇编对不上，不要参考
            UIImage()
        }
        internal var staticImage: UIImage? {
            let bundle = location.bundleOrNil ?? Image._mainNamedBundle
            return UIImage(named: name, in: bundle, compatibleWith: nil)
        }
    }
}

@available(iOS 13.0, *)
extension Image {
    
    fileprivate struct RedactedImageProvider : _ImageProvider, Equatable {
        
        private let resolved: Image.Resolved?
        
        internal init(resolved: Image.Resolved?) {
            self.resolved = resolved
        }
        
        fileprivate func resolve(in environment: EnvironmentValues, style: Text.Style?) -> Image.Resolved {
            guard let resolved = resolved else {
                return Image.Resolved(image: GraphicsImage(contents: .color(Color.foreground.opacity(0.16).resolvePaint(in: environment)),
                                                           scale: 1.0,
                                                           unrotatedPixelSize: CGSize(width: 1.0, height: 1.0),
                                                           orientation: .up,
                                                           maskColor: nil,
                                                           resizingInfo: ResizingInfo.resizable,
                                                           isAntialiased: true,
                                                           interpolation: .none),
                                      label: nil,
                                      platformItemImage: nil,
                                      decorative: true)
            }
            guard environment.shouldRedactContent else {
                return resolved
            }
            
            return Image.Resolved(image: GraphicsImage(contents: .color(Color.foreground.opacity(0.16).resolvePaint(in: environment)),
                                                       scale: resolved.image.scale,
                                                       unrotatedPixelSize: resolved.image.unrotatedPixelSize,
                                                       orientation: resolved.image.orientation,
                                                       maskColor: resolved.image.maskColor,
                                                       resizingInfo: resolved.image.resizingInfo,
                                                       isAntialiased: resolved.image.isAntialiased,
                                                       interpolation: resolved.image.interpolation),
                                  label: resolved.label,
                                  platformItemImage: resolved.platformItemImage,
                                  decorative: resolved.decorative)
        }
        
        fileprivate var staticImage: UIImage? {
            nil
        }
    }
    
    public static var redacted : Image {
        .init(provider: ImageProviderBox(RedactedImageProvider(resolved: nil)))
    }
}


@available(iOS 13.0, *)
extension Image {
    
    /// Creates a labeled image that you can use as content for controls.
    ///
    /// - Parameters:
    ///   - name: The name of the image resource to lookup, as well as the
    ///     localization key with which to label the image.
    ///   - bundle: The bundle to search for the image resource and localization
    ///     content. If `nil`, DanceUI uses the main `Bundle`. Defaults to `nil`.
    public init(_ name: String, bundle: Bundle? = nil) {
        
        /// DanceUIAddition
#if DEBUG || DANCE_UI_INHOUSE
        checkImage(name, bundle: bundle)
#endif
        
        let location: Location = .bundle(bundle ?? Image.mainBundle)
        
        provider = ImageProviderBox(NamedImageProvider(name: name,
                                                       location: location,
                                                       backupLocation: .privateSystem,
                                                       label: Text(name),
                                                       decorative: false))
    }
    
    /// Creates a labeled image that you can use as content for controls, with
    /// the specified label.
    ///
    /// - Parameters:
    ///   - name: The name of the image resource to lookup
    ///   - bundle: The bundle to search for the image resource. If `nil`,
    ///     DanceUI uses the main `Bundle`. Defaults to `nil`.
    ///   - label: The label associated with the image. DanceUI uses the label
    ///     for accessibility.
    public init(_ name: String, bundle: Bundle? = nil, label: Text) {
        
#if DEBUG || DANCE_UI_INHOUSE
        checkImage(name, bundle: bundle)
#endif
        
        let location: Location = .bundle(bundle ?? Image.mainBundle)
        
        provider = ImageProviderBox(NamedImageProvider(name: name,
                                                       location: location,
                                                       backupLocation: .privateSystem,
                                                       label: label,
                                                       decorative: false))
    }
    
    /// Creates an unlabeled, decorative image.
    ///
    /// DanceUI ignores this image for accessibility purposes.
    ///
    /// - Parameters:
    ///   - name: The name of the image resource to lookup
    ///   - bundle: The bundle to search for the image resource. If `nil`,
    ///     DanceUI uses the main `Bundle`. Defaults to `nil`.
    public init(decorative name: String, bundle: Bundle? = nil) {
        
#if DEBUG || DANCE_UI_INHOUSE
        checkImage(name, bundle: bundle)
#endif
        
        let location: Location = .bundle(bundle ?? Image.mainBundle)
        
        provider = ImageProviderBox(NamedImageProvider(name: name,
                                                       location: location,
                                                       backupLocation: .privateSystem,
                                                       label: nil,
                                                       decorative: true))
    }
    
    internal init(systemName: String) {
        provider = ImageProviderBox(NamedImageProvider(name: systemName,
                                                       location: .bundle(Image.mainBundle),
                                                       backupLocation: .privateSystem,
                                                       label: Text(systemName),
                                                       decorative: false))
    }
    
    internal init(_internalSystemName systemName: String) {
        provider = ImageProviderBox(NamedImageProvider(name: systemName,
                                                       location: .bundle(Image.mainBundle),
                                                       backupLocation: .system,
                                                       label: Text(systemName),
                                                       decorative: false))
    }
}

@available(iOS 13.0, *)
extension Image {
    @available(*, deprecated, message: "Use .renderingMode(.original)")
    internal init(_systemName systemName: String, colorPalette: [Color]? = nil) {
        let image = Image(systemName: systemName)
        provider = ImageProviderBox(RenderingModeProvider(base: image, renderingMode: .original))
    }
    
    @available(*, deprecated, message: "Use .renderingMode(.original)")
    internal init(_internalSystemName systemName: String, colorPalette: [Color]? = nil) {
        let image = Image(_internalSystemName: systemName)
        provider = ImageProviderBox(RenderingModeProvider(base: image, renderingMode: .original))
    }
}

// MARK: DanceUI addition

#if DEBUG || DANCE_UI_INHOUSE
@available(iOS 13.0, *)
private struct CheckImageManager {
    
    private static var cache = [Key:Bool]()
    
    private struct Key: Hashable {
        let name: String
        let bundle: String?
    }
    
    fileprivate static func hasImage(_ name: String, bundle: Bundle?) -> Bool {
        let imageBundle = bundle ?? Image.mainBundle
        let key = Key(name: name, bundle: imageBundle.bundleIdentifier)
        
        let hasImage: Bool
        if let _hasImage = cache[key] {
            hasImage = _hasImage
        } else {
            hasImage = (UIImage(named: name, in: imageBundle, compatibleWith: nil) != nil)
            cache[key] = hasImage
        }
        return hasImage
    }
}

@available(iOS 13.0, *)
private func checkImage(_ name: String, bundle: Bundle?) {
    if !CheckImageManager.hasImage(name, bundle: bundle) {
        runtimeIssue(type: .warning, "No image named \"%@\" in asset catalog.", name)
    }
}

#endif

@available(iOS 13.0, *)
extension Image {
    
    public var uiImage: UIImage? {
        if let image = provider.staticImage {
            return image
        }
        let resolved = provider.resolve(in: EnvironmentValues(), style: nil)
        if resolved.label != nil {
            if let uiImage = resolved.platformItemImage {
                return uiImage
            }
            return resolved.image.makePlatformImage(fixedSymbolConfiguration: false, flattenMaskColor: false)
        }
        return nil
    }
}
