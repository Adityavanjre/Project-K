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

import UIKit

@available(iOS 13.0, *)
// MARK: - Autocorrection

extension EnvironmentValues {
    
    /// Whether auto-correction is enabled for the view hierarchy contained
    /// in `self`.
    ///
    /// The default is `nil`, which means the system default will be applied.
    @inline(__always)
    public var disableAutocorrection: Bool? {
        get {
            self[AutocorrectionTypeKey.self]
        }
        set {
            self[AutocorrectionTypeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct AutocorrectionTypeKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool?
    
    fileprivate static var defaultValue: Value {
        nil
    }
    
}

@available(iOS 13.0, *)
extension UITextAutocorrectionType {
    
    @usableFromInline
    internal init(_ disableAutocorrection: Bool?) {
        switch disableAutocorrection {
        case .some(true):   self = .no // 1
        case .some(false):  self = .yes // 2
        case .none:         self = .default
        }
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets whether to disable autocorrection for this view.
    ///
    /// Use `disableAutocorrection(_:)` when the effect of autocorrection would
    /// make it more difficult for the user to input information. The entry of
    /// proper names and street addresses are examples where autocorrection can
    /// negatively affect the user's ability complete a data entry task.
    ///
    /// In the example below configures a ``TextField`` with the `.default`
    /// keyboard. Disabling autocorrection allows the user to enter arbitrary
    /// text without the autocorrection system offering suggestions or
    /// attempting to override their input.
    ///
    ///     TextField("1234 Main St.", text: $address)
    ///         .keyboardType(.default)
    ///         .disableAutocorrection(true)
    ///
    /// - Parameter enabled: A Boolean value that indicates whether
    ///   autocorrection is disabled for this view.
    @available(watchOS, unavailable)
    public func disableAutocorrection(_ disable: Bool?) -> some View {
        environment(\.disableAutocorrection, disable)
    }
    
}

@available(iOS 13.0, *)
// MARK: - Keyboard Type

extension EnvironmentValues {
    
    @inline(__always)
    internal var keyboardType: Int {
        get {
            self[KeyboardTypeKey.self]
        }
        set {
            self[KeyboardTypeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct KeyboardTypeKey: EnvironmentKey {
    
    fileprivate typealias Value = Int
    
    fileprivate static var defaultValue: Value {
        0
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets the keyboard type for this view.
    ///
    /// Use `keyboardType(_:)` to specify the keyboard type to use for text
    /// entry. A number of different keyboard types are available to meet
    /// specialized input needs, such as entering email addresses or phone
    /// numbers.
    ///
    /// The example below presents a ``TextField`` to input an email address.
    /// Setting the text field's keyboard type to `.emailAddress` ensures the
    /// user can only enter correctly formatted email addresses.
    ///
    ///     TextField("someone@example.com", text: $emailAddress)
    ///         .keyboardType(.emailAddress)
    ///
    /// There are several different kinds of specialized keyboard types
    /// available though the
    /// <https://developer.apple.com/documentation/UIKit/UIKeyboardType> enumeration. To
    /// specify the default system keyboard type, use `.default`.
    ///
    ///
    /// - Parameter type: One of the keyboard types defined in the
    /// <https://developer.apple.com/documentation/UIKit/UIKeyboardType> enumeration.
    @available(tvOS, unavailable)
    @available(OSX, unavailable)
    @available(watchOS, unavailable)
    public func keyboardType(_ type: UIKeyboardType) -> some View {
        environment(\.keyboardType, type.rawValue)
    }
    
}

@available(iOS 13.0, *)
// MARK: - Autocapitalization Type

extension EnvironmentValues {
    
    @inline(__always)
    internal var autocapitalizationType: Int {
        get {
            self[AutocapitalizationTypeKey.self]
        }
        set {
            self[AutocapitalizationTypeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct AutocapitalizationTypeKey: EnvironmentKey {
    
    fileprivate typealias Value = Int
    
    fileprivate static var defaultValue: Value {
        UITextAutocapitalizationType.sentences.rawValue
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets whether to apply auto-capitalization to this view.
    ///
    /// Use `autocapitalization(_:)` when you need to automatically capitalize
    /// words, sentences, or other text like proper nouns.
    ///
    /// In example below, as the user enters text each word is automatically
    /// capitalized:
    ///
    ///     TextField("Last, First", text: $fullName)
    ///         .autocapitalization(UITextAutocapitalizationType.words)
    ///
    /// The <https://developer.apple.com/documentation/UIKit/UITextAutocapitalizationType>
    /// enumeration defines the available capitalization modes. The default is
    /// <https://developer.apple.com/documentation/UIKit/UITextAutocapitalizationType/sentences>.
    ///
    /// - Parameter style: One of the autocapitalization modes defined in the
    /// <https://developer.apple.com/documentation/UIKit/UITextAutocapitalizationType>
    /// enumeration.
    @available(tvOS, unavailable)
    @available(OSX, unavailable)
    @available(watchOS, unavailable)
    public func autocapitalization(_ style: UITextAutocapitalizationType) -> some View{
        environment(\.autocapitalizationType, style.rawValue)
    }
    
}

@available(iOS 13.0, *)
// MARK: - Text Content Type


extension EnvironmentValues {
    
    @usableFromInline
    internal var textContentType: String? {
        get {
            self[TextContentTypeKey.self]
        }
        set {
            self[TextContentTypeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct TextContentTypeKey: EnvironmentKey {
    
    fileprivate typealias Value = String?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets the text content type for this view, which the system uses to
    /// offer suggestions while the user enters text on an iOS or tvOS device.
    ///
    /// Use this method to set the content type for input text.
    /// For example, you can configure a ``TextField`` for the entry of email
    /// addresses:
    ///
    ///     TextField("Enter your email", text: $emailAddress)
    ///         .textContentType(.emailAddress)
    ///
    /// - Parameter textContentType: One of the content types available in the
    ///   <https://developer.apple.com/documentation/UIKit/UITextContentType>
    ///   structure that identify the semantic meaning expected for a text-entry
    ///   area. These include support for email addresses, location names, URLs,
    ///   and telephone numbers, to name just a few.
    @available(tvOS, unavailable)
    @available(OSX, unavailable)
    @available(watchOS, unavailable)
    @inlinable
    public func textContentType(_ textContentType: UITextContentType?) -> some View {
        environment(\.textContentType, textContentType?.rawValue)
    }
    
}
