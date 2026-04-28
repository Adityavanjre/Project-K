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
//internal struct DynamicPropertyBehaviors: RawRepresentable {
//
//    internal typealias RawValue = UInt32
//
//    internal var rawValue: UInt32
//
//    internal init?(rawValue: UInt32) {
//        self.rawValue = rawValue
//    }
//}

internal typealias DynamicPropertyBehaviors = DGTypeApplyOptions
@available(iOS 13.0, *)
internal struct DynamicPropertyCache {
    
    
    internal struct Fields {
        
        internal enum Layout {
            
            case product([Field])
            
            case sum(Any.Type, [TaggedFields])
            
            @inlinable
            internal var isEmpty: Bool {
                switch self {
                case .product(let fields):
                    return fields.isEmpty
                case .sum(_, let taggedFields):
                    return taggedFields.isEmpty
                }
            }
            
            @inlinable
            internal func forEachField(_ body: (_ index: Int, _ field: Field) -> Void) {
                if case .product(let productFields) = self {
                    productFields.enumerated().forEach(body)
                }
            }
        }
        
        internal var layout: Layout

        internal var behaviors: DynamicPropertyBehaviors

        internal init(layout: Layout) {
            var behaviors: UInt32 = 0
            switch layout {
            case .product(let fields):
                for field in fields {
                    behaviors |= field.type._propertyBehaviors
                }
            case .sum(_, let taggedFields):
                for taggedField in taggedFields {
                    for field in taggedField.fields {
                        behaviors |= field.type._propertyBehaviors
                    }
                }
            }
            self.layout = layout
            self.behaviors = .init(rawValue: behaviors)
        }
    }
    
    internal struct Field {

        internal var type: DynamicProperty.Type

        internal var offset: Int

        internal var name: UnsafePointer<Int8>?
    }

    internal struct TaggedFields {

        internal var tag: Int

        internal var fields: [Field]

    }
    
    @inline(__always)
    internal static func withCache<R>(_ body: (MutableBox<[ObjectIdentifier : Fields]>) -> R) -> R {
        guard DanceUIFeature.hostingConfigurationReaderAsyncComputerSize.isEnable else {
            return body(cache)
        }
        if Thread.isMainThread {
            return body(cache)
        } else {
            return asyncCache.withContent { cache in
                body(cache)
            }
        }
    }
    
    internal static func fields(of type: Any.Type) -> Fields {
        let id = ObjectIdentifier(type)
        return withCache { cache in
            if let fields = cache.value[id] {
                return fields
            }
            
            let fields: Fields
            
            switch DGTypeID(type).kind {
            case .optional, .enum:
                var taggedFields = [TaggedFields]()
                let behaviors: DynamicPropertyBehaviors = [.continueWhenUnknown, .allowVisitEnum]
                forEachField(of: type, options: behaviors) { (namePtr, offset, metadata) in
                    
                    let tupleType = DGTupleType(metadata)
                    
                    var elementFields = [Field]()
                    
                    for elementIndex in 0..<tupleType.count {
                        let elementType = tupleType.getElementType(at: elementIndex)
                        let offset = tupleType.offset(at: elementIndex)
                        
                        guard let dynamicPropertyType = elementType as? DynamicProperty.Type else {
                            continue
                        }
                        
                        elementFields.append(Field(type: dynamicPropertyType, offset: offset, name: namePtr))
                    }
                    
                    if !elementFields.isEmpty {
                        taggedFields.append(TaggedFields(tag: taggedFields.count, fields: elementFields))
                    }
                    return true
                }
                fields = .init(layout: .sum(type, taggedFields))
            case .tuple, .struct:
                var productedFields = [Field]()
                let behaviors: DynamicPropertyBehaviors = [.continueWhenUnknown]
                forEachField(of: type, options: behaviors) { (namePtr, offset, metadata) in
                    
                    if let dynamicPropertyType = metadata as? DynamicProperty.Type {
                        productedFields.append(Field(type: dynamicPropertyType, offset: offset, name: namePtr))
                    }
                    
                    return true
                }
                fields = .init(layout: .product(productedFields))
            default:
                fields = .init(layout: .product([]))
            }
            
            cache.value[id] = fields
            return fields
        }
    }
    
    private static let cache = MutableBox([ObjectIdentifier : Fields]())
    
    private static let asyncCache = AsyncCache(MutableBox([ObjectIdentifier : Fields]()))
    
}

struct AsyncCache<T> {
    
    private var content: T
    
    private let lock = NSRecursiveLock()
    
    internal init(_ content: T) {
        self.content = content
    }
    
    mutating func withMutableContent<R>(_ body: (inout T) -> R) -> R {
        lock.lock()
        defer {
            lock.unlock()
        }
        return body(&content)
    }
    
    func withContent<R>(_ body: (T) -> R) -> R {
        lock.lock()
        defer {
            lock.unlock()
        }
        return body(content)
    }
    
}
