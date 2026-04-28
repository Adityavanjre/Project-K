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

/// The key used to look up an entry in a strings file or strings dictionary
/// file.
///
/// Initializers for several DanceUI types -- such as ``Text``, ``Toggle``,
/// ``Picker`` and others --  implicitly look up a localized string when you
/// provide a string literal. When you use the initializer `Text("Hello")`,
/// DanceUI creates a `LocalizedStringKey` for you and uses that to look up a
/// localization of the `Hello` string. This works because `LocalizedStringKey`
/// conforms to
/// <doc://com.apple.documentation/documentation/Swift/ExpressibleByStringLiteral>.
///
/// Types whose initializers take a `LocalizedStringKey` usually have
/// a corresponding initializer that accepts a parameter that conforms to
/// <doc://com.apple.documentation/documentation/Swift/StringProtocol>. Passing
/// a `String` variable to these initializers avoids localization, which is
/// usually appropriate when the variable contains a user-provided value.
///
/// As a general rule, use a string literal argument when you want
/// localization, and a string variable argument when you don't. In the case
/// where you want to localize the value of a string variable, use the string to
/// create a new `LocalizedStringKey` instance.
///
/// The following example shows how to create ``Text`` instances both
/// with and without localization. The title parameter provided to the
/// ``Section`` is a literal string, so DanceUI creates a
/// `LocalizedStringKey` for it. However, the string entries in the
/// `messageStore.today` array are `String` variables, so the ``Text`` views
/// in the list use the string values verbatim.
///
///     List {
///         Section(header: Text("Today")) {
///             ForEach(messageStore.today) { message in
///                 Text(message.title)
///             }
///         }
///     }
///
/// If the app is localized into Japanese with the following
/// translation of its `Localizable.strings` file:
///
/// ```other
/// "Today" = "今日";
/// ```
///
/// When run in Japanese, the example produces a
/// list like the following, localizing "Today" for the section header, but not
/// the list items.
///
@frozen
@available(iOS 13.0, *)
public struct LocalizedStringKey : Equatable, ExpressibleByStringInterpolation {
    
    @usableFromInline
    internal let key: String
    @usableFromInline
    internal let hasFormatting: Bool
    @usableFromInline
    internal let arguments: [FormatArgument]
    
    /// Creates a localized string key from the given string value.
    ///
    /// - Parameter value: The string to use as a localization key.
    @inlinable
    public init(_ value: String) {
        self.init(stringLiteral: value)
    }
    
    /// Creates a localized string key from the given string literal.
    ///
    /// - Parameter value: The string literal to use as a lLocalizedStringKeyocalization key.
    public init(stringLiteral value: String) {
        key = value
        hasFormatting = false
        arguments = []
    }
    
    /// Creates a localized string key from the given string interpolation.
    ///
    /// To create a localized string key from a string interpolation, use
    /// the `\()` string interpolation syntax. Swift matches the parameter
    /// types in the expression to one of the `appendInterpolation` methods
    /// in ``LocalizedStringKey/StringInterpolation``. The interpolated
    /// types can include numeric values, Foundation types, and DanceUI
    /// ``Text`` and ``Image`` instances.
    ///
    /// The following example uses a string interpolation with two arguments:
    /// an unlabeled
    /// <doc://com.apple.documentation/documentation/Foundation/Date>
    /// and a ``Text/DateStyle`` labeled `style`. The compiler maps these to the
    /// method
    /// ``LocalizedStringKey/StringInterpolation/appendInterpolation(_:style:)``
    /// as it builds the string that it creates the
    /// ``LocalizedStringKey`` with.
    ///
    ///     let key = LocalizedStringKey("Date is \(company.foundedDate, style: .offset)")
    ///     let text = Text(key) // Text contains "Date is +45 years"
    ///
    /// You can write this example more concisely, implicitly creating a
    /// ``LocalizedStringKey`` as the parameter to the ``Text``
    /// initializer:
    ///
    ///     let text = Text("Date is \(company.foundedDate, style: .offset)")
    ///
    /// - Parameter stringInterpolation: The string interpolation to use as the
    ///   localization key.
    public init(stringInterpolation: LocalizedStringKey.StringInterpolation) {
        key = stringInterpolation.key
        arguments = stringInterpolation.arguments
        hasFormatting = true
    }
    
    /// A type that represents an extended grapheme cluster literal.
    ///
    /// Valid types for `ExtendedGraphemeClusterLiteralType` are `Character`,
    /// `String`, and `StaticString`.
    public typealias ExtendedGraphemeClusterLiteralType = String
    
    /// A type that represents a string literal.
    ///
    /// Valid types for `StringLiteralType` are `String` and `StaticString`.
    public typealias StringLiteralType = String
    
    /// A type that represents a Unicode scalar literal.
    ///
    /// Valid types for `UnicodeScalarLiteralType` are `Unicode.Scalar`,
    /// `Character`, `String`, and `StaticString`.
    public typealias UnicodeScalarLiteralType = String
    
    internal func resolvesToEmpty(in environment: EnvironmentValues, options: Text.ResolveOptions, table: String?, bundle: Bundle?) -> Bool {
        let bundle: Bundle = bundle ?? Bundle.main
        let localeEnv = environment.locale
        let localizedString = _LocalizeString(bundle: bundle, key: key, table: table, locale: localeEnv)
        
        guard !localizedString.isEmpty else {
            return false
        }
        if hasFormatting {
            let cvarArgs = arguments.map { argument in
                argument.resolve(in: environment)
            }
            let transed = String(format: localizedString, locale: localeEnv, arguments: cvarArgs)
            return !transed.isEmpty
        } else {
            return true
        }
    }
    
    internal func resolve(into resolved: inout Text.Resolved, in environment: EnvironmentValues, options: Text.ResolveOptions, table: String?, bundle: Bundle?) {
        let localeEnv = environment.locale
        let localizedAttributedString = _LocalizeAttributedString(bundle: bundle ?? .main, key: key, table: table, locale: localeEnv)
        if hasFormatting {
            let style = resolved.style
            let cvarArgs = getArgumentsForInflection(for: localizedAttributedString, in: environment, with: options, including: style)
            let translatedRaw: NSAttributedString = withVaList(cvarArgs) { va_list in
                return NSAttributedString(format: localizedAttributedString, locale: localeEnv, arguments: va_list)
            }
            resolveArguments(from: translatedRaw, into: &resolved, in: environment, options: options)
        } else {
            resolved.append(localizedAttributedString, in: environment, with: options)
        }
    }
    
    internal func resolveArguments(from translatedRaw: NSAttributedString, into resolved: inout Text.Resolved, in environment: EnvironmentValues, options: Text.ResolveOptions) {
        let arguments = getTextArguments()
        guard arguments.count > 0 else {
            resolved.append(translatedRaw, in: environment, with: options)
            return
        }
        scan(
            string: translatedRaw.string,
            in: environment,
            options: options,
            textArgs: arguments) { string, indexRange in
                let partTranslatedRaw = translatedRaw.attributedSubstring(from: NSRange(range: indexRange, in: translatedRaw.string))
                resolved.append(partTranslatedRaw, in: environment, with: options)
            } appendText: { text, indexRange in
                let nsIndexRange = NSRange(range: indexRange, in: translatedRaw.string)
                let partTranslatedRaw = translatedRaw.attributes(at: nsIndexRange.lowerBound, longestEffectiveRange: nil, in: nsIndexRange)
                let newText = text.withInlinePresentationIntent(from: partTranslatedRaw)
                newText.resolve(into: &resolved, in: environment, with: options)
            }
    }
    
    private func scan(string: String,
                      in environment: EnvironmentValues,
                      options: Text.ResolveOptions,
                      textArgs: [(Int, FormatArgument)],
                      appendLiteral: (String, Range<String.Index>) -> (),
                      appendText: (Text, Range<String.Index>) -> ()) {
        let textArgsDic = [Int: FormatArgument](uniqueKeysWithValues: textArgs)
        
//        let scanner = Scanner(string: string)
//        let delimiterCharacterSet = CharacterSet(charactersIn: "\(FormatArgument.Token.delimiter)")
//        while(!scanner.isAtEnd) {
//            let rawStringPreIndex = scanner.currentIndex
//            let rawString = scanner.scanUpToCharacters(from: delimiterCharacterSet)
//
//            if let rawString = rawString {
//                let rawStringNowIndex = scanner.currentIndex
//                guard rawStringNowIndex >= rawStringPreIndex else {
//                    _danceuiFatalError()
//                }
//                appendLiteral(rawString, rawStringPreIndex..<rawStringNowIndex)
//            }
//
//            let startDelimiterIndex = scanner.currentIndex
//            let startDelimiter = scanner.scanCharacters(from: delimiterCharacterSet)
//            if startDelimiter == nil {
//                continue
//            }
//            let textIdRawNumber = scanner.scanInt(representation: .decimal)
//            if let textId = textIdRawNumber {
//                let endDelimiter = scanner.scanCharacter()
//                if endDelimiter == nil {
//                    continue
//                }
//                let textToBeUsed = textArgsDic[textId]
//                if let arg = textToBeUsed {
//                    let textNowIndex = scanner.currentIndex
//                    if case .text((let text, _)) = arg.storage {
//                        appendText(text, startDelimiterIndex..<textNowIndex)
//                    } else {
//                        _danceuiFatalError()
//                    }
//                } else {
//                    logger.warning("[DanceUI Localization] No matching target found for navigation link presenting value of type \(string).")
//                    continue
//                }
//            } else {
//                continue
//            }
//        }
        
        let delimiter = FormatArgument.Token.delimiter

        var stringToBeScanned = String.SubSequence(stringLiteral: string)
        while(true) {
            let splitedString = stringToBeScanned.split(separator: delimiter, maxSplits: 2, omittingEmptySubsequences: false)

            let rawString = splitedString.first
            if let rawString = rawString, !rawString.isEmpty {
                appendLiteral(String(rawString), rawString.startIndex..<rawString.endIndex)
            }
            let idString = splitedString.second
            if let idString = idString, !idString.isEmpty {
                let id = Int(String(idString))
                if let id = id, let textToBeUsed = textArgsDic[id] {
                    if case .text((let text, _)) = textToBeUsed.storage {
                        appendText(text, idString.startIndex..<idString.endIndex)
                    } else {
                        _danceuiFatalError()
                    }
                }
            }
            let remainingString = splitedString.third
            if let remainingString = remainingString {
                stringToBeScanned = remainingString
            } else {
                break
            }
        }
        
    }
    
    internal func getTextArguments() -> [(Int, FormatArgument)] {
        guard arguments.count > 0 else {
            return []
        }
        return arguments.filter { formatArgument in
            if case .text((_, _)) = formatArgument.storage {
                return true
            }
            return false
        }.map { formatArgument in
            if case .text((_, let token)) = formatArgument.storage {
                return (token.id, formatArgument)
            } else {
                _danceuiFatalError()
            }
        }
    }
    
    internal func getArgumentsForInflection(for key: NSAttributedString,
                                            in environment: EnvironmentValues,
                                            with options: Text.ResolveOptions,
                                            including style: Text.Style? = nil) -> [CVarArg] {
        arguments.map { argument in
            // TODO: _notImplemented hasMorphologyAttribute unused
//            if case .text((let text, let _)) = argument.storage {
//                if case .anyTextStorage(let textStorage) = text.storage {
//                    if let storage = textStorage as? Text.AttributedStringTextStorage {
//                        if storage.str.hasMorphologyAttribute {
//                            _notImplemented()
//                        }
//                    }
//                }
//            }
            return argument.resolve(in: environment)
        }
    }
    
    internal static var cache: [Bundle: String?] = [:]
    
    internal static var lock: SpinLock = .init()
}

@inline(__always)
@available(iOS 13.0, *)
internal func _LocalizeAttributedString(bundle: Bundle, key: String, table: String?, locale: Locale) -> NSAttributedString {
    if let bestLocale = _getBestLocalization(bundle: bundle, locale: locale) {
        return bundle.localizedAttributedStringForKey(key: key, value: nil, table: table, localization: bestLocale, locale: locale)
    } else {
        return bundle.localizedAttributedStringForKey(key: key, value: nil, table: table, localization: nil, locale: locale)
    }
}

@inline(__always)
@available(iOS 13.0, *)
internal func _LocalizeString(bundle: Bundle, key: String, table: String?, locale: Locale) -> String {
    if let bestLocale = _getBestLocalization(bundle: bundle, locale: locale) {
        return bundle.localizedAttributedStringForKey(key: key, value: nil, table: table, localization: bestLocale, locale: locale).string
    } else {
        return bundle.localizedAttributedStringForKey(key: key, value: nil, table: table, localization: locale._languageFullCode, locale: locale).string
    }
}

@inline(__always)
@available(iOS 13.0, *)
internal func _getBestLocalization(bundle: Bundle, locale: Locale) -> String? {
    guard Locale.current != locale else {
        return nil
    }
    guard let languargeCode = locale.languageCode else {
        return nil
    }
    
    return LocalizedStringKey.lock.withLock {
        if let bundleCacheLocale =  LocalizedStringKey.cache[bundle], bundleCacheLocale == languargeCode {
            return bundleCacheLocale
        } else {
            let preferredLanguageCode = Bundle.preferredLocalizations(from: bundle.localizations, forPreferences: [languargeCode]).first
            LocalizedStringKey.cache[bundle] = preferredLanguageCode
            return preferredLanguageCode
        }
    }
}

@available(iOS 13.0, *)
extension Text {
    
    internal func withInlinePresentationIntent(from attributes: [NSAttributedString.Key: Any]) -> Text {
        var attributes = attributes
        
        attributes.translateToDanceUIAttributes()
        
        var resultText: Text = self
        if let inlinePresentationIntentType = attributes[.inlinePresentationIntent] as? InlinePresentationIntent {
            if inlinePresentationIntentType.hasType(.emphasized) {
                resultText = resultText.italic()
            }
            if inlinePresentationIntentType.hasType(.stronglyEmphasized) {
                resultText = resultText.bold()
            }
            if inlinePresentationIntentType.hasType(.code) {
                if #available(iOS 13.0, *) {
                    resultText = resultText.monospaced()
                }
            }
            if inlinePresentationIntentType.hasType(.strikethrough) {
                resultText = resultText.strikethrough()
            }
        }
        
        return resultText
    }
}

@available(iOS 13.0, *)
extension Locale {
    
    @inline(__always)
    internal var _languageFullCode: String {
        
        guard let languageCode = self.languageCode else {
            return ""
        }
        
        if let variantCode = self.scriptCode {
            return languageCode + "-" + variantCode
        } else {
            return languageCode
        }
    }
}
