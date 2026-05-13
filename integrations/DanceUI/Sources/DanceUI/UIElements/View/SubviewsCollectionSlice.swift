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

@available(iOS 13.0, *)
public struct SubviewsCollectionSlice: RandomAccessCollection {
    
    internal var base: Slice<SubviewsCollection>
    
    public subscript(index: Int) -> Subview {
        base[index]
    }
    
    public subscript(bounds: Range<Int>) -> SubviewsCollectionSlice {
        let subViewList = base[bounds].base
        let slice = Slice<SubviewsCollection>(base: subViewList, bounds: bounds)
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
    
    public typealias Iterator = IndexingIterator<SubviewsCollectionSlice>
    
    public typealias SubSequence = SubviewsCollectionSlice
}

@available(iOS 13.0, *)
extension SubviewsCollectionSlice: PrimitiveView, MultiView {
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        let children = view[{.of(&$0.base)}]
        let sliceAttribute = children.value
        let childrenAttribute = Attribute(Child(slice: sliceAttribute))
        return ForEach._makeViewList(view: _GraphValue(childrenAttribute), inputs: inputs)
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        ForEach<Slice<SubviewsCollection>, Subview.ID, Subview>._viewListCount(inputs: inputs)
    }
    
    private struct Child: Rule {
        @Attribute
        fileprivate var slice: Slice<SubviewsCollection>
        
        fileprivate init(slice: Attribute<Slice<SubviewsCollection>>) {
            self._slice = slice
        }
        
        fileprivate var value: ForEach<Slice<SubviewsCollection>, Subview.ID, Subview> {
            let items = self.slice
            return ForEach<Slice<SubviewsCollection>, Subview.ID, Subview>(items) { item in
                Subview(base: item.base)
            }
        }
    }
}
