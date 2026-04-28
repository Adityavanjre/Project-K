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

@frozen
@available(iOS 13.0, *)
public struct _SafeAreaIgnoringLayout: UnaryLayout {

    public typealias Body = Never
    
    public typealias Content = Void
    
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = _PositionAwarePlacementContext
    
    public var edges: Edge.Set
    
    @inlinable
    public init(edges: Edge.Set = .all) {
        self.edges = edges
    }

    internal func placement(of child: LayoutProxy, in context: _PositionAwarePlacementContext) -> _Placement {
        _SafeAreaRegionsIgnoringLayout(regions: .all, edges: edges).placement(of: child, in: context)
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        child.layoutComputer.engine.sizeThatFits(proposedSize)
    }
}

@available(iOS, deprecated: 100000.0, message: "Use ignoresSafeArea(_:edges:) instead.")
@available(macOS, deprecated: 100000.0, message: "Use ignoresSafeArea(_:edges:) instead.")
@available(tvOS, deprecated: 100000.0, message: "Use ignoresSafeArea(_:edges:) instead.")
@available(watchOS, deprecated: 100000.0, message: "Use ignoresSafeArea(_:edges:) instead.")
@available(iOS 13.0, *)
extension View {
    
    /// Changes the view's proposed area to extend outside the screen's safe
    /// areas.
    ///
    /// Use `edgesIgnoringSafeArea(_:)` to change the area proposed for this
    /// view so that — were the proposal accepted — this view could extend
    /// outside the safe area to the bounds of the screen for the specified
    /// edges.
    ///
    /// For example, you can propose that a text view ignore the safe area's top
    /// inset:
    ///
    ///     VStack {
    ///         Text("This text is outside of the top safe area.")
    ///             .edgesIgnoringSafeArea([.top])
    ///             .border(Color.purple)
    ///         Text("This text is inside VStack.")
    ///             .border(Color.yellow)
    ///     }
    ///     .border(Color.gray)
    ///
    ///
    /// Depending on the surrounding view hierarchy, DanceUI may not honor an
    /// `edgesIgnoringSafeArea(_:)` request. This can happen, for example, if
    /// the view is inside a container that respects the screen's safe area. In
    /// that case you may need to apply `edgesIgnoringSafeArea(_:)` to the
    /// container instead.
    ///
    /// - Parameter edges: The set of the edges in which to expand the size
    ///   requested for this view.
    ///
    /// - Returns: A view that may extend outside of the screen's safe area
    ///   on the edges specified by `edges`.
    @inlinable
    public func edgesIgnoringSafeArea(_ edges: Edge.Set) -> some View {
        return modifier(_SafeAreaIgnoringLayout(edges: edges))
    }
    
}
