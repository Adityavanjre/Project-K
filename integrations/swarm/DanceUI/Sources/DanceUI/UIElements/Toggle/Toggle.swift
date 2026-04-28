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

    /// Sets the style for toggles in a view hierarchy.
    ///
    /// Use this modifier on a ``Toggle`` instance to set a style that defines
    /// the control's appearance and behavior. For example, you can choose
    /// the ``ToggleStyle/switch`` style:
    ///
    ///     Toggle("Vibrate on Ring", isOn: $vibrateOnRing)
    ///         .toggleStyle(.switch)
    ///
    /// Built-in styles typically have a similar appearance across platforms,
    /// tailored to the platform's overall style:
    ///
    /// | Platform    | Appearance |
    /// |-------------|------------|
    ///
    /// ### Styling toggles in a hierarchy
    ///
    /// You can set a style for all toggle instances within a view hierarchy
    /// by applying the style modifier to a container view. For example, you
    /// can apply the ``ToggleStyle/button`` style to an ``HStack``:
    ///
    ///     HStack {
    ///         Toggle(isOn: $isFlagged) {
    ///             Label("Flag", systemImage: "flag.fill")
    ///         }
    ///         Toggle(isOn: $isMuted) {
    ///             Label("Mute", systemImage: "speaker.slash.fill")
    ///         }
    ///     }
    ///     .toggleStyle(.button)
    ///
    /// The example above has the following appearance when `isFlagged` is
    /// `true` and `isMuted` is `false`:
    ///
    /// | Platform    | Appearance |
    /// |-------------|------------|
    ///
    /// ### Automatic styling
    ///
    /// If you don't set a style, DanceUI assumes a value of
    /// ``ToggleStyle/automatic``, which corresponds to a context-specific
    /// default. Specify the automatic style explicitly to override a
    /// container's style and revert to the default:
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
    ///             .toggleStyle(.automatic) // Revert to the default style.
    ///     }
    ///     .toggleStyle(.button) // Use button style for toggles in the stack.
    ///     .labelStyle(.iconOnly) // Omit the title from any labels.
    ///
    /// The style that DanceUI uses as the default depends on both the platform
    /// and the context. In macOS, the default in most contexts is a
    /// ``ToggleStyle/checkbox``, while in iOS, the default toggle style is a
    /// ``ToggleStyle/switch``:
    ///
    /// | Platform    | Appearance |
    /// |-------------|------------|
    ///
    /// > Note: Like toggle style does for toggles, the ``View/labelStyle(_:)``
    /// modifier sets the style for ``Label`` instances in the hierarchy. The
    /// example above demostrates the compact ``LabelStyle/iconOnly`` style,
    /// which is useful for button toggles in space-constrained contexts.
    /// Always include a descriptive title for better accessibility.
    ///
    /// For more information about how DanceUI chooses a default toggle style,
    /// see the ``ToggleStyle/automatic`` style.
    ///
    /// - Parameter style: The toggle style to set. Use one of the built-in
    ///   values, like ``ToggleStyle/switch`` or ``ToggleStyle/button``,
    ///   or a custom style that you define by creating a type that conforms
    ///   to the ``ToggleStyle`` protocol.
    ///
    /// - Returns: A view that uses the specified toggle style for itself
    ///   and its child views.
    public func toggleStyle<S>(_ style: S) -> some View where S : ToggleStyle {
        modifier(ToggleStyleModifier(style:style))
    }
}

/// A control that toggles between on and off states.
///
/// You create a toggle by providing an `isOn` binding and a label. Bind `isOn`
/// to a Boolean property that determines whether the toggle is on or off. Set
/// the label to a view that visually describes the purpose of switching between
/// toggle states. For example:
///
///     @State private var vibrateOnRing = false
///
///     var body: some View {
///         Toggle(isOn: $vibrateOnRing) {
///             Text("Vibrate on Ring")
///         }
///     }
///
/// For the common case of text-only labels, you can use the convenience
/// initializer that takes a title string (or localized string key) as its first
/// parameter, instead of a trailing closure:
///
///     @State private var vibrateOnRing = true
///
///     var body: some View {
///         Toggle("Vibrate on Ring", isOn: $vibrateOnRing)
///     }
///
/// ### Styling toggles
///
/// Toggles use a default style that varies based on both the platform and
/// the context. For more information, read about the ``ToggleStyle/automatic``
/// toggle style.
///
/// You can customize the appearance and interaction of toggles by applying
/// styles using the ``View/toggleStyle(_:)`` modifier. You can apply built-in
/// styles, like ``ToggleStyle/switch``, to either a toggle, or to a view
/// hierarchy that contains toggles:
///
///     VStack {
///         Toggle("Vibrate on Ring", isOn: $vibrateOnRing)
///         Toggle("Vibrate on Silent", isOn: $vibrateOnSilent)
///     }
///     .toggleStyle(.switch)
///
/// You can also define custom styles by creating a type that conforms to the
/// ``ToggleStyle`` protocol.
@available(iOS 13.0, *)
public struct Toggle<Label> : View where Label : View {
    
    @Binding
    internal var _isOn: Bool
    
    internal var _label: Label

    
    /// Creates a toggle that displays a custom label.
    ///
    /// - Parameters:
    ///   - isOn: A binding to a property that determines whether the toggle is on
    ///     or off.
    ///   - label: A view that describes the purpose of the toggle.
    public init(isOn: Binding<Bool>, @ViewBuilder label: () -> Label) {
        self.__isOn = isOn
        self._label = label()
    }
    
    // The content and behavior of the view.
    public var body: some View {
        ResolvedToggleStyle(configuration: ToggleStyleConfiguration(label: ToggleStyleConfiguration.Label(), isOn: self.__isOn))
            .viewAlias(ToggleStyleConfiguration.Label.self) {
                _label
            }
        #warning("accessibility not implement")
//            .accessibilityElement(children: AccessibilityChildBehavior.combine)
//            .accessibility(value: AccessibilityValue)
//            .accessibility(addTraits: AccessibilityTraits)
//            .accessibility(removeTraits: AccessibilityTraits)
//        .accessibilityAction(_ actionKind: AccessibilityActionKind = .default, _ handler: @escaping () -> Void)
    }
}

@available(iOS 13.0, *)
extension Toggle where Label == ToggleStyleConfiguration.Label {

    /// Creates a toggle based on a toggle style configuration.
    ///
    /// You can use this initializer within the
    /// ``ToggleStyle/makeBody(configuration:)`` method of a ``ToggleStyle`` to
    /// create an instance of the styled toggle. This is useful for custom
    /// toggle styles that only modify the current toggle style, as opposed to
    /// implementing a brand new style.
    ///
    /// For example, the following style adds a red border around the toggle,
    /// but otherwise preserves the toggle's current style:
    ///
    ///     struct RedBorderedToggleStyle : ToggleStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             Toggle(configuration)
    ///                 .border(Color.red)
    ///         }
    ///     }
    ///
    /// - Parameter configuration: A toggle style configuration.
    public init(_ configuration: ToggleStyleConfiguration) {
        self.__isOn = configuration.$isOn
        self._label = configuration.label
    }
}

@available(iOS 13.0, *)
extension Toggle where Label == Text {

    /// Creates a toggle that generates its label from a localized string key.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// `Text` for more information about localizing strings.
    ///
    /// To initialize a toggle with a string variable, use
    /// ``Toggle/init(_:isOn:)`` instead.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the toggle's localized title, that describes
    ///     the purpose of the toggle.
    ///   - isOn: A binding to a property that indicates whether the toggle is
    ///    on or off.
    public init(_ titleKey: LocalizedStringKey, isOn: Binding<Bool>) {
        self.__isOn = isOn
        self._label = Text(titleKey)
    }

    /// Creates a toggle that generates its label from a string.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(_:)``. See `Text` for more
    /// information about localizing strings.
    ///
    /// To initialize a toggle with a localized string key, use
    /// ``Toggle/init(_:isOn:)`` instead.
    ///
    /// - Parameters:
    ///   - title: A string that describes the purpose of the toggle.
    ///   - isOn: A binding to a property that indicates whether the toggle is
    ///    on or off.
    public init<S>(_ title: S, isOn: Binding<Bool>) where S : StringProtocol {
        self.__isOn = isOn
        let label: () -> Text = {
            Text(title)
        }
        self._label = label()
    }
}

@available(iOS 13.0, *)
internal struct ResolvedToggleStyle: StyleableView {
    
    internal var configuration: ToggleStyleConfiguration
    
    internal func defaultBody() -> some View {
        DefaultToggleStyle().makeBody(configuration: configuration)
            .toggleStyle(SwitchToggleStyle())
    }
}


