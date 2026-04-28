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
internal import DanceUIRuntime

@available(iOS 13.0, *)
public protocol PropertyKey {
    
    associatedtype Value
    
    static var defaultValue: Value { get }
}

@available(iOS 13.0, *)
internal protocol DerivedPropertyKey: PropertyKey where Value: Equatable {
    
    static func value(in propertyList: PropertyList) -> Value
}

@available(iOS 13.0, *)
internal protocol DerivedEnvironmentKey: DerivedPropertyKey {
    
    static func value(in environment: EnvironmentValues) -> Value
}

@available(iOS 13.0, *)
extension DerivedEnvironmentKey {
    
    internal static func value(in propertyList: PropertyList) -> Value {
        value(in: EnvironmentValues(propertyList: propertyList))
    }
}

@available(iOS 13.0, *)
private struct EmptyKey: PropertyKey {
    
    internal typealias Value = Void
    
    internal static var defaultValue: Value {
        ()
    }
}

@available(iOS 13.0, *)
private protocol AnyTrackedValue {
    
    associatedtype Value
    
    func hasMatchingValue(in propertyList: PropertyList) -> Bool
    
    func unwrap() -> Value
}

@available(iOS 13.0, *)
private struct DerivedValue<Key: DerivedPropertyKey>: AnyTrackedValue {
    
    internal typealias Value = Key.Value
    
    internal var value: Value
    
    internal func hasMatchingValue(in propertyList: PropertyList) -> Bool {
        Key.value(in: propertyList) == value
    }
    
    internal func unwrap() -> Key.Value {
        value
    }
}

@available(iOS 13.0, *)
private struct TrackedValue<Key: PropertyKey>: AnyTrackedValue {
    
    internal typealias Value = Key.Value
    
    internal var value: Value
    
    internal func hasMatchingValue(in propertyList: PropertyList) -> Bool {
        DGCompareValues(lhs: value, rhs: propertyList[Key.self])
    }
    
    internal func unwrap() -> Key.Value {
        value
    }
}

@frozen
@usableFromInline
@available(iOS 13.0, *)
internal struct PropertyList {
    
    @usableFromInline
    internal var elements: Element?
    
    @inlinable
    internal init(elements: Element? = nil) {
        self.elements = elements
    }
    
    @_semantics("optimize.sil.specialize.generic.never")
    internal subscript<K: PropertyKey>(_ key: K.Type) -> K.Value {
        get {
            withExtendedLifetime(key) {
                guard let found = find(elements.map({.passUnretained($0)}), key: key) else {
                    return key.defaultValue
                }
                
                return found.takeUnretainedValue().value
            }
        }
        set(newValue) {
            let after: Element?
            
            if let found = find(elements.map({.passUnretained($0)}), key: key) {
                guard !DGCompareValues(lhs: newValue,
                                       rhs: found.takeUnretainedValue().value) else {
                    return
                }
                
                after = self.elements
            } else {
                after = self.elements
            }
            
            self.elements = TypedElement<K>(value: newValue, before: nil, after: after)
            
            #if DEBUG
            #endif
        }
    }
    
    internal func forEach<Key: PropertyKey>(keyType: Key.Type, _ body: (Key.Value, inout Bool) -> Void) {
        elements?.forEach { element, stop in
            guard element.flatMap({ $0.keyType == keyType }) else {
                return
            }
            
            let typedElement = element.map { unsafeDowncast($0, to: TypedElement<Key>.self) }
            
            let value = typedElement.flatMap { $0.value }
            
            body(value, &stop)
        }
    }
    
    internal mutating func override(with propertyList: PropertyList) {
        guard let elements = elements else {
            self.elements = propertyList.elements
            return
        }
        self.elements = elements.byPrepending(propertyList.elements)
    }
    
    internal func match(_ propertyList: PropertyList) -> Bool {
        guard let id = DanceUI.match(id: elements?.id ?? .zero, from: self, to: propertyList) else {
            return false
        }
        return id != .zero
    }
    
    internal mutating func merge(_ propertyList: PropertyList) {
        #if DEBUG
        #endif
        
        guard let selfHeadElement = self.elements else {
            self.elements = propertyList.elements
            return
        }

        guard let otherHeadElement = propertyList.elements else {
            return
        }

        guard otherHeadElement !== selfHeadElement else {
            return
        }

        var elementsCountToCopy = 0

        var currentOtherElement: Element? = otherHeadElement

        var currentSelfElement: Element? = selfHeadElement

        repeat {
            if currentOtherElement!.length >= currentSelfElement!.length {
                elementsCountToCopy &+= 1

                let nextElement = currentOtherElement!.after

                currentOtherElement = nextElement

                if currentOtherElement == nil {
                    break
                }

            } else {
                currentSelfElement = currentSelfElement!.after

                if currentSelfElement == nil {
                    break
                }
            }

        } while currentOtherElement !== currentSelfElement

        switch (currentSelfElement, currentOtherElement) {
        case (.some(let commonAncestorOnSelf), .some(let commonAncestorOnOther))
                where commonAncestorOnSelf === commonAncestorOnOther:

            if commonAncestorOnOther === propertyList.elements {
                return
            }

            if self.elements != nil && self.elements === commonAncestorOnSelf {
                self = propertyList
                return
            }

        case (.none, .none):

            if self.elements == nil {
                self = propertyList
                return
            }

        default:
            self.override(with: propertyList)

            return
        }

        if elementsCountToCopy == 0 {
            return
        }

        withUnsafeTuple(of: PropertyList.Element.self, count: elementsCountToCopy) { (unsafeMutableTuple) in

            let ptr = unsafeMutableTuple.tuple.assumingMemoryBound(to: PropertyList.Element.self)

            var currentElement = propertyList.elements!

            for index in 0..<elementsCountToCopy {
                ptr[index] = currentElement

                currentElement = currentElement.after!
            }

            var lastCopiedHeadingElement = self.elements!

            for index in (0..<elementsCountToCopy).reversed() {
                let element: PropertyList.Element = ptr[index]

                lastCopiedHeadingElement = element.copy(before: element.before, after: lastCopiedHeadingElement)

                self.elements = lastCopiedHeadingElement
            }
        }
    }
    
    @inline(__always)
    internal func merged(_ propertyList: PropertyList) -> PropertyList {
        var mergedPlist = self
        mergedPlist.merge(propertyList)
        return mergedPlist
    }
    
    @inline(__always)
    internal func mayNotBeEqual(to otherList: PropertyList) -> Bool {
        guard let elements = elements else {
            return otherList.elements != nil
        }
        var types = Set<ObjectIdentifier>()
        return !elements.isEqual(to: otherList.elements, ignoredTypes: &types)
    }
    
    internal func mayNotBeEqualWithoutOrdering(to otherList: PropertyList) -> Bool {
        
        guard let elements = elements else {
            return otherList.elements != nil
        }
        
        guard let otherElements = otherList.elements else {
            return true
        }
        
        var typeSet = Set<DGTypeID>()
        
        var hasDifference = false
        
        elements.forEach { element, stop in

            hasDifference = !compareElements(element.takeUnretainedValue(), otherElements)
            
            stop = hasDifference
        }
        
        guard !hasDifference else {
            return true
        }
        
        otherElements.forEach { element, stop in
            hasDifference = !compareElements(element.takeUnretainedValue(), elements)
            
            stop = hasDifference
        }
        
        func compareElements(_ lhs: PropertyList.Element, _ rhs: PropertyList.Element) -> Bool {
            if let before = lhs.before, !compareElements(before, otherElements) {
                return false
            }
            if !typeSet.contains(DGTypeID(lhs.keyType)) {
                typeSet.insert(DGTypeID(lhs.keyType))
                return lhs.hasMatchingValue(in: .passUnretained(rhs))
            }
            return true
        }
        
        return hasDifference
    }
    
    fileprivate struct TrackerData {
        
        internal var plistID: UniqueID = .zero
        
        internal var values: [ObjectIdentifier: any AnyTrackedValue] = [:]
        
        internal var derivedValues: [ObjectIdentifier: any AnyTrackedValue] = [:]
        
        internal var invalidValues: [any AnyTrackedValue] = []
        
        internal var unrecordedDependencies: Bool = false
        
        internal mutating func removeAll() {
            plistID = .zero
            values.removeAll(keepingCapacity: true)
            derivedValues.removeAll(keepingCapacity: true)
            invalidValues.removeAll(keepingCapacity: true)
            unrecordedDependencies = false
        }
    }
    
    @usableFromInline
    internal final class Tracker {
        
        @UnsafeLockedPointer
        private var data = TrackerData()
        
        @usableFromInline
        internal init() {
        }
        
        deinit {
            $data.destroy()
        }
        
        internal func reset() {
            data.removeAll()
        }

        internal func hasDifferentUsedValues(_ propertyList: PropertyList) -> Bool {
            let data = self.data
            guard !data.unrecordedDependencies else {
                return true
            }
            let dataVersion = data.plistID
            if dataVersion == .zero {
                return true
            }
            if compare(data.values, against: propertyList) {
                return true
            }
            if compare(data.derivedValues, against: propertyList) {
                return true
            }
            for invalidValue in data.invalidValues {
                if !invalidValue.hasMatchingValue(in: propertyList)  {
                    continue
                }
                return true
            }
            return false
        }
        
        internal func initializeValues(from propertyList: PropertyList) {
            data.plistID = propertyList.elements?.id ?? .zero
        }
        
        internal func invalidateValue<K: PropertyKey>(for type: K.Type,
                                                      from fromPropertyList: PropertyList,
                                                      to toPropertyList: PropertyList) {
            $data.withMutableData { data in
                guard let id = DanceUI.match(id: data.plistID, from: fromPropertyList, to: toPropertyList) else {
                    return
                }
                
                if let removedValue = data.values.removeValue(forKey: ObjectIdentifier(type)) {
                    data.invalidValues.append(removedValue)
                }
                
                move(&data.derivedValues, to: &data.invalidValues)
                
                data.plistID = id
            }
        }
        
        internal func invalidateAllValues(from fromPropertyList: PropertyList,
                                          to toPropertyList: PropertyList) {
            $data.withMutableData { data in
                guard let id = DanceUI.match(id: data.plistID, from: fromPropertyList, to: toPropertyList) else {
                    return
                }
                move(&data.values, to: &data.invalidValues)
                move(&data.derivedValues, to: &data.invalidValues)
                
                data.plistID = id
            }
        }
        
        internal func value<K: PropertyKey>(_ propertyList: PropertyList,
                                            for type: K.Type) -> K.Value {
            $data.withMutableData { data in
                if let elements = propertyList.elements {
                    if data.plistID != elements.id {
                        data.unrecordedDependencies = true
                        return propertyList[type]
                    }
                } else if data.plistID != .zero {
                    data.unrecordedDependencies = true
                    return K.defaultValue
                }
                let key = ObjectIdentifier(type)
                guard let trackedValue = data.values[key] as? TrackedValue<K> else {
                    let resolvedValue = propertyList[type]
                    data.values[key] = TrackedValue<K>(value: resolvedValue)
                    return resolvedValue
                }
                return trackedValue.unwrap()
            }
        }
        
        internal func derivedValue<K: DerivedPropertyKey>(_ propertyList: PropertyList,
                                                          for type: K.Type) -> K.Value {
            $data.withMutableData { data in
                if let elements = propertyList.elements {
                    if data.plistID != elements.id {
                        return K.value(in: propertyList)
                    }
                } else if data.plistID != .zero {
                    return K.value(in: propertyList)
                }
                let key = ObjectIdentifier(type)
                guard let derivedValue = data.derivedValues[key] as? DerivedValue<K> else {
                    let resolvedValue = K.value(in: propertyList)
                    data.derivedValues[key] = DerivedValue<K>(value: resolvedValue)
                    return resolvedValue
                }
                return derivedValue.unwrap()
            }
        }
    }
    
    @usableFromInline
    internal class Element: CustomStringConvertible {
        
        internal let keyType: Any.Type
        
        internal var before: Element?
        
        internal var after: Element?
        
        internal let length: Int
        
        internal var keyFilter: BloomFilter
        
        internal let id: UniqueID = .init()
        
        @inline(__always)
        internal var isValid: Bool { 
            id != .zero
        }
        
        @usableFromInline
        internal init(keyType: Any.Type,
                      before: PropertyList.Element?,
                      after: PropertyList.Element?) {
            self.keyType = keyType
            self.before = before
            self.after = after
            self.keyFilter = BloomFilter(type: keyType)
            self.keyFilter.value |= ((before?.keyFilter.value ?? 0) | (after?.keyFilter.value ?? 0))
            self.length = (before?.length ?? 0) &+ (after?.length ?? 0) &+ 1
        }
        
        @usableFromInline
        internal var description: String {
            _abstract(self)
        }
        
        internal func matches(_ element: PropertyList.Element, ignoredTypes: inout Set<ObjectIdentifier>) -> Bool {
            _abstract(self)
        }
        
        internal func hasMatchingValue(in: Unmanaged<Element>?) -> Bool {
            _abstract(self)
        }
        
        internal func copy(before: Element?, after: Element?) -> Element {
            _abstract(self)
        }
        
        internal func byPrepending(_ element: Element?) -> Element {
            #if DEBUG
            defer {
            }
            #endif
            
            guard element != nil else {
                return self
            }
            return TypedElement<EmptyKey>(value: EmptyKey.defaultValue,
                                          before: element,
                                          after: self)
        }
        
        internal func isEqual(to element: Element?, ignoredTypes: inout Set<ObjectIdentifier>) -> Bool {
            guard let element = element else {
                return false
            }
            guard length == element.length else {
                return false
            }
            guard self !== element else {
                return true
            }
            guard self.matches(element, ignoredTypes: &ignoredTypes) else {
                return false
            }
            if let before = self.before {
                guard before.isEqual(to: element.before, ignoredTypes: &ignoredTypes) else {
                    return false
                }
            } else {
                guard element.before == nil else {
                    return false
                }
            }
            
            if let after = self.after {
                guard after.isEqual(to: element.after, ignoredTypes: &ignoredTypes) else {
                    return false
                }
            } else {
                guard element.after == nil else {
                    return false
                }
            }
            
            return true
        }
        
        internal func forEach(_ body: (_ element: Unmanaged<Element>,
                                       _ stop: inout Bool) -> Void) {
            var element: Element? = self
            var stop = false
            while let _element = element {
                if let before = _element.before {
                    before.forEach(body)
                }
                body(.passUnretained(_element), &stop)
                guard !stop else {
                    return
                }
                element = _element.after
            }
        }
    }
}

@available(iOS 13.0, *)
extension PropertyList: CustomStringConvertible {
    
    @usableFromInline
    internal var description: String {
        guard let elements = elements else {
            return [].description
        }
        var desc = [String]()
        elements.forEach { (element, _) in
            desc.append(element.takeUnretainedValue().description)
        }
        return desc.description
    }
    
}

@available(iOS 13.0, *)
private final class TypedElement<A: PropertyKey>: PropertyList.Element {
    
    internal var value: A.Value
    
    fileprivate init(value: A.Value, before: PropertyList.Element?, after: PropertyList.Element?) {
        self.value = value
        super.init(keyType: A.self, before: before, after: after)
    }
    
    deinit {
        
    }
    
    fileprivate override var description: String {
        "\(A.self) = \(value)"
    }
    
    fileprivate override func hasMatchingValue(in element: Unmanaged<PropertyList.Element>?) -> Bool {
        guard let element = element else {
            return false
        }
        guard let unmanagedFound = find(element, key: A.self) else {
            return DGCompareValues(lhs: value, rhs: A.defaultValue)
        }
        return unmanagedFound._withUnsafeGuaranteedRef { (found) in
            DGCompareValues(lhs: value, rhs: found.value)
        }
    }
    
    fileprivate override func copy(before: PropertyList.Element?,
                                   after: PropertyList.Element?) -> PropertyList.Element {
        TypedElement(value: value, before: before, after: after)
    }
    
    fileprivate override func matches(_ element: PropertyList.Element, ignoredTypes: inout Set<ObjectIdentifier>) -> Bool {
        guard let typedElement = element as? TypedElement<A> else {
            return false
        }
        
        guard !ignoredTypes.contains(ObjectIdentifier(A.self)) else {
            return true
        }
        
        guard DGCompareValues(lhs: typedElement.value, rhs: self.value) else {
            return false
        }
        
        ignoredTypes.insert(ObjectIdentifier(A.self))
        
        return true
    }
    
    @inline(__always)
    fileprivate func matches(_ value: A.Value) -> Bool {
        DGCompareValues(lhs: value, rhs: self.value)
    }
    
}

@available(iOS 13.0, *)
extension Unmanaged {
    
    @inlinable
    internal func map<A1: AnyObject>(_ transform: (Instance) throws -> A1) rethrows -> Unmanaged<A1> {
        try _withUnsafeGuaranteedRef { (instance) -> Unmanaged<A1> in
            .passUnretained(try transform(instance))
        }
    }
    
    @inlinable
    internal func map<A1: AnyObject>(_ transform: (Instance) throws -> A1?) rethrows -> Unmanaged<A1>? {
        try _withUnsafeGuaranteedRef { (instance) -> Unmanaged<A1>? in
            try transform(instance).map({Unmanaged<A1>.passUnretained($0)})
        }
    }
    
    @inlinable
    internal func flatMap<Value>(_ transform: (Instance) throws -> Value) rethrows -> Value {
        try _withUnsafeGuaranteedRef { (instance) -> Value in
            try transform(instance)
        }
    }
    
    @inlinable
    internal func flatMap<Value>(_ transform: (Instance) throws -> Value?) rethrows -> Value? {
        try _withUnsafeGuaranteedRef { (instance) -> Value? in
            try transform(instance)
        }
    }
    
    @inlinable
    internal static func == (lhs: Unmanaged, rhs: Unmanaged) -> Bool {
        return lhs.toOpaque() == rhs.toOpaque()
    }
    
}

@available(iOS 13.0, *)
private func find<A: PropertyKey>(_ elementOrNil: Unmanaged<PropertyList.Element>?,
                                  key: A.Type,
                                  keyFilter: BloomFilter = .init(type: A.self)) -> Unmanaged<TypedElement<A>>? {
    guard var currentElement = elementOrNil else {
        return nil
    }

    repeat {
        guard (currentElement.takeUnretainedValue().keyFilter.value & keyFilter.value) == keyFilter.value else {
            return nil
        }

        if let elementBefore = currentElement.map({$0.before}),
           let result = find(elementBefore, key: key, keyFilter: keyFilter)
        {
            return result
        }

        if currentElement.takeUnretainedValue().keyType == key {
            return currentElement.map { (element) -> TypedElement<A> in
                unsafeDowncast(element, to: TypedElement<A>.self)
            }
        } else {
            if let elementAfter = currentElement.map({$0.after}) {
                currentElement = elementAfter

                if (elementAfter.takeUnretainedValue().keyFilter.value & keyFilter.value) != keyFilter.value {
                    return nil
                }

            } else {
                return nil
            }
        }
    } while true
}

#if DEBUG
@available(iOS 13.0, *)
private func detectCycle(_ propertyList: PropertyList) {
    typealias Level = (element: PropertyList.Element, isBeforeVisited: Bool, isAfterVisited: Bool)
    
    guard let rootElement = propertyList.elements else {
        return
    }
    
    var objectIds: Set<ObjectIdentifier> = Set()
    
    func visit(_ element: PropertyList.Element) {
        let objectId = ObjectIdentifier(element)
        _danceuiPrecondition(!objectIds.contains(objectId))
        objectIds.insert(objectId)
    }
    
    var stack: [Level] = [(element: rootElement, isBeforeVisited: false, isAfterVisited: false)]
    stack.reserveCapacity(rootElement.length)
    
    visit(rootElement)
    
    while !stack.isEmpty {
        let (topElement, isBeforeVisited, isAfterVisited) = stack.removeLast()
        
        if !isBeforeVisited {
            stack.append((element: topElement, isBeforeVisited: true, isAfterVisited: isAfterVisited))
            
            if let beforeElement = topElement.before {
                visit(beforeElement)
                stack.append((element: beforeElement, isBeforeVisited: false, isAfterVisited: false))
            }
        } else if !isAfterVisited {
            stack.append((element: topElement, isBeforeVisited: isBeforeVisited, isAfterVisited: true))
            
            if let afterElement = topElement.after {
                visit(afterElement)
                stack.append((element: afterElement, isBeforeVisited: false, isAfterVisited: false))
            }
        }
        
    }
    
}
#endif
@available(iOS 13.0, *)
private func compare(_ keyValues: [ObjectIdentifier: any AnyTrackedValue],
                     against propertyList: PropertyList) -> Bool {
    for (_, value) in keyValues {
        if !value.hasMatchingValue(in: propertyList) {
            return true
        }
    }
    return false
}

@available(iOS 13.0, *)
private func move(_ keyValues: inout [ObjectIdentifier: any AnyTrackedValue],
                  to invalidValues: inout [any AnyTrackedValue]) {
    guard !keyValues.isEmpty else {
        return
    }
    invalidValues.append(contentsOf: keyValues.values)
    keyValues.removeAll()
}

@available(iOS 13.0, *)
@_transparent
@inline(__always)
private func match(id: UniqueID,
                   from fromPropertyList: PropertyList,
                   to toPropertyList: PropertyList) -> UniqueID? {
    if let fromElement = fromPropertyList.elements,
       fromElement.id == id {
        if let toElement = toPropertyList.elements {
            toElement.id != id ? toElement.id : nil
        } else {
            id != .zero ? .zero : nil
        }
    } else if fromPropertyList.elements == nil,
              id == .zero,
              let toElement = toPropertyList.elements,
              toElement.id != id {
        toElement.id
    } else {
        nil
    }
}

@available(iOS 13.0, *)
extension PropertyList.Tracker: CustomDebugStringConvertible {
    
    @usableFromInline
    internal var debugDescription: String {
        let data = self.data
        return String("ID: \(data.plistID); values: \(data.values); derivedValues: \(data.derivedValues); invalidValues: \(data.invalidValues)")
    }
}
