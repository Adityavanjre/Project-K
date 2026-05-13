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
public struct _AspectRatioLayout: UnaryLayout {
    
    public typealias Body = Never
    
    public typealias Content = Void
    
    public typealias AnimatableData = EmptyAnimatableData
    
    internal typealias PlacementContextType = PlacementContext

    public var aspectRatio: CGFloat?
    
    public var contentMode: ContentMode

    @inlinable
    public init(aspectRatio: CGFloat? = nil, contentMode: ContentMode) {
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
    }
    
    internal func placement(of child: LayoutProxy, in context: PlacementContext) -> _Placement {
        let size = context.size
        let space = spaceOffered(to: child, in: .init(size: size))
        let position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        return _Placement(proposedSize: space,
                          anchor: .center,
                          at: position)
    }
    
    internal func sizeThatFits(in proposedSize: _ProposedSize, context: SizeAndSpacingContext, child: LayoutProxy) -> CGSize {
        let targetSize = spaceOffered(to: child, in: proposedSize)
        return child.layoutComputer.engine.sizeThatFits(targetSize)
    }
    
    private func spaceOffered(to child: LayoutProxy,
                              in proposedSize: _ProposedSize) -> _ProposedSize {
        guard proposedSize != .unspecified else {
            return proposedSize
        }

        let ratioSize = effectiveRatio(child: child)
        
        switch contentMode {
        case .fit:
            return _ProposedSize(size: ratioSize.scaledToFit(proposedSize))
        case .fill:
            return _ProposedSize(size: ratioSize.scaledToFill(proposedSize))
        }
    }
    
    private func effectiveRatio(child: LayoutProxy) -> CGSize {
        let size = aspectRatio.map { CGSize(width: $0, height: 1) } ??
            child.layoutComputer.engine.sizeThatFits(_ProposedSize())
        if size.width == size.height {
            return CGSize(width: 1, height: 1)
        }
        return size
    }

}

@available(iOS 13.0, *)
extension View {
    
    /// Constrains this view's dimensions to the specified aspect ratio.
    ///
    /// Use `aspectRatio(_:contentMode:)` to constrain a view's dimensions to an
    /// aspect ratio specified by a
    /// <https://developer.apple.com/documentation/CoreGraphics/CGFloat> using the specified
    /// content mode.
    ///
    /// If this view is resizable, the resulting view will have `aspectRatio` as
    /// its aspect ratio. In this example, the purple ellipse has a 3:4
    /// width-to-height ratio, and scales to fit its frame:
    ///
    ///     Ellipse()
    ///         .fill(Color.purple)
    ///         .aspectRatio(0.75, contentMode: .fit)
    ///         .frame(width: 200, height: 200)
    ///         .border(Color(white: 0.75))
    ///
    ///
    /// - Parameters:
    ///   - aspectRatio: The ratio of width to height to use for the resulting
    ///     view. Use `nil` to maintain the current aspect ratio in the
    ///     resulting view.
    ///   - contentMode: A flag that indicates whether this view fits or fills
    ///     the parent context.
    ///
    /// - Returns: A view that constrains this view's dimensions to the aspect
    ///   ratio of the given size using `contentMode` as its scaling algorithm.
    @inlinable
    public func aspectRatio(_ aspectRatio: CGFloat? = nil,
                            contentMode: ContentMode) -> some View {
        modifier(_AspectRatioLayout(aspectRatio: aspectRatio,
                                    contentMode: contentMode))
    }
    
    /// Constrains this view's dimensions to the aspect ratio of the given size.
    ///
    /// Use `aspectRatio(_:contentMode:)` to constrain a view's dimensions to
    /// an aspect ratio specified by a
    /// <https://developer.apple.com/documentation/CoreGraphics/CGSize>.
    ///
    /// If this view is resizable, the resulting view uses `aspectRatio` as its
    /// own aspect ratio. In this example, the purple ellipse has a 3:4
    /// width-to-height ratio, and scales to fill its frame:
    ///
    ///     Ellipse()
    ///         .fill(Color.purple)
    ///         .aspectRatio(CGSize(width: 3, height: 4), contentMode: .fill)
    ///         .frame(width: 200, height: 200)
    ///         .border(Color(white: 0.75))
    ///
    ///
    /// - Parameters:
    ///   - aspectRatio: A size that specifies the ratio of width to height to
    ///     use for the resulting view.
    ///   - contentMode: A flag indicating whether this view should fit or fill
    ///     the parent context.
    ///
    /// - Returns: A view that constrains this view's dimensions to
    ///   `aspectRatio`, using `contentMode` as its scaling algorithm.
    @inlinable
    public func aspectRatio(_ aspectRatio: CGSize,
                            contentMode: ContentMode) -> some View {
        self.aspectRatio(aspectRatio.width / aspectRatio.height,
                         contentMode: contentMode)
    }
    
    /// Scales this view to fit its parent.
    ///
    /// Use `scaledToFit()` to scale this view to fit its parent, while
    /// maintaining the view's aspect ratio as the view scales.
    ///
    ///     Circle()
    ///         .fill(Color.pink)
    ///         .scaledToFit()
    ///         .frame(width: 300, height: 150)
    ///         .border(Color(white: 0.75))
    ///
    ///
    /// This method is equivalent to calling
    /// ``View/aspectRatio(_:contentMode:)-8z8dy`` with a `nil` aspectRatio and
    /// a content mode of ``ContentMode/fit``.
    ///
    /// - Returns: A view that scales this view to fit its parent, maintaining
    ///   this view's aspect ratio.
    @inlinable
    public func scaledToFit() -> some View {
        aspectRatio(contentMode: .fit)
    }
    
    /// Scales this view to fill its parent.
    ///
    /// Use `scaledToFill()` to scale this view to fill its parent, while
    /// maintaining the view's aspect ratio as the view scales:
    ///
    ///     Circle()
    ///         .fill(Color.pink)
    ///         .scaledToFill()
    ///         .frame(width: 300, height: 150)
    ///         .border(Color(white: 0.75))
    ///
    ///
    /// This method is equivalent to calling
    /// ``View/aspectRatio(_:contentMode:)-8z8dy`` with a `nil` aspectRatio and
    /// a content mode of ``ContentMode/fill``.
    ///
    /// - Returns: A view that scales this view to fill its parent, maintaining
    ///   this view's aspect ratio.
    @inlinable
    public func scaledToFill() -> some View {
        aspectRatio(contentMode: .fill)
    }
    
}

@available(iOS 13.0, *)
extension CGSize {
    
    internal func scaledToFit(_ proposal: _ProposedSize) -> CGSize {
        guard proposal != .unspecified else {
            return self
        }
        var widthScale: CGFloat = .infinity
        if let width = proposal.width {
            widthScale = width / self.width
        }
        
        var heightScale: CGFloat = .infinity
        if let height = proposal.height {
            heightScale = height / self.height
        }
        let scale = CGFloat.minimum(widthScale, heightScale)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
    
    internal func scaledToFill(_ proposal: _ProposedSize) -> CGSize {
        guard proposal != .unspecified else {
            return self
        }
        var widthScale: CGFloat = -.infinity
        if let width = proposal.width {
            widthScale = width / self.width
        }
        
        var heightScale: CGFloat = -.infinity
        if let height = proposal.height {
            heightScale = height / self.height
        }
        let scale = CGFloat.maximum(widthScale, heightScale)
        return CGSize(width: self.width * scale, height: self.height * scale)
    }
    
}
