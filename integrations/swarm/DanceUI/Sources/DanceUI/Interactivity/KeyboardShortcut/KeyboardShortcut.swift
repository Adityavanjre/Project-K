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

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct KeyboardShortcut {

    /// Options for how a keyboard shortcut participates in automatic localization.
    ///
    /// A shortcut's `key` that is defined on an US-English keyboard
    /// layout might not be reachable on international layouts.
    /// For example the shortcut `⌘[` works well for the US layout but is
    /// hard to reach for German users.
    /// On the German keyboard layout, pressing `⌥5` will produce
    /// `[`, which causes the shortcut to become `⌥⌘5`.
    /// If configured, which is the default behavior, automatic shortcut
    /// remapping will convert it to `⌘Ö`.
    ///
    /// In addition to that, some keyboard shortcuts carry information
    /// about directionality.
    /// Right-aligning a block of text or seeking forward in context of music
    /// playback are such examples. These kinds of shortcuts benefit from the option
    /// ``KeyboardShortcut/Localization-swift.struct/withoutMirroring``
    /// to tell the system that they won't be flipped when running in a
    /// right-to-left context.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public struct Localization {

        internal enum Style {
            
            case automatic

            case withoutMirroring

            case custom
        }
        
        internal let style : Style
        
        /// Remap shortcuts to their international counterparts, mirrored for
        /// right-to-left usage if appropriate.
        ///
        /// This is the default configuration.
        public static let automatic: KeyboardShortcut.Localization = Localization(style: .automatic)

        /// Don't mirror shortcuts.
        ///
        /// Use this for shortcuts that always have a specific directionality, like
        /// aligning something on the right.
        ///
        /// Don't use this option for navigational shortcuts like "Go Back" because navigation
        /// is flipped in right-to-left contexts.
        public static let withoutMirroring: KeyboardShortcut.Localization = Localization(style: .withoutMirroring)

        /// Don't use automatic shortcut remapping.
        ///
        /// When you use this mode, you have to take care of international use-cases separately.
        public static let custom: KeyboardShortcut.Localization = Localization(style: .custom)
    }

    /// The standard keyboard shortcut for the default button, consisting of
    /// the Return (↩) key and no modifiers.
    ///
    /// On macOS, the default button is designated with special coloration. If
    /// more than one control is assigned this shortcut, only the first one is
    /// emphasized.
    public static let defaultAction: KeyboardShortcut = .init(.return, modifiers: [])

    /// The standard keyboard shortcut for cancelling the in-progress action
    /// or dismissing a prompt, consisting of the Escape (⎋) key and no
    /// modifiers.
    public static let cancelAction: KeyboardShortcut = .init(.escape, modifiers: [])

    /// The key equivalent that the user presses in conjunction with any
    /// specified modifier keys to activate the shortcut.
    public var key: KeyEquivalent

    /// The modifier keys that the user presses in conjunction with a key
    /// equivalent to activate the shortcut.
    public var modifiers: EventModifiers

    /// The localization strategy to apply to this shortcut.
    public var localization: KeyboardShortcut.Localization

    /// Creates a new keyboard shortcut with the given key equivalent and set of
    /// modifier keys.
    ///
    /// The localization configuration defaults to ``KeyboardShortcut/Localization-swift.struct/automatic``.
    public init(_ key: KeyEquivalent, modifiers: EventModifiers = .command) {
        self.key = key
        self.modifiers = modifiers
        self.localization = .automatic
    }

    /// Creates a new keyboard shortcut with the given key equivalent and set of
    /// modifier keys.
    ///
    /// Use the `localization` parameter to specify a localization strategy
    /// for this shortcut.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(_ key: KeyEquivalent, modifiers: EventModifiers = .command, localization: KeyboardShortcut.Localization) {
        self.key = key
        self.modifiers = modifiers
        self.localization = localization
    }
}

@available(iOS 13.0, *)
extension KeyboardShortcut: Hashable {
    
    public static func == (lhs: KeyboardShortcut, rhs: KeyboardShortcut) -> Bool {
        lhs.key.character == rhs.key.character &&
        lhs.modifiers == rhs.modifiers &&
        lhs.localization.style == rhs.localization.style
    }
    
    /// Hashes the essential components of this value by feeding them into the
    /// given hasher.
    ///
    /// Implement this method to conform to the `Hashable` protocol. The
    /// components used for hashing must be the same as the components compared
    /// in your type's `==` operator implementation. Call `hasher.combine(_:)`
    /// with each of these components.
    ///
    /// - Important: Never call `finalize()` on `hasher`. Doing so may become a
    ///   compile-time error in the future.
    ///
    /// - Parameter hasher: The hasher to use when combining the components
    ///   of this instance.
    public func hash(into hasher: inout Hasher) {
        key.character.hash(into: &hasher)
        hasher.combine(modifiers.rawValue)
        hasher.combine(localization.style)
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct KeyEquivalent {

    /// Up Arrow (U+F700)
    public static let upArrow: KeyEquivalent = "\u{F700}"

    /// Down Arrow (U+F701)
    public static let downArrow: KeyEquivalent = "\u{F701}"

    /// Left Arrow (U+F702)
    public static let leftArrow: KeyEquivalent = "\u{F702}"

    /// Right Arrow (U+F703)
    public static let rightArrow: KeyEquivalent = "\u{F703}"

    /// Escape (U+001B)
    public static let escape: KeyEquivalent = "\u{001B}"

    /// Delete (U+0008)
    public static let delete: KeyEquivalent = "\u{0008}"

    /// Delete Forward (U+F728)
    public static let deleteForward: KeyEquivalent = "\u{F728}"

    /// Home (U+F729)
    public static let home: KeyEquivalent = "\u{F729}"

    /// End (U+F72B)
    public static let end: KeyEquivalent = "\u{F72B}"

    /// Page Up (U+F72C)
    public static let pageUp: KeyEquivalent = "\u{F72C}"

    /// Page Down (U+F72D)
    public static let pageDown: KeyEquivalent = "\u{F72D}"

    /// Clear (U+F739)
    public static let clear: KeyEquivalent = "\u{F739}"

    /// Tab (U+0009)
    public static let tab: KeyEquivalent = "\u{0009}"

    /// Space (U+0020)
    public static let space: KeyEquivalent = "\u{0020}"

    /// Return (U+000D)
    public static let `return`: KeyEquivalent = "\u{000D}"

    /// The character value that the key equivalent represents.
    public var character: Character

    /// Creates a new key equivalent from the given character value.
    public init(_ character: Character) {
        self.character = character
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension KeyEquivalent : ExpressibleByExtendedGraphemeClusterLiteral {

    /// Creates an instance initialized to the given value.
    ///
    /// - Parameter value: The value of the new instance.
    public init(extendedGraphemeClusterLiteral: Character) {
        self.character = extendedGraphemeClusterLiteral
    }

    /// A type that represents an extended grapheme cluster literal.
    ///
    /// Valid types for `ExtendedGraphemeClusterLiteralType` are `Character`,
    /// `String`, and `StaticString`.
    public typealias ExtendedGraphemeClusterLiteralType = Character

    /// A type that represents a Unicode scalar literal.
    ///
    /// Valid types for `UnicodeScalarLiteralType` are `Unicode.Scalar`,
    /// `Character`, `String`, and `StaticString`.
    public typealias UnicodeScalarLiteralType = Character
}
