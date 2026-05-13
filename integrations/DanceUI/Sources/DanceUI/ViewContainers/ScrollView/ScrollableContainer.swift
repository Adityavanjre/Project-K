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
internal protocol ScrollableContainer: Scrollable {
    
    var children: [Scrollable]? { get }
    
    var parent: Scrollable? { get }
    
    func makeTarget<ID: Hashable>(for identifier: ID, anchor: UnitPoint?) -> ContentOffsetTarget?
    
}

@available(iOS 13.0, *)
extension ScrollableContainer {
    
    @inlinable
    internal var contentSize: CGSize? {
        apply { child in
            child.contentSize
        }
    }
    
    @inlinable
    internal var contentOffset: CGPoint? {
        apply { child in
            child.contentOffset
        }
    }
    
    @inlinable
    internal var adjustedContentInset: UIEdgeInsets? {
        apply { child in
            child.adjustedContentInset
        }
    }
    
    @inlinable
    internal var isDragging: Bool? {
        apply { child in
            child.isDragging
        }
    }
    
    @inlinable
    internal func scroll<ID: Hashable>(to identifier: ID, anchor: UnitPoint?) -> Bool {
        if let target = makeTarget(for: identifier, anchor: anchor) {
            return setContentOffset(target: target)
        }
        return apply { child in
            child.scroll(to: identifier, anchor: anchor)
        }
    }
    
    @inlinable
    internal func scroll(to contentOffset: CGPoint) -> Bool {
        apply { child in
            child.scroll(to: contentOffset)
        }
    }
    
    /// DanceUI Extension
    private func apply(_ block: (Scrollable) -> Bool) -> Bool {
        guard let children = children else {
            return false
        }
        for child in children where block(child) {
            return true
        }
        
        return false
    }
    
    /// DanceUI Extension
    private func apply<T>(_ block: (Scrollable) -> T?) -> T? {
        guard let children = children else {
            return nil
        }
        for child in children {
            if let result = block(child) {
                return result
            }
        }
        return nil
    }
    
    @inlinable
    internal func setContentOffset(target: @escaping ContentOffsetTarget) -> Bool {
        parent?.setContentOffset(target: target) ?? false
    }
    
    @inlinable
    internal func adjustContentOffset(by size: CGSize) -> Bool {
        parent?.adjustContentOffset(by: size) ?? false
    }
    
    @inlinable
    internal func containsScrollable<ID: Hashable>(_ scrollViewID: ID) -> Bool {
        apply { child in
            child.containsScrollable(scrollViewID)
        }
    }
        
    @inlinable
    internal func scroll<ID: Hashable>(_ scrollViewID: ID, to offset: CGPoint) -> Bool {
        apply { child in
            child.scroll(scrollViewID, to: offset)
        }
    }
    
    @inlinable
    internal func getScrollable<ID: Hashable>(of scrollViewID: ID) -> Scrollable? {
        apply { child in
            child.getScrollable(of: scrollViewID)
        }
    }
    
}
