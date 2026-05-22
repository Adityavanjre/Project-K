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
import CoreGraphics
internal import DanceUIRuntime
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif


// MARK: - Using CoreText to build the attributed text

/// A view that displays one or more lines of read-only text.
///
/// A text view draws a string in your app's user interface using a
/// ``Font/body`` font that's appropriate for the current platform. You can
/// choose a different standard font, like ``Font/title`` or ``Font/caption``,
/// using the ``View/font(_:)`` view modifier.
///
///     Text("Hamlet")
///         .font(.title)
///
///
/// If you need finer control over the styling of the text, you can use the same
/// modifier to configure a system font or choose a custom font. You can also
/// apply view modifiers like ``Text/bold()`` or ``Text/italic()`` to further
/// adjust the formatting.
///
///     Text("by William Shakespeare")
///         .font(.system(size: 12, weight: .light, design: .serif))
///         .italic()
///
///
///
/// A text view always uses exactly the amount of space it needs to display its
/// rendered contents, but you can affect the view's layout. For example, you
/// can use the ``View/frame(width:height:alignment:)`` modifier to propose
/// specific dimensions to the view. If the view accepts the proposal but the
/// text doesn't fit into the available space, the view uses a combination of
/// wrapping, tightening, scaling, and truncation to make it fit. With a width
/// of `100` points but no constraint on the height, a text view might wrap a
/// long string:
///
///     Text("To be, or not to be, that is the question:")
///         .frame(width: 100)
///
///
/// Use modifiers like ``View/lineLimit(_:)-513mb``, ``View/allowsTightening(_:)``,
/// ``View/minimumScaleFactor(_:)``, and ``View/truncationMode(_:)`` to
/// configure how the view handles space constraints. For example, combining a
/// fixed width and a line limit of `1` results in truncation for text that
/// doesn't fit in that space:
///
///     Text("Brevity is the soul of wit.")
///         .frame(width: 100)
///         .lineLimit(1)
///
///
/// ### Localizing strings
///
/// If you initialize a text view with a string literal, the view uses the
/// ``Text/init(_:tableName:bundle:comment:)`` initializer, which interprets the
/// string as a localization key and searches for the key in the table you
/// specify, or in the default table if you don't specify one.
///
///     Text("pencil") // Searches the default table in the main bundle.
///
/// For an app localized in both English and Spanish, the above view displays
/// "pencil" and "lápiz" for English and Spanish users, respectively. If the
/// view can't perform localization, it displays the key instead. For example,
/// if the same app lacks Danish localization, the view displays "pencil" for
/// users in that locale. Similarly, an app that lacks any localization
/// information displays "pencil" in any locale.
///
/// To explicitly bypass localization for a string literal, use the
/// ``Text/init(verbatim:)`` initializer.
///
///     Text(verbatim: "pencil") // Displays the string "pencil" in any locale.
///
/// If you intialize a text view with a variable value, the view uses the
/// ``Text/init(_:)-9d1g4`` initializer, which doesn't localize the string. However,
/// you can request localization by creating a ``LocalizedStringKey`` instance
/// first, which triggers the ``Text/init(_:tableName:bundle:comment:)``
/// initializer instead:
///
///     // Don't localize a string variable...
///     Text(writingImplement)
///
///     // ...unless you explicitly convert it to a localized string key.
///     Text(LocalizedStringKey(writingImplement))
///
/// When localizing a string variable, you can use the default table by omitting
/// the optional initialization parameters — as in the above example — just like
/// you might for a string literal.
@available(iOS 13.0, *)
@frozen
public struct Text : PrimitiveView, Equatable {
    
    @usableFromInline
    internal let storage: Storage
    
    internal let modifiers: [Modifier]
    
    /// Creates a text view that displays a string literal without localization.
    ///
    /// Use this initializer to create a text view with a string literal without
    /// performing localization:
    ///
    ///     Text(verbatim: "pencil") // Displays the string "pencil" in any locale.
    ///
    /// If you want to localize a string literal before displaying it, use the
    /// ``Text/init(_:tableName:bundle:comment:)`` initializer instead. If you
    /// want to display a string variable, use the ``Text/init(_:)-9d1g4``
    /// initializer, which also bypasses localization.
    ///
    /// - Parameter content: A string to display without localization.
    @inlinable
    public init(verbatim content: String) {
        self.init(.verbatim(content), modifiers: [])
    }
    
    /// Creates a text view that displays a stored string without localization.
    ///
    /// Use this initializer to create a text view that displays — without
    /// localization — the text in a string variable.
    ///
    ///     Text(someString) // Displays the contents of `someString` without localization.
    ///
    /// DanceUI doesn't call the `init(_:)` method when you initialize a text
    /// view with a string literal as the input. Instead, a string literal
    /// triggers the ``Text/init(_:tableName:bundle:comment:)`` method — which
    /// treats the input as a ``LocalizedStringKey`` instance — and attempts to
    /// perform localization.
    ///
    /// By default, DanceUI assumes that you don't want to localize stored
    /// strings, but if you do, you can first create a localized string key from
    /// the value, and initialize the text view with that. Using a key as input
    /// triggers the ``Text/init(_:tableName:bundle:comment:)`` method instead.
    ///
    /// - Parameter content: The string value to display without localization.
    @_disfavoredOverload
    public init<S>(_ content: S) where S : StringProtocol {
        self.init(.verbatim(String(content)), modifiers: [])
    }
    
    /// Creates an instance that wraps an `Image`, suitable for concatenating
    /// with other `Text`
    public init(_ image: Image) {
        self.init(.anyTextStorage(AttachmentTextStorage(image: image)), modifiers: [])
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: Text, b: Text) -> Bool {
        (a.storage == b.storage) && (a.modifiers == b.modifiers)
    }
    
    internal struct System {
        internal static func kitlocalized(_ localizedStringKey: LocalizedStringKey, tableName: String, comment: StaticString? = nil) -> Text {
            // use Bundle.DanceUI
            return Text(localizedStringKey, tableName: tableName, bundle: Bundle.DanceUI, comment: comment)
        }
        
        internal static let done: Text = Text.System.kitlocalized("Done", tableName: "Localizable")
        
        internal static let edit: Text = Text.System.kitlocalized("Edit", tableName: "Localizable")
        
    }
}

@available(iOS 13.0, *)
extension Text {

    /// Creates a text view that displays localized content identified by a key.
    ///
    /// Use this initializer to look for the `key` parameter in a localization
    /// table and display the associated string value in the initialized text
    /// view. If the initializer can't find the key in the table, or if no table
    /// exists, the text view displays the string representation of the key
    /// instead.
    ///
    ///     Text("pencil") // Localizes the key if possible, or displays "pencil" if not.
    ///
    /// When you initialize a text view with a string literal, the view triggers
    /// this initializer because it assumes you want the string localized, even
    /// when you don't explicitly specify a table, as in the above example. If
    /// you haven't provided localization for a particular string, you still get
    /// reasonable behavior, because the initializer displays the key, which
    /// typically contains the unlocalized string.
    ///
    /// If you initialize a text view with a string variable rather than a
    /// string literal, the view triggers the ``Text/init(_:)-9d1g4``
    /// initializer instead, because it assumes that you don't want localization
    /// in that case. If you do want to localize the value stored in a string
    /// variable, you can choose to call the `init(_:tableName:bundle:comment:)`
    /// initializer by first creating a ``LocalizedStringKey`` instance from the
    /// string variable:
    ///
    ///     Text(LocalizedStringKey(someString)) // Localizes the contents of `someString`.
    ///
    /// If you have a string literal that you don't want to localize, use the
    /// ``Text/init(verbatim:)`` initializer instead.
    ///
    /// - Parameters:
    ///   - key: The key for a string in the table identified by `tableName`.
    ///   - tableName: The name of the string table to search. If `nil`, use the
    ///     table in the `Localizable.strings` file.
    ///   - bundle: The bundle containing the strings file. If `nil`, use the
    ///     main bundle.
    ///   - comment: Contextual information about this key-value pair.
    public init(_ key: LocalizedStringKey, tableName: String? = nil, bundle: Bundle? = nil, comment: StaticString? = nil) {
        self.init(.anyTextStorage(LocalizedTextStorage(key: key, table: tableName, bundle: bundle)), modifiers: [])
    }
    
    /// Creates a text view that displays styled attributed content.
    ///
    /// - Parameters:
    ///   - nsattributedContent: An attributed string to style and display,
    ///   in accordance with its attributes.
    public init(_ nsAttributedContent: NSAttributedString) {
        self.init(.anyTextStorage(AttributedStringTextStorage(attributedString: nsAttributedContent)), modifiers: [])
    }
}

@available(iOS 13.0, *)

extension Text {
    
    /// The type of truncation to apply to a line of text when it's too long to
    /// fit in the available space.
    ///
    /// When a text view contains more text than it's able to display, the view
    /// might truncate the text and place an ellipsis (...) at the truncation
    /// point. Use the ``View/truncationMode(_:)`` modifier with one of the
    /// `TruncationMode` values to indicate which part of the text to
    /// truncate, either at the beginning, in the middle, or at the end.
    public enum TruncationMode: Hashable, Encodable {
        
        /// Truncate at the beginning of the line.
        ///
        /// Use this kind of truncation to omit characters from the beginning of
        /// the string. For example, you could truncate the English alphabet as
        /// "...wxyz".
        case head
        
        /// Truncate at the end of the line.
        ///
        /// Use this kind of truncation to omit characters from the end of the
        /// string. For example, you could truncate the English alphabet as
        /// "abcd...".
        case tail
        
        /// Truncate in the middle of the line.
        ///
        /// Use this kind of truncation to omit characters from the middle of
        /// the string. For example, you could truncate the English alphabet as
        /// "ab...yz".
        case middle

        case wordWrapping
        
        case charWrapping
        
        case clipping
        
    }
    
    public enum Case: Hashable {
        
        /// Displays text in all uppercase characters.
        ///
        /// For example, "Hello" would be displayed as "HELLO".
        ///
        /// - SeeAlso: `StringProtocol.uppercased(with:)`
        case uppercase
        
        /// Displays text in all lowercase characters.
        ///
        /// For example, "Hello" would be displayed as "hello".
        ///
        /// - SeeAlso: `StringProtocol.lowercased(with:)`
        case lowercase
        
        internal func applied(to nsString: NSAttributedString, locale: Locale) -> NSAttributedString {
            let string: String
            switch(self) {
            case .uppercase:
                string = nsString.string.uppercased(with: locale)
            case .lowercase:
                string = nsString.string.lowercased(with: locale)
            }
            let mutableString = NSMutableAttributedString(attributedString: nsString)
            mutableString.mutableString.setString(string)
            return mutableString
        }
    }
}

@available(iOS 13.0, *)

extension Text {
    
    public static func + (lhs: Text, rhs: Text) -> Text {
        .init(.anyTextStorage(ConcatenatedTextStorage(first: lhs,
                                                      second: rhs)),
              modifiers: [])
    }
    
}

@available(iOS 13.0, *)

extension Text {
    
    @usableFromInline
    @frozen
    internal enum Storage: Equatable {
        
        @usableFromInline
        internal static func == (lhs: Text.Storage, rhs: Text.Storage) -> Bool {
            switch (lhs, rhs) {
            case (.verbatim(let lv), .verbatim(let rv)):
                return lv == rv
            case (.anyTextStorage(let lv), .anyTextStorage(let rv)):
                return lv.isEqual(to: rv)
            default:
                return false
            }
        }
        
        case verbatim(_ :String)
        case anyTextStorage(_: AnyTextStorage)
    }
    
    @usableFromInline
    internal func resolvesToEmpty(in environment: EnvironmentValues, with options: Text.ResolveOptions) -> Bool {
        switch(storage) {
        case .verbatim(let string):
            return string.isEmpty
        case .anyTextStorage(let storage):
            return storage.resolvesToEmpty(in: environment, with: options)
        }
    }
    
    @usableFromInline
    internal init(_ storage: Storage, modifiers: [Modifier]) {
        self.storage = storage
        self.modifiers = modifiers
    }
    
    @usableFromInline
    internal class AnyTextStorage {
        
        internal init() {
        }
        
        
        internal func resolve(into: inout Text.Resolved, in environmentValues: EnvironmentValues, options: ResolveOptions) {
            _abstract(self)
        }
        
        internal func isEqual(to rhs: AnyTextStorage) -> Bool {
            _abstract(self)
        }
        
        internal func isStyled(options: ResolveOptions = .zero) -> Bool {
            _abstract(self)
        }
        
        internal func resolvesToEmpty(in environment: EnvironmentValues, with options: ResolveOptions) -> Bool {
            var resolved = Resolved()
            resolve(into: &resolved, in: environment, options: options)
            guard let mutableAttributedString = resolved.mutableAttributedString else {
                return true
            }
            return mutableAttributedString.string.isEmpty
        }
    }
    
    @usableFromInline
    internal func isStyled(options: ResolveOptions) -> Bool {
        if case .anyTextStorage(let storage) = self.storage {
            if storage.isStyled(options: options) {
                return true
            }
        }
        return !modifiers.isEmpty
    }
    
    @usableFromInline
    internal final class AttributedStringTextStorage: AnyTextStorage {
        
        internal let str: NSAttributedString
        
        @usableFromInline
        internal init(attributedString: NSAttributedString) {
            self.str = attributedString
        }
        
        internal override func resolve(into resolved: inout Resolved, in environment: EnvironmentValues, options: ResolveOptions) {
            resolved.append(str, in: environment, with: options)
        }
        
        internal override func isEqual(to instance: Text.AnyTextStorage) -> Bool {
            guard let instance = instance as? AttributedStringTextStorage else {
                return false
            }
            return self.str == instance.str
        }
        
        internal override func isStyled(options _: Text.ResolveOptions = .zero) -> Bool {
            return str.isStyled
        }
    }
    
    
    @usableFromInline
    internal final class LocalizedTextStorage: AnyTextStorage {
        
        internal let key: LocalizedStringKey
        
        internal let table: String?
        
        internal let bundle: Bundle?
        
        @usableFromInline
        internal init(key: LocalizedStringKey, table: String?, bundle: Bundle?) {
            self.key = key
            self.table = table
            self.bundle = bundle
        }
        
        internal override func resolve(into resolved: inout Resolved, in environment: EnvironmentValues, options: ResolveOptions) {
            key.resolve(into: &resolved, in: environment, options: options, table: table, bundle: bundle)
        }
        
        internal override func isEqual(to instance: Text.AnyTextStorage) -> Bool {
            guard let instance = instance as? LocalizedTextStorage else {
                return false
            }
            return self.key == instance.key &&
            self.bundle == instance.bundle &&
            self.table == instance.table
        }
        
        internal override func resolvesToEmpty(in environment: EnvironmentValues, with options: ResolveOptions) -> Bool {
            key.resolvesToEmpty(in: environment, options: options, table: table, bundle: bundle)
        }
        
        internal override func isStyled(options: Text.ResolveOptions = .zero) -> Bool {
            for argument in key.arguments {
                switch argument.storage {
                case .value((_, _)):
                    continue
                case .text((let text, _)):
                    if text.isStyled(options: options) {
                        return true
                    }
                case .formatStyleValue(_):
                    continue
                case .attributedString(let attributedString):
                    if attributedString.isStyled {
                        return true
                    }
                }
            }
            if #available(iOS 15, *) {
                var resultBool = false
                let markdownString = NSAttributedString(markdown: self.key.key)
                markdownString.enumerateAttribute(.inlinePresentationIntent, in: markdownString.range, options: .init()) { value, _, stop in
                    if let value = value as? UInt, value != 0 {
                        resultBool = true
                        stop.pointee = true
                    }
                }
                guard !resultBool else {
                    return true
                }
            }
            return false
        }
    }
    
    @usableFromInline
    internal final class ConcatenatedTextStorage: AnyTextStorage {
        
        internal var first: Text
        internal var second: Text
        
        internal init(first: Text, second: Text) {
            self.first = first
            self.second = second
        }
        
        internal override func resolve(into resolved: inout Text.Resolved, in environment: EnvironmentValues, options: ResolveOptions) {
            let oldStyle = resolved.style
            defer {
                resolved.style = oldStyle
            }
            Text.makeStyle(&resolved.style, modifiers: first.modifiers)
            first.resolve(into: &resolved, in: environment, with: options)
            
            resolved.style = oldStyle
            
            Text.makeStyle(&resolved.style, modifiers: second.modifiers)
            second.resolve(into: &resolved, in: environment, with: options)
        }
        
        internal override func resolvesToEmpty(in environment: EnvironmentValues, with options: Text.ResolveOptions) -> Bool {
            return first.resolvesToEmpty(in: environment, with: options) && second.resolvesToEmpty(in: environment, with: options)
        }
        
        internal override func isEqual(to instance: Text.AnyTextStorage) -> Bool {
            guard let instance = instance as? ConcatenatedTextStorage else {
                return false
            }
            return self.first == instance.first &&
            self.second == instance.second
        }
        
        internal override func isStyled(options: Text.ResolveOptions = .zero) -> Bool {
            return first.isStyled(options: options) || second.isStyled(options: options)
        }
    }
}

@available(iOS 13.0, *)

extension Text {
    
    @_spi(DanceUICompose)
    public struct Style {
        
        internal var baseFont: Font? = nil
        internal var fontModifiers: [AnyFontModifier] = []
        internal var color: Color? = nil
        internal var backgroundColor: Color? = nil
        internal var baselineOffset: CGFloat? = nil
        internal var kerning: CGFloat? = nil
        internal var tracking: CGFloat? = nil
        internal var strikethrough: LineStyle = .default
        internal var underline: LineStyle = .default
        
        internal var clearedFontModifiers: Set<AnyFontModifier> = []
        
        internal var tapAction: (() -> Void)? = nil
        
        internal enum LineStyle {
            
          case explicit(Text.LineStyle)
            
          case implicit
            
          case `default`
        }
        
        @inline(__always)
        internal mutating func addFontModifier<A: StaticFontModifier>(type: A.Type) {
            fontModifiers.append(.static(type: type))
            clearedFontModifiers.remove(.static(type: type))
        }
        
        @inline(__always)
        internal mutating func removeFontModifier<A: StaticFontModifier>(type: A.Type) {
            clearedFontModifiers.insert(.static(type: type))
        }
        
        internal func nsAttributes(environment: EnvironmentValues,
                                   includeDefaultAttributes: Bool) -> [NSAttributedString.Key: Any] {
            var result = [NSAttributedString.Key: Any]()
            var ctFont: CTFont? = nil
            
            var combinedFontModifiers = environment.fontModifiers + fontModifiers
            combinedFontModifiers.removeAll { modifier in
                clearedFontModifiers.contains(modifier)
            }
            
            if let font = baseFont {
                ctFont = font.platformFont(in: environment, fontModifiers: combinedFontModifiers)
            } else {
                let font = environment.effectiveFont
                ctFont = font.platformFont(in: environment, fontModifiers: combinedFontModifiers)
            }
            if let ctFont = ctFont {
                result[.font] = ctFont
            }
            guard includeDefaultAttributes else {
                return result
            }
            
            var foregroundUIColor: UIColor
            if let foregroundColor = color {
                foregroundUIColor = foregroundColor.resolvedUIColor(in: environment)
            } else {
                foregroundUIColor = Color.foreground.resolvedUIColor(in: environment)
            }
            
            if environment.shouldRedactContent {
                foregroundUIColor = foregroundUIColor.withAlphaComponent(0.16)
            }
            result[.foregroundColor] = foregroundUIColor
            
            let baselineOffset = baselineOffset ?? environment.baselineOffset
            if !baselineOffset.isZero && !baselineOffset.isNaN {
                result[.baselineOffset] = baselineOffset as NSNumber
            }
            let kerning = kerning ?? environment.kerning
            if !kerning.isZero && !kerning.isNaN {
                result[.kern] = kerning as NSNumber
            }
            let tracking = tracking ?? environment.tracking
            if !tracking.isZero && !tracking.isNaN {
                result[(kCTTrackingAttributeName as NSString) as NSAttributedString.Key] = tracking as NSNumber
            }
            let strikethroughInUse: Text.LineStyle?
            switch strikethrough {
            case .explicit(let value):
                strikethroughInUse = value
            case .implicit:
                strikethroughInUse = nil
            case .default:
                strikethroughInUse = environment.strikethroughStyle
            }
            if let strikethroughInUse = strikethroughInUse {
                result[.strikethroughStyle] = strikethroughInUse.nsUnderlineStyle.rawValue as NSNumber
                if let color = strikethroughInUse.color {
                    result[.strikethroughColor] = color.resolvedUIColor(in: environment)
                }
            }
            let underlineInUse: Text.LineStyle?
            switch underline {
            case .explicit(let value):
                underlineInUse = value
            case .implicit:
                underlineInUse = nil
            case .default:
                underlineInUse = environment.underlineStyle
            }
            if let underlineInUse = underlineInUse {
                result[.underlineStyle] = underlineInUse.nsUnderlineStyle.rawValue as NSNumber
                if let color = underlineInUse.color {
                    result[.underlineColor] = color.resolvedUIColor(in: environment)
                }
            }
            
            if includeDefaultAttributes || environment.shouldRedactContent {
                var parahraphStyle = makeParagraphStyle(environment: environment)
                if environment.shouldRedactContent {
                    parahraphStyle.baseWritingDirection = environment.layoutDirection == .leftToRight ? .leftToRight : .rightToLeft
                    parahraphStyle.alignment = .justified
                    parahraphStyle.lineBreakMode = .byCharWrapping
                }
                result[.paragraphStyle] = parahraphStyle as NSParagraphStyle
            }
            
            if let action = tapAction {
                result[.danceUI.textOnTapAction] = TextOnTapAction(action: { string, subrange, bounds, info in
                    action()
                })
            }
            // DanceUI Addition End
            return result
        }
        
        internal func cfAttributes(environment: EnvironmentValues,
                                   includeDefaultAttributes: Bool) -> CFDictionary {
            @_transparent
            func finalize(_ mutable: CFMutableDictionary) -> CFDictionary {
                return CFDictionaryCreateCopy(kCFAllocatorDefault, mutable)!
            }
            
            let maxAttributesToAppend: CFIndex = 8
            
            let cfAtributes = withUnsafePointer(to: kCFTypeDictionaryKeyCallBacks) { key in
                withUnsafePointer(to: kCFTypeDictionaryValueCallBacks) { value in
                    CFDictionaryCreateMutable(kCFAllocatorDefault, maxAttributesToAppend, key, value)!
                }
            }
            
            let ctFont: CTFont
            
            var combinedFontModifiers = environment.fontModifiers + fontModifiers
            combinedFontModifiers.removeAll { modifier in
                clearedFontModifiers.contains(modifier)
            }
            
            if let font = baseFont  {
                ctFont = font.platformFont(in: environment, fontModifiers: combinedFontModifiers)
            } else {
                let font = environment.effectiveFont
                ctFont = font.platformFont(in: environment, fontModifiers: combinedFontModifiers)
            }
            DanceUICTAttributesSetAttribute(cfAtributes, .font, ctFont)
            
            guard includeDefaultAttributes else {
                return finalize(cfAtributes)
            }
            
            let uiColor: UIColor
            if let foregroundColor = color {
                uiColor = foregroundColor.resolvedUIColor(in: environment)
            } else {
                uiColor = Color.foreground.resolvedUIColor(in: environment)
            }
            DanceUICTAttributesSetAttribute(cfAtributes, .foregroundColor, uiColor)
            
            let baselineOffset = baselineOffset ?? environment.baselineOffset
            if !baselineOffset.isZero && !baselineOffset.isNaN {
                DanceUICTAttributesSetAttribute(cfAtributes, .baselineOffset, baselineOffset)
            }
            let kerning = kerning ?? environment.kerning
            if !kerning.isZero && !kerning.isNaN {
                DanceUICTAttributesSetAttribute(cfAtributes, .kern, kerning)
            }
            let tracking = tracking ?? environment.tracking
            if !tracking.isZero && !tracking.isNaN {
                DanceUICTAttributesSetAttribute(cfAtributes, .tracking, tracking)
            }
            let strikethroughInUse: Text.LineStyle?
            switch strikethrough {
            case .explicit(let value):
                strikethroughInUse = value
            case .implicit:
                strikethroughInUse = nil
            case .default:
                strikethroughInUse = environment.strikethroughStyle
            }
            if let strikethroughInUse = strikethroughInUse {
                DanceUICTAttributesSetAttribute(cfAtributes, .strikethroughStyle, strikethroughInUse.nsUnderlineStyle.rawValue)
                if let color = strikethroughInUse.color {
                    let uiColor = color.resolvedUIColor(in: environment)
                    DanceUICTAttributesSetAttribute(cfAtributes, .strikethroughColor, uiColor)
                }
            }
            let underlineInUse: Text.LineStyle?
            switch underline {
            case .explicit(let value):
                underlineInUse = value
            case .implicit:
                underlineInUse = nil
            case .default:
                underlineInUse = environment.underlineStyle
            }
            if let underlineInUse = underlineInUse {
                DanceUICTAttributesSetAttribute(cfAtributes, .underlineStyle, underlineInUse.nsUnderlineStyle.rawValue)
                if let color = underlineInUse.color {
                    let uiColor = color.resolvedUIColor(in: environment)
                    DanceUICTAttributesSetAttribute(cfAtributes, .underlineColor, uiColor)
                }
            }
            
            let paragraphStyle = makeParagraphStyle(environment: environment)
            DanceUICTAttributesSetAttribute(cfAtributes, .paragraphStyle, paragraphStyle)
            
            return finalize(cfAtributes)
        }
    }
}

@available(iOS 13.0, *)

extension Text {
    
    @usableFromInline
    @frozen
    internal enum Modifier: Equatable {
        case color(_ : Color?)
        case font(_: Font?)
        case weight(_: Font.Weight)
        case kerning(_: CGFloat)
        case tracking(_: CGFloat)
        case baseline(_: CGFloat)
        case anyTextModifier(_ : AnyTextModifier)
        case tapAction(_: () -> Void)
        case italic
        case rounded
        
        @usableFromInline
        internal static func == (lhs: Modifier, rhs: Modifier) -> Bool {
            switch (lhs, rhs) {
            case (.color(let value0), .color(let value1)):
                return value0 == value1
            case (.anyTextModifier(let value0), .anyTextModifier(let value1)):
                return value0.isEqual(to: value1)
            case (.font(let value0), .font(let value1)):
                return value0 == value1
            case (.weight(let value0), .weight(let value1)):
                return value0 == value1
            case (.kerning(let value0), .kerning(let value1)):
                return value0 == value1
            case (.tracking(let value0), .tracking(let value1)):
                return value0 == value1
            case (.baseline(let value0), .baseline(let value1)):
                return value0 == value1
            case (.italic, italic):
                return true
            case (.rounded, .rounded):
                return true
            case (.tapAction(let lhs), .tapAction(let rhs)):
                return DGCompareValues(lhs: lhs, rhs: rhs)
            default:
                return false
            }
        }
    }
    
    private func modified(with modifier: Modifier) -> Text {
        var modifiers = self.modifiers
        modifiers.append(modifier)
        return .init(storage, modifiers: modifiers)
    }
}

@available(iOS 13.0, *)

extension Text {
    
    /// Sets the color of the text displayed by this view.
    ///
    /// Use this method to change the color of the text rendered by a text view.
    ///
    /// For example, you can display the names of the colors red, green, and
    /// blue in their respective colors:
    ///
    ///     HStack {
    ///         Text("Red").foregroundColor(.red)
    ///         Text("Green").foregroundColor(.green)
    ///         Text("Blue").foregroundColor(.blue)
    ///     }
    ///
    ///
    /// - Parameter color: The color to use when displaying this text.
    /// - Returns: A text view that uses the color value you supply.
    public func foregroundColor(_ color: Color?) -> Text {
        self.modified(with: .color(color))
    }
    
    /// Set the action to be triggered when the text is taped.
    ///
    /// Use this method to change the action that is triggered when the text is taped.
    ///
    /// For example, You can add a touch callback to a piece of text:
    ///
    ///     HStack {
    ///         Text("Red").onTapGesture {
    ///             // do something
    ///         }
    ///         Text("Green").foregroundColor(.green)
    ///         Text("Blue").foregroundColor(.blue)
    ///     }
    /// You can also add callback actions to a Cnmbined text with +
    ///
    ///     Text("Green").foregroundColor(.green)
    ///     +
    ///     Text("Red").onTapGesture {
    ///             // do something
    ///     }
    ///     +
    ///     Text("Blue").foregroundColor(.blue)
    ///
    ///
    /// - Parameter action: The action is triggered when the text is taped.
    /// - Returns: A text view that uses the tap action value you supply.
    public func onTap(perform action: @escaping () -> Void) -> Text {
        
        self.modified(with: .tapAction(action))
    }
    
    /// Sets the default font for text in the view.
    ///
    /// Use `font(_:)` to apply a specific font to an individual
    /// Text View, or all of the text views in a container.
    ///
    /// In the example below, the first text field has a font set directly,
    /// while the font applied to the following container applies to all of the
    /// text views inside that container:
    ///
    ///     VStack {
    ///         Text("Font applied to a text view.")
    ///             .font(.largeTitle)
    ///
    ///         VStack {
    ///             Text("These two text views have the same font")
    ///             Text("applied to their parent view.")
    ///         }
    ///         .font(.system(size: 16, weight: .light, design: .default))
    ///     }
    ///
    ///
    ///
    /// - Parameter font: The font to use when displaying this text.
    /// - Returns: Text that uses the font you specify.
    public func font(_ font: Font?) -> Text {
        self.modified(with: .font(font))
    }
    
    /// Sets the font weight of the text.
    ///
    /// - Parameter weight: One of the available font weights.
    ///
    /// - Returns: Text that uses the font weight you specify.
    public func fontWeight(_ weight: Font.Weight?) -> Text {
        self.modified(with: .weight(weight ?? .regular))
    }
    
    /// Make the font weight of this text heavier.
    ///
    /// - Returns: Heavier text.
    public func bold() -> Text {
        self.modified(with: .anyTextModifier(BoldTextModifier(isActive: true)))
    }
    
    /// Applies a bold font weight to the text.
    ///
    /// - Parameter isActive: A Boolean value that indicates
    ///   whether text has bold styling.
    ///
    /// - Returns: Bold text.
    public func bold(_ isActive: Bool) -> Text {
        self.modified(with: .anyTextModifier(BoldTextModifier(isActive: isActive)))
    }
    
    /// Applies italics to this text.
    ///
    /// - Returns: Italic text.
    public func italic() -> Text {
        self.modified(with: .italic)
    }
    
    /// Applies italics to the text.
    ///
    /// - Parameter isActive: A Boolean value that indicates
    ///   whether italic styling is added.
    ///
    /// - Returns: Italic text.
    public func italic(_ isActive: Bool) -> Text {
        self.modified(with: .anyTextModifier(ItalicTextModifier(isActive: isActive)))
    }
    
    /// Applies a strikethrough to this text.
    ///
    /// - Parameters:
    ///   - active: A Boolean value that indicates whether the text has a
    ///     strikethrough applied.
    ///   - color: The color of the strikethrough. If `color` is `nil`, the
    ///     strikethrough uses the default foreground color.
    /// - Returns: Text with a line through its center.
    public func strikethrough(_ isActive: Bool = true, color: Color? = nil) -> Text {
        return self.modified(with: .anyTextModifier(StrikethroughTextModifier(isActive, .single, color: color)))
    }
    
    /// Applies an underline to this text.
    ///
    /// - Parameters:
    ///   - active: A Boolean value that indicates whether the text has an
    ///     underline.
    ///   - color: The color of the underline. If `color` is `nil`, the
    ///     underline uses the default foreground color.
    /// - Returns: Text with a line running along its baseline.
    public func underline(_ isActive: Bool = true, color: Color? = nil) -> Text {
        return self.modified(with: .anyTextModifier(UnderlineTextModifier(isActive, .single, color: color)))
    }
    
    /// Sets the spacing, or kerning, between characters.
    ///
    /// Kerning defines the offset, in points, that a text view should shift
    /// characters from the default spacing. Use positive kerning to widen the
    /// spacing between characters. Use negative kerning to tighten the spacing
    /// between characters.
    ///
    ///     VStack(alignment: .leading) {
    ///         Text("ABCDEF").kerning(-3)
    ///         Text("ABCDEF")
    ///         Text("ABCDEF").kerning(3)
    ///     }
    ///
    /// The last character in the first case, which uses negative kerning,
    /// experiences cropping because the kerning affects the trailing edge of
    /// the text view as well.
    ///
    ///
    /// Kerning attempts to maintain ligatures. For example, the Hoefler Text
    /// font uses a ligature for the letter combination _ffl_, as in the word
    /// _raffle_, shown here with a small negative and a small positive kerning:
    ///
    ///
    /// The *ffl* letter combination keeps a constant shape as the other letters
    /// move together or apart. Beyond a certain point in either direction,
    /// however, kerning does disable nonessential ligatures.
    ///
    ///
    /// - Important: If you add both the ``Text/tracking(_:)`` and
    ///   ``Text/kerning(_:)`` modifiers to a view, the view applies the
    ///   tracking and ignores the kerning.
    ///
    /// - Parameter kerning: The spacing to use between individual characters in
    ///   this text. Value of `0` sets the kerning to the system default value.
    ///
    /// - Returns: Text with the specified amount of kerning.
    public func kerning(_ kerning: CGFloat) -> Text {
        self.modified(with: .kerning(kerning))
    }
    
    /// Sets the tracking for the text.
    ///
    /// Tracking adds space, measured in points, between the characters in the
    /// text view. A positive value increases the spacing between characters,
    /// while a negative value brings the characters closer together.
    ///
    ///     VStack(alignment: .leading) {
    ///         Text("ABCDEF").tracking(-3)
    ///         Text("ABCDEF")
    ///         Text("ABCDEF").tracking(3)
    ///     }
    ///
    /// The code above uses an unusually large amount of tracking to make it
    /// easy to see the effect.
    ///
    ///
    /// The effect of tracking resembles that of the ``Text/kerning(_:)``
    /// modifier, but adds or removes trailing whitespace, rather than changing
    /// character offsets. Also, using any nonzero amount of tracking disables
    /// nonessential ligatures, whereas kerning attempts to maintain ligatures.
    ///
    /// - Important: If you add both the ``Text/tracking(_:)`` and
    ///   ``Text/kerning(_:)`` modifiers to a view, the view applies the
    ///   tracking and ignores the kerning.
    ///
    /// - Parameter tracking: The amount of additional space, in points, that
    ///   the view should add to each character cluster after layout. Value of `0`
    ///   sets the tracking to the system default value.
    ///
    /// - Returns: Text with the specified amount of tracking.
    public func tracking(_ tracking: CGFloat) -> Text {
        self.modified(with: .tracking(tracking))
    }
    
    /// Sets the vertical offset for the text relative to its baseline.
    ///
    /// Change the baseline offset to move the text in the view (in points) up
    /// or down relative to its baseline. The bounds of the view expand to
    /// contain the moved text.
    ///
    ///     HStack(alignment: .top) {
    ///         Text("Hello")
    ///             .baselineOffset(-10)
    ///             .border(Color.red)
    ///         Text("Hello")
    ///             .border(Color.green)
    ///         Text("Hello")
    ///             .baselineOffset(10)
    ///             .border(Color.blue)
    ///     }
    ///     .background(Color(white: 0.9))
    ///
    /// By drawing a border around each text view, you can see how the text
    /// moves, and how that affects the view.
    ///
    ///
    /// The first view, with a negative offset, grows downward to handle the
    /// lowered text. The last view, with a positive offset, grows upward. The
    /// enclosing ``HStack`` instance, shown in gray, ensures all the text views
    /// remain aligned at their top edge, regardless of the offset.
    ///
    /// - Parameter baselineOffset: The amount to shift the text vertically (up
    ///   or down) relative to its baseline.
    ///
    /// - Returns: Text that's above or below its baseline.
    public func baselineOffset(_ baselineOffset: CGFloat) -> Text {
        self.modified(with: .baseline(baselineOffset))
    }
    
    /// Modifies the text view's font to use fixed-width digits, while leaving
    /// other characters proportionally spaced.
    ///
    /// This modifier only affects numeric characters, and leaves all other
    /// characters unchanged.
    ///
    /// The following example shows the effect of `monospacedDigit()` on a
    /// text view. It arranges two text views in a ``VStack``, each displaying
    /// a formatted date that contains many instances of the character 1.
    /// The second text view uses the `monospacedDigit()`. Because 1 is
    /// usually a narrow character in proportional fonts, applying the
    /// modifier widens all of the 1s, and the text view as a whole.
    /// The non-digit characters in the text view remain unaffected.
    ///
    ///     let myDate = DateComponents(
    ///         calendar: Calendar(identifier: .gregorian),
    ///         timeZone: TimeZone(identifier: "EST"),
    ///         year: 2011,
    ///         month: 1,
    ///         day: 11,
    ///         hour: 11,
    ///         minute: 11
    ///     ).date!
    ///
    ///     var body: some View {
    ///         VStack(alignment: .leading) {
    ///             Text(myDate.formatted(date: .long, time: .complete))
    ///                 .font(.system(size: 20))
    ///             Text(myDate.formatted(date: .long, time: .complete))
    ///                 .font(.system(size: 20))
    ///                 .monospacedDigit()
    ///         }
    ///         .padding()
    ///         .navigationTitle("monospacedDigit() Modifier")
    ///     }
    ///
    ///
    /// If the base font of the text view doesn't support fixed-width digits,
    /// the font remains unchanged.
    ///
    /// - Returns: A text view with a modified font that uses fixed-width
    /// numeric characters, while leaving other characters proportionally
    /// spaced.
    public func monospacedDigit() -> Text {
        self.modified(with: .anyTextModifier(MonospacedDigitTextModifier()))
    }
    
    /// Modifies the font of the text to use the fixed-width variant
    /// of the current font, if possible.
    ///
    /// - Parameter isActive: A Boolean value that indicates
    ///   whether monospaced styling is added. Default value is `true`.
    ///
    /// - Returns: Monospaced text.
    public func monospaced(_ isActive: Bool = true) -> Text {
        self.modified(with: .anyTextModifier(MonospacedTextModifier(isActive)))
    }
}

@available(iOS 13.0, *)

// MARK: - Text.Resolved

extension Text {
    
    internal struct Resolved {
        
        internal var style: Text.Style
        
        internal var mutableAttributedString: NSMutableAttributedString? = nil
        
        
        internal init() {
            style = Style()
            mutableAttributedString = nil
        }
        
        internal init(style: Style) {
            self.style = style
            mutableAttributedString = nil
        }
        
        internal mutating func append(_ image: Image.Resolved, in environment: EnvironmentValues) {
            let attributes = style.nsAttributes(environment: environment, includeDefaultAttributes: mutableAttributedString != nil)
            
            guard !environment.shouldRedactContent else {
                append("", with: attributes, in: environment) // neverUsed0xbcbfef
                return
            }
            let nsTextAttachment = NSTextAttachment.init()
            var graphicsImage = image.image
            if nil == image.image.maskColor {
                graphicsImage.maskColor = nil
            } else {
                var usedColor: Color
                if let foregroundColor = self.style.color {
                    usedColor = foregroundColor
                } else {
                    usedColor = Color.foreground
                }
                
                let realColor = usedColor.resolvePaint(in: environment)
                graphicsImage.maskColor = realColor
            }
            nsTextAttachment.image = graphicsImage.makePlatformImage(fixedSymbolConfiguration: true, flattenMaskColor: true)
            
            let nsAttributedString = NSMutableAttributedString(attachment: nsTextAttachment)
            nsAttributedString.addAttributes(attributes,
                                             range: nsAttributedString.range)
            append(nsAttributedString)
        }
        
        internal mutating func append<T: StringProtocol>(_ text: T, in environment: EnvironmentValues) {
            let locale = environment.locale
            var string: String = ""
            
            switch environment.textCase {
            case .lowercase:
                string = text.lowercased(with: locale)
            case .uppercase:
                string = text.uppercased(with: locale)
            case .none:
                string = String(text)
            }
            
            let attributes = style.nsAttributes(environment: environment,
                                                includeDefaultAttributes: true)
            append(string, with: attributes, in: environment)
        }
        
        internal mutating func append_lowBridgingOverhead<T: StringProtocol>(_ text: T, in environment: EnvironmentValues) {
            let locale = environment.locale
            var string: String = ""
            
            switch environment.textCase {
            case .lowercase:
                string = text.lowercased(with: locale)
            case .uppercase:
                string = text.uppercased(with: locale)
            case .none:
                string = String(text)
            }
            
            let attributes = style.cfAttributes(environment: environment,
                                                includeDefaultAttributes: true)
            append_lowBridgingOverhead(string, with: attributes, in: environment)
        }
        
        internal mutating func append(_ string: String,
                                      with attributes: [NSAttributedString.Key: Any],
                                      in environment: EnvironmentValues) {
            var string = string
            if environment.shouldRedactContent {
                string = String(repeating: "􀮷", count: string.count)
            }
            let attributedString = NSAttributedString(string: string,
                                                      attributes: attributes)
            
            append(attributedString)
        }
        
        internal mutating func append_lowBridgingOverhead(_ string: String,
                                                          with attributes: CFDictionary /* [NSAttributedString.Key: Any] */,
                                                          in environment: EnvironmentValues) {
            var string = string
            if environment.shouldRedactContent {
                string = String(repeating: "􀮷", count: string.count)
            }
            let attributedString = NSAttributedString(string: string,
                                                      cfAttributes: attributes)
            
            append(attributedString)
        }
        
        internal mutating func append(_ attributedString: NSAttributedString) {
            let attributedString = NSMutableAttributedString(attributedString: attributedString)
            
            if #unavailable(iOS 16) {
                if #available(iOS 15, *) {
                    attributedString.enumerateAttribute(.attachment, in: attributedString.range) { value, range, _ in
                        if let nsTextAttachment = value as? NSTextAttachment,
                           let image = nsTextAttachment.image,
                           let yOffset = attributedString.attribute(.baselineOffset, at: range.lowerBound, effectiveRange: nil) as? CGFloat {
                            var newBounds = nsTextAttachment.bounds
                            newBounds.origin.y -= yOffset
                            if nsTextAttachment.bounds.size == .zero {
                                newBounds.size = image.size
                            }

                            let newAttachment = NSTextAttachment()
                            newAttachment.image = image
                            newAttachment.bounds = newBounds
                            attributedString.addAttribute(.attachment, value: newAttachment, range: range)
                        }
                    }
                }
            }
            guard let mutableAttributedString = mutableAttributedString else {
                self.mutableAttributedString = attributedString.mutableCopy() as? NSMutableAttributedString
                return
            }
            mutableAttributedString.append(attributedString)
        }
        
        internal mutating func append(_ attributedString: NSAttributedString,
                                      in environment: EnvironmentValues,
                                      with options: Text.ResolveOptions) {
            
            let newAttributedString: NSAttributedString
            if let textCase = environment.textCase {
                newAttributedString = textCase.applied(to: attributedString, locale: environment.locale)
            } else {
                newAttributedString = attributedString
            }
            
            let range = newAttributedString.range

            newAttributedString.enumerateAttributes(
                in: range,
                options: .init()) { [
                    environment,
                    newAttributedString
                ] dictionary, partRange, _ in
                    var dictionary = dictionary
                    var style = self.style
                    dictionary.transferAttributedStringStyles(to: &style)
                    if dictionary[.link] != nil {
                        dictionary[.link] = nil
                        if nil == dictionary[.danceUIForegroundColor] as? Color {
                            style.color = Color.accentColor
                        }
                    }
                    if dictionary[.danceUI.textOnTapAction] != nil && self.style.tapAction != nil {
#if DEBUG || DANCE_UI_INHOUSE
                        print("Text and its content NSAttributeString(\(newAttributedString.string)) cannot have tap actions set simultaneously, as this will result in a conflict.")
#endif
                    }
                    
                    if dictionary[.attachment] != nil && dictionary[.font] != nil {
#if DEBUG || DANCE_UI_INHOUSE
                        print("NSTextAttachment shall be set without font attribute.")
#endif
                        dictionary[.font] = nil
                    }
                    
                    let attributes = style.nsAttributes(
                        environment: environment,
                        includeDefaultAttributes: true
                    )
                    var finalDictionary = dictionary
                    finalDictionary.merge(attributes) { currentValue, newValue in
                       return currentValue
                    }
                    let partString = newAttributedString.attributedSubstring(from: partRange).string
                    self.append(partString, with: finalDictionary, in: environment)
                }
            
            guard mutableAttributedString != nil else {
                self.mutableAttributedString = NSMutableAttributedString(attributedString: attributedString)
                return
            }
            return
        }
    }
    
    @inline(__always)
    internal func resolveText(in environment: EnvironmentValues) -> String {
        switch storage {
        case .verbatim(let string):
            return string
        case .anyTextStorage(_):
            let attributeString = self.resolveString(in: environment, includeDefaultAttributes: false, options: .zero)
            return attributeString?.string ?? ""
        }
    }
    
    public func _resolveText(in environment: EnvironmentValues) -> String {
        switch storage {
        case .verbatim(let string):
            return string
        case .anyTextStorage(_):
            let attributeString = self.resolveString(in: environment, includeDefaultAttributes: false, options: .zero)
            return attributeString?.string ?? ""
        }
    }
    
    private static func makeStyle(_ style: inout Style, modifiers: [Text.Modifier]) {
        for modifier in modifiers.reversed() {
            switch modifier {
            case .color(let color):
                style.color = color ?? .primary
            case .font(let font):
                style.baseFont = font
            case .weight(let weight):
                style.fontModifiers.append(.dynamic(modifier: Font.WeightModifier(weight: weight)))
            case .kerning(let kerning):
                style.kerning = kerning
            case .tracking(let tracking):
                style.tracking = tracking
            case .baseline(let baselineOffset):
                style.baselineOffset = baselineOffset
            case .anyTextModifier(let textModifier):
                textModifier.modify(style: &style)
            case .tapAction(let action):
                style.tapAction = action
                // DanceUI Addition End
            case .italic:
                style.addFontModifier(type: Font.ItalicModifier.self)
            case .rounded:
                style.addFontModifier(type: Font.RoundedModifier.self)
            }
        }
    }
    
    internal func resolveString(in environment: EnvironmentValues,
                                includeDefaultAttributes: Bool,
                                options: ResolveOptions) -> NSAttributedString? {
        var style = Style()
        Text.makeStyle(&style, modifiers: self.modifiers)
        var resolved = Resolved(style: style)
        
        switch storage {
        case .anyTextStorage(let textStorage):
            textStorage.resolve(into: &resolved, in: environment, options: options)
        case .verbatim(let string):
            resolved.append_lowBridgingOverhead(string, in: environment)
        }
        let paragraphStyle = makeParagraphStyle(environment: environment)
        guard let mutableAttributedString = resolved.mutableAttributedString else {
            return nil
        }
        
        let attributedStringCopy = NSAttributedString(attributedString: mutableAttributedString)
        attributedStringCopy.enumerateAttribute(.paragraphStyle, in: NSRange(0..<mutableAttributedString.length)) { originParagraphStyle, partRange, _ in
            guard let _ = originParagraphStyle as? NSParagraphStyle else {
                mutableAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: partRange)
                return
            }
            return
        }
        
        return mutableAttributedString
    }
    
    internal func resolve(into resolved: inout Text.Resolved,
                          in environment: EnvironmentValues,
                          with options: ResolveOptions) {
        let originStyle = resolved.style
        Text.makeStyle(&resolved.style, modifiers: modifiers)
        switch storage {
        case .anyTextStorage(let textStorage):
            textStorage.resolve(into: &resolved, in: environment, options: options)
        case .verbatim(let string):
            resolved.append(string, in: environment)
        }
        resolved.style = originStyle
    }
}
