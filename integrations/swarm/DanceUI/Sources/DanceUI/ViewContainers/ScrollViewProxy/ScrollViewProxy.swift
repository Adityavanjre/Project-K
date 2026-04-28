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

internal import DanceUIGraph

/// A proxy value that supports programmatic scrolling of the scrollable
/// views within a view hierarchy.
///
/// You don't create instances of `ScrollViewProxy` directly. Instead, your
/// ``ScrollViewReader`` receives an instance of `ScrollViewProxy` in its
/// `content` view builder. You use actions within this view builder, such
/// as button and gesture handlers or the ``View/onChange(of:perform:)``
/// method, to call the proxy's ``ScrollViewProxy/scrollTo(_:anchor:)`` method.
@available(iOS 13.0, *)
public struct ScrollViewProxy {

    @WeakAttribute
    private var values: [Scrollable]?
    
    internal init(values: WeakAttribute<[Scrollable]>) {
        self._values = values
    }
    
    /// Scans all scroll views contained by the proxy for the first
    /// with a child view with identifier `id`, and then scrolls to
    /// that view.
    ///
    /// If `anchor` is `nil`, this method finds the container of the identified
    /// view, and scrolls the minimum amount to make the identified view
    /// wholly visible.
    ///
    /// If `anchor` is non-`nil`, it defines the points in the identified
    /// view and the scroll view to align. For example, setting `anchor` to
    /// ``UnitPoint/top`` aligns the top of the identified view to the top of
    /// the scroll view. Similarly, setting `anchor` to ``UnitPoint/bottom``
    /// aligns the bottom of the identified view to the bottom of the scroll
    /// view, and so on.
    ///
    /// - Parameters:
    ///   - id: The identifier of a child view to scroll to.
    ///   - anchor: The alignment behavior of the scroll action.
    public func scrollTo<ID: Hashable>(_ id: ID, anchor: UnitPoint? = nil) {
        _danceuiPrecondition(!GraphHost.isUpdating)
        DGGraphRef.withoutUpdate {
            apply { scrollable in
                scrollable.scroll(to: id, anchor: anchor)
            }
        }
    }
    
    /// Scroll to the specified position.
    ///
    /// If Reader has mutiple scrollViews, the call will only scroll the first
    /// one.
    ///
    /// - Parameter contentOffset: The distance that the content is offset from
    ///             the browser’s origin.
    public func scrollTo(_ contentOffset: CGPoint) {
        _danceuiPrecondition(!GraphHost.isUpdating)
        DGGraphRef.withoutUpdate {
            apply { scrollable in
                scrollable.scroll(to: contentOffset)
            }
        }
    }
    
    /// Get the `contentOffset` property of first scroll view in view hierarchy.
    public var contentOffset: CGPoint {
        scrollViewProperty {
            $0.contentOffset
        } ?? .zero
    }
    
    /// Get the `contentSize` property of first scroll view in view hierarchy.
    @inline(__always)
    public var contentSize: CGSize {
        scrollViewProperty {
            $0.contentSize
        } ?? .zero
    }
    
    /// Get the `adjustedContentInset` property of first scroll view in view
    /// hierarchy.
    @inline(__always)
    public var adjustedContentInset: UIEdgeInsets {
        scrollViewProperty {
            $0.adjustedContentInset
        } ?? .zero
    }
    
    /// Get the `isDragging` property of first scroll view in view hierarchy.
    @inline(__always)
    public var isDragging: Bool {
        scrollViewProperty {
            $0.isDragging
        } ?? false
    }
    
    /// Created an isolate scroll view proxy use specific identifier. If view
    /// hierarchy do not contains this scroll view, it will return `nil`
    ///
    /// - Parameter: scrollViewID: The scrollView identifier
    @inlinable
    public subscript<ID: Hashable>(scrollViewID: ID) -> Isolated<ID>? {
        Isolated(scrollViewID: scrollViewID, parent: self)
    }

    internal func scrollTo(rect: CGRect, anchor: UnitPoint?) {
        _danceuiPrecondition(!GraphHost.isUpdating)
        DGGraphRef.withoutUpdate {
            apply {
                $0.setContentOffset { contentSize, bounds in
                    ScrollViewUtilities.animationOffset(for: rect, anchor: anchor, bounds: bounds, contentSize: contentSize)
                }
            }
        }
    }

    internal func setContentOffset(_ contentOffset: CGPoint) {
        _danceuiPrecondition(!GraphHost.isUpdating)
        
        func target(contentSize: CGSize, bounds: CGRect) -> CGPoint? {
            contentOffset
        }
        
        DGGraphRef.withoutUpdate {
            apply {
                $0.setContentOffset(target: target)
            }
        }
    }

    private func apply(to scroll: (_ scrollable: Scrollable) -> Bool) {
        guard let values = values else {
            return
        }

        for eachScrollable in values {
            if scroll(eachScrollable) {
                return
            }
        }
    }
    
    /// DanceUI Extension
    private func apply<T>(to body: (Scrollable) -> (T?)) -> T? {
        guard let values = values else {
            return nil
        }
        
        for scrollable in values {
            if let result = body(scrollable) {
                return result
            }
        }

        return nil
    }
    
    /// DanceUI Extension
    private func scrollViewProperty<T>(_ propertyGetter: (Scrollable) -> T?) -> T? {
        DGGraphRef.withoutUpdate {
            guard let result = apply(to: propertyGetter) else {
                runtimeIssue(type: .warning, "Cannot find the correct ScrollView. Only actions created within `ScrollViewReader.content` can call the proxy.")
                return nil
            }
            return result
        }
    }
    
    /// A Isolated type `ScrollViewProxy`. It will operate one and only one
    /// scrollable view.
    ///
    /// **DanceUI Extension.**
    ///
    /// A proxy value that supports programmatic operation of the scrollable
    /// view within a view hierarchy.
    ///
    /// You don't create instances of ``ScrollViewProxy/Isolated`` directly.
    /// Instead, your ``ScrollViewReader`` receives an instance of
    /// `ScrollViewProxy` in its `content` view builder, Then use
    /// ``ScrollViewProxy/subscript(scrollViewID:)`` to created an instance.
    public struct Isolated<ID: Hashable> {

        @WeakAttribute
        private var scrollables: [Scrollable]?
        
        private let scrollViewID: ID
        
        @MutableBox
        private var cachedIndex: Int?
        
        /// For DanceUI Extension only.
        ///
        /// > Important: Do not use this API to create instances directly.
        @inline(__always)
        public init?(scrollViewID: ID, parent: ScrollViewProxy) {
            guard let values = parent.values else {
                return nil
            }
            guard let index = values.firstIndex(where: { $0.containsScrollable(scrollViewID)}) else {
                return nil
            }
            
            self.init(scrollables: parent._values, scrollViewID: scrollViewID, index: index)
        }
        
        @inline(__always)
        internal init(scrollables: WeakAttribute<[Scrollable]>, scrollViewID: ID, index: Int) {
            self._scrollables = scrollables
            self.scrollViewID = scrollViewID
            self._cachedIndex = MutableBox(index)
        }
        
        /// Get the `contentOffset` property of scroll view.
        public var contentOffset: CGPoint {
            scrollViewProperty {
                $0.contentOffset
            } ?? .zero
        }
        
        /// Get the `contentSize` property of scroll view.
        public var contentSize: CGSize {
            scrollViewProperty {
                $0.contentSize
            } ?? .zero
        }
        
        /// Get the `adjustedContentInset` property of scroll view.
        /// hierarchy.
        @inline(__always)
        public var adjustedContentInset: UIEdgeInsets {
            scrollViewProperty {
                $0.adjustedContentInset
            } ?? .zero
        }
        
        /// Get the `isDragging` property of scroll view.
        @inline(__always)
        public var isDragging: Bool {
            scrollViewProperty {
                $0.isDragging
            } ?? false
        }
        
        
        /// Scans a child view with identifier `id`, and then scrolls to that view.
        ///
        /// If `anchor` is `nil`, this method finds the container of the identified
        /// view, and scrolls the minimum amount to make the identified view
        /// wholly visible.
        ///
        /// If `anchor` is non-`nil`, it defines the points in the identified
        /// view and the scroll view to align. For example, setting `anchor` to
        /// ``UnitPoint/top`` aligns the top of the identified view to the top of
        /// the scroll view. Similarly, setting `anchor` to ``UnitPoint/bottom``
        /// aligns the bottom of the identified view to the bottom of the scroll
        /// view, and so on.
        ///
        /// - Parameters:
        ///   - id: The identifier of a child view to scroll to.
        ///   - anchor: The alignment behavior of the scroll action.
        public func scrollTo<TargetID: Hashable>(_ id: TargetID, anchor: UnitPoint? = nil) {
            _danceuiPrecondition(!GraphHost.isUpdating)
            return DGGraphRef.withoutUpdate {
                guard let scrollable = scrollable?.getScrollable(of: scrollViewID) else {
                    return
                }
                _ = scrollable.scroll(to: id, anchor: anchor)
            }
        }
        
        /// Scroll to the specified position.
        ///
        /// - Parameter contentOffset: The distance that the content is offset from
        ///             the browser’s origin.
        @inline(__always)
        public func scrollTo(_ contentOffset: CGPoint) {
            _danceuiPrecondition(!GraphHost.isUpdating)
            return DGGraphRef.withoutUpdate {
                guard let scrollable = scrollable?.getScrollable(of: scrollViewID) else {
                    return
                }
                _ = scrollable.scroll(scrollViewID, to: contentOffset)
            }
        }
        
        private var scrollable: Scrollable? {
            guard let scrollablesAtt = $scrollables else {
                return nil
            }
            let (scrollable, scrollableChanged) = scrollablesAtt.changedValue()
            if !scrollableChanged, let offset = cachedIndex {
                return scrollable[offset]
            }
            guard let index = scrollable.firstIndex(where: { $0.containsScrollable(scrollViewID)}) else {
                cachedIndex = nil
                return nil
            }
            
            cachedIndex = index
            return scrollable[index]
        }
        
        private func scrollViewProperty<T>(_ propertyGetter: (Scrollable) -> T?) -> T? {
            DGGraphRef.withoutUpdate {
                guard let scrollable = scrollable?.getScrollable(of: scrollViewID) else {
                    runtimeIssue(type: .warning, "Cannot find the correct ScrollView: %@. Please check id or Only actions created within `ScrollViewReader.content` can call the proxy.", "\(scrollViewID)")
                    return nil
                }
                return propertyGetter(scrollable)
            }
        }
        
    }

}
