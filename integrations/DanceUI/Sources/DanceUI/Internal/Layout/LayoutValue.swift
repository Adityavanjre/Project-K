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

/// A key for accessing a layout value of a layout container's subviews.
///
/// If you create a custom layout by defining a type that conforms to the
/// ``Layout`` protocol, you can also create custom layout values
/// that you set on individual views, and that your container view can access
/// to guide its layout behavior. Your custom values resemble
/// the built-in layout values that you set with view modifiers
/// like ``View/layoutPriority(_:)`` and ``View/zIndex(_:)``, but have a
/// purpose that you define.
///
/// To create a custom layout value, define a type that conforms to the
/// `LayoutValueKey` protocol and implement the one required property that
/// returns the default value of the property. For example, you can create
/// a property that defines an amount of flexibility for a view, defined as
/// an optional floating point number with a default value of `nil`:
///
///     private struct Flexibility: LayoutValueKey {
///         static let defaultValue: CGFloat? = nil
///     }
///
/// The Swift compiler infers this particular key's associated type as an
/// optional [CGFloat](https://developer.apple.com/documentation/CoreGraphics/CGFloat)
/// from this definition.
///
/// ### Set a value on a view
///
/// Set the value on a view by adding the ``View/layoutValue(key:value:)``
/// view modifier to the view. To make your custom value easier to work
/// with, you can do this in a convenience modifier in an extension of the
/// ``View`` protocol:
///
///     extension View {
///         func layoutFlexibility(_ value: CGFloat?) -> some View {
///             layoutValue(key: Flexibility.self, value: value)
///         }
///     }
///
/// Use your modifier to set the value on any views that need a nondefault
/// value:
///
///     BasicVStack {
///         Text("One View")
///         Text("Another View")
///             .layoutFlexibility(3)
///     }
///
/// Any view that you don't explicitly set a value for uses the default
/// value, as with the first ``Text`` view, above.
///
/// ### Retrieve a value during layout
///
/// Access a custom layout value using the key as an index
/// on subview's proxy (an instance of ``LayoutSubview``)
/// and use the value to make decisions about sizing, placement, or other
/// layout operations. For example, you might read the flexibility value
/// in your layout view's ``LayoutSubview/sizeThatFits(_:)`` method, and
/// adjust your size calculations accordingly:
///
///     extension BasicVStack {
///         func sizeThatFits(
///             proposal: ProposedViewSize,
///             subviews: Subviews,
///             cache: inout Void
///         ) -> CGSize {
///
///             // Map the flexibility property of each subview into an array.
///             let flexibilities = subviews.map { subview in
///                 subview[Flexibility.self]
///             }
///
///             // Calculate and return the size of the layout container.
///             // ...
///         }
///     }
///
@available(iOS 13.0, *)
public protocol LayoutValueKey {

    /// The type of the key's value.
    ///
    /// Swift typically infers this type from your implementation of the
    /// ``defaultValue`` property, so you don't have to define it explicitly.
    associatedtype Value

    static var defaultValue: Self.Value { get }
}

@available(iOS 13.0, *)
extension View {
    
    /// Associates a value with a custom layout property.
    ///
    /// Use this method to set a value for a custom property that
    /// you define with ``LayoutValueKey``. For example, if you define
    /// a `Flexibility` key, you can set the key on a ``Text`` view
    /// using the key's type and a value:
    ///
    ///     Text("Another View")
    ///         .layoutValue(key: Flexibility.self, value: 3)
    ///
    /// For convenience, you might define a method that does this in an
    /// extension to ``View``:
    ///
    ///     extension View {
    ///         func layoutFlexibility(_ value: CGFloat?) -> some View {
    ///             layoutValue(key: Flexibility.self, value: value)
    ///         }
    ///     }
    ///
    /// This method makes the call site easier to read:
    ///
    ///     Text("Another View")
    ///         .layoutFlexibility(3)
    ///
    /// If you perform layout operations in a type that conforms to the
    /// ``Layout`` protocol, you can read the key's associated value for
    /// each subview of your custom layout type. Do this by indexing the
    /// subview's proxy with the key. For more information, see
    /// ``LayoutValueKey``.
    ///
    /// - Parameters:
    ///   - key: The type of the key that you want to set a value for.
    ///     Create the key as a type that conforms to the ``LayoutValueKey``
    ///     protocol.
    ///   - value: The value to assign to the key for this view.
    ///     The value must be of the type that you establish for the key's
    ///     associated value when you implement the key's
    ///     ``LayoutValueKey/defaultValue`` property.
    ///
    /// - Returns: A view that has the specified value for the specified key.
    @inlinable
    public func layoutValue<K: LayoutValueKey>(key: K.Type, value: K.Value) -> some View {
        _trait(_LayoutTrait<K>.self, value)
    }
  
}
