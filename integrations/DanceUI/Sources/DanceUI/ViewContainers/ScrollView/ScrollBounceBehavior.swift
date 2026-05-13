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

@available(iOS 13.0, *)
extension View {
    
    /// Configures the bounce behavior of scrollable views along the specified
    /// axis.
    ///
    /// Use this modifier to indicate whether scrollable views bounce when
    /// people scroll to the end of the view's content, taking into account the
    /// relative sizes of the view and its content. For example, the following
    /// ``ScrollView`` only enables bounce behavior if its content is large
    /// enough to require scrolling:
    ///
    ///     ScrollView {
    ///         Text("Small")
    ///         Text("Content")
    ///     }
    ///     .scrollBounceBehavior(.basedOnSize)
    ///
    /// The modifier passes the scroll bounce mode through the ``Environment``,
    /// which means that the mode affects any scrollable views in the modified
    /// view hierarchy. Provide an axis to the modifier to constrain the kinds
    /// of scrollable views that the mode affects. For example, all the scroll
    /// views in the following example can access the mode value, but
    /// only the two nested scroll views are affected, because only they use
    /// horizontal scrolling:
    ///
    ///     ScrollView { // Defaults to vertical scrolling.
    ///         ScrollView(.horizontal) {
    ///             ShelfContent()
    ///         }
    ///         ScrollView(.horizontal) {
    ///             ShelfContent()
    ///         }
    ///     }
    ///     .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
    ///
    /// You can use this modifier to configure any kind of scrollable view,
    /// including ``ScrollView``, ``List``, ``Table``, and ``TextEditor``:
    ///
    ///     List {
    ///         Text("Hello")
    ///         Text("World")
    ///     }
    ///     .scrollBounceBehavior(.basedOnSize)
    ///
    /// - Parameters:
    ///   - behavior: The bounce behavior to apply to any scrollable views
    ///     within the configured view. Use one of the ``ScrollBounceBehavior``
    ///     values.
    ///   - axes: The set of axes to apply `behavior` to. The default is
    ///     ``Axis/vertical``.
    ///
    /// - Returns: A view that's configured with the specified scroll bounce
    ///   behavior.
    public func scrollBounceBehavior(_ behavior: ScrollBounceBehavior, axes: Axis.Set = [.vertical]) -> some View {
        modifier(TransformScrollBounceBehavior(behavior: behavior, axes: axes))
    }
    
}

/// The ways that a scrollable view can bounce when it reaches the end of its
/// content.
///
/// Use the ``View/scrollBounceBehavior(_:axes:)`` view modifier to set a value
/// of this type for a scrollable view, like a ``ScrollView`` or a ``List``.
/// The value configures the bounce behavior when people scroll to the end of
/// the view's content.
///
/// You can configure each scrollable axis to use a different bounce mode.
@available(iOS 13.0, *)
public struct ScrollBounceBehavior: Equatable {
    
    internal var role : Role
    
    @frozen
    internal enum Role: Hashable {
        
        case automatic

        case always

        case basedOnSize
        
        case never
    }
    
    /// The automatic behavior.
    ///
    /// The scrollable view automatically chooses whether content bounces when
    /// people scroll to the end of the view's content. By default, scrollable
    /// views use the ``ScrollBounceBehavior/always`` behavior.
    public static var automatic: ScrollBounceBehavior {
        ScrollBounceBehavior(role: .automatic)
    }
    
    /// The scrollable view always bounces.
    ///
    /// The scrollable view always bounces along the specified axis,
    /// regardless of the size of the content.
    public static var always: ScrollBounceBehavior {
        ScrollBounceBehavior(role: .always)
    }
    
    /// The scrollable view bounces when its content is large enough to require
    /// scrolling.
    ///
    /// The scrollable view bounces along the specified axis if the size of
    /// the content exceeeds the size of the scrollable view in that axis.
    public static var basedOnSize: ScrollBounceBehavior {
        ScrollBounceBehavior(role: .basedOnSize)
    }
    
    public static var never: ScrollBounceBehavior {
        ScrollBounceBehavior(role: .never)
    }
 
}

@available(iOS 13.0, *)
private struct TransformScrollBounceBehavior: ViewModifier {
    
    private let behavior: ScrollBounceBehavior
    
    private let axes: Axis.Set
    
    fileprivate init(behavior: ScrollBounceBehavior, axes: Axis.Set) {
        self.behavior = behavior
        self.axes = axes
    }
    
    fileprivate func body(content: Content) -> some View {
        content
            .transformEnvironment(\.horizontalScrollBounceBehavior) { value in
                if axes.contains(.horizontal) {
                    value = behavior
                }
            }
            .transformEnvironment(\.verticalScrollBounceBehavior) { value in
                if axes.contains(.vertical) {
                    value = behavior
                }
            }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    /// The scroll bounce mode for the vertical axis of scrollable views.
    ///
    /// Use the ``View/scrollBounceBehavior(_:axes:)`` view modifier to set this
    /// value in the ``Environment``.
    public var verticalScrollBounceBehavior: ScrollBounceBehavior {
        get {
            self[VerticalScrollBounceBehaviorKey.self]
        }
        set {
            self[VerticalScrollBounceBehaviorKey.self] = newValue
        }
    }

    /// The scroll bounce mode for the horizontal axis of scrollable views.
    ///
    /// Use the ``View/scrollBounceBehavior(_:axes:)`` view modifier to set this
    /// value in the ``Environment``.
    public var horizontalScrollBounceBehavior: ScrollBounceBehavior {
        get {
            self[HorizontalScrollBounceBehaviorKey.self]
        }
        set {
            self[HorizontalScrollBounceBehaviorKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct VerticalScrollBounceBehaviorKey: EnvironmentKey {
    
    fileprivate typealias Value = ScrollBounceBehavior
    
    fileprivate static var defaultValue: ScrollBounceBehavior { .automatic }

}

@available(iOS 13.0, *)
private struct HorizontalScrollBounceBehaviorKey: EnvironmentKey {
    
    fileprivate typealias Value = ScrollBounceBehavior
    
    fileprivate static var defaultValue: ScrollBounceBehavior { .automatic }

}
