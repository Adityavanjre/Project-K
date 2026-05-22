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
internal import DanceUIGraph

/// A type-erased view.
///
/// An `AnyView` allows changing the type of view used in a given view
/// hierarchy. Whenever the type of view used with an `AnyView` changes, the old
/// hierarchy is destroyed and a new hierarchy is created for the new type.
@frozen
@available(iOS 13.0, *)
public struct AnyView: PrimitiveView {
    
    internal let storage: AnyViewStorageBase
    
    /// Create an instance that type-erases `view`.
    public init<V: View>(_ view: V) {
        self.init(view, id: nil)
    }
    
    @inlinable
    public init<V: View>(erasing view: V) {
        self.init(view)
    }
    
    internal init<V: View>(_ view: V, id: UniqueID?) {
        if let view = view as? AnyView {
            storage = view.storage
        } else {
            storage = AnyViewStorage(view: view, id: id)
        }
    }
    
    /// DanceUI extension
    /// This init is used a ViewBuilder to build a AnyView
    /// Apply origin init `init?(_fromValue:)` always return nil
    /// - Parameter content: View builder
    @inlinable
    public init<Content: View>(@ViewBuilder content: () -> Content) {
        let view = content()
        self.init(view)
    }
    
    public init?(_fromValue value: Any) {
        
        struct Visitor: ViewTypeVisitor {
            
            internal var value: Any

            internal var view: AnyView?
            
            internal mutating func visit<ViewType: View>(type: ViewType.Type) {
                view = AnyView(value as! ViewType)
            }
        }
        guard let viewConformance = TypeConformance<ViewDescriptor>(type(of: value)) else {
            return nil
        }
        var visitor = Visitor(value: value)
        viewConformance.visitType(visitor: &visitor)
        self = visitor.view!
    }
    
    public static func _makeView(view: _GraphValue<AnyView>, inputs: _ViewInputs) -> _ViewOutputs {
        
        let outputs = inputs.makeIndirectOutputs()
        let subgraph = DGSubgraphRef.current!
        
        let container = AnyViewContainer(view: view.value, inputs: inputs, outputs: outputs, parentSubgraph: subgraph)
        let containerAttribute = Attribute(container)
        
        outputs.preferences.forEach { keyType, attribute in
            attribute.indirectDependency = containerAttribute.identifier
        }
        
        outputs.layout.attribute?.identifier.indirectDependency = containerAttribute.identifier
        return outputs
    }
    
    public static func _makeViewList(view: _GraphValue<AnyView>, inputs: _ViewListInputs) -> _ViewListOutputs {
         
        
        let viewList = AnyViewList(view: view.value, inputs: inputs, parentSubgraph: .current!, allItems: MutableBox([]), lastItem: nil)
        let viewListAttribute = Attribute(viewList)

        return _ViewListOutputs(views: .dynamicList(viewListAttribute, nil), nextImplicitID: inputs.implicitID, staticCount: nil)
    }

    internal func visitContent<V: ViewVisitor>(_ visitor: inout V) {
        storage.visitContent(&visitor)
    }
}

@available(iOS 13.0, *)
extension View {
    
    @inline(__always)
    public func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
    
}

@available(iOS 13.0, *)
extension AnyView {
    
    @inline(__always)
    public func eraseToAnyView() -> AnyView {
        self
    }
    
}

@available(iOS 13.0, *)
fileprivate struct AnyViewInfo {

    fileprivate var item: AnyViewStorageBase

    fileprivate var subgraph: DGSubgraphRef

    fileprivate var uniqueId: UInt32

}

@available(iOS 13.0, *)
fileprivate struct AnyViewContainer: StatefulRule {
    
    internal typealias Value = AnyViewInfo
    
    @Attribute
    internal var view: AnyView
    
    internal let inputs: _ViewInputs

    internal let outputs: _ViewOutputs

    internal let parentSubgraph: DGSubgraphRef
    
    internal mutating func updateValue() {
        let view = self.view
        
        var uniqueId: UInt32 = 0
        
        let newValue: Value
        defer {
            value = newValue
        }
        
        if let oldInfo = optionalValue {
            guard !oldInfo.item.matches(view.storage) else {
                newValue = AnyViewInfo(item: view.storage,
                                       subgraph: oldInfo.subgraph,
                                       uniqueId: oldInfo.uniqueId)
                return
            }
            eraseItem(info: oldInfo)
            uniqueId = oldInfo.uniqueId &+ 1
        }
        
        newValue = makeItem(view.storage, uniqueId: uniqueId)
    }
    
    internal func makeItem(_ storage: AnyViewStorageBase, uniqueId: UInt32) -> AnyViewInfo {
        let currentAttribute = DGAttribute.current!
        let child = DGSubgraphCreate(parentSubgraph.graph)
        parentSubgraph.add(child: child)
        
        return child.apply {
            let newInputs = _ViewInputs(deepCopy: inputs)
            let newOutput = storage.makeChild(
                uniqueId: uniqueId,
                container: Attribute(identifier: currentAttribute),
                inputs: newInputs
            )
            outputs.attachIndirectOutputs(to: newOutput)
            
            return AnyViewInfo(item: storage, subgraph: child, uniqueId: uniqueId)
        }
        
    }

    internal func eraseItem(info: AnyViewInfo) {
        outputs.detachIndirectOutputs()
        let subgraph = info.subgraph
        subgraph.willInvalidate(isInserted: true)
        subgraph.invalidate()
    }
    
}

@usableFromInline
@available(iOS 13.0, *)
internal class AnyViewStorageBase {

    internal let id: UniqueID?
    
    deinit {
        _intentionallyLeftBlank()
    }
    
    internal init(id: UniqueID?) {
        self.id = id
    }
    
    internal var type: Any.Type {
        _abstract(self)
    }
    
    fileprivate var canTransition: Bool {
        _abstract(self)
    }
    
    fileprivate func matches(_ storage: AnyViewStorageBase) -> Bool {
        _abstract(self)
    }
    
    fileprivate func makeChild(uniqueId: UInt32, container: Attribute<AnyViewInfo>, inputs: _ViewInputs) -> _ViewOutputs {
        _abstract(self)
    }
    
    internal func child<A>() -> A {
        _abstract(self)
    }
    
    fileprivate func makeViewList(view: _GraphValue<AnyView>, inputs: _ViewListInputs) -> _ViewListOutputs {
        _abstract(self)
    }
    
    fileprivate func visitContent<A: ViewVisitor>(_ visitor: inout A) {
        _abstract(self)
    }
    
}

@available(iOS 13.0, *)
private final class AnyViewStorage<V: View>: AnyViewStorageBase {

    internal let view: V
    
    deinit {
        _intentionallyLeftBlank()
    }
    
    internal init(view: V, id: UniqueID?) {
        self.view = view
        super.init(id: id)
    }
    
    internal override var type: Any.Type {
        V.self
    }
    
    internal override var canTransition: Bool {
        id != nil
    }
    
    internal override func makeChild(uniqueId: UInt32, container: Attribute<AnyViewInfo>, inputs: _ViewInputs) -> _ViewOutputs {
        
        let child = AnyViewChild<V>(info: container, uniqueId: uniqueId)
        let childAttribute = Attribute(child)
        let graphValue = _GraphValue(childAttribute)
        
        return V.makeDebuggableView(value: graphValue, inputs: inputs)
    }
    
    internal override func child<A>() -> A {
        view as! A
    }

    internal override func makeViewList(view: _GraphValue<AnyView>, inputs: _ViewListInputs) -> _ViewListOutputs {
        
        let childList = AnyViewChildList<V>(view: view.value, id: id)
        
        let childListAttribute = Attribute(childList)
        _ = childListAttribute.setValue(self.view)

        return V._makeViewList(view: _GraphValue(childListAttribute), inputs: inputs)
    }
    
    internal override func matches(_ storage: AnyViewStorageBase) -> Bool {
        storage is AnyViewStorage<V>
    }
    
    internal override func visitContent<Visitor: ViewVisitor>(_ visitor: inout Visitor) {
        visitor.visit(view)
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyViewChild<Value>: StatefulRule, CustomStringConvertible {

    @Attribute
    internal var info: AnyViewInfo

    internal let uniqueId: UInt32
    
    internal mutating func updateValue() {
        let info = self.info
        guard info.uniqueId == uniqueId else {
            return
        }
        value = info.item.child()
    }
    
    internal var description: String {
        "\(Value.self)"
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyViewList: StatefulRule {

    internal typealias Value = ViewList

    @Attribute
    private var view: AnyView

    private let inputs: _ViewListInputs

    private let parentSubgraph: DGSubgraphRef

    private let allItems: MutableBox<[Unmanaged<Item>]>

    private var lastItem: Item?
    
    internal init(view: Attribute<AnyView>, inputs: _ViewListInputs, parentSubgraph: DGSubgraphRef, allItems: MutableBox<[Unmanaged<Item>]>, lastItem: AnyViewList.Item? = nil) {
        self._view = view
        self.inputs = inputs
        self.parentSubgraph = parentSubgraph
        self.allItems = allItems
        self.lastItem = lastItem
    }

    internal mutating func updateValue() {
        let view = self.view
        let lastItemID = lastItem?.id
        let viewType = view.storage.type
        
        guard parentSubgraph.isValid else { //BDCOV_EXCL_BLOCK 抖动
            value = EmptyViewList()
            return
        }
        
        if let lastItem = lastItem {
            var shouldReleaseLastItem = false
            if viewType != lastItem.type {
                shouldReleaseLastItem = true
            } else if let viewId = view.storage.id, viewId != lastItem.id {
                shouldReleaseLastItem = true
            } else if !lastItem.isValid {
                shouldReleaseLastItem = true
            }
            
            if shouldReleaseLastItem {
                lastItem.release(isInserted: true)
                self.lastItem = nil
            }
        }
        
        if let lastItem {
            setValue(for: lastItem, id: lastItemID)
            return
        }
        
        for value in allItems.value {
            let item = value.takeUnretainedValue()
            if item.type != view.storage.type || view.storage.id != item.id ||
                !item.isValid {
                continue
            }
            item.retain()
            lastItem = item
            break
        }
        
        if let lastItem {
            setValue(for: lastItem, id: lastItemID)
            return
        }
        
        guard parentSubgraph.isValid else {
            value = EmptyViewList()
            return
        }
        
        let child = DGSubgraphCreate(parentSubgraph.graph)
        parentSubgraph.add(child: child)
        let (listAttribute, isUnary) = child.apply { () -> (Attribute<ViewList>, Bool) in
            
            var newInputs = inputs
            newInputs.implicitID = 0
            newInputs.needTransition = newInputs.needTransition || view.storage.canTransition
            
            let output = view.storage.makeViewList(view: _GraphValue($view), inputs: newInputs)
            
            let attribute = output.makeAttribute(inputs: newInputs)
            
            return (attribute, output.staticCount == 0x1)
        }
        
        let currentAttribute = context.attribute
        
        let id = view.storage.id ?? UniqueID()
        
        let item = Item(type: view.storage.type,
                        owner: currentAttribute.identifier,
                        list: listAttribute,
                        id: id,
                        isUnary: isUnary,
                        subgraph: child,
                        allItems: allItems)
        lastItem = item
        setValue(for: item, id: lastItemID)

    }
    
    private mutating func setValue(for item: AnyViewList.Item, id: UniqueID?) {
        value = WrappedList(
            base: item.list,
            item: item,
            lastID: id,
            lastTransaction: TransactionID(context: context)
        )
    }

    internal struct WrappedList: ViewList {

        internal let base: ViewList

        internal let item: Item
        
        internal let lastID: UniqueID?

        internal let lastTransaction: TransactionID

        internal var traitKeys: ViewTraitKeys? {
            var traitKeys = base.traitKeys
            traitKeys?.isDataDependent = true
            return traitKeys
        }

        internal var traits: ViewTraitCollection {
            base.traits
        }
        
        internal var viewIDs: _ViewList_ID.Views? {
            guard let id = base.viewIDs else {
                return nil
            }
            
            return _ViewList_ID._Views(WrappedIDs(base: id, item: item), isDataDependent: true)
        }
        
        internal func applyNodes(from index: inout Int, style: _ViewList_IteratorStyle, list: _GraphValue<ViewList>?, transform: inout _ViewList_SublistTransform, to body: (inout Int, _ViewList_IteratorStyle, _ViewList_Node, inout _ViewList_SublistTransform) -> Bool) -> Bool {
            transform.push(Transform(item: item))
            defer {
                transform.pop()
            }
            return base.applyNodes(from: &index, style: style, list: list, transform: &transform, to: body)
        }

        internal func count(style: _ViewList_IteratorStyle) -> Int {
            base.count(style: style)
        }

        internal func edit(forID id: _ViewList_ID, since transaction: TransactionID) -> _ViewList_Edit? {
            if lastTransaction <= transaction, let lastID = lastID, lastID != item.id, let explicitID: UniqueID? = id.explicitID(owner: item.owner) {
                if explicitID == lastID {
                    return .removed
                } else if explicitID == item.id {
                    return .inserted
                }
            }
            return base.edit(forID: id, since: transaction)
        }

        internal func estimatedCount(style: _ViewList_IteratorStyle) -> Int {
            base.estimatedCount(style: style)
        }

        internal func firstOffset<A: Hashable>(forID id: A, style: _ViewList_IteratorStyle) -> Int? {
            base.firstOffset(forID: id, style: style)
        }

    }

    internal struct Transform: _ViewList_SublistTransform_Item {

        internal var item: Item
        
        internal func apply(sublist: inout _ViewList_Sublist) {
            item.bindID(&sublist.id)
            sublist.elements = item.wrapping(sublist.elements)
        }

    }

    internal struct WrappedIDs: RandomAccessCollection, Equatable {

        internal typealias Element = _ViewList_ID

        internal typealias Iterator = IndexingIterator<Self>

        internal typealias Index = Int

        internal typealias SubSequence = Slice<Self>

        internal typealias Indices = Range<Int>

        internal let base: _ViewList_ID.Views

        internal let item: Item
        
        internal var startIndex: Int {
            0
        }

        internal var endIndex: Int {
            base.endIndex
        }

        internal subscript(position: Int) -> _ViewList_ID {
            var element = base[position]
            item.bindID(&element)
            return element
        }

        internal static func == (lhs: Self, rhs: Self) -> Bool {
            guard lhs.item === rhs.item else {
                return false
            }
            
            return lhs.base.isEqual(to: rhs.base)
        }

    }


    internal final class Item: _ViewList_Subgraph {

        internal let type: Any.Type

        internal let owner: DGAttribute

        @Attribute
        internal var list: ViewList

        internal let id: UniqueID

        internal let isUnary: Bool

        internal let allItems: MutableBox<[Unmanaged<Item>]>
        
        internal let cachedHashedId: AnyHashable

        deinit {
            _intentionallyLeftBlank()
        }

        internal init(type: Any.Type,
                      owner: DGAttribute,
                      list: Attribute<ViewList>,
                      id: UniqueID,
                      isUnary: Bool,
                      subgraph: DGSubgraphRef,
                      allItems: MutableBox<[Unmanaged<AnyViewList.Item>]>) {
            self.type = type
            self.owner = owner
            self._list = list
            self.id = id
            self.isUnary = isUnary
            self.allItems = allItems
            self.cachedHashedId = AnyHashable(id)
            super.init(subgraph: subgraph)
            
            self.allItems.value.append(.passUnretained(self))
        }

        internal func bindID(_ id: inout _ViewList_ID) {
            id.bind(id: cachedHashedId, owner: owner, isUnary: isUnary)
        }

        internal override func invalidate() {
            let selfOpaquePointer = Unmanaged.passUnretained(self).toOpaque()
            for (index, item) in allItems.value.enumerated() {
                guard item.toOpaque() == selfOpaquePointer else {
                    continue
                }
                
                allItems.value.remove(at: index)
                return
            }
        }
    }

}

@available(iOS 13.0, *)
fileprivate struct AnyViewChildList<Value: View>: StatefulRule {

    @Attribute
    internal var view: AnyView

    internal var id: UniqueID?

    internal mutating func updateValue() {
        
        guard let storage = view.storage as? AnyViewStorage<Value>, storage.id == id else {
            return
        }
        
        value = storage.view
    }

}
