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

/// A proxy that represents one subview of a layout.
///
/// This type acts as a proxy for a view that your custom layout container
/// places in the user interface. ``Layout`` protocol methods
/// receive a ``LayoutSubviews`` collection that contains exactly one
/// proxy for each of the subviews arranged by your container.
///
/// Use a proxy to get information about the associated subview, like its
/// dimensions, layout priority, or custom layout values. You also use the
/// proxy to tell its corresponding subview where to appear by calling the
/// proxy's ``LayoutSubview/place(at:anchor:proposal:)`` method.
/// Do this once for each subview from your implementation of the layout's
/// ``Layout/placeSubviews(in:proposal:subviews:cache:)`` method.
///
/// You can read custom layout values associated with a subview
/// by using the property's key as an index on the subview. For more
/// information about defining, setting, and reading custom values,
/// see ``LayoutValueKey``.
@available(iOS 13.0, *)
public struct LayoutSubview : Equatable {
    
    internal let proxy: LayoutProxy
    
    internal let index: Int32

    /// Gets the value for the subview that's associated with the specified key.
    ///
    /// If you define a custom layout value using ``LayoutValueKey``,
    /// you can read the key's associated value for a given subview in
    /// a layout container by indexing the container's subviews with
    /// the key type. For example, if you define a `Flexibility` key
    /// type, you can put the associated values of all the layout's
    /// subviews into an array:
    ///
    ///     let flexibilities = subviews.map { subview in
    ///         subview[Flexibility.self]
    ///     }
    ///
    /// For more information about creating a custom layout, see ``Layout``.
    public subscript<K>(key: K.Type) -> K.Value where K : LayoutValueKey {
        guard let viewList = proxy.attributes._traitsList.value else {
            return K.defaultValue
        }
        return viewList.traits.value(for: _LayoutTrait<K>.self, defaultValue: _LayoutTrait<K>.defaultValue)
    }
    
    public func _trait<K: _ViewTraitKey>(key: K.Type) -> K.Value {
        guard let viewList = proxy.attributes._traitsList.value else {
            return K.defaultValue
        }
        return viewList.traits.value(for: key, defaultValue: K.defaultValue)
    }

    /// The layout priority of the subview.
    ///
    /// If you define a custom layout type using the ``Layout``
    /// protocol, you can read this value from subviews and use the value
    /// when deciding how to assign space to subviews. For example, you
    /// can read all of the subview priorities into an array before
    /// placing the subviews in a custom layout type called `BasicVStack`:
    ///
    ///     extension BasicVStack {
    ///         func placeSubviews(
    ///             in bounds: CGRect,
    ///             proposal: ProposedViewSize,
    ///             subviews: Subviews,
    ///             cache: inout ()
    ///         ) {
    ///             let priorities = subviews.map { subview in
    ///                 subview.priority
    ///             }
    ///
    ///             // Place views, based on priorities.
    ///         }
    ///     }
    ///
    /// Set the layout priority for a view that appears in your layout by
    /// applying the ``View/layoutPriority(_:)`` view modifier. For example,
    /// you can assign two different priorities to views that you arrange
    /// with `BasicVStack`:
    ///
    ///     BasicVStack {
    ///         Text("High priority")
    ///             .layoutPriority(10)
    ///         Text("Low priority")
    ///             .layoutPriority(1)
    ///     }
    ///
    public var priority: Double {
        proxy.layoutComputer.engine.layoutPriority()
    }

    /// Asks the subview for its size.
    ///
    /// Use this method as a convenience to get the ``ViewDimensions/width``
    /// and ``ViewDimensions/height`` properties of the ``ViewDimensions``
    /// instance returned by the ``dimensions(in:)`` method, reported as a
    /// [CGSize](https://developer.apple.com/documentation/CoreGraphics/CGSize)
    /// instance.
    ///
    /// - Parameter proposal: A proposed size for the subview. In DanceUI,
    ///   views choose their own size, but can take a size proposal from
    ///   their parent view into account when doing so.
    ///
    /// - Returns: The size that the subview chooses for itself, given the
    ///   proposal from its container view.
    public func sizeThatFits(_ proposal: ProposedViewSize) -> CGSize {
        proxy.layoutComputer.engine.sizeThatFits(proposal.proposal)
    }

    /// Asks the subview for its dimensions and alignment guides.
    ///
    /// Call this method to ask a subview of a custom ``Layout`` type
    /// about its size and alignment properties. You can call it from
    /// your implementation of any of that protocol's methods, like
    /// ``Layout/placeSubviews(in:proposal:subviews:cache:)`` or
    /// ``Layout/sizeThatFits(proposal:subviews:cache:)``, to get
    /// information for your layout calculations.
    ///
    /// When you call this method, you propose a size using the `proposal`
    /// parameter. The subview can choose its own size, but might take the
    /// proposal into account. You can call this method more than
    /// once with different proposals to find out if the view is flexible.
    /// For example, you can propose:
    ///
    /// * ``ProposedViewSize/zero`` to get the subview's minimum size.
    /// * ``ProposedViewSize/infinity`` to get the subview's maximum size.
    /// * ``ProposedViewSize/unspecified`` to get the subview's ideal size.
    ///
    /// If you need only the view's height and width, you can use the
    /// ``sizeThatFits(_:)`` method instead.
    ///
    /// - Parameter proposal: A proposed size for the subview. In DanceUI,
    ///   views choose their own size, but can take a size proposal from
    ///   their parent view into account when doing so.
    ///
    /// - Returns: A ``ViewDimensions`` instance that includes a height
    ///   and width, as well as a set of alignment guides.
    public func dimensions(in proposal: ProposedViewSize) -> ViewDimensions {
        let proposedSize = proposal.proposal
        let fittingSize = proxy.layoutComputer.engine.sizeThatFits(proposedSize)
        return ViewDimensions(guideComputer: proxy.layoutComputer, size: ViewSize(value: fittingSize, proposal: proposedSize))
    }

    /// The subviews's preferred spacing values.
    ///
    /// This ``ViewSpacing`` instance indicates how much space a subview
    /// in a custom layout prefers to have between it and the next view.
    /// It contains preferences for all edges, and might take into account
    /// the type of both this and the adjacent view. If your ``Layout`` type
    /// places subviews based on spacing preferences, use this instance
    /// to compute a distance between this subview and the next. See
    /// ``Layout/placeSubviews(in:proposal:subviews:cache:)`` for an
    /// example.
    ///
    /// You can also merge this instance with instances from other subviews
    /// to construct a new instance that's suitable for the subviews' container.
    /// See ``Layout/spacing(subviews:cache:)-4kg4w``.
    public var spacing: ViewSpacing {
        ViewSpacing(spacing: proxy.layoutComputer.engine.spacing())
    }

    /// Assigns a position and proposed size to the subview.
    ///
    /// Call this method from your implementation of the ``Layout``
    /// protocol's ``Layout/placeSubviews(in:proposal:subviews:cache:)``
    /// method for each subview arranged by the layout.
    /// Provide a position within the container's bounds where the subview
    /// should appear, and an anchor that indicates which part of the subview
    /// appears at that point.
    ///
    /// Include a proposed size that the subview can take into account when
    /// sizing itself. To learn the subview's size for a given proposal before
    /// calling this method, you can call the ``dimensions(in:)`` or
    /// ``sizeThatFits(_:)`` method on the subview with the same proposal.
    /// That enables you to know subview sizes before committing to subview
    /// positions.
    ///
    /// > Important: Call this method only from within your
    ///   ``Layout`` type's implementation of the
    /// ``Layout/placeSubviews(in:proposal:subviews:cache:)`` method.
    ///
    /// If you call this method more than once for a subview, the last call
    /// takes precedence. If you don't call this method for a subview, the
    /// subview appears at the center of its layout container and uses the
    /// layout container's size proposal.
    ///
    /// - Parameters:
    ///   - position: The place where the anchor of the subview should
    ///     appear in its container view, relative to container's bounds.
    ///   - anchor: The unit point on the subview that appears at `position`.
    ///     You can use a built-in point, like ``UnitPoint/center``, or
    ///     you can create a custom ``UnitPoint``.
    ///   - proposal: A proposed size for the subview. In DanceUI,
    ///     views choose their own size, but can take a size proposal from
    ///     their parent view into account when doing so.
    public func place(at position: CGPoint, anchor: UnitPoint = .topLeading, proposal: ProposedViewSize) {
        LayoutData.current.appendPlacement(.init(proposedSize: _ProposedSize(width: proposal.width,
                                                                             height: proposal.height),
                                                 anchor: anchor,
                                                 at: position),
                                           at: Int(index))
    }
    
    internal func place(at geometry: ViewGeometry) {
        LayoutData.current.geometries?.append(geometry)
    }
    
    internal func finallyPlaced(at placement: _Placement, in size: CGSize, layoutDirection: LayoutDirection) -> ViewGeometry {
        proxy.finallyPlaced(at: placement, in: size, layoutDirection: layoutDirection)
    }
    
    internal func lengthThatFits(_ proposedSize: _ProposedSize, in axis: Axis) -> CGFloat {
        proxy.layoutComputer.engine.lengthThatFits(proposedSize, in: axis)
    }
}

@available(iOS 13.0, *)
class LayoutSubviewStorage {
    
    internal var placement: _Placement?
}
