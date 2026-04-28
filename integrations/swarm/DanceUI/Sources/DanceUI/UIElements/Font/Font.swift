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

import CoreText
import MyShims

// MARK: - Font

/// An environment-dependent font.
///
/// The system resolves a font's value at the time it uses the font in a given
/// environment because ``Font`` is a late-binding token.
@frozen
@available(iOS 13.0, *)
public struct Font : Hashable {
    
    @usableFromInline
    internal var provider: AnyFontBox
    
    @inline(__always)
    internal init(storage: AnyFontBox) {
        provider = storage
    }
    
    @inline(__always)
    internal init<P: FontProvider>(provider: P) {
        self.init(storage: FontBox(provider: provider))
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    @inline(__always)
    public static func ==(lhs: Font, rhs: Font) -> Bool {
        lhs.provider == rhs.provider
    }
}

@available(iOS 13.0, *)

extension Font {
    
    /// Create a font with the large title text style.
    public static let largeTitle: Font = .init(provider: TextStyleProvider(textStyle: .largeTitle, design: .default))
    
    /// Create a font with the title text style.
    public static let title: Font = .init(provider: TextStyleProvider(textStyle: .title, design: .default))
    
    /// Create a font with the title2 text style.
    public static let title2: Font = .init(provider: TextStyleProvider(textStyle: .title2, design: .default))
    
    /// Create a font with the title3 text style.
    public static let title3: Font = .init(provider: TextStyleProvider(textStyle: .title3, design: .default))
    
    /// Create a font with the headline text style.
    public static let headline: Font = .init(provider: TextStyleProvider(textStyle: .headline, design: .default))
    
    /// Create a font with the subheadline text style.
    public static let subheadline: Font = .init(provider: TextStyleProvider(textStyle: .subheadline, design: .default))
    
    /// Create a font with the body text style.
    public static let body: Font = .init(provider: TextStyleProvider(textStyle: .body, design: .default))
    
    /// Create a font with the callout text style.
    public static let callout: Font = .init(provider: TextStyleProvider(textStyle: .callout, design: .default))
    
    /// Create a font with the footnote text style.
    public static let footnote: Font = .init(provider: TextStyleProvider(textStyle: .footnote, design: .default))
    
    /// Create a font with the caption text style.
    public static let caption: Font = .init(provider: TextStyleProvider(textStyle: .caption, design: .default))
    
    /// Create a font with the caption2 text style.
    public static let caption2: Font = .init(provider: TextStyleProvider(textStyle: .caption2, design: .default))
    
    /// Create a system font with the given `style`.
    public static func system(_ style: Font.TextStyle, design: Font.Design = .default) -> Font {
        return Font(provider: TextStyleProvider(textStyle: style, design: design))
    }
    
    /// Create a system font with the given `size`, `weight` and `design`.
    public static func system(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        return Font(provider: SystemProvider(size: size, weight: weight, design: design))
    }
    
    /// Use this function to create a system font by specifying the text style,
    /// a type design, and weight together. The following styles the text with
    /// a system font in ``Font/TextStyle/body`` text style and
    /// ``Font/Weight/semibold`` weight:
    ///
    ///     Text("Hello").font(.system(.body, weight: .semibold))
    ///
    /// While the following styles the text as ``Font/TextStyle/caption`` text
    /// style with ``Font/Weight/bold`` weight, and applies a `serif`
    /// ``Font/Design`` to the system font:
    ///
    ///     Text("Hello").font(.system(.body, design: .serif, weight: .bold))
    ///
    /// Both `design` and `weight` can be optional. When you do not provide a
    /// `design` or `weigght`, the system can pick one based on the current
    /// context, which may not be ``Font/Weight/regular`` or
    /// ``Font/Design/default`` in certain context. The following example styles
    /// the text as ``Font/TextStyle/body`` system font in ``Font/Weight/bold``,
    /// while its design can depend on the current context:
    ///
    ///     Text("Hello").font(.system(.body, weight: .bold))
    public static func system(_ style: Font.TextStyle, design: Font.Design? = nil, weight: Font.Weight? = nil) -> Font {
        return Font(provider: TextStyleProvider(textStyle: style, design: design ?? .default)).weight(weight ?? .regular)
    }
    
    /// Create a custom font with the given `name` and `size`.
    public static func custom(_ name: String, size: CGFloat) -> Font {
        Font(provider: NamedProvider(name: name, size: size, textStyle: .body))
    }
    
    /// Create a custom font with the given `name` and `size` that scales
    /// relative to the given `textStyle`.
    public static func custom(_ name: String, size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        Font(provider: NamedProvider(name: name, size: size, textStyle: textStyle))
    }
    
    /// Create a custom font with the given `name` and a fixed `size` that does
    /// not scale with Dynamic Type.
    public static func custom(_ name: String, fixedSize: CGFloat) -> Font {
        Font(provider: NamedProvider(name: name, size: fixedSize))
    }
    
    /// Create a custom font with the given CTFont.
    public init(_ font: CTFont) {
        self.init(provider: PlatformFontProvider(ctFont: font))
    }
    
    fileprivate struct PlatformFontProvider: FontProvider {
        
        private let font: CTFont
        
        fileprivate init(ctFont: CTFont) {
            font = ctFont
        }
        
        internal func resolve(in context: Context) -> CTFontDescriptor {
            CTFontCopyFontDescriptor(font)
        }
        
        internal static func == (lhs: PlatformFontProvider, rhs: PlatformFontProvider) -> Bool {
            return lhs.font === rhs.font
        }
        
        internal func hash(into hasher: inout Hasher) {
            font.hash(into: &hasher)
        }
    }
    
    fileprivate struct NamedProvider: FontProvider {
        
        private let name: String
        
        private let size: CGFloat
        
        private let textStyle: Font.TextStyle?
        
        fileprivate init(name: String, size: CGFloat, textStyle: Font.TextStyle? = nil) {
            self.name = name
            self.size = size
            self.textStyle = textStyle
        }
        
        internal func resolve(in context: Font.Context) -> CTFontDescriptor {
            context.resolveCustomFont(name: name,
                                      size: size,
                                      textStyle: self.textStyle,
                                      sizeCategory: context.sizeCategory)
        }
        
        internal static func == (lhs: NamedProvider, rhs: NamedProvider) -> Bool {
            lhs.name == rhs.name && lhs.size == rhs.size && lhs.textStyle == rhs.textStyle
        }
        
        internal func hash(into hasher: inout Hasher) {
            name.hash(into: &hasher)
            size.hash(into: &hasher)
            textStyle.hash(into: &hasher)
        }
    }
    
    fileprivate struct SystemProvider: FontProvider {
        
        private let size: CGFloat
        
        private let weight: Weight
        
        private let design: Design
        
        fileprivate init(size: CGFloat, weight: Weight, design: Design) {
            self.size = size
            self.weight = weight
            self.design = design
        }
        
        internal func resolve(in context: Context) -> CTFontDescriptor {
            context.resolveSystemFont(size: size, weight: weight, design: design, sizeCategory: context.sizeCategory)
        }
        
    }
    
    internal struct TextStyleProvider: FontProvider {
        
        private let textStyle: TextStyle
        
        private let design: Design
        
        private let weight: Weight?
        
        @inline(__always)
        internal init(textStyle: TextStyle, design: Design, weight: Weight? = nil) {
            self.textStyle = textStyle
            self.design = design
            self.weight = weight
        }
        
        internal func resolve(in context: Context) -> CTFontDescriptor {
            context.resolveTextStyleFont(textStyle: textStyle, design: design, weight: weight, sizeCategory: context.sizeCategory)
        }
        
    }
}

@available(iOS 13.0, *)

extension Font {
    
    /// Adds italics to the font.
    public func italic() -> Font {
        return Font(provider: StaticModifierProvider<ItalicModifier>(base: self))
    }
    
    /// Adjusts the font to enable all small capitals.
    ///
    /// See ``Font/lowercaseSmallCaps()`` and ``Font/uppercaseSmallCaps()`` for
    /// more details.
    public func smallCaps() -> Font {
        let intermediate = Font(provider: ModifierProvider(base: self, modifier: LowercaseSmallCapsModifier()))
        let final = Font(provider: ModifierProvider(base: intermediate, modifier: UppercaseSmallCapsModifier()))
        return final
    }
    
    /// Adjusts the font to enable lowercase small capitals.
    ///
    /// This function turns lowercase characters into small capitals for the
    /// font. It is generally used for display lines set in large and small
    /// caps, such as titles. It may include forms related to small capitals,
    /// such as old-style figures.
    public func lowercaseSmallCaps() -> Font {
        return Font(provider: ModifierProvider(base: self, modifier: LowercaseSmallCapsModifier()))
    }
    
    /// Adjusts the font to enable uppercase small capitals.
    ///
    /// This feature turns capital characters into small capitals. It is
    /// generally used for words which would otherwise be set in all caps, such
    /// as acronyms, but which are desired in small-cap form to avoid disrupting
    /// the flow of text.
    public func uppercaseSmallCaps() -> Font {
        return Font(provider: ModifierProvider(base: self, modifier: UppercaseSmallCapsModifier()))
    }
    
    /// Returns a modified font that uses fixed-width digits, while leaving
    /// other characters proportionally spaced.
    ///
    /// This modifier only affects numeric characters, and leaves all other
    /// characters unchanged. If the base font doesn't support fixed-width,
    /// or _monospace_ digits, the font remains unchanged.
    ///
    /// The following example shows two text fields arranged in a ``VStack``.
    /// Both text fields specify the 12-point system font, with the second
    /// adding the `monospacedDigit()` modifier to the font. Because the text
    /// includes the digit 1, normally a narrow character in proportional
    /// fonts, the second text field becomes wider than the first.
    ///
    ///     @State private var userText = "Effect of monospacing digits: 111,111."
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField("Proportional", text: $userText)
    ///                 .font(.system(size: 12))
    ///             TextField("Monospaced", text: $userText)
    ///                 .font(.system(size: 12).monospacedDigit())
    ///         }
    ///         .padding()
    ///         .navigationTitle(Text("Font + monospacedDigit()"))
    ///     }
    ///
    /// ![A macOS window showing two text fields arranged vertically. Each
    /// shows the text Effect of monospacing digits: 111,111. The even spacing
    /// of the digit 1 in the second text field causes it to be noticably wider
    /// than the first.](Environment-Font-monospacedDigit-1)
    ///
    /// - Returns: A font that uses fixed-width numeric characters.
    public func monospacedDigit() -> Font {
        return Font(provider: StaticModifierProvider<MonospacedDigitModifier>(base: self))
    }
    
    /// Sets the weight of the font.
    public func weight(_ weight: Font.Weight) -> Font {
        return Font(provider: ModifierProvider(base: self, modifier: WeightModifier(weight: weight)))
    }
    
    /// Adds bold styling to the font.
    public func bold() -> Font {
        return Font(provider: StaticModifierProvider<BoldModifier>(base: self))
    }
    
    /// Returns a fixed-width font from the same family as the base font.
    ///
    /// If there's no suitable font face in the same family, DanceUI
    /// returns a default fixed-width font.
    ///
    /// The following example adds the `monospaced()` modifier to the default
    /// system font, then applies this font to a ``Text`` view:
    ///
    ///     struct ContentView: View {
    ///         let myFont = Font
    ///             .system(size: 24)
    ///             .monospaced()
    ///
    ///         var body: some View {
    ///             Text("Hello, world!")
    ///                 .font(myFont)
    ///                 .padding()
    ///                 .navigationTitle("Monospaced")
    ///         }
    ///     }
    ///
    ///
    /// ![A macOS window showing the text Hello, world in a 24-point
    /// fixed-width font.](Environment-Font-monospaced-1)
    ///
    /// DanceUI may provide different fixed-width replacements for standard
    /// user interface fonts (such as ``Font/title``, or a system font created
    /// with ``Font/system(_:design:)``) than for those same fonts when created
    /// by name with ``Font/custom(_:size:)``.
    ///
    /// The ``View/font(_:)`` modifier applies the font to all text within
    /// the view. To mix fixed-width text with other styles in the same
    /// `Text` view, use the ``Text/init(_:)-1a4oh`` initializer to use an
    /// appropropriately-styled
    /// <doc://com.apple.documentation/documentation/Foundation/AttributedString>
    /// for the text view's content. You can use the
    /// <doc://com.apple.documentation/documentation/Foundation/AttributedString/3796160-init>
    /// initializer to provide a Markdown-formatted string containing the
    /// backtick-syntax (\`…\`) to apply code voice to specific ranges
    /// of the attributed string.
    ///
    /// - Returns: A fixed-width font from the same family as the base font,
    /// if one is available, and a default fixed-width font otherwise.
    @available(iOS 13.0, *)   public func monospaced() -> Font {
        return Font(provider: StaticModifierProvider<MonospacedModifier>(base: self))
    }
    
    
    /// Create a version of `self` that uses leading (line spacing) adjustment.
    ///
    /// The availability of leading adjustments depends on font.
    ///
    /// For example, `Font.body.leading(.tight)` will return a `Font` in `body`
    /// text style with tight line spacing. This modifier may return the
    /// original `Font` unchanged for some fonts.
    public func leading(_ leading: Leading) -> Font {
        return Font(provider: ModifierProvider(base: self, modifier: LeadingModifier(leading: leading)))
    }
    
    internal struct LeadingModifier: FontModifier {
        
        internal var leading: Leading
        
        internal func modify(descriptor: inout CTFontDescriptor) {
            let traits: CTFontSymbolicTraits = leading.toCTFontSymbolicTrait
            descriptor = CTFontDescriptorCreateCopyWithSymbolicTraits(descriptor, traits, traits) ?? descriptor
        }
    }
    
    internal struct BoldModifier: StaticFontModifier {
        
        internal static func modify(descriptor: inout CTFontDescriptor) {
            let traits: CTFontSymbolicTraits = .traitBold
            descriptor = CTFontDescriptorCreateCopyWithSymbolicTraits(descriptor, traits, traits) ?? descriptor
        }
    }
    
    internal struct ItalicModifier: StaticFontModifier {
        
        internal static func modify(descriptor: inout CTFontDescriptor) {
            let traits: CTFontSymbolicTraits = .traitItalic
            descriptor = CTFontDescriptorCreateCopyWithSymbolicTraits(descriptor, traits, traits) ?? descriptor
        }
    }
    
    internal struct WeightModifier: FontModifier {
        
        internal let _weight: Font.Weight
        
        init(weight: Font.Weight) {
            _weight = weight
        }
        
        internal func modify(descriptor: inout CTFontDescriptor) {
            var attributes: CFDictionary!
            
            if DanceUI_CTFontDescriptorIsSystemUIFont(descriptor) {
                attributes = [
                    kCTFontTraitsAttribute: [
                        kCTFontWeightTrait: _weight._rawWeight as CFNumber
                    ]
                ] as CFDictionary
                descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, attributes)
            } else {
                
                guard let originalFontFamilyNameAttribute = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) else {
                    return
                }
                var originAllAttributes = (CTFontDescriptorCopyAttributes(descriptor) as? [CFString: Any]) ?? [:]
                originAllAttributes.removeValue(forKey: kCTFontNameAttribute)
                originAllAttributes[kCTFontFamilyNameAttribute] = originalFontFamilyNameAttribute as! NSString as String
                
                let originalFontTraitsAttribute = CTFontDescriptorCopyAttribute(descriptor, kCTFontTraitsAttribute) as! CFDictionary?
                var mutableFontTraitsAttributes = (originalFontTraitsAttribute as? [CFString: Any]) ?? [:]
                
                mutableFontTraitsAttributes[kCTFontWeightTrait] = _weight._rawWeight
                attributes = [
                    kCTFontTraitsAttribute: mutableFontTraitsAttributes as CFDictionary,
                ] as CFDictionary
                
                originAllAttributes[kCTFontTraitsAttribute] = mutableFontTraitsAttributes
                descriptor = CTFontDescriptorCreateWithAttributes(originAllAttributes as CFDictionary)
            }
        }
    }
    
    fileprivate struct LowercaseSmallCapsModifier: FontModifier {
        
        fileprivate func modify(descriptor: inout CTFontDescriptor) {
            descriptor = CTFontDescriptorCreateCopyWithFeature(
                descriptor,
                kLowerCaseType as CFNumber,
                kAllCapsSelector as CFNumber
            )
        }
    }
    
    fileprivate struct UppercaseSmallCapsModifier: FontModifier {
        
        fileprivate func modify(descriptor: inout CTFontDescriptor) {
            descriptor = CTFontDescriptorCreateCopyWithFeature(
                descriptor,
                kUpperCaseType as CFNumber,
                kAllCapsSelector as CFNumber
            )
        }
    }
    
    internal struct MonospacedDigitModifier: StaticFontModifier {
        
        internal static func modify(descriptor: inout CTFontDescriptor) {
            descriptor = CTFontDescriptorCreateCopyWithFeature(
                descriptor,
                kNumberSpacingType as CFNumber,
                kMonospacedNumbersSelector as CFNumber
            )
        }
    }
    
    internal struct StylisticAlternativeModifier: FontModifier {
        
        internal let selector: CFIndex
        
        @inline(__always)
        internal init(selector: CFIndex) {
            self.selector = selector
        }
        
        internal func modify(descriptor: inout CTFontDescriptor) {
            let features = [
                kCTFontFeatureTypeIdentifierKey: kStylisticAlternativesType,
                kCTFontFeatureTypeSelectorsKey: selector,
            ] as CFDictionary
            
            let attributes = [
                kCTFontFeaturesAttribute: features,
            ] as CFDictionary
            
            descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, attributes)
        }
    }
    
    internal struct RoundedModifier: StaticFontModifier {
        
        internal static func modify(descriptor: inout CTFontDescriptor) {
            let oldFontTraits = CTFontDescriptorCopyAttribute(descriptor, kCTFontTraitsAttribute) as! CFDictionary
            
            var mutableFontTraits = oldFontTraits as! [CFString: Any]
            
            mutableFontTraits[MyCTFontUIFontDesignTrait] = MyCTFontUIFontDesignRounded
            
            let attributes = [
                kCTFontTraitsAttribute: mutableFontTraits as CFDictionary,
            ] as CFDictionary
            
            descriptor = CTFontDescriptorCreateCopyWithAttributes(descriptor, attributes)
        }
    }
    
    fileprivate struct ModifierProvider<M: FontModifier>: FontProvider {
        
        fileprivate typealias Modifier = M
        
        private let base: Font
        
        private let modifier: Modifier
        
        @inline(__always)
        fileprivate init(base: Font, modifier: Modifier) {
            self.base = base
            self.modifier = modifier
        }
        
        fileprivate func resolve(in context: Context) -> CTFontDescriptor {
            var descriptor = base.provider.resolve(in: context)
            modifier.modify(descriptor: &descriptor)
            return descriptor
        }
    }
    
    fileprivate struct StaticModifierProvider<M: StaticFontModifier>: FontProvider {
        
        private let base: Font
        
        @inline(__always)
        fileprivate init(base: Font) {
            self.base = base
        }
        
        fileprivate func resolve(in context: Context) -> CTFontDescriptor {
            var descriptor = base.provider.resolve(in: context)
            M.modify(descriptor: &descriptor)
            return descriptor
        }
    }
}

@available(iOS 13.0, *)

extension Font {
    
    /// A weight to use for fonts.
    @frozen
    public struct Weight : Hashable {
        
        fileprivate let _rawWeight: CGFloat
        
        @inline(__always)
        @_spi(DanceUICompose)
        public init(rawWeight: CGFloat) {
            _rawWeight = rawWeight
        }
        
        public static let ultraLight: Font.Weight = .init(rawWeight: -0.8)
        
        public static let thin: Font.Weight = .init(rawWeight: -0.6)
        
        public static let light: Font.Weight = .init(rawWeight: -0.4)
        
        public static let regular: Font.Weight = .init(rawWeight: 0)
        
        public static let medium: Font.Weight = .init(rawWeight: 0.23)
        
        public static let semibold: Font.Weight = .init(rawWeight: 0.3)
        
        public static let bold: Font.Weight = .init(rawWeight: 0.4)
        
        public static let heavy: Font.Weight = .init(rawWeight: 0.56)
        
        public static let black: Font.Weight = .init(rawWeight: 0.62)
    }
    
    /// A dynamic text style to use for fonts.
    public enum TextStyle : Hashable, CaseIterable {
        
        public typealias AllCases = [TextStyle]
        
        public static var allCases: [Font.TextStyle] {
            return [.largeTitle, .title, .title2, .title3, .headline, .subheadline, .body, .callout, .footnote, .caption, .caption2]
        }
        
        case largeTitle
        
        case title
        
        case title2
        
        case title3
        
        case headline
        
        case subheadline
        
        case body
        
        case callout
        
        case footnote
        
        case caption
        // 0xa
        case caption2
        
        @inline(__always)
        fileprivate var ctTextStyle: CFString {
            let retVal: CFString
            
            switch self {
            case .largeTitle:   retVal = MyCTUIFontTextStyleTitle0
            case .title:        retVal = MyCTUIFontTextStyleTitle1
            case .title2:       retVal = MyCTUIFontTextStyleTitle2
            case .title3:       retVal = MyCTUIFontTextStyleTitle3
            case .headline:     retVal = MyCTUIFontTextStyleHeadline
            case .subheadline:  retVal = MyCTUIFontTextStyleSubhead
            case .body:         retVal = MyCTUIFontTextStyleBody
            case .callout:      retVal = MyCTUIFontTextStyleCallout
            case .footnote:     retVal = MyCTUIFontTextStyleFootnote
            case .caption:      retVal = MyCTUIFontTextStyleCaption1
            case .caption2:     retVal = MyCTUIFontTextStyleCaption2
            }
            
            return retVal
        }
    }
    
    /// A design to use for fonts.
    public enum Design : Hashable {
        
        case `default`
        
        @available(watchOS, unavailable)
        @available(iOS 13.0, *)       
        case serif
        
        case rounded
        
        @available(watchOS, unavailable)
        @available(iOS 13.0, *)       
        case monospaced
        
        @inline(__always)
        fileprivate var ctFontDesign: String {
            let design: CFString
            
            switch self {
            case .default:
                design = MyCTFontUIFontDesignDefault
            case .monospaced:
                if #available(iOS 13.0, *) {
                    design = MyCTFontUIFontDesignMonospaced
                } else {  //BDCOV_EXCL_BLOCK
                    assertionFailure("'Font.Design.monospaced' are only available in iOS 13.0.0 or newer.")
                    // DanceUI Addition: 额外的补救措施
                    design = MyCTUIFontTextStyleBody
                }
            case .rounded:
                design = MyCTFontUIFontDesignRounded
            case .serif:
                if #available(iOS 13.0, *) {
                    design = MyCTFontUIFontDesignSerif
                } else { //BDCOV_EXCL_BLOCK
                    assertionFailure("'Font.Design.serif' are only available in iOS 13.0.0 or newer.")
                    // DanceUI Addition: 额外的补救措施
                    design = MyCTUIFontTextStyleBody
                }
            }
            
            return design as String
        }
    }
    
    /// A line spacing adjustment that you can apply to a font.
    ///
    /// Apply one of the `Leading` values to a font using the
    /// ``Font/leading(_:)`` method to increase or decrease the line spacing.
    public enum Leading: Hashable {
        
        /// The font's default line spacing.
        ///
        /// If you modify a font to use a nonstandard line spacing like
        /// ``tight`` or ``loose``, you can use this value to return to
        /// the font's default line spacing.
        case standard
        
        /// Reduced line spacing.
        ///
        /// This value typically reduces line spacing by 1 point for watchOS
        /// and 2 points on other platforms.
        case tight
        
        /// Increased line spacing.
        ///
        /// This value typically increases line spacing by 1 point for watchOS
        /// and 2 points on other platforms.
        case loose
        
        @inlinable
        internal var toCTFontSymbolicTrait: CTFontSymbolicTraits {
            switch self {
            case .tight:
                return .tight
            case .standard:
                return .standard
            case .loose:
                return .loose
            @unknown default:
                return .standard
            }
        }
    }
}

@available(iOS 13.0, *)
extension CTFontSymbolicTraits {
    
    @inlinable
    internal static var tight: CTFontSymbolicTraits {
        CTFontSymbolicTraits(rawValue: 1 << 15)
    }
    
    @inlinable
    internal static var loose: CTFontSymbolicTraits {
        CTFontSymbolicTraits(rawValue: 1 << 16)
    }
    
    @inlinable
    internal static var standard: CTFontSymbolicTraits {
        tight.union(.loose)
    }
}


@usableFromInline
@available(iOS 13.0, *)
internal class AnyFontBox: Hashable {
    
    internal func resolve(in: Font.Context) -> CTFontDescriptor {
        _abstract(self)
    }
    
    @usableFromInline
    internal static func == (lhs: AnyFontBox, rhs: AnyFontBox) -> Bool {
        return lhs.isEqual(to: rhs)
    }
    
    @usableFromInline
    internal func hash(into hasher: inout Hasher) {
        _abstract(self)
    }
    
    internal func isEqual(to another: AnyFontBox) -> Bool {
        _abstract(self)
    }
}


@available(iOS 13.0, *)
private final class FontBox<P: FontProvider>: AnyFontBox, FontProvider {
    
    fileprivate typealias Provider = P
    
    private let _provider: Provider
    
    fileprivate init(provider: Provider) {
        _provider = provider
    }
    
    fileprivate override func resolve(in context: Font.Context) -> CTFontDescriptor {
        _provider.resolve(in: context)
    }
    
    fileprivate override func isEqual(to another: AnyFontBox) -> Bool {
        if let fontBox = another as? FontBox {
            return fontBox._provider == _provider
        }
        return false
    }
    
    fileprivate override func hash(into hasher: inout Hasher) {
        _provider.hash(into: &hasher)
    }
}

@available(iOS 13.0, *)
extension Font {
    
    internal func platformFont(in environment: EnvironmentValues,
                               fontModifiers: [AnyFontModifier]) -> CTFont {
        Font.withCache { cache in
            let fontResolutionContext = environment.fontResolutionContext
            let resolved = Resolved(font: self, modifiers: fontModifiers, context: fontResolutionContext)
            return cache[resolved]
        }
    }
    
    internal struct Context : Hashable {
        
        internal let sizeCategory: ContentSizeCategory
        
        internal let legibilityWeight: LegibilityWeight?
        
        internal let fontDefinition: FontDefinitionType
        
        @inline(__always)
        internal func resolveTextStyleFont(textStyle: Font.TextStyle, design: Font.Design, weight: Font.Weight?, sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
            fontDefinition.base.resolveTextStyleFont(textStyle: textStyle, design: design, weight: weight, sizeCategory: sizeCategory)
        }
        
        @inline(__always)
        internal func resolveSystemFont(size: CGFloat, weight: Font.Weight, design: Font.Design, sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
            fontDefinition.base.resolveSystemFont(size: size, weight: weight, design: design, sizeCategory: sizeCategory)
        }
        
        @inline(__always)
        internal func resolveCustomFont(name: String, size: CGFloat, textStyle: Font.TextStyle?, sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
            fontDefinition.base.resolveCustomFont(name: name, size: size, textStyle: textStyle, sizeCategory: sizeCategory)
        }
        
        internal static func == (lhs: Font.Context, rhs: Font.Context) -> Bool {
            lhs.sizeCategory == rhs.sizeCategory &&
            lhs.legibilityWeight == rhs.legibilityWeight &&
            lhs.fontDefinition == rhs.fontDefinition
        }
    }
}

@available(iOS 13.0, *)
internal struct FontDefinitionType : Hashable {
    
    internal var base: FontDefinition.Type
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(base))
    }
    
    internal static func == (lhs: FontDefinitionType, rhs: FontDefinitionType) -> Bool {
        return lhs.base == rhs.base
    }
}

@available(iOS 13.0, *)
internal protocol FontDefinition {
    
    static func resolveTextStyleFont(textStyle: Font.TextStyle, design: Font.Design, weight: Font.Weight?, sizeCategory: ContentSizeCategory) -> CTFontDescriptor
    
    static func resolveSystemFont(size: CGFloat, weight: Font.Weight, design: Font.Design, sizeCategory: ContentSizeCategory) -> CTFontDescriptor
    
    static func resolveCustomFont(name: String, size: CGFloat, textStyle: Font.TextStyle?, sizeCategory: ContentSizeCategory) -> CTFontDescriptor
}

@available(iOS 13.0, *)
internal enum DefaultFontDefinition : FontDefinition {
    
    internal static func resolveTextStyleFont(textStyle: Font.TextStyle, design: Font.Design, weight: Font.Weight?, sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
        
        let baseFontDescriptor = MyCTFontDescriptorCreateWithTextStyle(
            textStyle.ctTextStyle as CFString,
            sizeCategory.ctTextSize as CFString,
            nil
        )
        
        let oldFontTraits = CTFontDescriptorCopyAttribute(baseFontDescriptor, kCTFontTraitsAttribute) as! CFDictionary
        
        var mutableFontTraits = oldFontTraits as! [CFString: Any]
        
        mutableFontTraits[MyCTFontUIFontDesignTrait] = design.ctFontDesign
        
        let attributes = [
            kCTFontTraitsAttribute: mutableFontTraits as CFDictionary,
        ] as CFDictionary
        
        return CTFontDescriptorCreateCopyWithAttributes(baseFontDescriptor, attributes)
    }
    
    internal static func resolveSystemFont(size: CGFloat, weight: Font.Weight, design: Font.Design, sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
        
        let design = design.ctFontDesign
        
        let fontTraits = [
            MyCTFontUIFontDesignTrait: design,
            kCTFontWeightTrait: weight._rawWeight,
        ] as CFDictionary
        
        let attributes = [
            kCTFontSizeAttribute: size,
            kCTFontTraitsAttribute: fontTraits,
        ] as CFDictionary
        
        return CTFontDescriptorCreateWithAttributes(attributes)
    }
    
    internal static func resolveCustomFont(name: String,
                                           size: CGFloat,
                                           textStyle: Font.TextStyle?,
                                           sizeCategory: ContentSizeCategory) -> CTFontDescriptor {
        if let _textStyle = textStyle {
            let newSize = round(Font.scaleFactor(textStyle: _textStyle, in: sizeCategory) * size)
            return CTFontDescriptorCreateWithNameAndSize(name as NSString, newSize)
        }
        return CTFontDescriptorCreateWithNameAndSize(name as NSString, size)
    }
}

@available(iOS 13.0, *)
extension Font {
    
    fileprivate static var ratioCache: [RatioKey: CGFloat] = [:]
    
    fileprivate struct RatioKey: Hashable {
        internal var textStyle: TextStyle
        internal var category: ContentSizeCategory
        
        internal func hash(into hasher: inout Hasher) {
            hasher.combine(textStyle)
            hasher.combine(category)
        }
    }
    
    internal static func scaleFactor(textStyle: TextStyle, in sizeCategory: ContentSizeCategory) -> CGFloat {
        let ratioKey = RatioKey(textStyle: textStyle, category: sizeCategory)
        if !Font.ratioCache.isEmpty, let cachedResult = Font.ratioCache[ratioKey] {
            return cachedResult
        }
        let fontFromTextStyle: CTFont = CTFontCreateWithFontDescriptor(MyCTFontDescriptorCreateWithTextStyle(textStyle.ctTextStyle, sizeCategory.ctTextSize, nil), 0, nil)
        let uiApplicationContentSizeCategory = ContentSizeCategory(__MyUIApplicationDefaultContentSizeCategory()) ?? .large
        let fontFromUIApplication: CTFont = CTFontCreateWithFontDescriptor(MyCTFontDescriptorCreateWithTextStyle(textStyle.ctTextStyle, uiApplicationContentSizeCategory.ctTextSize, nil), 0, nil)
        let result = fontFromTextStyle.bodyLeading / fontFromUIApplication.bodyLeading
        Font.ratioCache[ratioKey] = result
        return result
    }
    
    fileprivate static let fontCache: ObjectCache<Resolved, CTFont> = .init {
        var fontDescriptor = $0.font.provider.resolve(in: $0.context)
        $0.modifiers.forEach { fontModifier in
            fontModifier.modify(descriptor: &fontDescriptor)
        }
        return CTFontCreateWithFontDescriptor(fontDescriptor, 0, nil)
    }
    
    fileprivate static let asyncCache: AsyncCache<ObjectCache<Resolved, CTFont>> = .init(ObjectCache {
        var fontDescriptor = $0.font.provider.resolve(in: $0.context)
        $0.modifiers.forEach { fontModifier in
            fontModifier.modify(descriptor: &fontDescriptor)
        }
        return CTFontCreateWithFontDescriptor(fontDescriptor, 0, nil)
    })
    
    @inline(__always)
    fileprivate static func withCache<R>(_ body: (ObjectCache<Resolved, CTFont>) -> R) -> R {
        guard DanceUIFeature.hostingConfigurationReaderAsyncComputerSize.isEnable else {
            return body(fontCache)
        }
        if Thread.isMainThread {
            return body(fontCache)
        } else {
            return asyncCache.withContent { cache in
                body(cache)
            }
        }
    }
}

@available(iOS 13.0, *)
extension CTFont {
    
    internal var bodyLeading: CGFloat {
        CTFontGetLeading(self) + CTFontGetDescent(self) + CTFontGetAscent(self)
    }
}


@available(iOS 13.0, *)
internal protocol FontProvider : Hashable {
    
    func resolve(in context: Font.Context) -> CTFontDescriptor
}

@available(iOS 13.0, *)
fileprivate struct Item<ResolvedItem, ResolveResult> {
    
}

@available(iOS 13.0, *)
extension Font {
    
    fileprivate struct Resolved : Hashable {
        fileprivate var font: Font
        fileprivate var modifiers: [AnyFontModifier]
        fileprivate let context: Context
    }
}

@available(iOS 13.0, *)
extension UIFont {
    
    /// DanceUI addition
    public convenience init(_ font: Font) {
        self.init(font__My: font.platformFont(in: EnvironmentValues(), fontModifiers: []) as UIFont)
    }
}


@available(iOS 13.0, *)
fileprivate func DanceUI_CTFontDescriptorIsSystemUIFont(_ descriptor: CTFontDescriptor) -> Bool {
    
    guard let priorityRef = CTFontDescriptorCopyAttribute(descriptor, kCTFontPriorityAttribute) else {
        return false
    }
    let fontPriority = priorityRef as! CFNumber
    var fontPriorityInt64: Int = 0
    CFNumberGetValue(fontPriority, .sInt64Type, &fontPriorityInt64)
    return fontPriorityInt64 == kCTFontPrioritySystem
}
