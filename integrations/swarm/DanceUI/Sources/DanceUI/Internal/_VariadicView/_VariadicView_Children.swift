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
public struct _VariadicView_Children : RandomAccessCollection, PrimitiveView, MultiView {

    public typealias Index = Int

    public typealias SubSequence = Slice<_VariadicView_Children>

    public typealias Iterator = IndexingIterator<_VariadicView_Children>

    public typealias Indices = Range<Int>

    internal var list: ViewList

    internal var contentSubgraph: DGSubgraphRef

    internal var transform: _ViewList_SublistTransform

    internal init(list: ViewList, contentSubgraph: DGSubgraphRef, transform: _ViewList_SublistTransform) {
        self.list = list
        self.contentSubgraph = contentSubgraph
        self.transform = transform
    }

    public subscript(index: Int) -> Element {
        var element: Element?
        var transformValue = self.transform
        Update.ensure {
            var i = index
            _ = list.applySublists(from: &i, style: .default, list: nil, transform: &transformValue) { sublist in
                guard sublist.start < sublist.count else {
                    return true
                }
                let view = _ViewList_View(elements: sublist.elements, id: sublist.id, index: sublist.start, count: sublist.count, contentSubgraph: contentSubgraph)
                element = Element(view: view, traits: sublist.traits)
                return false
            }
        }
        return element!
    }

    public var startIndex: Int { 0 }

    public var endIndex: Int {
        list.count
    }

    public func tagIndex<A: Hashable>(tag: Binding<A>) -> Binding<Int?> {
        tag.projecting(TagIndexProjection<A>(list: list))
    }

    public static func _makeViewList(view: _GraphValue<_VariadicView_Children>, inputs: _ViewListInputs) -> _ViewListOutputs {
        Child.Value._makeViewList(view: _GraphValue(Child(children: view.value)), inputs: inputs)
    }

    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        nil
    }

    public struct Element : Identifiable, UnaryView, PrimitiveView {

        public typealias ID = AnyHashable

        internal var view: _ViewList_View

        internal var traits: ViewTraitCollection

        public var id: AnyHashable {
            view.viewID
        }

        internal func tag<A: Hashable>(for type: A.Type) -> A? {
            traits.tagValue(for: type)
        }

        internal subscript<A: _ViewTraitKey>(_ type: A.Type) -> A.Value {
            get {
                traits[type]
            }
            set {
                traits[type] = newValue
            }
        }

        public static func _makeView(view: _GraphValue<_VariadicView_Children.Element>, inputs: _ViewInputs) -> _ViewOutputs {
            _ViewList_View._makeView(view: view[ {.of(&$0.view)} ], inputs: inputs)
        }
    }

    fileprivate struct Child : Rule {

        fileprivate typealias Value = ForEach<_VariadicView_Children, AnyHashable, Element>

        @Attribute
        fileprivate var children: _VariadicView_Children

        fileprivate var value: Value {
            ForEach(children) { $0 }
        }
    }
}

@available(iOS 13.0, *)
private final class TagIndexProjection<A : Hashable> : Projection {

    fileprivate typealias Base = A

    fileprivate typealias Projected = Int?

    fileprivate let list: ViewList

    fileprivate var nextIndex: Int? = 0

    fileprivate var indexMap: Dictionary<Int, A> = [:]

    fileprivate var tagMap: Dictionary<A, Int> = [:]

    fileprivate init(list: ViewList) {
        self.list = list
    }

    fileprivate func readUntil(matcher: (Int, A) -> Bool) {
        guard var nextIndex = nextIndex else {
            return
        }
        var next = nextIndex
        if list.applySublists(from: &nextIndex, list: nil, to: { subList in
            var result = true

            next -= subList.start

            let value = subList.traits[TagValueTraitKey<A>.self]
            if case let .tagged(tag) = value,
               !subList.traits.value(for: IsAuxiliaryContentTraitKey.self, defaultValue: false) {
                var count = subList.count
                var startIndex = next
                tagMap[tag] = startIndex
                while count != 0 {
                    indexMap[startIndex] = tag
                    startIndex += 1
                    count -= 1
                }
                result = !matcher(next, tag)
            }
            next += subList.count
            self.nextIndex = next
            return result
        }) {
            self.nextIndex = nil
        }
    }

    fileprivate var startIndex: Int {
        0
    }

    fileprivate var endIndex: Int {
        self.list.count
    }

    fileprivate func get(base: A) -> Int? {
        var tagIndex = tagMap[base]
        if tagIndex == nil {
            readUntil { index, hashValue in
                let result = hashValue == base
                if result {
                    tagIndex = index
                }
                return result
            }
        }
        return tagIndex
    }

    fileprivate func set(base: inout A, newValue: Int?) {
        guard let newValue = newValue else {
            return
        }
        if let tag = indexMap[newValue] {
            base = tag
        } else {
            readUntil { index, hashValue in
                let result = newValue == index
                if result {
                    base = hashValue
                }
                return result
            }
        }
    }

    fileprivate func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    fileprivate var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }

    fileprivate static func == (lhs: TagIndexProjection<A>, rhs: TagIndexProjection<A>) -> Bool {
        lhs === rhs
    }
}
