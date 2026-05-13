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
internal import os

@available(iOS 13.0, *)
public struct _DynamicPropertyBuffer {

    internal private(set) var buf: UnsafeMutableRawPointer

    internal private(set) var size: Int32

    internal private(set) var _count: Int32
    
    @inline(__always)
    internal init() {
        buf = nullPtr
        size = 0
        _count = 0
    }
    
    @inline(__always)
    internal init<A>(fields: DynamicPropertyCache.Fields,
                     container: _GraphValue<A>,
                     inputs: inout _GraphInputs,
                     baseOffset: Int = 0) {
        self.init(fields: fields, container: container, inputs: &inputs, baseOffset: baseOffset, wrappingFieldName: nil)
    }
    
    /// - Parameter wrappingFieldName: `enum`-based dynamic property may
    /// has dynamic property elements in its cases.
    @inline(__always)
    fileprivate init<A>(fields: DynamicPropertyCache.Fields,
                     container: _GraphValue<A>,
                     inputs: inout _GraphInputs,
                     baseOffset: Int,
                     wrappingFieldName: String?) {
        self.init()
        addFields(fields,
                  container: container,
                  inputs: &inputs,
                  baseOffset: baseOffset,
                  wrappingFieldName: wrappingFieldName)
    }
    
    /// Makes a traced dynamic property buffer. The base offset of the dynamic
    /// property buffer is the default value, which is zero.
    ///
    @inline(__always)
    internal static func makeTraced<A, R>(fields: DynamicPropertyCache.Fields,
                                          container: _GraphValue<A>,
                                          inputs: inout _GraphInputs,
                                          do body: (_DynamicPropertyBuffer) -> R) -> R {
        let links = _DynamicPropertyBuffer(fields: fields,
                                           container: container,
                                           inputs: &inputs)
        defer {
            links.traceMountedProperties(to: container, fields: fields)
        }
        return body(links)
    }
    
    internal func traceMountedProperties<Body>(to body: _GraphValue<Body>,
                                               fields: DynamicPropertyCache.Fields) {
        guard Signpost.linkCreate.isEnabled else {
            return
        }
#if DANCE_UI_INHOUSE || DEBUG
        fields.layout.forEachField { index, field in
            Signpost.linkCreate.traceEvent(
                "%{public}@ [ %p ] to %{public}@ (in %{public}@) at offset +%d [%d] (%p)",
                [_typeName(field.type, qualified: false), // %@
                UInt(bitPattern: self.body(at: index)), // %p
                String(describing: Body.self), // %@
                Tracing.libraryName(defining: Body.self), // %@
                field.offset, // offset: %d
                body.value.identifier.rawValue, // %d
                body.value.graph.internTypes] // %p
            )
        }
#endif
    }
    
    internal mutating func addFields<Container>(_ fields: DynamicPropertyCache.Fields,
                                                container: _GraphValue<Container>,
                                                inputs: inout _GraphInputs,
                                                baseOffset: Int) {
        addFields(fields, container: container, inputs: &inputs, baseOffset: baseOffset, wrappingFieldName: nil)
    }

    fileprivate mutating func addFields<Container>(_ fields: DynamicPropertyCache.Fields,
                                                   container: _GraphValue<Container>,
                                                   inputs: inout _GraphInputs,
                                                   baseOffset: Int,
                                                   wrappingFieldName: String?) {
        switch fields.layout {
        case .product(let fields):
            for eachField in fields {
                let name = eachField.name.map({ namePtr in
                    if let wrappingFieldName {
                        wrappingFieldName + "." + String(cString: namePtr)
                    } else {
                        String(cString: namePtr)
                    }
                })
                eachField.type._makeProperty(in: &self,
                                             container: container,
                                             fieldOffset: eachField.offset + baseOffset,
                                             name: name,
                                             inputs: &inputs)
            }
        case .sum(let type, let taggedFields):
            guard taggedFields.count > 0 else {
                return
            }
            
            let boxSize = MemoryLayout<Item>.size + MemoryLayout<EnumBox>.size
            
            let alignedBoxSize = (boxSize &+ 0xf) & ~0xf
            
            // No static_assert in Swift. Use assert instead.
            assert(alignedBoxSize == 0x30)
            
            let ptr = allocate(bytes: alignedBoxSize)
            
            let headerPtr = ptr.assumingMemoryBound(to: Item.self)
            let bodyPtr = ptr.advanced(by: MemoryLayout<Item>.size)
                .assumingMemoryBound(to: EnumBox.self)
            
            func project<Enum>(type: Enum.Type) {
                headerPtr.initialize(to: Item(vtable: EnumVTable<Enum>.self,
                                              // DO NOT USE Int32(truncatingIfNeeded:) instead!!!
                                              // Overflow checking is required.
                                              size: Int32(alignedBoxSize),
                                              // DO NOT USE Int32(truncatingIfNeeded:) instead!!!
                                              // Overflow checking is required.
                                              fieldOffset: Int32(baseOffset)))
            }
            
            _openExistential(type, do: project)
            
            bodyPtr.initialize(to: EnumBox(cases: taggedFields.map { each in
                (
                    tag: each.tag,
                    links: _DynamicPropertyBuffer(fields: .init(layout: .product(each.fields)),
                                                  container: container,
                                                  inputs: &inputs,
                                                  baseOffset: 0,
                                                  wrappingFieldName: wrappingFieldName)
                )
            },
                                           active: nil))
            
            _count &+= 1
        }
    }
    
    @inline(__always)
    internal func reset() {
        _danceuiPrecondition(_count >= 0)
        
        for (headerPtr, boxPtr) in MutableView(self) {
            headerPtr.pointee.vtable.reset(ptr: boxPtr)
        }
    }
    
    @discardableResult
    internal func update(container: UnsafeMutableRawPointer,
                         phase: _GraphInputs.Phase) -> Bool {
        _danceuiPrecondition(_count >= 0)
        
        let wasUpdated = MutableView(self).reduce(false) { (flag, buffer) in
            let (headerPtr, boxPtr) = buffer
            
            let field = container.advanced(by: Int(headerPtr.pointee.fieldOffset))
            
            let updateResult = headerPtr.pointee.vtable.update(ptr: boxPtr,
                                                               property: field,
                                                               phase: phase)
            headerPtr.pointee.lastChanged = updateResult
            
            return updateResult || flag
        }
        
        return wasUpdated
    }
    
    internal func destroy() {
        _danceuiPrecondition(_count >= 0)
        
        for (headerPtr, boxPtr) in MutableView(self) {
            headerPtr.pointee.vtable.deinitialize(ptr: boxPtr)
#if DANCE_UI_INHOUSE || DEBUG
            Signpost.linkDestroy.traceEvent("Detached: [ %p ]", [UInt(bitPattern: boxPtr)])
#endif
        }
        
        if self.size != 0 {
            self.buf.deallocate()
        }
    }
    
    @inline(__always)
    internal var isEmpty: Bool {
        size == 0
    }

    @inline(__always)
    private func body(at index: Int) -> UnsafeMutableRawPointer {
        MutableView(self)[index].body
    }
    
    internal mutating func append<Box: DynamicPropertyBox>(_ box: Box,
                                                           fieldOffset: Int) {
        
        let compoundBoxSize = MemoryLayout<Item>.size + MemoryLayout<Box>.size
        let alignedCompoundBoxSize = (compoundBoxSize &+ 0xf) & ~0xf
        
        let boxPtr = allocate(bytes: alignedCompoundBoxSize)
        
        _danceuiPrecondition(_count == 0 || (_count != 0 && boxPtr != buf))
        
        let headerPtr = boxPtr.assumingMemoryBound(to: Item.self)
        let bodyPtr = boxPtr.advanced(by: MemoryLayout<Item>.size)
            .assumingMemoryBound(to: Box.self)
        
        headerPtr.initialize(to: Item(vtable: BoxVTable<Box>.self,
                                      size: Int32(alignedCompoundBoxSize),
                                      fieldOffset: Int32(fieldOffset)))
        bodyPtr.initialize(to: box)
        
        _count &+= 1
    }
    
    internal func getState<A>(type: A.Type) -> Binding<A>? {
        var binding: Binding<A>?
        
        for (headerPtr, boxPtr) in MutableView(self) where binding == nil {
            binding = headerPtr.pointee.vtable.getState(ptr: boxPtr, type: A.self)
        }
        
        return binding
    }
    
    internal func applyChanged(to body: (Int) -> ()) {
        for (idx, item) in MutableView(self).enumerated() where item.header.pointee.lastChanged {
            body(Int(item.header.pointee.fieldOffset))
        }
    }
    
    private mutating func allocate(bytes: Int) -> UnsafeMutableRawPointer {
        _danceuiPrecondition(_count >= 0)
        
        let bufEnd = MutableView(self).reduce(self.buf) { (_, item) in
            let (header, _) = item
            
            let rawHeader = UnsafeMutableRawPointer(header)
            
            let end = rawHeader.advanced(by: Int(header.pointee.size))
            
            return end
        }
        
        let usedSize = self.buf.distance(to: bufEnd)
        
        guard bytes > (Int(self.size) &- usedSize) else {
            return bufEnd
        }
        
        return allocateSlow(bytes: bytes, ptr: bufEnd)
    }
    
    private mutating func allocateSlow(bytes: Int,
                                       ptr: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
        let expectedAllocSize = Int(self.size * 2)
        
        // The minimum initial size is 64 bytes.
        var allocSize = expectedAllocSize > 0x3f ? expectedAllocSize : 0x40
        
        let requiredSize = bytes &+ Int(self.size)
        
        while allocSize < requiredSize {
            allocSize += allocSize
        }
        
        let newBuff = UnsafeMutableRawPointer.allocate(byteCount: allocSize,
                                                       alignment: -1)
        let oldBuff = self.buf
        
        let count = Int(_count)
        
        let oldView = MutableView(buffer: oldBuff, count: count)
        
        var rawNewHeaderPtr = newBuff
        
        for oldElement in oldView {
            
            let (oldHeaderPtr, oldBodyPtr) = oldElement
            
            let newHeaderPtr = rawNewHeaderPtr.assumingMemoryBound(to: Item.self)
            let newBodyPtr = rawNewHeaderPtr.advanced(by: MemoryLayout<Item>.size)
            
            let step = oldHeaderPtr.pointee.size
            
            newHeaderPtr.initialize(to: oldHeaderPtr.move())
            
            newHeaderPtr.pointee.vtable.moveInitialize(ptr: newBodyPtr, from: oldBodyPtr)
            
            rawNewHeaderPtr = rawNewHeaderPtr.advanced(by: Int(step))
        }
        
        if self.size > 0 {
            oldBuff.deallocate()
        }
        
        self.buf = newBuff
        self.size = Int32(allocSize)
        
        let newBuffEnd = newBuff.advanced(by: ptr - oldBuff)
        
        return newBuffEnd
    }
    
    private struct Item {

        internal private(set) var vtable: BoxVTableBase.Type

        internal private(set) var size: Int32

        private var _fieldOffsetAndLastChanged: UInt32
        
        @inline(__always)
        internal init(vtable: BoxVTableBase.Type,
                      size: Int32,
                      fieldOffset: Int32) {
            self.vtable = vtable
            self.size = size
            self._fieldOffsetAndLastChanged = UInt32(bitPattern: fieldOffset)
        }
        
        fileprivate static let fieldOffsetMask = UInt32(0x7fffffff)
        
        fileprivate static let lastChangedMask = UInt32(0x80000000)
        
        @inline(__always)
        internal var fieldOffset: Int32 {
            get {
                Int32(bitPattern: _fieldOffsetAndLastChanged & Item.fieldOffsetMask)
            }
            set {
                _fieldOffsetAndLastChanged = UInt32(bitPattern: newValue) & Item.fieldOffsetMask
            }
        }
        
        @inline(__always)
        internal var lastChanged: Bool {
            get {
                (_fieldOffsetAndLastChanged & Item.lastChangedMask) == Item.lastChangedMask
            }
            set {
                if newValue {
                    _fieldOffsetAndLastChanged |= Item.lastChangedMask
                } else {
                    _fieldOffsetAndLastChanged &= ~Item.lastChangedMask
                }
            }
        }
    }
    
    private struct MutableView: Sequence {
        
        private let buffer: UnsafeMutableRawPointer
        
        private let count: Int
        
        @inlinable
        internal init(_ buffer: _DynamicPropertyBuffer) {
            self.buffer = buffer.buf
            self.count = Int(buffer._count)
        }
        
        @inlinable
        internal init(buffer: UnsafeMutableRawPointer, count: Int) {
            self.buffer = buffer
            self.count = count
        }
        
        @inlinable
        internal subscript(position: Int) -> Iterator.Element {
            var element = makeIterator().element
            for each in self {
                element = each
            }
            return element
        }
        
        internal struct Iterator: IteratorProtocol {
            
            internal typealias Element = (header: UnsafeMutablePointer<Item>, body: UnsafeMutableRawPointer)
            
            private var buffer: UnsafeMutableRawPointer
            
            private var index: Int
            
            private let count: Int
            
            internal init(_ mutableView: MutableView) {
                buffer = mutableView.buffer
                index = 0
                count = mutableView.count
            }
            
            @inline(__always)
            fileprivate var element: Element {
                let headerPtr = buffer.assumingMemoryBound(to: Item.self)
                let bodyPtr = buffer.advanced(by: MemoryLayout<Item>.size)
                return (headerPtr, bodyPtr)
            }
            
            @inlinable
            internal mutating func next() -> Element? {
                guard index < count else {
                    return nil
                }
                
                let (headerPtr, bodyPtr) = element
                
                index &+= 1
                buffer = buffer.advanced(by: Int(headerPtr.pointee.size))
                
                return (header: headerPtr, body: bodyPtr)
            }
        }
        
        @inlinable
        internal func makeIterator() -> Iterator {
            return Iterator(self)
        }
    }
}

@available(iOS 13.0, *)
fileprivate class BoxVTableBase {

    fileprivate class func moveInitialize(ptr: UnsafeMutableRawPointer,
                                          from: UnsafeMutableRawPointer) {
        _abstract(self)
    }

    fileprivate class func deinitialize(ptr: UnsafeMutableRawPointer) {
        _abstract(self)
    }

    fileprivate class func reset(ptr: UnsafeMutableRawPointer) {
        _abstract(self)
    }

    fileprivate class func update(ptr: UnsafeMutableRawPointer,
                                  property: UnsafeMutableRawPointer,
                                  phase: _GraphInputs.Phase) -> Bool {
        _abstract(self)
    }

    fileprivate class func getState<A>(ptr: UnsafeMutableRawPointer,
                                       type: A.Type) -> Binding<A>? {
        _abstract(self)
    }

}

@available(iOS 13.0, *)
private final class BoxVTable<Box: DynamicPropertyBox>: BoxVTableBase {
    
    fileprivate override class func moveInitialize(ptr: UnsafeMutableRawPointer,
                                                   from: UnsafeMutableRawPointer) {
        let destBoxPtr = ptr.assumingMemoryBound(to: Box.self)
        let sourceBoxPtr = from.assumingMemoryBound(to: Box.self)
        destBoxPtr.initialize(to: sourceBoxPtr.move())
    }
    
    fileprivate override class func deinitialize(ptr: UnsafeMutableRawPointer) {
        let typedPtr = ptr.assumingMemoryBound(to: Box.self)
        typedPtr.pointee.destroy()
        typedPtr.deinitialize(count: 1)
    }
    
    fileprivate override class func reset(ptr: UnsafeMutableRawPointer) {
        let typedPtr = ptr.assumingMemoryBound(to: Box.self)
        typedPtr.pointee.reset()
    }
    
    fileprivate override class func update(ptr: UnsafeMutableRawPointer,
                                           property: UnsafeMutableRawPointer,
                                           phase: _GraphInputs.Phase) -> Bool {
        let typedPtr = ptr.assumingMemoryBound(to: Box.self)
        let typedProperty = property.assumingMemoryBound(to: Box.Property.self)
        let isUpdated = typedPtr.pointee.update(property: &typedProperty.pointee, phase: phase)
#if DANCE_UI_INHOUSE || DEBUG
        Signpost.linkUpdate.traceEvent("Updated: %{public}@ [ %p ] - %@",
                                       [_typeName(type(of: typedPtr.pointee)),
                                       UInt(bitPattern: ptr),
                                       typedProperty.pointee.linkValueDescription])
#endif
        return isUpdated
    }
    
    fileprivate override class func getState<A1>(ptr: UnsafeMutableRawPointer,
                                                 type: A1.Type) -> Binding<A1>? {
        let typedPtr = ptr.assumingMemoryBound(to: Box.self)
        return typedPtr.pointee.getState(type: type)
    }
    
}

@available(iOS 13.0, *)
private final class EnumVTable<Enum>: BoxVTableBase {
    
    fileprivate override class func moveInitialize(ptr: UnsafeMutableRawPointer,
                                                   from: UnsafeMutableRawPointer) {
        let destBoxPtr = ptr.assumingMemoryBound(to: EnumBox.self)
        let sourceBoxPtr = from.assumingMemoryBound(to: EnumBox.self)
        destBoxPtr.initialize(to: sourceBoxPtr.move())
    }
    
    fileprivate override class func deinitialize(ptr: UnsafeMutableRawPointer) {
        let boxPtr = ptr.assumingMemoryBound(to: EnumBox.self)
        for (_, links) in boxPtr.pointee.cases {
            links.destroy()
        }
        boxPtr.deinitialize(count: 1)
    }
    
    fileprivate override class func reset(ptr: UnsafeMutableRawPointer) {
        let boxPtr = ptr.assumingMemoryBound(to: EnumBox.self)
        guard let (_, index) = boxPtr.pointee.active else {
            return
        }
        
        boxPtr.pointee.cases[index].links.reset()
        boxPtr.pointee.active = nil
    }
    
    fileprivate override class func update(ptr: UnsafeMutableRawPointer,
                                           property: UnsafeMutableRawPointer,
                                           phase: _GraphInputs.Phase) -> Bool {
        var isUpdated: Bool = false
        let boxPtr = ptr.assumingMemoryBound(to: EnumBox.self)
        
        withUnsafeMutablePointerToEnumCase(of: property.assumingMemoryBound(to: Enum.self)) { (tag, type, containerPtr) in
            if let (activeTag, activeIndex) = boxPtr.pointee.active, activeTag != tag {
                boxPtr.pointee.cases[activeIndex].links.reset()
                boxPtr.pointee.active = nil
                isUpdated = true
            }
            if boxPtr.pointee.active == nil {
                guard let caseIndex = boxPtr.pointee.cases.firstIndex(where: {$0.tag == tag}) else {
                    return
                }
                boxPtr.pointee.active = (tag, caseIndex)
                isUpdated = true
            }
            if let (_, idx) = boxPtr.pointee.active {
                isUpdated = boxPtr.pointee.cases[idx].links.update(container: containerPtr, phase: phase)
            }
        }
        
        return isUpdated
    }
    
    fileprivate override class func getState<A>(ptr: UnsafeMutableRawPointer,
                                                type: A.Type) -> Binding<A>? {
        let boxPtr = ptr.assumingMemoryBound(to: EnumBox.self)
        guard let (_, index) = boxPtr.pointee.active else {
            return nil
        }
        
        return boxPtr.pointee.cases[index].links.getState(type: type)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct EnumBox {
    
    fileprivate var cases: [(tag: Int, links: _DynamicPropertyBuffer)]
    
    fileprivate var active: (tag: Int, index: Int)?
    
}

@available(iOS 13.0, *)
fileprivate let nullPtr = Unmanaged<AnyObject>.passUnretained(unsafeBitCast(0, to: AnyObject.self)).toOpaque()
@available(iOS 13.0, *)
extension DynamicProperty {
    fileprivate var linkValueDescription: String {
        if let descriptive = self as? DescriptiveDynamicProperty {
            return descriptive.linkValueDescription
        } else {
            return String(describing: self)
        }
    }

}

@available(iOS 13.0, *)
fileprivate protocol DescriptiveDynamicProperty: DynamicProperty {
    
    var _linkValue: Any { get }
    
}

@available(iOS 13.0, *)
extension DescriptiveDynamicProperty {

    fileprivate var linkValueDescription: String {
        let linkValue = _linkValue
        if let next = linkValue as? DescriptiveDynamicProperty {
            return next.linkValueDescription
        } else {
            return String(describing: linkValue)
        }
    }

}

@available(iOS 13.0, *)
extension State: DescriptiveDynamicProperty {

    fileprivate var _linkValue: Any {
        projectedValue.wrappedValue
    }

}

@available(iOS 13.0, *)
extension Binding: DescriptiveDynamicProperty {

    fileprivate var _linkValue: Any {
        wrappedValue
    }

}

@available(iOS 13.0, *)
extension Environment: DescriptiveDynamicProperty {

    fileprivate var _linkValue: Any {
        wrappedValue
    }

}
