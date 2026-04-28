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

/// The inset distances for the sides of a rectangle.
@frozen
@available(iOS 13.0, *)
public struct EdgeInsets: Equatable, Animatable, _VectorMath {
    
    public var top: CGFloat

    public var leading: CGFloat

    public var bottom: CGFloat

    public var trailing: CGFloat
    
    public static let zero: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

    /// The type defining the data to be animated.
    public typealias AnimatableData = AnimatablePair<CGFloat, AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>>>
    
    /// The data to be animated.
    @inlinable
    public var animatableData: AnimatableData {
        get {
            .init(top, .init(leading, .init(bottom, trailing)))
        }
        set {
            top = newValue.first
            leading = newValue.second.first
            bottom = newValue.second.second.first
            trailing = newValue.second.second.second
        }
    }
    
    @usableFromInline
    internal init(_ uiEdgeInsets: UIEdgeInsets) {
        self.init(top: uiEdgeInsets.top,
                  leading: uiEdgeInsets.left,
                  bottom: uiEdgeInsets.bottom,
                  trailing: uiEdgeInsets.right)
    }
    
    @inlinable
    public init(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
    
    @usableFromInline
    internal init(_ size: CGFloat, edges: Edge.Set) {
        self.init(top: edges.contains(.top) ? size : 0,
                  leading: edges.contains(.leading) ? size : 0,
                  bottom: edges.contains(.bottom) ? size : 0,
                  trailing: edges.contains(.trailing) ? size : 0)
    }
    
    @usableFromInline
    internal init(_ value: CGFloat, edge: Edge) {
        var insets = EdgeInsets()
        insets.setValue(value, for: edge)
        
        self = insets
    }
    
    @inlinable
    public init() {
        self.init(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    
    internal func rounded(_ rule: FloatingPointRoundingRule,
                          toMultipleOf: CGFloat) -> EdgeInsets {
        var top = self.top
        var leading = self.leading
        var bottom = self.bottom
        var trailing = self.trailing
        top.round(rule, toMultipleOf: toMultipleOf)
        leading.round(rule, toMultipleOf: toMultipleOf)
        bottom.round(rule, toMultipleOf: toMultipleOf)
        trailing.round(rule, toMultipleOf: toMultipleOf)
        return .init(top: top,
                     leading: leading,
                     bottom: bottom,
                     trailing: trailing)
    }
    
    @usableFromInline
    internal func `in`(_ edgeSet: Edge.Set) -> EdgeInsets {
        EdgeInsets(top: edgeSet.contains(.top) ? top : 0,
                   leading: edgeSet.contains(.leading) ? leading : 0,
                   bottom: edgeSet.contains(.bottom) ? bottom : 0,
                   trailing: edgeSet.contains(.trailing) ? trailing : 0)
    }
    
}

@available(iOS 13.0, *)
extension UIEdgeInsets {
    
    internal init(_ insets: EdgeInsets) {
        self.init(top: insets.top, left: insets.leading, bottom: insets.bottom, right: insets.trailing)
    }
    
    internal init(_ insets: EdgeInsets, layoutDirection: LayoutDirection) {
        self.init(
            top: insets.top,
            left: layoutDirection == .leftToRight ? insets.leading : insets.trailing,
            bottom: insets.bottom,
            right: layoutDirection == .leftToRight ? insets.trailing : insets.leading)
    }
    
}

@available(iOS 13.0, *)
extension CGSize {
    
    @inline(__always)
    internal func inset(by insets: EdgeInsets) -> CGSize {
        var size = CGSize(width: width - (insets.leading + insets.trailing),
               height: height - (insets.top + insets.bottom))
        size.width = .maximum(size.width, 0)
        size.height = .maximum(size.height, 0)
        return size
    }
}

@available(iOS 13.0, *)
extension EdgeInsets {
    
    internal func value(for edge: Edge) -> CGFloat {
        switch edge {
        case .top:
            return top
        case .leading:
            return leading
        case .bottom:
            return bottom
        case .trailing:
            return trailing
        }
    }
    
    internal mutating func setValue(_ value: CGFloat, for edge: Edge) {
        switch edge {
        case .top:
            top = value
        case .leading:
            leading = value
        case .bottom:
            bottom = value
        case .trailing:
            trailing = value
        }
        
    }
}
