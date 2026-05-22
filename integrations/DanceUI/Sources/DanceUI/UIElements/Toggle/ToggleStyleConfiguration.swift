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

/// The properties of a toggle instance.
///
/// When you define a custom toggle style by creating a type that conforms to
/// the ``ToggleStyle`` protocol, you implement the
/// ``ToggleStyle/makeBody(configuration:)`` method. That method takes a
/// `ToggleStyleConfiguration` input that has the information you need
/// to define the behavior and appearance of a ``Toggle``.
///
/// The configuration structure's ``label-swift.property`` reflects the
/// toggle's content, which might be the value that you supply to the
/// `label` parameter of the ``Toggle/init(isOn:label:)`` initializer.
/// Alternatively, it could be another view that DanceUI builds from an
/// initializer that takes a string input, like ``Toggle/init(_:isOn:)``.
/// In either case, incorporate the label into the toggle's view to help
/// the user understand what the toggle does. For example, the built-in
/// ``ToggleStyle/switch`` style horizontally stacks the label with the
/// control element.
///
/// The structure's ``isOn`` property provides a ``Binding`` to the state
/// of the toggle. Adjust the appearance of the toggle based on this value.
/// For example, the built-in ``ToggleStyle/button`` style fills the button's
/// background when the property is `true`, but leaves the background empty
/// when the property is `false`. Change the value when the user performs
/// an action that's meant to change the toggle, like the button does when
/// tapped or clicked by the user.

@available(iOS 13.0, *)
public struct ToggleStyleConfiguration {

    /// A type-erased label of a toggle.
    public struct Label : ViewAlias {
        
        /// The type of view representing the body of this view.
        public typealias Body = Never
        
    }

    /// A view that describes the effect of switching the toggle between states.
    ///
    /// Use this value in your implementation of the
    /// ``ToggleStyle/makeBody(configuration:)`` method when defining a custom
    /// ``ToggleStyle``. Access it through the that method's `configuration`
    /// parameter.
    ///
    /// Because the label is a ``View``, you can incorporate it into the
    /// view hierarchy that you return from your style definition. For example,
    /// you can combine the label with a circle image in an ``HStack``:
    ///
    ///     HStack {
    ///         Image(systemName: configuration.isOn
    ///             ? "checkmark.circle.fill"
    ///             : "circle")
    ///         configuration.label
    ///     }
    ///
    public let label: ToggleStyleConfiguration.Label

    /// A binding to a state property that indicates whether the toggle is on.
    ///
    /// Because this value is a ``Binding``, you can both read and write it
    /// in your implementation of the ``ToggleStyle/makeBody(configuration:)``
    /// method when defining a custom ``ToggleStyle``. Access it through
    /// that method's `configuration` parameter.
    ///
    /// Read this value to set the appearance of the toggle. For example, you
    /// can choose between empty and filled circles based on the `isOn` value:
    ///
    ///     Image(systemName: configuration.isOn
    ///         ? "checkmark.circle.fill"
    ///         : "circle")
    ///
    /// Write this value when the user takes an action that's meant to change
    /// the state of the toggle. For example, you can toggle it inside the
    /// `action` closure of a ``Button`` instance:
    ///
    ///     Button {
    ///         configuration.isOn.toggle()
    ///     } label: {
    ///         // Draw the toggle.
    ///     }
    ///
    @Binding
    public var isOn: Bool
    
}
