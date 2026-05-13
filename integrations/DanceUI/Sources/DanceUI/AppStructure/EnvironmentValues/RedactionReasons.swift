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

/// The reasons to apply a redaction to data displayed on screen.
@available(iOS 13.0, *)
public struct RedactionReasons : OptionSet {

    /// The raw value.
    public let rawValue: Int

    /// Creates a new set from a raw value.
    ///
    /// - Parameter rawValue: The raw value with which to create the
    ///   reasons for redaction.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public init() {
        self.rawValue = 0
    }

    /// Displayed data should appear as generic placeholders.
    ///
    /// Text and images will be automatically masked to appear as
    /// generic placeholders, though maintaining their original size and shape.
    /// Use this to create a placeholder UI without directly exposing
    /// placeholder data to users.
    public static let placeholder: RedactionReasons = .init(rawValue: 1)

    /// Displayed data should be obscured to protect private information.
    ///
    /// Views marked with `privacySensitive` will be automatically redacted
    /// using a standard styling. To apply a custom treatment the redaction
    /// reason can be read out of the environment.
    ///
    ///     struct BankingContentView: View {
    ///         @Environment(\.redactionReasons) var redactionReasons
    ///
    ///         var body: some View {
    ///             if redactionReasons.contains(.privacy) {
    ///                 FullAppCover()
    ///             } else {
    ///                 AppContent()
    ///             }
    ///         }
    ///     }
    public static let privacy: RedactionReasons = .init(rawValue: 2)

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = RedactionReasons
    
    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias Element = RedactionReasons

    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias RawValue = Int
}
