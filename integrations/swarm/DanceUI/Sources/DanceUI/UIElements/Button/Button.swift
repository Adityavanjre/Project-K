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
public struct Button<Label: View>: View {
    
    internal var role: ButtonRole? = nil
    
    internal var _label: Label
    
    internal var action: () -> Void
    
    internal var name: String?
    
    /// Creates a button that displays a custom label.
    ///
    /// - Parameters:
    ///   - action: The action to perform when the user triggers the button.
    ///   - label: A view that describes the purpose of the button's `action`.
    public init(action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self._label = label()
        self.name = nil
    }
    
    /// Creates a button that displays a custom label.
    ///
    /// - Parameters:
    ///   - name: A string to name the button's gestures.
    ///   - action: The action to perform when the user triggers the button.
    ///   - label: A view that describes the purpose of the button's `action`.
    public init(name: String, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.action = action
        self._label = label()
        self.name = name
    }
    
    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: some View {
        ResolvedButtonStyle(configuration: PrimitiveButtonStyleConfiguration(role: self.role, action: action, name: name))
            .viewAlias(PrimitiveButtonStyleConfiguration.Label.self,
                             source: { _label })
            .viewAlias(ButtonStyleConfiguration.Label.self,
                             source: { _label })
            .accessibilityElement(children: .combine)
            .accessibilityActivationPoint(UnitPoint(x: 0.5, y: 0.5))
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(.isImage)
            .accessibilityAction(.default, action)
    }
    
}

@available(iOS 13.0, *)
extension Button where Label == Text {
    
    /// Creates a button that generates its label from a localized string key.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// ``Text`` for more information about localizing strings.
    ///
    /// To initialize a button with a string variable, use
    /// ``Button/init(_:action:)-lpm7`` instead.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the button's localized title, that describes
    ///     the purpose of the button's `action`.
    ///   - action: The action to perform when the user triggers the button.
    public init(_ titleKey: LocalizedStringKey, action: @escaping () -> Void) {
        if DanceUIFeature.gestureContainer.isEnable {
            self.init(name: titleKey.key, action: action, label: {Text(titleKey, tableName: nil, bundle: nil, comment: nil)})
        } else {
            self.init(action: action, label: {Text(titleKey, tableName: nil, bundle: nil, comment: nil)})
        }
    }
    
    /// Creates a button that generates its label from a string.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(_:)-9d1g4``. See ``Text`` for more
    /// information about localizing strings.
    ///
    /// To initialize a button with a localized string key, use
    /// ``Button/init(_:action:)-1asy`` instead.
    ///
    /// - Parameters:
    ///   - title: A string that describes the purpose of the button's `action`.
    ///   - action: The action to perform when the user triggers the button.
    @_disfavoredOverload
    public init<S>(_ title: S, action: @escaping () -> Void) where S : StringProtocol {
        if DanceUIFeature.gestureContainer.isEnable {
            self.init(name: String(title), action: action, label: {Text.init(title)})
        } else {
            self.init(action: action, label: {Text.init(title)})
        }
    }
    
}

@available(iOS 13.0, *)
extension Button where Label == PrimitiveButtonStyleConfiguration.Label {
    
    /// Creates a button based on a configuration for a style with a custom
    /// appearance and custom interaction behavior.
    ///
    /// Use this initializer within the
    /// ``PrimitiveButtonStyle/makeBody(configuration:)`` method of a
    /// ``PrimitiveButtonStyle`` to create an instance of the button that you
    /// want to style. This is useful for custom button styles that modify the
    /// current button style, rather than implementing a brand new style.
    ///
    /// For example, the following style adds a red border around the button,
    /// but otherwise preserves the button's current style:
    ///
    ///     struct RedBorderedButtonStyle: PrimitiveButtonStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             Button(configuration)
    ///                 .border(Color.red)
    ///         }
    ///     }
    ///
    /// - Parameter configuration: A configuration for a style with a custom
    ///   appearance and custom interaction behavior.
    public init(_ configuration: PrimitiveButtonStyleConfiguration) {
        _label = configuration.label
        action = configuration.action
        role = configuration.role
        name = configuration.name
    }
    
}

@available(iOS 13.0, *)
extension Button {

    /// Creates a button with a specified role that displays a custom label.
    ///
    /// - Parameters:
    ///   - role: An optional semantic role that describes the button. A value of
    ///     `nil` means that the button doesn't have an assigned role.
    ///   - action: The action to perform when the user interacts with the button.
    ///   - label: A view that describes the purpose of the button's `action`.
    public init(role: ButtonRole?, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.role = role
        self.action = action
        self._label = label()
    }
}

@available(iOS 13.0, *)
extension Button where Label == Text {

    /// Creates a button with a specified role that generates its label from a
    /// localized string key.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// ``Text`` for more information about localizing strings.
    ///
    /// To initialize a button with a string variable, use
    /// ``init(_:role:action:)-8y5yk`` instead.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the button's localized title, that describes
    ///     the purpose of the button's `action`.
    ///   - role: An optional semantic role describing the button. A value of
    ///     `nil` means that the button doesn't have an assigned role.
    ///   - action: The action to perform when the user triggers the button.
    public init(_ titleKey: LocalizedStringKey, role: ButtonRole?, action: @escaping () -> Void) {
        self.role = role
        self.action = action
        self._label = Text(titleKey)
    }

    /// Creates a button with a specified role that generates its label from a
    /// string.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(_:)-9d1g4``. See ``Text`` for more
    /// information about localizing strings.
    ///
    /// To initialize a button with a localized string key, use
    /// ``init(_:role:action:)-93ek6`` instead.
    ///
    /// - Parameters:
    ///   - title: A string that describes the purpose of the button's `action`.
    ///   - role: An optional semantic role describing the button. A value of
    ///     `nil` means that the button doesn't have an assigned role.
    ///   - action: The action to perform when the user interacts with the button.
    @_disfavoredOverload
    public init<S>(_ title: S, role: ButtonRole?, action: @escaping () -> Void) where S : StringProtocol {
        self.role = role
        self.action = action
        self._label = Text(title)
    }
}
