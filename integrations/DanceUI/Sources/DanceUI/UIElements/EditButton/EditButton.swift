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

/// A button that toggles the edit mode environment value.
///
/// An edit button toggles the environment's ``EnvironmentValues/editMode``
/// value for content within a container that supports edit mode.
/// In the following example, an edit button placed inside a ``NavigationView``
/// supports editing of a ``List``:
///
///     @State private var fruits = [
///         "Apple",
///         "Banana",
///         "Papaya",
///         "Mango"
///     ]
///
///     var body: some View {
///         NavigationView {
///             List {
///                 ForEach(fruits, id: \.self) { fruit in
///                     Text(fruit)
///                 }
///                 .onDelete { fruits.remove(atOffsets: $0) }
///                 .onMove { fruits.move(fromOffsets: $0, toOffset: $1) }
///             }
///             .navigationTitle("Fruits")
///             .toolbar {
///                 EditButton()
///             }
///         }
///     }
///
/// Because the ``ForEach`` in the above example defines behaviors for
/// ``DynamicViewContent/onDelete(perform:)`` and
/// ``DynamicViewContent/onMove(perform:)``, the editable list displays the
/// delete and move UI when the user taps Edit. Notice that the Edit button
/// displays the title "Done" while edit mode is active:
///
///
/// You can also create custom views that react to changes in the edit mode
/// state, as described in ``EditMode``.
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct EditButton : View {

    internal let editMode: Environment<Binding<EditMode>?>
    
    private struct EditText: View {

        internal var editMode: EditMode

        internal var body: some View {
            // 0x40c210 iOS14.3
            // typealias Body = Text
            switch self.editMode {
            case .inactive:
                return Text.System.edit
            default:
                return Text.System.done
            }
        }
    }
    
    /// Creates an Edit button instance.
    public init() {
        self.editMode = .init(\.editMode)
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
        // 0x40c300 iOS14.3
        /*
        typealias Body =
        ModifiedContent<
            Button<EditButton.EditText>,
            _AnimationModifier<EditMode>
        >
        */
        let buttonMode: Binding<EditMode>? = self.editMode.wrappedValue
        var textMode: EditMode = .default
        var animationMode: EditMode = .default
        if var binding = buttonMode {
            textMode = binding.wrappedValue
            animationMode = binding.wrappedValue
            return Button(action: {
                var newMode = EditMode.inactive
                if (binding.wrappedValue == .default) {
                    newMode = .active
                }
                binding = binding.animation(.default)
                binding.wrappedValue = newMode
            }, label: {
                EditButton.EditText(editMode: textMode)
            })
                .animation(nil, value: animationMode)
        } else {
            return Button(action: {
                
            }, label: {
                EditButton.EditText(editMode: .default)
            })
                .animation(nil, value: EditMode.default)
        }
    }
}


