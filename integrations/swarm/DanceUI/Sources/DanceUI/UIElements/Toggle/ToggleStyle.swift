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
public protocol ToggleStyle {

    /// A view that represents the appearance and interaction of a toggle.
    associatedtype Body : View

    @ViewBuilder func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = ToggleStyleConfiguration
}

@available(tvOS, unavailable)
@available(iOS 13.0, *)
extension ToggleStyle where Self == SwitchToggleStyle {

    /// A toggle style that displays a leading label and a trailing switch.
    ///
    /// Apply this style to a ``Toggle`` or to a view hierarchy that contains
    /// toggles using the ``View/toggleStyle(_:)`` modifier:
    ///
    ///     Toggle("Enhance Sound", isOn: $isEnhanced)
    ///         .toggleStyle(.switch)
    ///
    /// The style produces a label that describes the purpose of the toggle
    /// and a switch that shows the toggle's state. The user taps or clicks
    /// the switch to change the toggle's state. The default appearance is
    /// similar across platforms, although the way you use switches in your
    /// user interface varies a little, as described in the respective Human
    /// Interface Guidelines sections:
    ///
    /// | Platform    | Appearance | Human Interface Guidelines |
    /// |-------------|------------|----------------------------|
    ///
    /// In iOS, iPadOS, and watchOS, the label and switch fill as much
    /// horizontal space as the toggle's parent offers by aligning the label's
    /// leading edge and the switch's trailing edge with the containing view's
    /// respective leading and trailing edges. In macOS, the style uses a
    /// minimum of horizontal space by aligning the trailing edge of the label
    /// with the leading edge of the switch. DanceUI helps you to manage the
    /// spacing and alignment when this style appears in a ``Form``.
    ///
    /// DanceUI uses this style as the default for iOS, iPadOS, and watchOS in
    /// most contexts when you don't set a style, or when you apply
    /// the ``ToggleStyle/automatic`` style.
    @_alwaysEmitIntoClient
    public static var `switch`: SwitchToggleStyle {
        SwitchToggleStyle()
    }
    
}

@available(iOS 13.0, *)
extension ToggleStyle where Self == DefaultToggleStyle {
    
    /// The default toggle style.
    ///
    /// Use this ``ToggleStyle`` to let DanceUI pick a suitable style for
    /// the current platform and context. Toggles use the `automatic` style
    /// by default, but you might need to set it explicitly using the
    /// ``View/toggleStyle(_:)`` modifier to override another style
    /// in the environment. For example, you can request automatic styling for
    /// a toggle in an ``HStack`` that's otherwise configured to use the
    /// ``ToggleStyle/button`` style:
    ///
    ///     HStack {
    ///         Toggle(isOn: $isShuffling) {
    ///             Label("Shuffle", systemImage: "shuffle")
    ///         }
    ///         Toggle(isOn: $isRepeating) {
    ///             Label("Repeat", systemImage: "repeat")
    ///         }
    ///
    ///         Divider()
    ///
    ///         Toggle("Enhance Sound", isOn: $isEnhanced)
    ///             .toggleStyle(.automatic) // Set the style automatically here.
    ///     }
    ///     .toggleStyle(.button) // Use button style for toggles in the stack.
    ///
    /// ### Platform defaults
    ///
    /// The `automatic` style produces an appearance that varies by platform,
    /// using the following styles in most contexts:
    ///
    /// | Platform    | Default style                            |
    /// |-------------|------------------------------------------|
    /// | iOS, iPadOS | ``ToggleStyle/switch``                   |
    /// | macOS       | ``ToggleStyle/checkbox``                 |
    /// | tvOS        | A tvOS-specific button style (see below) |
    /// | watchOS     | ``ToggleStyle/switch``                   |
    ///
    /// The default style for tvOS behaves like a button. However,
    /// unlike the ``ToggleStyle/button`` style that's available in some other
    /// platforms, the tvOS toggle takes as much horizontal space as its parent
    /// offers, and displays both the toggle's label and a text field that
    /// indicates the toggle's state. You typically collect tvOS toggles into
    /// a ``List``:
    ///
    ///     List {
    ///         Toggle("Show Lyrics", isOn: $isShowingLyrics)
    ///         Toggle("Shuffle", isOn: $isShuffling)
    ///         Toggle("Repeat", isOn: $isRepeating)
    ///     }
    ///
    ///
    /// ### Contextual defaults
    ///
    /// A toggle's automatic appearance varies in certain contexts:
    ///
    /// * A toggle that appears as part of the content that you provide to one
    ///   of the toolbar modifiers, like ``View/toolbar(content:)-5w0tj``, uses
    ///   the ``ToggleStyle/button`` style by default.
    ///
    /// * A toggle in a ``Menu`` uses a style that you can't create explicitly:
    ///     ```
    ///     Menu("Playback") {
    ///         Toggle("Show Lyrics", isOn: $isShowingLyrics)
    ///         Toggle("Shuffle", isOn: $isShuffling)
    ///         Toggle("Repeat", isOn: $isRepeating)
    ///     }
    ///     ```
    ///   DanceUI shows the toggle's label with a checkmark that appears only
    ///   in the `on` state:
    ///
    @_alwaysEmitIntoClient
    public static var automatic: DefaultToggleStyle {
        DefaultToggleStyle()
    }
}
