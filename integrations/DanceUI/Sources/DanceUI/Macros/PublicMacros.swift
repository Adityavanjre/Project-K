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

/// Creates an environment values, transaction, container values,
/// or focused values entry.
///
/// ## Environment Values
///
/// Create ``EnvironmentValues`` entries by extending the
/// ``EnvironmentValues`` structure with new properties and attaching the
/// @Entry macro to the variable declarations:
///
/// ```swift
/// extension EnvironmentValues {
///     @Entry var myCustomValue: String = "Default value"
///     @Entry var anotherCustomValue = true
/// }
/// ```
///
/// ## Transaction Values
///
/// Create ``Transaction`` entries by extending the ``Transaction``
/// structure with new properties and attaching the @Entry macro
/// to the variable declarations:
///
/// ```swift
/// extension Transaction {
///     @Entry var myCustomValue: String = "Default value"
/// }
/// ```
///
/// ## Container Values
///
/// Create ``ContainerValues`` entries by extending the ``ContainerValues``
/// structure with new properties and attaching the @Entry macro
/// to the variable declarations:
///
/// ```swift
/// extension ContainerValues {
///     @Entry var myCustomValue: String = "Default value"
/// }
/// ```
///
/// ## Focused Values
///
/// Since the default value for ``FocusedValues`` is always `nil`,
/// ``FocusedValues`` entries cannot specify a different default value and
/// must have an Optional type.
///
/// Create ``FocusedValues`` entries by extending the
/// ``FocusedValues`` structure with new properties and attaching
/// the @Entry macro to the variable declarations:
///
/// ```swift
/// extension FocusedValues {
///     @Entry var myCustomValue: String?
/// }
/// ```
@attached(accessor) @attached(peer, names: prefixed(__Key_)) public macro Entry() = #externalMacro(
    module: "DanceUIMacros", type: "EntryMacro"
)

@attached(accessor) public macro __EntryDefaultValue() = #externalMacro(
    module: "DanceUIMacros", type: "EntryDefaultValueMacro"
)

