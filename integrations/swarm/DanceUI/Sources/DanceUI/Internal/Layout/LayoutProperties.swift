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

/// Layout-specific properties of a layout container.
///
/// This structure contains configuration information that's
/// applicable to a layout container. For example, the ``stackOrientation``
/// value indicates the layout's primary axis, if any.
///
/// You can use an instance of this type to characterize a custom layout
/// container, which is a type that conforms to the ``Layout`` protocol.
/// Implement the protocol's ``Layout/layoutProperties-6xtrx`` property
/// to return an instance. For example, you can indicate that your layout
/// has a vertical stack orientation:
///
///     extension BasicVStack {
///         static var layoutProperties: LayoutProperties {
///             var properties = LayoutProperties()
///             properties.stackOrientation = .vertical
///             return properties
///         }
///     }
///
/// If you don't implement the property in your custom layout, the protocol
/// provides a default implementation that returns a `LayoutProperties`
/// instance with default values.
@available(iOS 13.0, *)
public struct LayoutProperties {

    /// Creates a default set of properties.
    ///
    /// Use a layout properties instance to provide information about
    /// a type that conforms to the ``Layout`` protocol. For example, you
    /// can create a layout properties instance in your layout's implementation
    /// of the ``Layout/layoutProperties-6xtrx`` method, and use it to
    /// indicate that the layout has a ``Axis/vertical`` orientation:
    ///
    ///     extension BasicVStack {
    ///         static var layoutProperties: LayoutProperties {
    ///             var properties = LayoutProperties()
    ///             properties.stackOrientation = .vertical
    ///             return properties
    ///         }
    ///     }
    ///
    public init(_ stackOrientation: Axis? = nil) {
        self.stackOrientation = stackOrientation
    }

    /// The orientation of the containing stack-like container.
    ///
    /// Certain views alter their behavior based on the stack orientation
    /// of the container that they appear in. For example, ``Spacer`` and
    /// ``Divider`` align their major axis to match that of their container.
    ///
    /// Set the orientation for your custom layout container by returning a
    /// configured ``LayoutProperties`` instance from your ``Layout``
    /// type's implementation of the ``Layout/layoutProperties-6xtrx``
    /// method. For example, you can indicate that your layout has a
    /// ``Axis/vertical`` major axis:
    ///
    ///     extension BasicVStack {
    ///         static var layoutProperties: LayoutProperties {
    ///             var properties = LayoutProperties()
    ///             properties.stackOrientation = .vertical
    ///             return properties
    ///         }
    ///     }
    ///
    /// A value of `nil`, which is the default when you don't specify a
    /// value, indicates an unknown orientation, or that a layout isn't
    /// one-dimensional.
    public var stackOrientation: Axis?
}
