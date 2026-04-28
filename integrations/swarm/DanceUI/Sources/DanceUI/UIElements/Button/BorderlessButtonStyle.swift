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
@available(tvOS, unavailable)
public struct BorderlessButtonStyle : PrimitiveButtonStyle, ButtonStyleConvertible {
    
    /// Creates a borderless button style.
    public init() { }

    /// Creates a view that represents the body of a button.
    ///
    /// The system calls this method for each ``Button`` instance in a view
    /// hierarchy where this style is the current button style.
    ///
    /// - Parameter configuration : The properties of the button.
    public func makeBody(configuration: Configuration) -> some View {
        AccessibilityButtonShapeModifier()
            .body(content: Button(configuration))
            .buttonStyle(buttonStyleRepresentation)
    }
    
    internal var buttonStyleRepresentation: some ButtonStyle {
        BorderlessButtonStyleBase()
    }
    
    @Environment(\.tintColor)
    private var controlTint: Color?
}

@available(iOS 13.0, *)
@available(tvOS, unavailable)
extension PrimitiveButtonStyle where Self == BorderlessButtonStyle {

    /// A button style that doesn't apply a border.
    ///
    /// To apply this style to a button, or to a view that contains buttons, use
    /// the ``View/buttonStyle(_:)-5sii2`` modifier.
    @_alwaysEmitIntoClient
    public static var borderless: BorderlessButtonStyle { BorderlessButtonStyle() }
}

@available(iOS 13.0, *)
@available(tvOS, unavailable)
private struct BorderlessButtonStyleBase: ButtonStyle {
    @inline(__always)
    fileprivate init() {}

    @Environment(\.keyboardShortcut)
    private var keyboardShortcut: KeyboardShortcut?

    @Environment(\.controlSize)
    private var controlSize: ControlSize

    @Environment(\.isEnabled)
    private var isEnable: Bool

    private var isDefault: Bool {
        keyboardShortcut == .defaultAction
    }

    private var defaultFont: Font {
        let style: Font.TextStyle
        switch controlSize {
        case .mini: style = .subheadline
        case .small: style = .subheadline
        case .regular: style = .body
        case .large: style = .body
        case .extraLarge: style = .body
        }
        let font = Font(provider: Font.TextStyleProvider(
            textStyle: style,
            design: .default,
            weight: isDefault ? .regular : .semibold)
        )
        return font
    }

    fileprivate func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
        .defaultFont(defaultFont)
        .multilineTextAlignment(.center)
        .buttonDefaultRenderingMode()
        .modifier(DefaultForegroundStyleModifier(style: BorderlessButtonLabelShapeStyle(role: configuration.role, isEnabled: isEnable, defaultForegroundStyle: TintShapeStyle())))
        .modifier(OpacityButtonHighlightModifier(highlighted: configuration.isPressed))
    }
}

@available(iOS 13.0, *)
internal struct BorderlessButtonLabelShapeStyle<Style>: ShapeStyle where Style: ShapeStyle {
    internal var role : ButtonRole?
    internal var isEnabled : Bool
    internal var defaultForegroundStyle: Style

    internal func _apply(to shape: inout _ShapeStyle_Shape) {
        if !isEnabled {
            HierarchicalShapeStyle.tertiary._apply(to: &shape)
        } else if let role, role == .destructive {
            Color.red._apply(to: &shape)
        } else {
            defaultForegroundStyle._apply(to: &shape)
        }
    }

    internal static func _apply(to type: inout _ShapeStyle_ShapeType) {
        type.result = .bool(true)
    }
}

@available(iOS 13.0, *)
internal struct OpacityButtonHighlightModifier: ViewModifier {
    internal var highlighted: Bool

    @Environment(\.colorScheme)
    internal var colorScheme: ColorScheme

    fileprivate var pressedOpacity: Double {
        switch colorScheme {
        case .light:    return 0.2
        case .dark:     return 0.4
        }
    }

    internal func body(content: Content) -> some View {
        content
            .opacity(highlighted ? pressedOpacity : 1.0)
            .contentShape(Rectangle(), eoFill: false)
    }
}
