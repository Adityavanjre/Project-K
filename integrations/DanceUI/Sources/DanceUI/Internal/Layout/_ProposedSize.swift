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

import CoreGraphics

@available(iOS 13.0, *)
@frozen
public struct _ProposedSize: Hashable, CustomDebugStringConvertible {
    
    /// The proposed horizontal size measured in points.
    ///
    /// A value of `nil` represents an unspecified width proposal, which a view
    /// interprets to mean that it should use its ideal width.
    public var width: CGFloat?
    
    /// The proposed vertical size measured in points.
    ///
    /// A value of `nil` represents an unspecified height proposal, which a view
    /// interprets to mean that it should use its ideal height.
    public var height: CGFloat?
    
    @inline(__always)
    internal var size: CGSize {
        CGSize(width: width ?? 0, height: height ?? 0)
    }
    
    /// The proposed size with both dimensions left unspecified.
    ///
    /// Both dimensions contain `nil` in this size proposal.
    /// Subviews of a custom layout return their ideal size when you propose
    /// this value using the ``LayoutSubview/dimensions(in:)`` method.
    /// A custom layout should also return its ideal size from the
    /// ``Layout/sizeThatFits(proposal:subviews:cache:)`` method for this
    /// value.
    public static let unspecified: _ProposedSize = _ProposedSize(width: nil, height: nil)
    
    /// A size proposal that contains zero in both dimensions.
    ///
    /// Subviews of a custom layout return their minimum size when you propose
    /// this value using the ``LayoutSubview/dimensions(in:)`` method.
    /// A custom layout should also return its minimum size from the
    /// ``Layout/sizeThatFits(proposal:subviews:cache:)`` method for this
    /// value.
    public static let zero: _ProposedSize = _ProposedSize(width: 0, height: 0)
    
    /// A size proposal that contains infinity in both dimensions.
    ///
    /// Both dimensions contain
    /// <doc://com.apple.documentation/documentation/CoreGraphics/CGFloat/1454161-infinity>
    /// in this size proposal.
    /// Subviews of a custom layout return their maximum size when you propose
    /// this value using the ``LayoutSubview/dimensions(in:)`` method.
    /// A custom layout should also return its maximum size from the
    /// ``Layout/sizeThatFits(proposal:subviews:cache:)`` method for this
    /// value.
    public static let infinity: _ProposedSize = _ProposedSize(width: CGFloat.infinity, height: CGFloat.infinity)
    
    @inline(__always)
    internal init() {
        width = nil
        height = nil
    }
    
    /// Creates a new proposed size from a specified size.
    ///
    /// - Parameter size: A proposed size with dimensions measured in points.
    @inlinable
    public init(size: CGSize) {
        width = size.width
        height = size.height
    }
    
    @inlinable
    public init(size: CGFloat, axis: Axis) {
        switch axis {
        case .horizontal:
            width = size
        case .vertical:
            height = size
        }
    }
    
    /// Creates a new proposed size using the specified width and height.
    ///
    /// - Parameters:
    ///   - width: A proposed width in points. Use a value of `nil` to indicate
    ///     that the width is unspecified for this proposal.
    ///   - height: A proposed height in points. Use a value of `nil` to
    ///     indicate that the height is unspecified for this proposal.
    @inlinable
    public init(width: CGFloat?, height: CGFloat?) {
        self.width = width
        self.height = height
    }
    
    @inline(__always)
    internal init(major: CGFloat?, axis: Axis, minor: CGFloat?) {
        if axis == .horizontal {
            self.width = major
            self.height = minor
        } else {
            self.width = minor
            self.height = major
        }
    }
    
    public var debugDescription: String {
        let widthString = width.map({$0.description}) ?? "nil"
        let heightString = height.map({$0.description}) ?? "nil"
        return "<ProposedViewSize; width = \(widthString), height = \(heightString)>"
    }
    
    @inlinable
    public func replacingUnspecifiedDimensions(by size: CGSize = CGSize(width: 10, height: 10)) -> CGSize {
        let width = self.width ?? size.width
        let height = self.height ?? size.height
        return CGSize(width: width, height: height)
    }
}

@available(iOS 13.0, *)
extension _ProposedSize {
    public struct Init {
        @inline(__always)
        public static func apply(_ size: CGSize) -> _ProposedSize {
            .init(size: size)
        }
    }
}

@available(iOS 13.0, *)
extension _ProposedSize {
    
    internal func contains(_ other: _ProposedSize) -> Bool {
        
        guard let width = width,
              let height = height,
              let otherWidth = other.width,
              let otherHeight = other.height else {
            return false
        }
        
        guard size.isVaild && other.size.isVaild else {
            return false
        }

        return width >= otherWidth && height >= otherHeight
    }
    
    internal func inset(by insets: EdgeInsets) -> _ProposedSize {
        var proposal = self
        if var width = proposal.width {
            width = width + (insets.trailing + insets.leading)
            proposal.width = .maximum(0, width)
        }
        if var height = proposal.height {
            height = height + (insets.top + insets.bottom)
            proposal.height = .maximum(0, height)
        }
        return proposal
    }
    
}

@available(iOS 13.0, *)
extension CGSize {
    
    internal var isVaild: Bool {
        width > 0 && width < .infinity && height > 0 && height < .infinity
    }
    
    internal func canOutOfSize(_ proposal: _ProposedSize) -> Bool {
        guard let width = proposal.width,
              let height = proposal.height else {
            return true
        }
        
        return width >= self.width || height >= self.height
    }
    
    internal var proposedSize: _ProposedSize {
        var size = _ProposedSize()
        if !width.isNaN {
            size.width = width
        }
        if !height.isNaN {
            size.height = height
        }
        return size
    }
    
}
