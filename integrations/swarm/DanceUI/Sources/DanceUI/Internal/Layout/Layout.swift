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

@available(iOS 13.0, *)
public protocol Layout : Animatable {

    /// Properties of a layout container.
    ///
    /// Implement this property in a type that conforms to the ``Layout``
    /// protocol to characterize your custom layout container. For example,
    /// you can indicate that your layout has a vertical
    /// ``LayoutProperties/stackOrientation``:
    ///
    ///     extension BasicVStack {
    ///         static var layoutProperties: LayoutProperties {
    ///             var properties = LayoutProperties()
    ///             properties.stackOrientation = .vertical
    ///             return properties
    ///         }
    ///     }
    ///
    /// If you don't implement this property in your custom layout, the protocol
    /// provides a default implementation, namely ``layoutProperties-7z59b``,
    /// that returns a ``LayoutProperties`` instance with default values.
    static var layoutProperties: LayoutProperties { get }

    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use
    /// a type alias to define this type as your data storage type.
    /// Alternatively, you can refer to the data storage type directly in all
    /// the places where you work with the cache.
    ///
    /// See ``Layout/makeCache(subviews:)-28zq1`` for more information.
    associatedtype Cache = Void

    /// A collection of proxies for the subviews of a layout view.
    ///
    /// This collection doesn't store views. Instead it stores instances of
    /// ``LayoutSubview``, each of which acts as a proxy for one of the
    /// views arranged by the layout. Use the proxies to
    /// get information about the views, and to tell the views where to
    /// appear.
    ///
    /// For more information about the behavior of the underlying
    /// collection type, see ``LayoutSubviews``.
    typealias Subviews = LayoutSubviews

    /// Creates and initializes a cache for a layout instance.
    ///
    /// You can optionally use a cache to preserve calculated values across
    /// calls to a layout container's methods. Many layout types don't need
    /// a cache, because DanceUI automatically reuses both the results of
    /// calls into the layout and the values that the layout reads from its
    /// subviews. Rely on the protocol's default implementation of this method
    /// if you don't need a cache.
    ///
    /// However you might find a cache useful when:
    ///
    /// - The layout container repeats complex, intermediate calculations
    /// across calls like ``sizeThatFits(proposal:subviews:cache:)``,
    /// ``placeSubviews(in:proposal:subviews:cache:)``, and
    /// ``explicitAlignment(of:in:proposal:subviews:cache:)-40eor``.
    /// You might be able to improve performance by calculating values
    /// once and storing them in a cache.
    /// - The layout container reads many ``LayoutValueKey`` values from
    /// subviews. It might be more efficient to do that once and store the
    /// results in the cache, rather than rereading the subviews' values before
    /// each layout call.
    /// - You want to maintain working storage, like temporary Swift arrays,
    /// across calls into the layout, to minimize the number of allocation
    /// events.
    ///
    /// Only implement a cache if profiling shows that it improves performance.
    ///
    /// ### Initialize a cache
    ///
    /// Implement the `makeCache(subviews:)` method to create a cache.
    /// You can add computed values to the cache right away, using information
    /// from the `subviews` input parameter, or you can do that later. The
    /// methods of the ``Layout`` protocol that can access the cache
    /// take the cache as an in-out parameter, which enables you to modify
    /// the cache anywhere that you can read it.
    ///
    /// You can use any storage type that makes sense for your layout
    /// algorithm, but be sure that you only store data that you derive
    /// from the layout and its subviews (lazily, if possible). For this to
    /// work correctly, DanceUI needs to be able to call this method to
    /// recreate the cache without changing the layout result.
    ///
    /// When you return a cache from this method, you implicitly define a type
    /// for your cache. Be sure to either make the type of the `cache`
    /// parameters on your other ``Layout`` protocol methods match, or use
    /// a type alias to define the ``Cache`` associated type.
    ///
    /// ### Update the cache
    ///
    /// If the layout container or any of its subviews change, DanceUI
    /// calls the ``updateCache(_:subviews:)-7dlay`` method so you can
    /// modify or invalidate the contents of the
    /// cache. The default implementation of that method calls the
    /// `makeCache(subviews:)` method to recreate the cache, but you can
    /// provide your own implementation of the update method to take an
    /// incremental approach, if appropriate.
    ///
    /// - Parameters:
    ///   - subviews: A collection of proxy instances that represent the
    ///     views that the container arranges. You can use the proxies in the
    ///     collection to get information about the subviews as you
    ///     calculate values to store in the cache.
    ///
    /// - Returns: Storage for calculated data that you share among
    ///   the methods of your custom layout container.
    func makeCache(subviews: Self.Subviews) -> Self.Cache

    /// Updates the layout's cache when something changes.
    ///
    /// If your custom layout container creates a cache by implementing the
    /// ``makeCache(subviews:)-8xi2d`` method, DanceUI calls the update method
    /// when your layout or its subviews change, giving you an opportunity
    /// to modify or invalidate the contents of the cache.
    /// The method's default implementation recreates the
    /// cache by calling the ``makeCache(subviews:)-8xi2d`` method,
    /// but you can provide your own implementation to take an
    /// incremental approach, if appropriate.
    ///
    /// - Parameters:
    ///   - cache: Storage for calculated data that you share among
    ///     the methods of your custom layout container.
    ///   - subviews: A collection of proxy instances that represent the
    ///     views arranged by the container. You can use the proxies in the
    ///     collection to get information about the subviews as you
    ///     calculate values to store in the cache.
    func updateCache(_ cache: inout Self.Cache, subviews: Self.Subviews)

    /// Returns the preferred spacing values of the composite view.
    ///
    /// Implement this method to provide custom spacing preferences
    /// for a layout container. The value you return affects
    /// the spacing around the container, but it doesn't affect how the
    /// container arranges subviews relative to one another inside the
    /// container.
    ///
    /// Create a custom ``ViewSpacing`` instance for your container by
    /// initializing one with default values, and then merging that with
    /// spacing instances of certain subviews. For example, if you define
    /// a basic vertical stack that places subviews in a column, you could
    /// use the spacing preferences of the subview edges that make
    /// contact with the container's edges:
    ///
    ///     extension BasicVStack {
    ///         func spacing(subviews: Subviews, cache: inout ()) -> ViewSpacing {
    ///             var spacing = ViewSpacing()
    ///
    ///             for index in subviews.indices {
    ///                 var edges: Edge.Set = [.leading, .trailing]
    ///                 if index == 0 { edges.formUnion(.top) }
    ///                 if index == subviews.count - 1 { edges.formUnion(.bottom) }
    ///                 spacing.formUnion(subviews[index].spacing, edges: edges)
    ///             }
    ///
    ///             return spacing
    ///         }
    ///     }
    ///
    /// In the above example, the first and last subviews contribute to the
    /// spacing above and below the container, respectively, while all subviews
    /// affect the spacing on the leading and trailing edges.
    ///
    /// If you don't implement this method, the protocol provides a default
    /// implementation, namely ``spacing(subviews:cache:)-leu1``,
    /// that merges the spacing preferences across all subviews on all edges.
    ///
    /// - Parameters:
    ///   - subviews: A collection of proxy instances that represent the
    ///     views that the container arranges. You can use the proxies in the
    ///     collection to get information about the subviews as you determine
    ///     how much spacing the container prefers around it.
    ///   - cache: Optional storage for calculated data that you can share among
    ///     the methods of your custom layout container. See
    ///     ``makeCache(subviews:)-8xi2d`` for details.
    ///
    /// - Returns: A ``ViewSpacing`` instance that describes the preferred
    ///   spacing around the container view.
    func spacing(subviews: Self.Subviews, cache: inout Self.Cache) -> ViewSpacing

    /// Returns the size of the composite view, given a proposed size
    /// and the view's subviews.
    ///
    /// Implement this method to tell your custom layout container's parent
    /// view how much space the container needs for a set of subviews, given
    /// a size proposal. The parent might call this method more than once
    /// during a layout pass with different proposed sizes to test the
    /// flexibility of the container, using proposals like:
    ///
    /// * The ``ProposedViewSize/zero`` proposal; respond with the
    ///   layout's minimum size.
    /// * The ``ProposedViewSize/infinity`` proposal; respond with the
    ///   layout's maximum size.
    /// * The ``ProposedViewSize/unspecified`` proposal; respond with the
    ///   layout's ideal size.
    ///
    /// The parent might also choose to test flexibility in one dimension at a
    /// time. For example, a horizontal stack might propose a fixed height and
    /// an infinite width, and then the same height with a zero width.
    ///
    /// The following example calculates the size for a basic vertical stack
    /// that places views in a column, with no spacing between the views:
    ///
    ///     private struct BasicVStack: Layout {
    ///         func sizeThatFits(
    ///             proposal: ProposedViewSize,
    ///             subviews: Subviews,
    ///             cache: inout ()
    ///         ) -> CGSize {
    ///             subviews.reduce(CGSize.zero) { result, subview in
    ///                 let size = subview.sizeThatFits(.unspecified)
    ///                 return CGSize(
    ///                     width: max(result.width, size.width),
    ///                     height: result.height + size.height)
    ///             }
    ///         }
    ///
    ///         // This layout also needs a placeSubviews() implementation.
    ///     }
    ///
    /// The implementation asks each subview for its ideal size by calling the
    /// ``LayoutSubview/sizeThatFits(_:)`` method with an
    /// ``ProposedViewSize/unspecified`` proposed size.
    /// It then reduces these values into a single size that represents
    /// the maximum subview width and the sum of subview heights.
    /// Because this example isn't flexible, it ignores its size proposal
    /// input and always returns the same value for a given set of subviews.
    ///
    /// DanceUI views choose their own size, so the layout engine always
    /// uses a value that you return from this method as the actual size of the
    /// composite view. That size factors into the construction of the `bounds`
    /// input to the ``placeSubviews(in:proposal:subviews:cache:)`` method.
    ///
    /// - Parameters:
    ///   - proposal: A size proposal for the container. The container's parent
    ///     view that calls this method might call the method more than once
    ///     with different proposals to learn more about the container's
    ///     flexibility before deciding which proposal to use for placement.
    ///   - subviews: A collection of proxies that represent the
    ///     views that the container arranges. You can use the proxies in the
    ///     collection to get information about the subviews as you determine
    ///     how much space the container needs to display them.
    ///   - cache: Optional storage for calculated data that you can share among
    ///     the methods of your custom layout container. See
    ///     ``makeCache(subviews:)-8xi2d`` for details.
    ///
    /// - Returns: A size that indicates how much space the container
    ///   needs to arrange its subviews.
    func sizeThatFits(proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache) -> CGSize

    /// Assigns positions to each of the layout's subviews.
    ///
    /// DanceUI calls your implementation of this method to tell your
    /// custom layout container to place its subviews. From this method, call
    /// the ``LayoutSubview/place(at:anchor:proposal:)`` method on each
    /// element in `subviews` to tell the subviews where to appear in the
    /// user interface.
    ///
    /// For example, you can create a basic vertical stack that places views
    /// in a column, with views horizontally aligned on their leading edge:
    ///
    ///     struct BasicVStack: Layout {
    ///         func placeSubviews(
    ///             in bounds: CGRect,
    ///             proposal: ProposedViewSize,
    ///             subviews: Subviews,
    ///             cache: inout ()
    ///         ) {
    ///             var point = bounds.origin
    ///             for subview in subviews {
    ///                 subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
    ///                 point.y += subview.dimensions(in: .unspecified).height
    ///             }
    ///         }
    ///
    ///         // This layout also needs a sizeThatFits() implementation.
    ///     }
    ///
    /// The example creates a placement point that starts at the origin of the
    /// specified `bounds` input and uses that to place the first subview. It
    /// then moves the point in the y dimension by the subview's height,
    /// which it reads using the ``LayoutSubview/dimensions(in:)`` method.
    /// This prepares the point for the next iteration of the loop. All
    /// subview operations use an ``ProposedViewSize/unspecified`` size
    /// proposal to indicate that subviews should use and report their ideal
    /// size.
    ///
    /// A more complex layout container might add space between subviews
    /// according to their ``LayoutSubview/spacing`` preferences, or a
    /// fixed space based on input configuration. For example, you can extend
    /// the basic vertical stack's placement method to calculate the
    /// preferred distances between adjacent subviews and store the results in
    /// an array:
    ///
    ///     let spacing: [CGFloat] = subviews.indices.dropLast().map { index in
    ///         subviews[index].spacing.distance(
    ///             to: subviews[index + 1].spacing,
    ///             along: .vertical)
    ///     }
    ///
    /// The spacing's ``ViewSpacing/distance(to:along:)`` method considers the
    /// preferences of adjacent views on the edge where they meet. It returns
    /// the smallest distance that satisfies both views' preferences for the
    /// given edge. For example, if one view prefers at least `2` points on its
    /// bottom edge, and the next view prefers at least `8` points on its top
    /// edge, the distance method returns `8`, because that's the smallest
    /// value that satisfies both preferences.
    ///
    /// Update the placement calculations to use the spacing values:
    ///
    ///     var point = bounds.origin
    ///     for (index, subview) in subviews.enumerated() {
    ///         if index > 0 { point.y += spacing[index - 1] } // Add spacing.
    ///         subview.place(at: point, anchor: .topLeading, proposal: .unspecified)
    ///         point.y += subview.dimensions(in: .unspecified).height
    ///     }
    ///
    /// Be sure that you use computations during placement that are consistent
    /// with those in your implementation of other protocol methods for a given
    /// set of inputs. For example, if you add spacing during placement,
    /// make sure your implementation of
    /// ``sizeThatFits(proposal:subviews:cache:)`` accounts for the extra space.
    /// Similarly, if the sizing method returns different values for different
    /// size proposals, make sure the placement method responds to its
    /// `proposal` input in the same way.
    ///
    /// - Parameters:
    ///   - bounds: The region that the container view's parent allocates to the
    ///     container view, specified in the parent's coordinate space.
    ///     Place all the container's subviews within the region.
    ///     The size of this region matches a size that your container
    ///     previously returned from a call to the
    ///     ``sizeThatFits(proposal:subviews:cache:)`` method.
    ///   - proposal: The size proposal from which the container generated the
    ///     size that the parent used to create the `bounds` parameter.
    ///     The parent might propose more than one size before calling the
    ///     placement method, but it always uses one of the proposals and the
    ///     corresponding returned size when placing the container.
    ///   - subviews: A collection of proxies that represent the
    ///     views that the container arranges. Use the proxies in the collection
    ///     to get information about the subviews and to tell the subviews
    ///     where to appear.
    ///   - cache: Optional storage for calculated data that you can share among
    ///     the methods of your custom layout container. See
    ///     ``makeCache(subviews:)-8xi2d`` for details.
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache)

    /// Returns the position of the specified horizontal alignment guide along
    /// the x axis.
    ///
    /// Implement this method to return a value for the specified alignment
    /// guide of a custom layout container. The value you return affects
    /// the placement of the container as a whole, but it doesn't affect how the
    /// container arranges subviews relative to one another.
    ///
    /// You can use this method to put an alignment guide in a nonstandard
    /// position. For example, you can indent the container's leading edge
    /// alignment guide by 10 points:
    ///
    ///     extension BasicVStack {
    ///         func explicitAlignment(
    ///             of guide: HorizontalAlignment,
    ///             in bounds: CGRect,
    ///             proposal: ProposedViewSize,
    ///             subviews: Subviews,
    ///             cache: inout ()
    ///         ) -> CGFloat? {
    ///             if guide == .leading {
    ///                 return bounds.minX + 10
    ///             }
    ///             return nil
    ///         }
    ///     }
    ///
    /// The above example returns `nil` for other guides to indicate that they
    /// don't have an explicit value. A guide without an explicit value behaves
    /// as it would for any other view. If you don't implement the
    /// method, the protocol's default implementation merges the
    /// subviews' guides.
    ///
    /// - Parameters:
    ///   - guide: The ``HorizontalAlignment`` guide that the method calculates
    ///     the position of.
    ///   - bounds: The region that the container view's parent allocates to the
    ///     container view, specified in the parent's coordinate space.
    ///   - proposal: A proposed size for the container.
    ///   - subviews: A collection of proxy instances that represent the
    ///     views arranged by the container. You can use the proxies in the
    ///     collection to get information about the subviews as you determine
    ///     where to place the guide.
    ///   - cache: Optional storage for calculated data that you can share among
    ///     the methods of your custom layout container. See
    ///     ``makeCache(subviews:)-8xi2d`` for details.
    ///
    /// - Returns: The guide's position relative to the `bounds`.
    ///   Return `nil` to indicate that the guide doesn't have an explicit
    ///   value.
    func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache) -> CGFloat?

    /// Returns the position of the specified vertical alignment guide along
    /// the y axis.
    ///
    /// Implement this method to return a value for the specified alignment
    /// guide of a custom layout container. The value you return affects
    /// the placement of the container as a whole, but it doesn't affect how the
    /// container arranges subviews relative to one another.
    ///
    /// You can use this method to put an alignment guide in a nonstandard
    /// position. For example, you can raise the container's bottom edge
    /// alignment guide by 10 points:
    ///
    ///     extension BasicVStack {
    ///         func explicitAlignment(
    ///             of guide: VerticalAlignment,
    ///             in bounds: CGRect,
    ///             proposal: ProposedViewSize,
    ///             subviews: Subviews,
    ///             cache: inout ()
    ///         ) -> CGFloat? {
    ///             if guide == .bottom {
    ///                 return bounds.minY - 10
    ///             }
    ///             return nil
    ///         }
    ///     }
    ///
    /// The above example returns `nil` for other guides to indicate that they
    /// don't have an explicit value. A guide without an explicit value behaves
    /// as it would for any other view. If you don't implement the
    /// method, the protocol's default implementation merges the
    /// subviews' guides.
    ///
    /// - Parameters:
    ///   - guide: The ``VerticalAlignment`` guide that the method calculates
    ///     the position of.
    ///   - bounds: The region that the container view's parent allocates to the
    ///     container view, specified in the parent's coordinate space.
    ///   - proposal: A proposed size for the container.
    ///   - subviews: A collection of proxy instances that represent the
    ///     views arranged by the container. You can use the proxies in the
    ///     collection to get information about the subviews as you determine
    ///     where to place the guide.
    ///   - cache: Optional storage for calculated data that you can share among
    ///     the methods of your custom layout container. See
    ///     ``makeCache(subviews:)-8xi2d`` for details.
    ///
    /// - Returns: The guide's position relative to the `bounds`.
    ///   Return `nil` to indicate that the guide doesn't have an explicit
    ///   value.
    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache) -> CGFloat?
}

@available(iOS 13.0, *)
extension Layout {

    /// The default property values for a layout.
    ///
    /// If you don't implement the ``Layout/layoutProperties-6xtrx`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which returns a ``LayoutProperties`` instance with
    /// default values. The properties instance contains information about the
    /// layout container, like a ``LayoutProperties/stackOrientation``
    /// property that indicates the container's major axis.
    public static var layoutProperties: LayoutProperties {
        .init()
    }

    /// Reinitializes a cache to a new value.
    ///
    /// If you don't implement the ``updateCache(_:subviews:)-7dlay`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which calls ``makeCache(subviews:)-8xi2d``.
    public func updateCache(_ cache: inout Self.Cache, subviews: Self.Subviews) {
        
    }

    /// Returns the result of merging the horizontal alignment guides of all
    /// subviews.
    ///
    /// If you don't implement the
    /// ``Layout/explicitAlignment(of:in:proposal:subviews:cache:)-40eor`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which merges the guides of all the subviews.
    public func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache) -> CGFloat? {
        guard !subviews.isEmpty else {
            return nil
        }
        var index: Int = 0
        var explicitAlignment: CGFloat? = nil
        for subview in subviews {
            let fittingSize = subview.sizeThatFits(proposal)
            let dimension = ViewDimensions(guideComputer: subview.proxy.layoutComputer, size: ViewSize(value: fittingSize, proposal: proposal.proposal))
            guard let alignment = dimension[explicit: guide.key] else {
                continue
            }
            let childValue: CGFloat = bounds.origin.x + alignment
            
            guide.key.id._combineExplicit(childValue: childValue, index, into: &explicitAlignment)
            index += 1
        }
        return explicitAlignment
    }

    /// Returns the result of merging the vertical alignment guides of all
    /// subviews.
    ///
    /// If you don't implement the
    /// ``Layout/explicitAlignment(of:in:proposal:subviews:cache:)-1noa1`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which merges the guides of all the subviews.
    public func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Self.Subviews, cache: inout Self.Cache) -> CGFloat? {
        guard !subviews.isEmpty else {
            return nil
        }
        var index: Int = 0
        var explicitAlignment: CGFloat? = nil
        for subview in subviews {
            let fittingSize = subview.sizeThatFits(proposal)
            let dimension = ViewDimensions(guideComputer: subview.proxy.layoutComputer, size: ViewSize(value: fittingSize, proposal: proposal.proposal))
            guard let alignment = dimension[explicit: guide.key] else {
                continue
            }
            let childValue: CGFloat = bounds.origin.y + alignment
            
            guide.key.id._combineExplicit(childValue: childValue, index, into: &explicitAlignment)
            index += 1
        }
        return explicitAlignment
    }

    /// Returns the union of all subview spacing.
    ///
    /// If you don't implement the ``Layout/spacing(subviews:cache:)-4kg4w`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which returns the union of the spacing preferences of all
    /// the layout's subviews.
    public func spacing(subviews: Self.Subviews, cache: inout Self.Cache) -> ViewSpacing {
        var spacing: Spacing = subviews.count == 0 ? .zero : Spacing(minima: [:])
        
        var edgeSets: [Edge.Set] = [.all]
        for (index, subview) in subviews.enumerated() {
            if index == 0 {
                edgeSets.append(.init(.leading))
                edgeSets.append(.init(.top))
            }
            if index == subviews.count - 1 {
                edgeSets.append(.init(.trailing))
                edgeSets.append(.init(.bottom))
            }
            let currentSpacing: Spacing = subview.proxy.layoutComputer.engine.spacing()
            spacing.incorporate(.init(edgeSets), of: currentSpacing)
        }
        return ViewSpacing(spacing: spacing)
    }
}

@available(iOS 13.0, *)
extension Layout where Self.Cache == () {

    /// Returns the empty value when your layout doesn't require a cache.
    ///
    /// If you don't implement the ``makeCache(subviews:)-8xi2d`` method in
    /// your custom layout, the protocol uses this default implementation
    /// instead, which returns an empty value.
    public func makeCache(subviews: Self.Subviews) -> Self.Cache {
        ()
    }
}

@available(iOS 13.0, *)
extension Layout {

    /// Combines the specified views into a single composite view using
    /// the layout algorithms of the custom layout container.
    ///
    /// Don't call this method directly. DanceUI calls it when you
    /// instantiate a custom layout that conforms to the ``Layout``
    /// protocol:
    ///
    ///     BasicVStack { // Implicitly calls callAsFunction.
    ///         Text("A View")
    ///         Text("Another View")
    ///     }
    ///
    /// For information about how Swift uses the `callAsFunction()` method to
    /// simplify call site syntax, see
    /// [Methods with Special Names](https://docs.swift.org/swift-book/ReferenceManual/Declarations.html#ID622)
    /// in *The Swift Programming Language*.
    ///
    /// - Parameter content: A ``ViewBuilder`` that contains the views to
    ///   lay out.
    ///
    /// - Returns: A composite view that combines all the input views.
    @_disfavoredOverload
    public func callAsFunction<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        _VariadicView.Tree(root: _LayoutRoot(layout: self), content: content())
    }

}

@available(iOS 13.0, *)
// Layout Procedure
// 1. Parent proposes a size for child
// 2. Child chooses its own size
// 3. Parent places child in parent's coordinate space
public enum CoordinateSpace: Equatable, Hashable {
    
//     Apple's public interface's definition is:
//
//     case global
//     case local
//     case named(AnyHashable)
//
//     but the order in dump file is:
//
//     case named
//     case global
//     case local
//
//     case offset: qword[0x18]
     
    
    // case: not 0x0 and not 0x1
    case named(AnyHashable)

    // case: 0x0
    case global

    // case: 0x1
    case local
    
}

@available(iOS 13.0, *)
public extension CoordinateSpace {
    public var isGlobal: Bool {
        switch self {
        case .global:
            return true
        default:
            return false
        }
    }
    
    public var isLocal: Bool {
        switch self {
        case .local:
            return true
        default:
            return false
        }
    }
}

@available(iOS 13.0, *)
extension CGPoint {
    static let invalidValue: CGPoint = CGPoint(x: Double.infinity, y: Double.infinity)
}

@available(iOS 13.0, *)
extension CGSize {
    static let invalidValue: CGSize = CGSize(width: Double.infinity, height: Double.infinity)
}

