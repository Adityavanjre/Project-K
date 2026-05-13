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

@available(iOS 13.0, *)
extension View {

    /// Adds help text to a view using a localized string that you provide.
    ///
    /// Adding help to a view configures the view's accessibility hint and
    /// its tooltip ("help tag") on macOS.
    /// For more information on using help tags, see
    /// [Help](https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/help/)
    /// in the macOS Human Interface Guidelines.
    ///
    ///     Button(action: composeMessage) {
    ///         Image(systemName: "square.and.pencil")
    ///     }
    ///     .help("Compose a new message")
    ///
    /// - Parameter textKey: The key for the localized text to use as help.
    @inlinable
    public func help(_ textKey: LocalizedStringKey) -> some View {
        help(Text(textKey))
    }

    /// Adds help text to a view using a text view that you provide.
    ///
    /// Adding help to a view configures the view's accessibility hint and
    /// its tooltip ("help tag") on macOS.
    /// For more information on using help tags, see
    /// [Help](https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/help/)
    /// in the macOS Human Interface Guidelines.
    ///
    ///     Slider("Opacity", value: $selectedShape.opacity)
    ///         .help(Text("Adjust the opacity of the selected \(selectedShape.name)"))
    ///
    /// - Parameter text: The Text view to use as help.
    public func help(_ text: Text) -> some View {
        if case .anyTextStorage(let storage) = text.storage, storage.isStyled() {
            logger.fault("Only unstyled text can be used with \(#function)")
        }
        
        if !text.modifiers.isEmpty {
            logger.fault("Only unstyled text can be used with \(#function)")
        }
        
#if os(iOS)
        return accessibilityHint(text)
#elseif os(macOS)
        _danceuiPreconditionFailure("macOS is not supported yet")
#endif
    }
    /// Adds help text to a view using a string that you provide.
    ///
    /// Adding help to a view configures the view's accessibility hint and
    /// its tooltip ("help tag") on macOS.
    /// For more information on using help tags, see
    /// [Help](https://developer.apple.com/design/human-interface-guidelines/macos/user-interaction/help/)
    /// in the macOS Human Interface Guidelines.
    ///
    ///     Image(systemName: "pin.circle")
    ///         .foregroundColor(pointOfInterest.tintColor)
    ///         .help(pointOfInterest.name)
    ///
    /// - Parameter text: The text to use as help.
    @inlinable
    public func help<S: StringProtocol>(_ text: S) -> some View {
        help(Text(text))
    }
}
