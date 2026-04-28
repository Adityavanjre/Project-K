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

@available(iOS 13.0, *)
extension Never: View {
    
    public typealias Body = Never
    
    public var body: Self.Body {
        _danceuiFatalError()
    }
    
    public static func _makeView(view: _GraphValue<Never>, inputs: _ViewInputs) -> _ViewOutputs {
        _danceuiPreconditionFailure()
    }
    
    public static func _makeViewList(view: _GraphValue<Never>, inputs: _ViewListInputs) -> _ViewListOutputs {
        _danceuiPreconditionFailure()
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        nil
    }
}

/// Constants that define how a view's content fills the available space.
@available(iOS 13.0, *)
public enum ContentMode: Hashable, CaseIterable {
    
    /// An option that resizes the content so it's all within the available space,
    /// both vertically and horizontally.
    ///
    /// This mode preserves the content's aspect ratio.
    /// If the content doesn't have the same aspect ratio as the available
    /// space, the content becomes the same size as the available space on
    /// one axis and leaves empty space on the other.
    case fit
    
    /// An option that resizes the content so it occupies all available space,
    /// both vertically and horizontally.
    ///
    /// This mode preserves the content's aspect ratio.
    /// If the content doesn't have the same aspect ratio as the available
    /// space, the content becomes the same size as the available space on
    /// one axis, and larger on the other axis.
    case fill
}

@available(iOS 13.0, *)
extension View {
    
    @inlinable
    public func environment<V>(_ keyPath: WritableKeyPath<EnvironmentValues, V>, _ value: V) -> some View {
        modifier(_EnvironmentKeyWritingModifier<V>(keyPath: keyPath, value: value))
    }
    
}

@available(iOS 13.0, *)
extension Optional: View where Wrapped : View {
    
    /// The type of gesture representing the body of `Self`.
    public typealias Body = Never
    
    public var body: Never {
        bodyError()
    }
    
#warning("Semantics")
    public static func _makeView(view: _GraphValue<Wrapped?>, inputs: _ViewInputs) -> _ViewOutputs {
        makeImplicitRoot(view: view, inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Wrapped?>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let child = OptionalChild<Wrapped>(view: view.value)
        return AnyView._makeViewList(view: _GraphValue(child), inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        if let count = Wrapped._viewListCount(inputs: inputs),
           count == 0 {
            return 0
        }
        return nil
    }

    private struct OptionalChild<V: View>: Rule {

        internal typealias Value = AnyView

        @Attribute
        internal var view: V?

        internal let ids: (UniqueID, UniqueID)
        
        internal init(view: Attribute<V?>) {
            self._view = view
            self.ids = (UniqueID(), UniqueID())
        }
        
        internal var value: AnyView {
            if let view = view {
                return AnyView(view, id: ids.0)
            } else {
                return AnyView(EmptyView(), id: ids.1)
            }
        }

    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Applies a modifier to a view and returns a new view.
    ///
    /// Use this modifier to combine a ``View`` and a ``ViewModifier``, to
    /// create a new view. For example, if you create a view modifier for
    /// a new kind of caption with blue text surrounded by a rounded rectangle:
    ///
    ///     struct BorderedCaption: ViewModifier {
    ///         func body(content: Content) -> some View {
    ///             content
    ///                 .font(.caption2)
    ///                 .padding(10)
    ///                 .overlay(
    ///                     RoundedRectangle(cornerRadius: 15)
    ///                         .stroke(lineWidth: 1)
    ///                 )
    ///                 .foregroundColor(Color.blue)
    ///         }
    ///     }
    ///
    /// You can use ``modifier(_:)`` to extend ``View`` to create new modifier
    /// for applying the `BorderedCaption` defined above:
    ///
    ///     extension View {
    ///         func borderedCaption() -> some View {
    ///             modifier(BorderedCaption())
    ///         }
    ///     }
    ///
    /// Then you can apply the bordered caption to any view:
    ///
    ///     Image(systemName: "bus")
    ///         .resizable()
    ///         .frame(width:50, height:50)
    ///     Text("Downtown Bus")
    ///         .borderedCaption()
    ///
    ///
    /// - Parameter modifier: The modifier to apply to this view.
    @inlinable
    public func modifier<T>(_ modifier: T) -> ModifiedContent<Self, T> {
        ModifiedContent(content: self, modifier: modifier)
    }
    
}

@available(iOS 13.0, *)
internal func makeSecondaryLayerView<ViewType: View>(
    secondaryLayer: Attribute<ViewType>,
    alignment: Attribute<Alignment>,
    inputs: _ViewInputs,
    body: (_Graph, _ViewInputs) -> _ViewOutputs,
    flipOrder: Bool) -> _ViewOutputs {
        let bodyOutputs = body(_Graph(), inputs)
        
        let layoutDirection = inputs.environmentAttribute(keyPath: \EnvironmentValues.layoutDirection)
        
        let geometry = Attribute(SecondaryLayerGeometryQuery(
            alignment: .init(alignment),
            layoutDirection: .init(layoutDirection),
            primaryPosition: inputs.position,
            primarySize: inputs.size,
            primaryLayoutComputer: bodyOutputs.layout,
            secondaryLayoutComputer: .init())
        )
        
        let view = _GraphValue(secondaryLayer)
        
        var newInputs = inputs
        newInputs.size = geometry.size()
        newInputs.position = geometry.origin()
        newInputs.implicitRootType = _ZStackLayout.self
        
        let selfOutpus = ViewType.makeDebuggableView(value: view, inputs: newInputs)
        
        geometry.mutateBody(as: SecondaryLayerGeometryQuery.self, invalidating: true) { body in
            body.$secondaryLayoutComputer = selfOutpus.layout.attribute
        }
        
        
        let visitorOutputs = flipOrder ? (selfOutpus, bodyOutputs) : (bodyOutputs, selfOutpus)
        
        var visitor = PairwisePreferenceCombinerVisitor(outputs: visitorOutputs,
                                                        result: _ViewOutputs())
        for key in inputs.preferences.keys {
            key.visitKey(&visitor)
        }
        visitor.result.overrideLayout(bodyOutputs.layout)
        return visitor.result
    }

@available(iOS 13.0, *)
extension View {
    
    /// Sets the alignment of multiline text in this view.
    ///
    /// Use `multilineTextAlignment(_:)` to select an alignment for all of the
    /// text in this view or view hierarchy.
    ///
    /// In the example below, the contents of the ``Text`` view are center
    /// aligned. This also applies to the interpolated newline placed in the
    /// middle of the text since "multiple lines" refers to all of the text
    /// inside the view, regardless of any internal formatting or inclusion of
    /// interpolated text.
    ///
    ///     Text("This is a block of text that will show up in a text element as multiple lines.\("\n") Here we have chosen to center this text.")
    ///         .frame(width: 200, height: 200, alignment: .leading)
    ///         .multilineTextAlignment(.center)
    ///
    ///
    /// - Parameter alignment: A value that you use to left-, right-, or
    ///   center-align the text within a view.
    ///
    /// - Returns: A view that aligns the lines of multiline ``Text`` instances
    ///   it contains.
    @inlinable
    public func multilineTextAlignment(_ alignment: TextAlignment) -> some View {
        environment(\.multilineTextAlignment, alignment)
    }
    
    
    /// Sets the truncation mode for lines of text that are too long to fit in
    /// the available space.
    ///
    /// Use the `truncationMode(_:)` modifier to determine whether text in a
    /// long line is truncated at the beginning, middle, or end. Truncation is
    /// indicated by adding an ellipsis (…) to the line when removing text to
    /// indicate to readers that text is missing.
    ///
    /// In the example below, the bounds of text view constrains the amount of
    /// text that the view displays and the `truncationMode(_:)` specifies from
    /// which direction and where to display the truncation indicator:
    ///
    ///     Text("This is a block of text that will show up in a text element as multiple lines. The text will fill the available space, and then, eventually, be truncated.")
    ///         .frame(width: 150, height: 150)
    ///         .truncationMode(.tail)
    ///
    ///
    /// - Parameter mode: The truncation mode that specifies where to truncate
    ///   the text within the text view, if needed. You can truncate at the
    ///   beginning, middle, or end of the text view.
    ///
    /// - Returns: A view that truncates text at different points in a line
    ///   depending on the mode you select.
    @inlinable
    public func truncationMode(_ mode: Text.TruncationMode) -> some View {
        environment(\.truncationMode, mode)
    }
    
    /// Sets the amount of space between lines of text in this view.
    ///
    /// Use `lineSpacing(_:)` to set the amount of spacing from the bottom of
    /// one line to the top of the next for text elements in the view.
    ///
    /// In the ``Text`` view in the example below, 10 points separate the bottom
    /// of one line to the top of the next as the text field wraps inside this
    /// view. Applying `lineSpacing(_:)` to a view hierarchy applies the line
    /// spacing to all text elements contained in the view.
    ///
    ///     Text("This is a string in a TextField with 10 point spacing applied between the bottom of one line and the top of the next.")
    ///         .frame(width: 200, height: 200, alignment: .leading)
    ///         .lineSpacing(10)
    ///
    ///
    /// - Parameter lineSpacing: The amount of space between the bottom of one
    ///   line and the top of the next line in points.
    @inlinable
    public func lineSpacing(_ lineSpacing: CGFloat) -> some View {
        environment(\.lineSpacing, lineSpacing)
    }
    
    
    /// Sets whether text in this view can compress the space between characters
    /// when necessary to fit text in a line.
    ///
    /// Use `allowsTightening(_:)` to enable the compression of inter-character
    /// spacing of text in a view to try to fit the text in the view's bounds.
    ///
    /// In the example below, two identically configured text views show the
    /// effects of `allowsTightening(_:)` on the compression of the spacing
    /// between characters:
    ///
    ///     VStack {
    ///         Text("This is a wide text element")
    ///             .font(.body)
    ///             .frame(width: 200, height: 50, alignment: .leading)
    ///             .lineLimit(1)
    ///             .allowsTightening(true)
    ///
    ///         Text("This is a wide text element")
    ///             .font(.body)
    ///             .frame(width: 200, height: 50, alignment: .leading)
    ///             .lineLimit(1)
    ///             .allowsTightening(false)
    ///     }
    ///
    ///
    /// - Parameter flag: A Boolean value that indicates whether the space
    ///   between characters compresses when necessary.
    ///
    /// - Returns: A view that can compress the space between characters when
    ///   necessary to fit text in a line.
    @inlinable
    public func allowsTightening(_ flag: Bool) -> some View {
        environment(\.allowsTightening, flag)
    }
    
    
    /// Sets the maximum number of lines that text can occupy in this view.
    ///
    /// Use `lineLimit(_:)` to cap the number of lines that an individual text
    /// element can display.
    ///
    /// The line limit applies to all ``Text`` instances within a hierarchy. For
    /// example, an ``HStack`` with multiple pieces of text longer than three
    /// lines caps each piece of text to three lines rather than capping the
    /// total number of lines across the ``HStack``.
    ///
    /// In the example below, the `lineLimit(_:)` operator limits the very long
    /// line in the ``Text`` element to the 2 lines that fit within the view's
    /// bounds:
    ///
    ///     Text("This is a long string that demonstrates the effect of DanceUI's lineLimit(:_) operator.")
    ///      .frame(width: 200, height: 200, alignment: .leading)
    ///      .lineLimit(2)
    ///
    ///
    /// - Parameter number: The line limit. If `nil`, no line limit applies.
    ///
    /// - Returns: A view that limits the number of lines that ``Text``
    ///   instances display.
    @inlinable
    public func lineLimit(_ number: Int?) -> some View {
        environment(\.lineLimit, number)
    }
    
    
    /// Sets the minimum amount that text in this view scales down to fit in the
    /// available space.
    ///
    /// Use the `minimumScaleFactor(_:)` modifier if the text you place in a
    /// view doesn't fit and it's okay if the text shrinks to accommodate. For
    /// example, a label with a minimum scale factor of `0.5` draws its text in
    /// a font size as small as half of the actual font if needed.
    ///
    /// In the example below, the ``HStack`` contains a ``Text`` label with a
    /// line limit of `1`, that is next to a ``TextField``. To allow the label
    /// to fit into the available space, the `minimumScaleFactor(_:)` modifier
    /// shrinks the text as needed to fit into the available space.
    ///
    ///     HStack {
    ///         Text("This is a long label that will be scaled to fit:")
    ///             .lineLimit(1)
    ///             .minimumScaleFactor(0.5)
    ///         TextField("My Long Text Field", text: $myTextField)
    ///     }
    ///
    ///
    /// - Parameter factor: A fraction between 0 and 1 (inclusive) you use to
    ///   specify the minimum amount of text scaling that this view permits.
    ///
    /// - Returns: A view that limits the amount of text downscaling.
    @inlinable
    public func minimumScaleFactor(_ factor: CGFloat) -> some View {
        environment(\.minimumScaleFactor, factor)
    }
    
    
    /// Sets a transform for the case of the text contained in this view when
    /// displayed.
    ///
    /// The default value is `nil`, displaying the text without any case
    /// changes.
    ///
    /// - Parameter textCase: One of the ``Text/Case`` enumerations; the
    ///   default is `nil`.
    /// - Returns: A view that transforms the case of the text.
    @inlinable
    public func textCase(_ textCase: Text.Case?) -> some View {
        environment(\.textCase, textCase)
    }
    
}

@available(iOS 13.0, *)
extension View {
    /// Sets the preferred color scheme for this presentation.
    ///
    /// The color scheme applies to the nearest enclosing presentation, such as
    /// a popover or window. Views may read the color scheme using the
    /// `colorScheme` environment value.
    @inlinable
    public func preferredColorScheme(_ colorScheme: ColorScheme?) -> some View {
        preference(key: PreferredColorSchemeKey.self, value: colorScheme)
    }
}
