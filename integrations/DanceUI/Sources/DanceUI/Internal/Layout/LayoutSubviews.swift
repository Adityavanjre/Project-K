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

/// A collection of proxy values that represent the subviews of a layout view.
///
/// You receive a `LayoutSubviews` input to your implementations of
/// ``Layout`` protocol methods, like
/// ``Layout/placeSubviews(in:proposal:subviews:cache:)`` and
/// ``Layout/sizeThatFits(proposal:subviews:cache:)``. The `subviews`
/// parameter (which the protocol aliases to the ``Layout/Subviews`` type)
/// is a collection that contains proxies for the layout's subviews (of type
/// ``LayoutSubview``). The proxies appear in the collection in the same
/// order that they appear in the ``ViewBuilder`` input to the layout
/// container. Use the proxies to perform layout operations.
///
/// Access the proxies in the collection as you would the contents of any
/// Swift random-access collection. For example, you can enumerate all of the
/// subviews and their indices to inspect or operate on them:
///
///     for (index, subview) in subviews.enumerated() {
///         // ...
///     }
///
@available(iOS 13.0, *)
public struct LayoutSubviews: Equatable, RandomAccessCollection {
    
    /// A type that contains a proxy value.
    public typealias Element = LayoutSubview
    
    /// A type that you can use to index proxy values.
    public typealias Index = Int
    
    /// A type that contains a subsequence of proxy values.
    public typealias SubSequence = LayoutSubviews
    
    /// A type that represents the indices that are valid for subscripting the
    /// collection, in ascending order.
    public typealias Indices = Range<Index>
    
    /// A type that provides the collection's iteration interface and
    /// encapsulates its iteration state.
    ///
    /// By default, a collection conforms to the `Sequence` protocol by
    /// supplying `IndexingIterator` as its associated `Iterator`
    /// type.
    public typealias Iterator = IndexingIterator<LayoutSubviews>
    
    /// The layout direction inherited by the container view.
    ///
    /// DanceUI supports both left-to-right and right-to-left directions.
    /// Read this property within a custom layout container
    /// to find out which environment the container is in.
    ///
    /// In most cases, you don't need to take any action based on this
    /// value. DanceUI horizontally flips the x position of each view within its
    /// parent when the mode switches, so layout calculations automatically
    /// produce the desired effect for both directions.
    public var layoutDirection: LayoutDirection
    
    private var storage: LayoutSubviews.Storage
    
    internal var context: AnyRuleContext
    
    /// The index of the first subview.
    public var startIndex: Int {
        0
    }
    
    /// An index that's one higher than the last subview.
    public var endIndex: Int {
        storage.count
    }
    
    /// Gets the subview proxy at a specified index.
    public subscript(position: Int) -> LayoutSubview {
        let info = storage[position]
        return LayoutSubview(proxy: LayoutProxy(context: context,
                                                attributes: info.attribute),
                             index: info.index)
    }
    
    /// Gets the subview proxies in the specified range.
    public subscript(bounds: Range<Int>) -> LayoutSubviews {
        LayoutSubviews(layoutDirection: layoutDirection,
                       storage: storage[bounds],
                       context: context)
    }
    
    /// Gets the subview proxies with the specified indicies.
    public subscript<S>(indices: S) -> LayoutSubviews where S : Sequence, S.Element == Int {
        LayoutSubviews(layoutDirection: layoutDirection,
                       storage: storage[indices],
                       context: context)
    }
    
    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (lhs: LayoutSubviews, rhs: LayoutSubviews) -> Bool {
        lhs.layoutDirection == rhs.layoutDirection &&
        lhs.storage == rhs.storage &&
        lhs.context.attribute.rawValue == rhs.context.attribute.rawValue
    }
    
    internal struct LayoutProxyInfo {
        internal let attribute: LayoutProxyAttributes
        internal let index: Int32
    }
    
    internal enum Storage: Equatable {
        
        case direct([LayoutProxyAttributes])
        
        case indirect([IndexedAttributes])
        
        var count: Int {
            switch self {
            case .direct(let attributes):
                return attributes.count
            case .indirect(let indexs):
                return indexs.count
            }
        }
        
        subscript(index: Int) -> LayoutProxyInfo {
            switch self {
            case .direct(let attributes):
                return LayoutProxyInfo(attribute: attributes[index],
                                       index: numericCast(index))
            case .indirect(let indexs):
                return LayoutProxyInfo(attribute: indexs[index].attributes,
                                       index: indexs[index].index)
            }
        }
        
        public subscript(bounds: Range<Int>) -> Storage {
            switch self {
            case .direct(let attributes):
                return .indirect(bounds.map({.init(attributes: attributes[$0], index: numericCast($0))}))
            case .indirect(let indexs):
                return .indirect(bounds.map({ indexs[$0] }))
            }
        }
        
        public subscript<S>(indices: S) -> Storage where S : Sequence, S.Element == Int {
            switch self {
            case .direct(let attributes):
                return .indirect(indices.map({.init(attributes: attributes[$0], index: numericCast($0))}))
            case .indirect(let indexs):
                return .indirect(indices.map({ indexs[$0] }))
            }
        }
        
        struct IndexedAttributes: Equatable {
            
            var attributes : LayoutProxyAttributes
            
            var index : Int32
            
            
        }
    }
    
    internal init(layoutDirection: LayoutDirection,
                  storage: LayoutSubviews.Storage,
                  context: AnyRuleContext) {
        self.layoutDirection = layoutDirection
        self.storage = storage
        self.context = context
    }
    
}
