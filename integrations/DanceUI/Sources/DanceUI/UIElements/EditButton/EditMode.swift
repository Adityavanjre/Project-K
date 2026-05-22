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

/// A mode that indicates whether the user can edit a view's content.
///
/// You receive an optional binding to the edit mode state when you
/// read the ``EnvironmentValues/editMode`` environment value. The binding
/// contains an `EditMode` value that indicates whether edit mode is active,
/// and that you can use to change the mode. To learn how to read an environment
/// value, see ``EnvironmentValues``.
///
/// Certain built-in views automatically alter their appearance and behavior
/// in edit mode. For example, a ``List`` with a ``ForEach`` that's
/// configured with the ``DynamicViewContent/onDelete(perform:)`` or
/// ``DynamicViewContent/onMove(perform:)`` modifier provides controls to
/// delete or move list items while in edit mode. On devices without an attached
/// keyboard and mouse or trackpad, people can make multiple selections in lists
/// only when edit mode is active.
///
/// You can also customize your own views to react to edit mode.
/// The following example replaces a read-only ``Text`` view with
/// an editable ``TextField``, checking for edit mode by
/// testing the wrapped value's ``EditMode/isEditing`` property:
///
///     @Environment(\.editMode) private var editMode
///     @State private var name = "Maria Ruiz"
///
///     var body: some View {
///         Form {
///             if editMode?.wrappedValue.isEditing == true {
///                 TextField("Name", text: $name)
///             } else {
///                 Text(name)
///             }
///         }
///         .animation(nil, value: editMode?.wrappedValue)
///         .toolbar { // Assumes embedding this view in a NavigationView.
///             EditButton()
///         }
///     }
///
/// You can set the edit mode through the binding, or you can
/// rely on an ``EditButton`` to do that for you, as the example above
/// demonstrates. The button activates edit mode when the user
/// taps it, and disables the mode when the user taps again.@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public enum EditMode {

    /// The user can't edit the view content.
    ///
    /// The ``isEditing`` property is `false` in this state.
    case inactive

    /// The view is in a temporary edit mode.
    ///
    /// The use of this state varies by platform and for different
    /// controls. As an example, DanceUI might engage temporary edit mode
    /// over the duration of a swipe gesture.
    ///
    /// The ``isEditing`` property is `true` in this state.
    case transient

    /// The user can edit the view content.
    ///
    /// The ``isEditing`` property is `true` in this state.
    case active

    public static let `default`: EditMode = .inactive
    
    /// Indicates whether a view is being edited.
    ///
    /// This property returns `true` if the mode is something other than
    /// inactive.
    public var isEditing: Bool {
        get {
            // 0x75df40 iOS14.3
            switch self {
            case .inactive:
                return false
            default:
                return true
            }
        }
    }
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension EditMode : Equatable {
}

@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension EditMode : Hashable {
}
