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

internal import DanceUIGraph
import UIKit
import MyShims

// MARK: - TextField

/// A control that displays an editable text interface.
///
/// You create a text field with a label and a binding to a value. If the
/// value is a string, the text field updates this value continuously as the
/// user types or otherwise edits the text in the field. For non-string types,
/// it updates the value when the user commits their edits, such as by pressing
/// the Return key.
///
/// The following example shows a text field to accept a username, and a
/// ``Text`` view below it that shadows the continuously updated value
/// of `username`. The ``Text`` view changes color as the user begins and ends
/// editing. When the user submits their completed entry to the text field,
/// the ``View/onSubmit(of:_:)`` modifer calls an internal `validate(name:)`
/// method.
///
///     @State private var username: String = ""
///     @FocusState private var emailFieldIsFocused: Bool = false
///
///     var body: some View {
///         TextField(
///             "User name (email address)",
///             text: $username
///         )
///         .focused($emailFieldIsFocused)
///         .onSubmit {
///             validate(name: username)
///         }
///         .textInputAutocapitalization(.never)
///         .disableAutocorrection(true)
///         .border(.secondary)
///
///         Text(username)
///             .foregroundColor(emailFieldIsFocused ? .red : .blue)
///     }
///
///
/// The bound value doesn't have to be a string. By using a
/// <https://developer.apple.com/documentation/Foundation/FormatStyle>,
/// you can bind the text field to a nonstring type, using the format style
/// to convert the typed text into an instance of the bound type. The following
/// example uses a
/// <https://developer.apple.com/documentation/Foundation/PersonNameComponents/FormatStyle>
/// to convert the name typed in the text field to a
/// <https://developer.apple.com/documentation/Foundation/PersonNameComponents>
/// instance. A ``Text`` view below the text field shows the debug description
/// string of this instance.
///
///     @State private var nameComponents = PersonNameComponents()
///
///     var body: some View {
///         TextField(
///             "Proper name",
///             value: $nameComponents,
///             format: .name(style: .medium)
///         )
///         .onSubmit {
///             validate(components: nameComponents)
///         }
///         .disableAutocorrection(true)
///         .border(.secondary)
///         Text(nameComponents.debugDescription)
///     }
///
///
/// ### Text field prompts
///
/// You can set an explicit prompt on the text field to guide users on what
/// text they should provide. Each text field style determines where and
/// when the text field uses a prompt and label. For example, a form on macOS
/// always places the label at the leading edge of the field and
/// uses a prompt, when available, as placeholder text within the field itself.
/// In the same context on iOS, the text field uses either the prompt or label
/// as placeholder text, depending on whether the initializer provided a prompt.
///
/// The following example shows a ``Form`` with two text fields, each of which
/// provides a prompt to indicate that the field is required, and a view builder
/// to provide a label:
///
///     Form {
///         TextField(text: $username, prompt: Text("Required")) {
///             Text("Username")
///         }
///         SecureField(text: $password, prompt: Text("Required")) {
///             Text("Password")
///         }
///     }
///
/// ![A macOS form, showing two text fields, arranged vertically, with labels to
/// the side that say Username and Password, respectively. Inside each text
/// field, the prompt text says Required.](TextField-prompt-1)
///
/// ![An iOS form, showing two text fields, arranged vertically, with prompt
/// text that says Required.](TextField-prompt-2)
///
/// ### Styling text fields
///
/// DanceUI provides a default text field style that reflects an appearance and
/// behavior appropriate to the platform. The default style also takes the
/// current context into consideration, like whether the text field is in a
/// container that presents text fields with a special style. Beyond this, you
/// can customize the appearance and interaction of text fields using the
/// ``View/textFieldStyle(_:)`` modifier, passing in an instance of
/// ``TextFieldStyle``. The following example applies the
/// ``TextFieldStyle/roundedBorder`` style to both text fields within a ``VStack``.
///
///     @State private var givenName: String = ""
///     @State private var familyName: String = ""
///
///     var body: some View {
///         VStack {
///             TextField(
///                 "Given Name",
///                 text: $givenName
///             )
///             .disableAutocorrection(true)
///             TextField(
///                 "Family Name",
///                 text: $familyName
///             )
///             .disableAutocorrection(true)
///         }
///         .textFieldStyle(.roundedBorder)
///     }
/// ![Two vertically-stacked text fields, with the prompt text Given Name and
/// Family Name, both with rounded
/// borders.](DanceUI-TextField-roundedBorderStyle.png)
///
@available(iOS 13.0, *)
public struct TextField<Label: View>: View {

    @Binding
    internal var text: String

    internal var isSecure: Bool

    internal var label: Label

    internal var onEditingChanged: (Bool) -> Void

    internal var onCommit: () -> Void
    
    internal var updatesContinuously: Bool

    @State
    internal var uncommittedText: String?
    
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
        ResolvedTextFieldStyle(configuration: TextField<_TextFieldStyleLabel>(self))
            .viewAlias(_TextFieldStyleLabel.self, source: { label })
    }
    
    internal init(_ binding: Binding<String>, isSecure: Bool, onEditingChanged: @escaping (Bool) -> Void = { _ in }, onCommit: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self._text = binding
        self.isSecure = isSecure
        self.label = label()
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
        self.updatesContinuously = true
        self.uncommittedText = nil
    }
    
    internal init<Contents>(_ binding: Binding<Contents>, formatter: Formatter, onEditingChanged: @escaping (Bool) -> Void, onCommit: @escaping () -> Void,  @ViewBuilder label: @escaping () -> Label) {
        self.init(
            binding.projecting(AnyToFormattedString<Contents>(formatter: formatter)),
            isSecure: false,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit,
            label: label
        )
        self.updatesContinuously = false
    }
    
}

@available(iOS 13.0, *)
extension TextField where Label == _TextFieldStyleLabel {
    
    internal init<OtherLabel: View>(_ textField: TextField<OtherLabel>) {
        self._text = Binding(get: {
            textField.uncommittedText ?? textField.text
        }, set: { (newValue) in
            if textField.updatesContinuously {
                textField.text = newValue // nodeIndex: 0xb98
            } else {
                textField.uncommittedText = newValue
            }
        })
        self.isSecure = textField.isSecure
        self.label = _TextFieldStyleLabel()
        self.onEditingChanged = textField.onEditingChanged
        self.onCommit = {
            defer {
                textField.onCommit()
            }
            
            guard let uncommittedText = textField.uncommittedText else {
                return
            }
            textField.text = uncommittedText
            textField.uncommittedText = nil
        }
        self.updatesContinuously = true
        self.uncommittedText = nil
    }
    
}

@available(iOS 13.0, *)
extension TextField where Label == Text {
    
    /// Creates a text field with a text label generated from a localized title
    /// string.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of the text field,
    ///     describing its purpose.
    ///   - text: The text to display and edit.
    ///   - onEditingChanged: The action to perform when the user
    ///     begins editing `text` and after the user finishes editing `text`.
    ///     The closure receives a Boolean value that indicates the editing
    ///     status: `true` when the user begins editing, `false` when they
    ///     finish.
    ///   - onCommit: An action to perform when the user performs an action
    ///     (for example, when the user presses the Return key) while the text
    ///     field has focus.
    public init(
        _ titleKey: LocalizedStringKey,
        text: Binding<String>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {}
    ) {
        self.init(
            text,
            isSecure: false,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        ) {
            Text(titleKey)
        }
    }
    
    /// Creates a text field with a text label generated from a title string.
    ///
    /// - Parameters:
    ///   - title: The title of the text view, describing its purpose.
    ///   - text: The text to display and edit.
    ///   - onEditingChanged: The action to perform when the user
    ///     begins editing `text` and after the user finishes editing `text`.
    ///     The closure receives a Boolean value that indicates the editing
    ///     status: `true` when the user begins editing, `false` when they
    ///     finish.
    ///   - onCommit: An action to perform when the user performs an action
    ///     (for example, when the user presses the Return key) while the text
    ///     field has focus.
    // FIXME: Uncomment `@_disfavoredOverload` when localization is done.
    /* @_disfavoredOverload */
    public init<S: StringProtocol>(
        _ title: S,
        text: Binding<String>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {}
    ) {
        self.init(
            text,
            isSecure: false,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        ) {
            Text(title)
        }
    }
    
    /// Creates a text field that applies a formatter to a bound
    /// value, with a label generated from a localized title string.
    ///
    /// Use this initializer to create a text field that binds to a bound
    /// value, using a
    /// <https://developer.apple.com/documentation/Foundation/Formatter>
    /// to convert to and from this type. Changes to the bound value update
    /// the string displayed by the text field. Editing the text field
    /// updates the bound value, as long as the formatter can parse the
    /// text. If the format style can't parse the input, the bound value
    /// remains unchanged.
    ///
    /// Use the ``View/onSubmit(of:_:)`` modifier to invoke an action
    /// whenever the user submits this text field.
    ///
    /// The following example uses a
    /// <https://developer.apple.com/documentation/Swift/Double>
    /// as the bound value, and a
    /// <https://developer.apple.com/documentation/Foundation/NumberFormatter>
    /// instance to convert to and from a string representation. The formatter
    /// uses the
    /// <https://developer.apple.com/documentation/Foundation/NumberFormatter/Style/decimal>
    /// style, to allow entering a fractional part. As the user types, the bound
    /// value updates, which in turn updates three ``Text`` views that use
    /// different format styles. If the user enters text that doesn't represent
    /// a valid `Double`, the bound value doesn't update.
    ///
    ///     @State private var myDouble: Double = 0.673
    ///     @State private var numberFormatter: NumberFormatter = {
    ///         var nf = NumberFormatter()
    ///         nf.numberStyle = .decimal
    ///         return nf
    ///     }()
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField(
    ///                 "Double",
    ///                 value: $myDouble,
    ///                 formatter: numberFormatter
    ///             )
    ///             Text(myDouble, format: .number)
    ///             Text(myDouble, format: .number.precision(.significantDigits(5)))
    ///             Text(myDouble, format: .number.notation(.scientific))
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of the text field,
    ///     describing its purpose.
    ///   - value: The underlying value to edit.
    ///   - formatter: A formatter to use when converting between the
    ///     string the user edits and the underlying value of type `V`.
    ///     If `formatter` can't perform the conversion, the text field doesn't
    ///     modify `binding.value`.
    ///   - prompt: A `Text` which provides users with guidance on what to enter
    ///     into the text field.
    public init<T>(
        _ titleKey: LocalizedStringKey,
        value: Binding<T>,
        formatter: Formatter,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {}
    ) {
        self.init(
            value,
            formatter: formatter,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        ) {
            Text(titleKey)
        }
    }
    
    /// Creates a text field that applies a formatter to a bound
    /// value, with a label generated from a title string.
    ///
    /// Use this initializer to create a text field that binds to a bound
    /// value, using a
    /// <https://developer.apple.com/documentation/Foundation/Formatter>
    /// to convert to and from this type. Changes to the bound value update
    /// the string displayed by the text field. Editing the text field
    /// updates the bound value, as long as the formatter can parse the
    /// text. If the format style can't parse the input, the bound value
    /// remains unchanged.
    ///
    /// Use the ``View/onSubmit(of:_:)`` modifier to invoke an action
    /// whenever the user submits this text field.
    ///
    ///
    /// The following example uses a
    /// <https://developer.apple.com/documentation/Swift/Double>
    /// as the bound value, and a
    /// <https://developer.apple.com/documentation/Foundation/NumberFormatter>
    /// instance to convert to and from a string representation. The formatter
    /// uses the
    /// <https://developer.apple.com/documentation/Foundation/NumberFormatter/Style/decimal>
    /// style, to allow entering a fractional part. As the user types, the bound
    /// value updates, which in turn updates three ``Text`` views that use
    /// different format styles. If the user enters text that doesn't represent
    /// a valid `Double`, the bound value doesn't update.
    ///
    ///     @State private var label = "Double"
    ///     @State private var myDouble: Double = 0.673
    ///     @State private var numberFormatter: NumberFormatter = {
    ///         var nf = NumberFormatter()
    ///         nf.numberStyle = .decimal
    ///         return nf
    ///     }()
    ///
    ///     var body: some View {
    ///         VStack {
    ///             TextField(
    ///                 label,
    ///                 value: $myDouble,
    ///                 formatter: numberFormatter
    ///             )
    ///             Text(myDouble, format: .number)
    ///             Text(myDouble, format: .number.precision(.significantDigits(5)))
    ///             Text(myDouble, format: .number.notation(.scientific))
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - title: The title of the text field, describing its purpose.
    ///   - value: The underlying value to edit.
    ///   - formatter: A formatter to use when converting between the
    ///     string the user edits and the underlying value of type `V`.
    ///     If `formatter` can't perform the conversion, the text field doesn't
    ///     modify `binding.value`.
    ///   - prompt: A `Text` which provides users with guidance on what to enter
    ///     into the text field.
    // FIXME: Uncomment `@_disfavoredOverload` when localization is done.
    @_disfavoredOverload
    public init<S: StringProtocol, T>(
        _ title: S,
        value: Binding<T>,
        formatter: Formatter,
        onEditingChanged: @escaping (Bool) -> Void = { _ in },
        onCommit: @escaping () -> Void = {}
    ) {
        self.init(
            value,
            formatter: formatter,
            onEditingChanged: onEditingChanged,
            onCommit: onCommit
        ) {
            Text(title)
        }
    }
    
}

@available(iOS 13.0, *)
// MARK: - TextFieldStyle

/// A specification for the appearance and interaction of a text field.
public protocol TextFieldStyle {
    
    associatedtype _Body: View
    
    func _body(configuration: TextField<_TextFieldStyleLabel>) -> _Body
    
}

/// A text field style with no decoration.
///
/// You can also use ``TextFieldStyle/plain`` to construct this style.
@available(iOS 13.0, *)
public struct PlainTextFieldStyle: TextFieldStyle {
    
    public typealias _Body = BodyContent
    
    public struct BodyContent: View {
        
        public var configuration: TextField<_TextFieldStyleLabel>
        
        public var body: some View {
            SystemTextField(configuration: SystemTextFieldConfiguration(textField: configuration, style: .none))
                .alignment(horizontal: .leading, vertical: nil)
                .fixedSize(horizontal: false, vertical: true)
        }

    }
    
    public init() { }
    
    public func _body(configuration: TextField<_TextFieldStyleLabel>) -> _Body {
        _Body(configuration: configuration)
    }
    
}

/// A text field style with a system-defined rounded border.
///
/// You can also use ``TextFieldStyle/roundedBorder`` to construct this style.
@available(iOS 13.0, *)
public struct RoundedBorderTextFieldStyle: TextFieldStyle {
    
    public typealias _Body = BodyContent
    
    public struct BodyContent: View {
        
        public var body: some View {
            SystemTextField(configuration: SystemTextFieldConfiguration(textField: configuration, style: .roundedRect))
                .alignment(horizontal: .leading, vertical: nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        
        public var configuration: TextField<_TextFieldStyleLabel>

    }
    
    public init() { }
    
    public func _body(configuration: TextField<_TextFieldStyleLabel>) -> _Body {
        _Body(configuration: configuration)
    }
    
}

@available(iOS 13.0, *)
public struct SquareBorderTextFieldStyle: TextFieldStyle {

    public typealias _Body = BodyContent
    
    public struct BodyContent: View {
        
        public var body: some View {
            SystemTextField(configuration: SystemTextFieldConfiguration(textField: configuration, style: .bezel))
                .alignment(horizontal: .leading, vertical: nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        
        @Environment
        public var environment: EnvironmentValues
        
        public var configuration: TextField<_TextFieldStyleLabel>
        
    }
    
    public init() { }
    
    public func _body(configuration: TextField<_TextFieldStyleLabel>) -> _Body {
        _Body(environment: Environment(\.self), configuration: configuration)
    }
    
}

/// The default text field style, based on the text field's context.
///
/// You can also use ``TextFieldStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultTextFieldStyle: TextFieldStyle {

    public struct _Body: View {
        
        public var body: some View {
            configuration
                .textFieldStyle(PlainTextFieldStyle())
        }
        
        public var configuration: TextField<_TextFieldStyleLabel>

    }
    
    public init() { }
    
    public func _body(configuration: TextField<_TextFieldStyleLabel>) -> _Body {
        _Body(configuration: configuration)
    }
    
}

@available(iOS 13.0, *)
internal struct TextFieldStyleModifier<Style: TextFieldStyle>: StyleModifier {
    
    internal typealias Body = Never
    
    internal typealias Subject = ResolvedTextFieldStyle
    
    internal typealias SubjectBody = Style._Body
    
    internal var style: Style
    
    internal static func body(view: ResolvedTextFieldStyle, style: Style) -> SubjectBody {
        style._body(configuration: view.configuration)
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    public func textFieldStyle<S: TextFieldStyle>(_ style: S) -> some View {
        modifier(TextFieldStyleModifier(style: style))
    }
    
}

@available(iOS 13.0, *)
public struct _TextFieldStyleLabel: ViewAlias {

}


@available(iOS 13.0, *)
internal struct ResolvedTextFieldStyle: StyleableView {
    
    internal typealias DefaultBody = DefaultTextFieldStyle._Body
    
    internal var configuration: TextField<_TextFieldStyleLabel>
    
    internal func defaultBody() -> DefaultBody {
        DefaultBody(configuration: configuration)
    }
    
}


@available(iOS 13.0, *)
internal struct SystemTextField<A: View>: View {

    internal var configuration: SystemTextFieldConfiguration<A>
    
    internal var body: some View {
        PlatformItemListView(content: configuration.textField.label) { (platformItemList) -> _SystemTextField<A> in
            _SystemTextField(
                configuration: configuration,
                label: SystemTextFieldLabel(base: platformItemList.items.reduce(PlatformItemList.Item()) { (reduced, item) in
                    var result = reduced
                    if result.text == nil {
                        result.text = item.text
                    }
                    if result.resolvedImage?.label == nil {
                        result.resolvedImage = item.resolvedImage
                    }
                    if result.accessibility == nil {
                        result.accessibility = item.accessibility
                    }
                    if result.children == nil {
                        result.children = item.children
                    }
                    if result.systemItem == nil {
                        result.systemItem = item.systemItem
                    }
                    return result
                })
            )
        }
    }
}

@available(iOS 13.0, *)
internal struct SystemTextFieldLabel: Equatable {

    internal var base: PlatformItemList.Item
    
    internal init(base: PlatformItemList.Item) {
        self.base = base
    }
    
    internal static func == (lhs: SystemTextFieldLabel, rhs: SystemTextFieldLabel) -> Bool {
        return lhs.base.text == rhs.base.text
    }
    
}

@available(iOS 13.0, *)
internal struct SystemTextFieldConfiguration<Label: View> {

    internal let textField: TextField<Label>

    internal let style: UITextField.BorderStyle
    
    internal init(textField: TextField<Label>, style: UITextField.BorderStyle) {
        self.textField = textField
        self.style = style
    }

}

@available(iOS 13.0, *)
// MARK: - System Text Field Implementation

private struct _SystemTextField<A: View>: UIViewRepresentable {
    
    fileprivate typealias UIViewType = MyTextField

    fileprivate var configuration: SystemTextFieldConfiguration<A>

    fileprivate var label: SystemTextFieldLabel
    
    fileprivate init(configuration: SystemTextFieldConfiguration<A>, label: SystemTextFieldLabel) {
        self.configuration = configuration
        self.label = label
    }
    
    fileprivate func makeUIView(context: Context) -> UIViewType {
        let coordinator = context.coordinator
        let textField = MyTextField(owner: DanceUIFeature.textFieldSupportsPinyinTransform.isEnable ? DGWeakAttribute(DGAttribute.current) : nil)
        textField.delegate = coordinator
        textField.addTarget(coordinator, action: #selector(Coordinator.my_textChanged(_:)), for: .editingChanged)
        textField.addTarget(coordinator, action: #selector(Coordinator.my_primaryActionTriggered(_:)), for: .primaryActionTriggered)
        textField.borderStyle = configuration.style
        textField.text = ""
        return textField
    }
    
    fileprivate func updateUIView(_ textField: UIViewType, context: Context) {
        
        context.coordinator.isViewUpdating = true
        
        textField.borderStyle = configuration.style
        
        textField.update(in: context.environment)
        
        let returnKeyType = UIReturnKeyType(context.environment.submitLabel)
        if textField.returnKeyType != returnKeyType {
            textField.returnKeyType = returnKeyType
        }
        
        textField.isSecureTextEntry = configuration.textField.isSecure
        
        textField.textAlignment = NSTextAlignment(in: context.environment)

        textField.adjustsFontSizeToFitWidth = context.environment.minimumScaleFactor > 1
        
        if textField.adjustsFontSizeToFitWidth {
            let font = context.environment.effectiveFont
            let platformFont = font.platformFont(in: context.environment, fontModifiers: [])
            let minSize = CTFontGetSize(platformFont)
            textField.minimumFontSize = minSize
        }
        
        textField.setText(configuration.textField.text, environment: context.environment)
        
        if let placeholderText = label.base.text {
            let mutableAttributedPlaceholder = NSMutableAttributedString(attributedString: placeholderText)
            
            let systemPlaceholderColor: UIColor
            if #available(iOS 13.0, *) {
                systemPlaceholderColor = .placeholderText
            } else {
                systemPlaceholderColor = .backwardCompatiblePlaceholderText
            }
            
            let placeholderColor = context.environment.placeholderColor.map(UIColor.init) ?? systemPlaceholderColor
            
            mutableAttributedPlaceholder.addAttributes(
                [NSAttributedString.Key.foregroundColor : placeholderColor],
                range: NSRange(location: 0, length: mutableAttributedPlaceholder.length)
            )
            
            textField.attributedPlaceholder = mutableAttributedPlaceholder
        }
        
        context.coordinator.configuration = configuration.textField
        context.coordinator.environment = context.environment
        
        context.coordinator.isViewUpdating = false
    }
    
    fileprivate func makeCoordinator() -> _SystemTextFieldCoordinator {
        _SystemTextFieldCoordinator(configuration: configuration.textField)
    }
    
    fileprivate func _overrideLayoutTraits(_ layoutTraits: inout _LayoutTraits, for uiView: UIViewType) {
        let width = layoutTraits.width
        
        let maxWidth = _LayoutTraits.Dimension(min: 0, ideal: width.max, max: width.max)
        
        layoutTraits.width = maxWidth
        
        let flexibleWidth = _LayoutTraits.Dimension(min: 0, ideal: width.ideal, max: .infinity)
        
        layoutTraits.width = flexibleWidth
    }
    
    fileprivate class _SystemTextFieldCoordinator: PlatformViewCoordinator,
        UITextFieldDelegate
    {

        fileprivate var configuration: TextField<A>

        fileprivate var environment: EnvironmentValues?

        fileprivate var isViewUpdating: Bool
        
        fileprivate init(configuration: TextField<A>) {
            self.configuration = configuration
            self.environment = nil
            self.isViewUpdating = false
        }
        
        @objc
        fileprivate func my_textChanged(_ sender: MyTextField) {
            guard !isViewUpdating else {
                return
            }
            
            let textField = configuration
            
            textField.text = sender.text ?? ""
        }
        
        @objc
        fileprivate func my_primaryActionTriggered(_ sender: MyTextField) {
            guard !isViewUpdating else {
                return
            }
            
            var textField = configuration
            
            Update.perform {
                textField.onCommit()
            }
            
            sender.endEditing(true)
            
            textField = configuration
            
            let text = textField.text
            
            let setText = sender.attributedText?.string
            
            guard text != setText else {
                return
            }
            
            guard let environment = self.environment else {
                return
            }
            
            textField = configuration
            
            let newText = textField.text
            
            sender.setText(newText, environment: environment)
        }
        
        @objc
        fileprivate func textFieldDidBeginEditing(_ textField: UITextField) {
            Update.perform {
                let textField = configuration
                textField.onEditingChanged(true)
            }
        }
        
        @objc
        fileprivate func textFieldDidEndEditing(_ textField: UITextField) {
            Update.perform {
                let textField = configuration
                textField.onEditingChanged(false)
            }
        }
        
        @objc
        fileprivate func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            return true
        }
    }


}

@available(iOS 13.0, *)
extension UIColor {
    
    @available(iOS, deprecated: 13.0)
    fileprivate static let backwardCompatiblePlaceholderText: UIColor = {
        let r = CGFloat(bitPattern: 0x3fce_1e1e_1e1e_1e1e)
        let g = CGFloat(bitPattern: 0x3fce_1e1e_1e1e_1e1e)
        let b = CGFloat(bitPattern: 0x3fd0_d0d0_d0d0_d0d1)
        let a = CGFloat(bitPattern: 0x3fd3_1313_1313_1313)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }()
    
}

@available(iOS 13.0, *)
internal final class MyTextField: _MyTextField {
    
    internal var customAccessibilityPlaceholder: String?
    
    internal let owner: DGWeakAttribute?
    
    internal init(owner: DGWeakAttribute?) {
        self.owner = owner
        super.init(frame: .zero)
    }
    
    internal required init?(coder: NSCoder) {
        nil
    }
    
    fileprivate func setText(_ text: String, environment: EnvironmentValues) {
        
        var resolvedText = Text.Resolved()
        
        resolvedText.append(text, in: environment)
        
        let attributes = resolvedText.style.nsAttributes(environment: environment,
                                                         /* FIXME: Requires resolvedText.style.includeDefaultAttributes */
                                                         includeDefaultAttributes: true)
        
        defaultTextAttributes = attributes
        
        guard let mutableAttributedString = resolvedText.mutableAttributedString else {
            return
        }
        
        // FIXME: Requires Text.Resolved.configuration
        /*
         if resolvedText.configuration.containsResolvable {
            let configuration = resolvedText.configuration
            let length = mutableAttributedString.length
            mutableAttributedString.addAttribute(.resolvableAttributeConfiguration, value: configuration, range: NSRange(0..<length))
         }
        */
        
        if attributedText?.string != text {
            attributedText = mutableAttributedString
        }
        
    }
    
    internal func update(in environmentValue: EnvironmentValues) {
        keyboardType = UIKeyboardType(rawValue: environmentValue.keyboardType)!
        autocapitalizationType = UITextAutocapitalizationType(rawValue: environmentValue.autocapitalizationType)!
        autocorrectionType = UITextAutocorrectionType(environmentValue.disableAutocorrection)
        textContentType = environmentValue.textContentType.map({ UITextContentType(rawValue: $0) })
    }
    
    internal override func setAttributedMarkedText(_ markedText: NSAttributedString?, selectedRange: NSRange) {
        super.setAttributedMarkedText(markedText, selectedRange: selectedRange)
        
        if DanceUIFeature.textFieldSupportsPinyinTransform.isEnable {
            Update.enqueueAction { [owner] in
                guard let owner = owner?.attribute else {
                    return
                }
                
                owner.graph.graphHost().flushTransactions()
            }
        }
    }
    
}

@available(iOS 13.0, *)
private final class AnyToFormattedString<A>: Projection {
    
    fileprivate typealias Base = A

    fileprivate typealias Projected = String

    fileprivate let formatter: Formatter
    
    fileprivate init(formatter: Formatter) {
        self.formatter = formatter
    }
    
    fileprivate func get(base: Base) -> Projected {
        self.formatter.string(for: base) ?? String()
    }
    
    fileprivate func set(base: inout Base, newValue: Projected) {
        applyFormatting(to: &base, using: newValue)
    }
    
    fileprivate func applyFormatting(to base: inout A, using string: String) {
        var objectValueOrNil: AnyObject?
        
        var errorDescriptionOrNil: NSString?
        
        self.formatter.getObjectValue(&objectValueOrNil, for: string, errorDescription: &errorDescriptionOrNil)
        
        if let errorDescription = errorDescriptionOrNil {
            // FIXME: handle errors
        }
        
        base = objectValueOrNil! as! A
    }
    
    fileprivate func hash(into hasher: inout Hasher) {
        formatter.hash(into: &hasher)
    }

    fileprivate static func == (lhs: AnyToFormattedString, rhs: AnyToFormattedString) -> Bool {
        guard lhs !== rhs else {
            return true
        }
        
        return lhs.formatter.isEqual(rhs.formatter)
    }
    
}
