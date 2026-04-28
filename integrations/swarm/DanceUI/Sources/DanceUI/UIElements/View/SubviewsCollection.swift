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

/// An opaque collection representing the subviews of view.
///
/// Subviews collection constructs subviews on demand, so only access the part
/// of the collection you need to create the resulting content.
///
/// You can get access to a view's subview collection by using the
/// ``Group/init(sectionsOf:transform:)`` initializer.
///
/// The collection's elements are the pieces that make up the given view, and
/// the collection as a whole acts as a proxy for the original view.
@available(iOS 13.0, *)
public struct SubviewsCollection: RandomAccessCollection {
    
    internal var base: _VariadicView_Children
    
    public func index(before i: Int) -> Int {
        base.index(before: i)
    }
    
    public func index(after i: Int) -> Int {
        base.index(after: i)
    }
    
    public subscript(index: Int) -> Subview {
        Subview(base: base[index])
    }
    
    public subscript(bounds: Range<Int>) -> SubviewsCollectionSlice {
        let subViewList = base[bounds].base
        let slice = Slice<SubviewsCollection>(base: SubviewsCollection(base: subViewList), bounds: bounds)
        return SubviewsCollectionSlice(base: slice)
    }
    
    public var startIndex: Int {
        base.startIndex
    }
    
    public var endIndex: Int {
        base.endIndex
    }
    
    public typealias Element = Subview
    
    public typealias Index = Int
    
    public typealias Indices = Range<Int>
    
    public typealias Iterator = IndexingIterator<SubviewsCollection>
    
    public typealias SubSequence = SubviewsCollectionSlice
}

@available(iOS 13.0, *)
extension SubviewsCollection: PrimitiveView, MultiView {
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let children = view[{.of(&$0.base)}]
        return _VariadicView_Children._makeViewList(view: children, inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        _VariadicView_Children._viewListCount(inputs: inputs)
    }
}
