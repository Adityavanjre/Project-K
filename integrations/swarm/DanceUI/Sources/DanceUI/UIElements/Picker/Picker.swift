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

/// A control for selecting from a set of mutually exclusive values.
///
/// You create a picker by providing a selection binding, a label, and the
/// content for the picker to display. Set the `selection` parameter to a bound
/// property that provides the value to display as the current selection. Set
/// the label to a view that visually describes the purpose of selecting content
/// in the picker, and then provide the content for the picker to display.
///
/// For example, consider an enumeration of ice cream flavors and a ``State``
/// variable to hold the selected flavor:
///
///     enum Flavor: String, CaseIterable, Identifiable {
///         case chocolate, vanilla, strawberry
///         var id: Self { self }
///     }
///
///     @State private var selectedFlavor: Flavor = .chocolate
///
/// You can create a picker to select among the values by providing a label, a
/// binding to the current selection, and a collection of views for the picker's
/// content. Append a tag to each of these content views using the
/// ``View/tag(_:)`` view modifier so that the type of each selection matches
/// the type of the bound state variable:
///
///     List {
///         Picker("Flavor", selection: $selectedFlavor) {
///             Text("Chocolate").tag(Flavor.chocolate)
///             Text("Vanilla").tag(Flavor.vanilla)
///             Text("Strawberry").tag(Flavor.strawberry)
///         }
///     }
///
/// If you provide a string label for the picker, as the example above does,
/// the picker uses it to initialize a ``Text`` view as a
/// label. Alternatively, you can use the ``init(selection:content:label:)``
/// initializer to compose the label from other views. The exact appearance
/// of the picker depends on the context. If you use a picker in a ``List``
/// in iOS, it appears in a row with the label and selected value, and a
/// chevron to indicate that you can tap the row to select a new value:
///
///
/// ### Iterating over a picker’s options
///
/// To provide selection values for the `Picker` without explicitly listing
/// each option, you can create the picker with a ``ForEach``:
///
///     Picker("Flavor", selection: $selectedFlavor) {
///         ForEach(Flavor.allCases) { flavor in
///             Text(flavor.rawValue.capitalized)
///         }
///     }
///
/// ``ForEach`` automatically assigns a tag to the selection views using
/// each option's `id`. This is possible because `Flavor` conforms to the
/// [Identifiable](https://developer.apple.com/documentation/Swift/Identifiable)
/// protocol.
///
/// The example above relies on the fact that `Flavor` defines the type of its
/// `id` parameter to exactly match the selection type. If that's not the case,
/// you need to override the tag. For example, consider a `Topping` type
/// and a suggested topping for each flavor:
///
///     enum Topping: String, CaseIterable, Identifiable {
///         case nuts, cookies, blueberries
///         var id: Self { self }
///     }
///
///     extension Flavor {
///         var suggestedTopping: Topping {
///             switch self {
///             case .chocolate: return .nuts
///             case .vanilla: return .cookies
///             case .strawberry: return .blueberries
///             }
///         }
///     }
///
///     @State private var suggestedTopping: Topping = .nuts
///
/// The following example shows a picker that's bound to a `Topping` type,
/// while the options are all `Flavor` instances. Each option uses the tag
/// modifier to associate the suggested topping with the flavor it displays:
///
///     List {
///         Picker("Flavor", selection: $suggestedTopping) {
///             ForEach(Flavor.allCases) { flavor in
///                 Text(flavor.rawValue.capitalized)
///                     .tag(flavor.suggestedTopping)
///             }
///         }
///         HStack {
///             Text("Suggested Topping")
///             Spacer()
///             Text(suggestedTopping.rawValue.capitalized)
///                 .foregroundStyle(.secondary)
///         }
///     }
///
/// When the user selects chocolate, the picker sets `suggestedTopping`
/// to the value in the associated tag:
///
///
/// Other examples of when the views in a picker's ``ForEach`` need an explicit
/// tag modifier include when you:
/// * Select over the cases of an enumeration that conforms to the
///   [Identifiable](https://developer.apple.com/documentation/Swift/Identifiable) protocol
///   by using anything besides `Self` as the `id` parameter type. For example,
///   a string enumeration might use the case's `rawValue` string as the `id`.
///   That identifier type doesn't match the selection type, which is the type
///   of the enumeration itself.
/// * Use an optional value for the `selection` input parameter. For that to
///   work, you need to explicitly cast the tag modifier's input as
///   [Optional](https://developer.apple.com/documentation/Swift/Optional) to match.
///   For an example of this, see ``View/tag(_:)``.
///
/// ### Styling pickers
///
/// You can customize the appearance and interaction of pickers using
/// styles that conform to the ``PickerStyle`` protocol, like
/// ``PickerStyle/segmented`` or ``PickerStyle/menu``. To set a specific style
/// for all picker instances within a view, use the ``View/pickerStyle(_:)``
/// modifier. The following example applies the ``PickerStyle/segmented``
/// style to two pickers that independently select a flavor and a topping:
///
///     VStack {
///         Picker("Flavor", selection: $selectedFlavor) {
///             ForEach(Flavor.allCases) { flavor in
///                 Text(flavor.rawValue.capitalized)
///             }
///         }
///         Picker("Topping", selection: $selectedTopping) {
///             ForEach(Topping.allCases) { topping in
///                 Text(topping.rawValue.capitalized)
///             }
///         }
///     }
///     .pickerStyle(.segmented)
///
@available(iOS 13.0, *)
public struct Picker<Label, SelectionValue, Content> : View where Label : View, SelectionValue : Hashable, Content : View {
    
    @Binding
    internal var selection: SelectionValue

    internal var label: Label

    internal var content: Content
    
    /// Creates a picker that displays a custom label.
    ///
    /// - Parameters:
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - content: A view that contains the set of options.
    ///     - label: A view that describes the purpose of selecting an option.
    public init(selection: Binding<SelectionValue>, label: Label, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.label = label
        self.content = content()
    }
    
//    typealias Body = ModifiedContent<ModifiedContent<ResolvedPicker<SelectionValue>, StaticSourceWriter<PickerStyleConfiguration<SelectionValue>.Label, Label>>, StaticSourceWriter<PickerStyleConfiguration<SelectionValue>.Content, Content>>

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
        ResolvedPicker(configuration: PickerStyleConfiguration(selection: $selection))
            .viewAlias(PickerStyleConfiguration<SelectionValue>.Label.self) {
                label
            }
            .viewAlias(PickerStyleConfiguration<SelectionValue>.Content.self) {
                content
            }
    }
}

@available(iOS 13.0, *)
extension Picker where Label == Text {
    
    /// Creates a picker that generates its label from a localized string key.
    ///
    /// - Parameters:
    ///     - titleKey: A localized string key that describes the purpose of
    ///       selecting an option.
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - content: A view that contains the set of options.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// ``Text`` for more information about localizing strings.
    ///
    /// To initialize a picker with a string variable, use
    /// ``init(_:selection:content:)-5njtq`` instead.
    public init(_ titleKey: LocalizedStringKey, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) {
        self.init(selection: selection, label: Text(titleKey), content: content)
    }
    
    /// Creates a picker that generates its label from a string.
    ///
    /// - Parameters:
    ///     - title: A string that describes the purpose of selecting an option.
    ///     - selection: A binding to a property that determines the
    ///       currently-selected option.
    ///     - content: A view that contains the set of options.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(_:)-9d1g4``. See ``Text`` for more
    /// information about localizing strings.
    ///
    /// To initialize a picker with a localized string key, use
    /// ``init(_:selection:content:)-6lwfn`` instead.
    @_disfavoredOverload
    public init<S>(_ title: S, selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content) where S : StringProtocol {
        self.init(selection: selection, label: Text(title), content: content)
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Sets the style for pickers within this view.
    public func pickerStyle<S>(_ style: S) -> some View where S : PickerStyle {
        modifier(PickerStyleWriter(style: style))
    }
}
