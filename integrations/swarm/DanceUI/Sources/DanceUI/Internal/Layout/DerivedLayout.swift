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
internal protocol DerivedLayout: Layout where Cache == Base.Cache, Subviews == Base.Subviews {
    
    associatedtype Base: Layout
    
    var base: Base { get }
}

@available(iOS 13.0, *)
extension DerivedLayout {
    
    public static var layoutProperties: LayoutProperties {
        Base.layoutProperties
    }

    public func makeCache(subviews: Self.Subviews) -> Self.Cache {
        base.makeCache(subviews: subviews)
    }

    public func updateCache(_ cache: inout Self.Cache,
                            subviews: Self.Subviews) { //BDCOV_EXCL_BLOCK 覆盖率抖动
        base.updateCache(&cache, subviews: subviews)
    }

    public func spacing(subviews: Self.Subviews,
                        cache: inout Self.Cache) -> ViewSpacing {
        base.spacing(subviews: subviews, cache: &cache)
    }

    public func sizeThatFits(proposal: ProposedViewSize,
                             subviews: Self.Subviews,
                             cache: inout Self.Cache) -> CGSize {
        base.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
    }

    public func placeSubviews(in bounds: CGRect,
                              proposal: ProposedViewSize,
                              subviews: Self.Subviews,
                              cache: inout Self.Cache) {
        base.placeSubviews(in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    public func explicitAlignment(of guide: HorizontalAlignment,
                                  in bounds: CGRect,
                                  proposal: ProposedViewSize,
                                  subviews: Self.Subviews,
                                  cache: inout Self.Cache) -> CGFloat? {
        base.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }

    public func explicitAlignment(of guide: VerticalAlignment,
                                  in bounds: CGRect,
                                  proposal: ProposedViewSize,
                                  subviews: Self.Subviews,
                                  cache: inout Self.Cache) -> CGFloat? {
        base.explicitAlignment(of: guide, in: bounds, proposal: proposal, subviews: subviews, cache: &cache)
    }
}

/// A horizontal container that you can use in conditional layouts.
///
/// This layout container behaves like an ``HStack``, but conforms to the
/// ``Layout`` protocol so you can use it in the conditional layouts that you
/// construct with ``AnyLayout``. If you don't need a conditional layout, use
/// ``HStack`` instead.
@frozen
@available(iOS 13.0, *)
public struct HStackLayout: DerivedLayout {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
    
    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use
    /// a type alias to define this type as your data storage type.
    /// Alternatively, you can refer to the data storage type directly in all
    /// the places where you work with the cache.
    ///
    /// See ``makeCache(subviews:)`` for more information.
    public typealias Cache = _StackLayoutCache
    
    internal typealias Base = _HStackLayout
    
    /// The vertical alignment of subviews.
    public var alignment: VerticalAlignment
    
    /// The distance between adjacent subviews.
    ///
    /// Set this value to `nil` to use default distances between subviews.
    public var spacing: CGFloat?
    
    internal var base: _HStackLayout {
        _HStackLayout(alignment: alignment, spacing: spacing)
    }
    
    /// Creates a horizontal stack with the specified spacing and vertical
    /// alignment.
    ///
    /// - Parameters:
    ///     - alignment: The guide for aligning the subviews in this stack. It
    ///       has the same vertical screen coordinate for all subviews.
    ///     - spacing: The distance between adjacent subviews. Set this value
    ///       to `nil` to use default distances between subviews.
    @inlinable
    public init(alignment: VerticalAlignment = .center,
                spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
}

/// A vertical container that you can use in conditional layouts.
///
/// This layout container behaves like a ``VStack``, but conforms to the
/// ``Layout`` protocol so you can use it in the conditional layouts that you
/// construct with ``AnyLayout``. If you don't need a conditional layout, use
/// ``VStack`` instead.
@frozen
@available(iOS 13.0, *)
public struct VStackLayout: DerivedLayout {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
    
    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use
    /// a type alias to define this type as your data storage type.
    /// Alternatively, you can refer to the data storage type directly in all
    /// the places where you work with the cache.
    ///
    /// See ``makeCache(subviews:)`` for more information.
    public typealias Cache = _StackLayoutCache
    
    internal typealias Base = _VStackLayout
    
    /// The horizontal alignment of subviews.
    public var alignment: HorizontalAlignment
    
    /// The distance between adjacent subviews.
    ///
    /// Set this value to `nil` to use default distances between subviews.
    public var spacing: CGFloat?
    
    internal var base: _VStackLayout {
        _VStackLayout(alignment: alignment, spacing: spacing)
    }
    
    /// Creates a vertical stack with the specified spacing and horizontal
    /// alignment.
    ///
    /// - Parameters:
    ///     - alignment: The guide for aligning the subviews in this stack. It
    ///       has the same horizontal screen coordinate for all subviews.
    ///     - spacing: The distance between adjacent subviews. Set this value
    ///       to `nil` to use default distances between subviews.
    @inlinable
    public init(alignment: HorizontalAlignment = .center,
                spacing: CGFloat? = nil) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
}

/// An overlaying container that you can use in conditional layouts.
///
/// This layout container behaves like a ``ZStack``, but conforms to the
/// ``Layout`` protocol so you can use it in the conditional layouts that you
/// construct with ``AnyLayout``. If you don't need a conditional layout, use
/// ``ZStack`` instead.
@frozen
@available(iOS 13.0, *)
public struct ZStackLayout: DerivedLayout {
    
    /// The type defining the data to animate.
    public typealias AnimatableData = EmptyAnimatableData
    
    /// Cached values associated with the layout instance.
    ///
    /// If you create a cache for your custom layout, you can use
    /// a type alias to define this type as your data storage type.
    /// Alternatively, you can refer to the data storage type directly in all
    /// the places where you work with the cache.
    ///
    /// See ``makeCache(subviews:)`` for more information.
    public typealias Cache = Void
    
    typealias Base = _ZStackLayout
    
    /// The alignment of subviews.
    public var alignment: Alignment
    
    internal var base: _ZStackLayout {
        _ZStackLayout(alignment: alignment)
    }
    
    /// Creates a stack with the specified alignment.
    ///
    /// - Parameters:
    ///   - alignment: The guide for aligning the subviews in this stack
    ///     on both the x- and y-axes.
    @inlinable public init(alignment: Alignment = .center) {
        self.alignment = alignment
    }
}
