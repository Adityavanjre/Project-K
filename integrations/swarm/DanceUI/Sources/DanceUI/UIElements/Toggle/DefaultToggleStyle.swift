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

/// The default toggle style.
///
/// Use the ``ToggleStyle/automatic`` static variable to create this style:
///
///     Toggle("Enhance Sound", isOn: $isEnhanced)
///         .toggleStyle(.automatic)
///

@available(iOS 13.0, *)
public struct DefaultToggleStyle : ToggleStyle {

    /// Creates a default toggle style.
        ///
        /// Don't call this initializer directly. Instead, use the
        /// ``ToggleStyle/automatic`` static variable to create this style:
        ///
        ///     Toggle("Enhance Sound", isOn: $isEnhanced)
        ///         .toggleStyle(.automatic)
        ///
    public init() {}

    /// Creates a view that represents the body of a toggle.
    ///
    /// The system calls this method for each ``Toggle`` instance in a view
    /// hierarchy where this style is the current toggle style.
    ///
    /// - Parameter configuration: The properties of the toggle.
    public func makeBody(configuration: DefaultToggleStyle.Configuration) -> some View {
        Toggle(configuration)
    }
}
