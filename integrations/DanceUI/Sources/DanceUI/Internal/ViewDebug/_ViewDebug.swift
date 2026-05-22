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
internal enum _ViewDebug {
    
    fileprivate static var properties = Properties()
    
    fileprivate static var isInitialized: Bool = false
    
    internal static func initialize() {
        if !isInitialized {
            if EnvValue.viewDebugEnable {
                properties = EnvValue.viewDebugPropertiesValue
            }
            isInitialized = true
        }
        
        if !properties.isEmpty {
            DGSubgraphRef.shouldRecordTree = true
        }
    }
    
    internal enum Property: UInt32, Hashable, Codable {
        
        case type
        
        case value
        
        case transform
        
        case position
        
        case size
        
        case environment
        
        case phase
        
        case layoutComputer
        
        case displayList
        
        case custom = 0x1F
    }
    
    internal struct Properties: OptionSet {
        
        internal let rawValue: UInt32
        
        internal static let invalid = Properties()
        
        internal static let value = Properties(rawValue: 1 << Property.value.rawValue)
        
        internal static let type = Properties(rawValue: 1 << Property.type.rawValue)
        
        internal static let transform = Properties(rawValue: 1 << Property.transform.rawValue)
        
        internal static let position = Properties(rawValue: 1 << Property.position.rawValue)
        
        internal static let size = Properties(rawValue: 1 << Property.size.rawValue)
        
        internal static let environment = Properties(rawValue: 1 << Property.environment.rawValue)
        
        internal static let phase = Properties(rawValue: 1 << Property.phase.rawValue)
        
        internal static let layoutComputer = Properties(rawValue: 1 << Property.layoutComputer.rawValue)
        
        internal static let displayList = Properties(rawValue: 1 << Property.displayList.rawValue)
        
        internal static let custom = Properties(rawValue: 1 << Property.custom.rawValue)
        
        internal static let all: Properties = [value, type, transform, position, size, environment, phase, layoutComputer, displayList, custom]
    }
}

@available(iOS 13.0, *)
@objc internal protocol XcodeViewDebugDataProvider {
    func makeViewDebugData() -> Data?
}

@available(iOS 13.0, *)
internal struct ViewDebugEnvKey: EnvKey {
    
    internal static var raw: String {
        "DANCEUI_VIEW_DEBUG"
    }
    
    internal static var defaultValue: Bool {
        true
    }
    
    @inlinable
    internal static func makeValue(rawValue: String) -> Bool {
        return (Int(rawValue) ?? 0) != 0
    }
}

@available(iOS 13, *)
extension EnvValue where K == ViewDebugEnvKey {
    
    private static let viewDebugEnv: Self = .init()
    
    @inline(__always)
    internal static var viewDebugEnable: Bool {
        viewDebugEnv.value
    }
}

@available(iOS 13.0, *)
internal struct ViewDebugPropertiesKey: EnvKey {
    
    internal static var raw: String {
        "DANCEUI_VIEW_DEBUG_PROPERTIES"
    }
    
    internal static var defaultValue: _ViewDebug.Properties {
        [.transform, .position, .size, .custom]
    }
    
    @inlinable
    internal static func makeValue(rawValue: String) -> _ViewDebug.Properties {
        guard let value = UInt32(rawValue, radix: 16) else {
            return defaultValue
        }
        return .init(rawValue: value)
    }
}

@available(iOS 13, *)
extension EnvValue where K == ViewDebugPropertiesKey {
    
    private static let viewDebugProperties: Self = .init()
    
    @inline(__always)
    internal static var viewDebugPropertiesValue: _ViewDebug.Properties {
        viewDebugProperties.value
    }
}

#if DEBUG || DANCE_UI_INHOUSE

@available(iOS 13.0, *)
extension _ViewDebug {
    @inline(never)
    fileprivate static func reallyWrap<A>(_ outputs: inout _ViewOutputs,
                                          value: _GraphValue<A>,
                                          inputs: UnsafePointer<_ViewInputs>) {
        var debugProperties = outputs.preferences.debugProperties.union(inputs.pointee.base.changedDebugProperties)
        outputs.preferences.debugProperties = .invalid
        if debugProperties.contains(.layoutComputer), outputs.layout.attribute == nil {
            debugProperties.remove(.layoutComputer)
        }
        if debugProperties.contains(.displayList), !outputs.preferences.contains(DisplayList.Key.self) {
            debugProperties.remove(.displayList)
        }
        
        guard debugProperties != .invalid else {
            return
        }
        guard DGSubgraphRef.shouldRecordTree else {
            return
        }
        
        if debugProperties.contains(.transform) {
            DGSubgraphRef.addTreeValue(inputs.pointee.transform, forKey: .transform)
        }
        if debugProperties.contains(.position) {
            DGSubgraphRef.addTreeValue(inputs.pointee.position, forKey: .position)
        }
        if debugProperties.contains(.size) {
            DGSubgraphRef.addTreeValue(inputs.pointee.size, forKey: .size)
        }
        if debugProperties.contains(.environment) {
            DGSubgraphRef.addTreeValue(inputs.pointee.environment, forKey: .environment)
        }
        if debugProperties.contains(.phase) {
            DGSubgraphRef.addTreeValue(inputs.pointee.phase, forKey: .phase)
        }
        if debugProperties.contains(.layoutComputer) {
            DGSubgraphRef.addTreeValue(outputs.layout.attribute!, forKey: .layoutComputer)
        }
        if debugProperties.contains(.displayList), let displayList = outputs.preferences[DisplayList.Key.self] {
            DGSubgraphRef.addTreeValue(displayList, forKey: .displayList)
        }
        if debugProperties.contains(.custom), let custom = inputs.pointee.viewDebugCustomValue.attribute {
            DGSubgraphRef.addTreeValue(custom, forKey: .custom)
        }
    }
    
    fileprivate static func appendDebugData(from element: DGTreeElement, to data: inout [Data]) {
        guard element.flags != 1, let value = element.value, let elementType = element.elementType else {
            var iterator = element.childElements
            while let next = iterator.next() {
                appendDebugData(from: next, to: &data)
            }
            return
        }
        
        var debugData = Data()
        
        func project<T>(_ _type: T.Type) {
            debugData.data[.type] = _type
            debugData.data[.value] = value.as(_type)
        }
        
        _openExistential(elementType, do: project)
        
        var iterator = element.childValues
        while let next = iterator.next() {
            let key = ViewDebugTreeValueKey(rawValue: String(cString: next.key))
            if properties.contains(.environment), key == .environment {
                debugData.data[.environment] = Attribute<EnvironmentValues>(identifier: next.value).value
            } else if properties.contains(.position), key == .position {
                debugData.data[.position] = Attribute<ViewOrigin>(identifier: next.value).value.value
            } else if properties.contains(.size), key == .size {
                debugData.data[.size] = Attribute<ViewSize>(identifier: next.value).value.value
            } else if properties.contains(.phase), key == .phase {
                debugData.data[.phase] = Attribute<_GraphInputs.Phase>(identifier: next.value).value
            } else if properties.contains(.transform), key == .transform {
                debugData.data[.transform] = Attribute<ViewTransform>(identifier: next.value).value
            } else if properties.contains(.layoutComputer), key == .layoutComputer {
                debugData.data[.layoutComputer] = Attribute<LayoutComputer>(identifier: next.value).value
            } else if properties.contains(.displayList), key == .displayList {
                debugData.data[.displayList] = Attribute<DisplayList>(identifier: next.value).value
            } else if properties.contains(.custom), key == .custom {
                let factory = Attribute<ViewDebugCustomValueFactory>(identifier: next.value).value
                if let value = debugData.data[.value], let custom = factory.makeValue(value) {
                    debugData.data[.custom] = custom
                }
            }
        }
        var elementsIterator = element.childElements
        while let next = elementsIterator.next() {
            appendDebugData(from: next, to: &debugData.childData)
        }
        data.append(debugData)
    }
}
    
@available(iOS 13.0, *)
extension _ViewDebug {
    
    internal struct Data {
        
        internal var data: [Property: Any] = [:]
        
        internal var childData: [Data] = []
        
        fileprivate func serializedProperties() -> [SerializedProperty] {
            return data.compactMap { (key: _ViewDebug.Property, value: Any) in
                if key != .type {
                    let depth = key == .value ? 6 : 4
                    if let attribute = serializedAttribute(for: value, label: nil, reflectionDepth: depth) {
                        return SerializedProperty(id: key, attribute: attribute)
                    } else {
                        return nil
                    }
                } else {
                    let anyType = (value as? Any.Type) ?? type(of: value)
                    let attribute = SerializedAttribute(type: anyType)
                    return SerializedProperty(id: .type, attribute: attribute)
                }
            }
        }
        
        private func serializedAttribute(for value: Any, label: String?, reflectionDepth: Int) -> SerializedAttribute? {
            guard let unwrappedValue = unwrapped(value) else {
                return nil
            }
            var serializedValue: Any? = nil
            if let _ = unwrappedValue as? Encodable {
                serializedValue = unwrappedValue
            } else if let _ = unwrappedValue as? CustomViewDebugValueConvertible {
                serializedValue = unwrappedValue
            }
            if serializedValue != nil || reflectionDepth == 0 {
                return SerializedAttribute(value: unwrappedValue, serializeValue: true, label: label, subattributes: nil)
            }
            
            if let mirror = effectiveMirror(for: unwrappedValue)  {
                let depth = reflectionDepth - 1
                guard !mirror.children.isEmpty else {
                    return SerializedAttribute(value: unwrappedValue, serializeValue: true, label: label, subattributes: nil)
                }
                let subattributes = mirror.children.compactMap { child in
                    serializedAttribute(for: child.value, label: child.label, reflectionDepth: depth)
                }
                return SerializedAttribute(value: unwrappedValue, serializeValue: false, label: label, subattributes: subattributes)
            }
            return SerializedAttribute(value: unwrappedValue, serializeValue: false, label: label, subattributes: nil)
        }
        
        private func effectiveMirror(for value: Any) -> Mirror? {
            if let reflectableValue = value as? CustomViewDebugReflectable {
                return reflectableValue.customViewDebugMirror
            }
            if let customReflectable = value as? CustomReflectable {
                return customReflectable.customMirror
            }
            return Mirror(reflecting: value)
        }
        
        private func unwrapped(_ value: Any) -> Any? {
            if let valueWrapper = value as? ValueWrapper {
                return valueWrapper.wrappedValue
            }
            return value
        }
        
        internal enum CodingKeys: CodingKey, Hashable {
            
            case properties
            
            case children
        }
        
        internal struct SerializedProperty: Encodable {
            
            internal let id : Property
            
            internal let attribute : SerializedAttribute
            
            internal enum CodingKeys: CodingKey, Hashable {
                
                case id
                
                case attribute
            }
        }
        
        internal struct SerializedAttribute: Encodable {
            
            internal let name : String?
            
            internal let type : String
            
            internal let readableType : String
            
            internal let flags : Flags
            
            internal var value : Any?
            
            internal let subattributes : [SerializedAttribute]?
            
            internal init(type: Any.Type) {
                self.name = nil
                self.type = String(reflecting: type)
                self.readableType = _typeName(type, qualified: false)
                let viewFlag: Flags = conformsToProtocol(type, ViewDescriptor.self) ? .view : .empty
                let viewModifierFlag: Flags = conformsToProtocol(type, ViewModifierDescriptor.self) ? .viewModifier : .empty
                self.flags = [viewFlag, viewModifierFlag]
                self.value = nil
                self.subattributes = nil
            }
            
            fileprivate init(value: Any, serializeValue: Bool, label: String?, subattributes: [SerializedAttribute]?) {
                self.name = label
                let valueType = Swift.type(of: value)
                self.type = String(reflecting: valueType)
                self.readableType = _typeName(valueType, qualified: false)
                let viewFlag: Flags = conformsToProtocol(Any.self, ViewDescriptor.self) ? .view : .empty
                let viewModifierFlag: Flags = conformsToProtocol(Any.self, ViewModifierDescriptor.self) ? .viewModifier : .empty
                self.flags = [viewFlag, viewModifierFlag]
                self.value = serializeValue ? _ViewDebug.Data.SerializedAttribute.serialize(value: value) : nil
                self.subattributes = subattributes
            }
            
            internal static func serialize(value: Any) -> Any? {
                let debugValue = (value as? CustomViewDebugValueConvertible)?.viewDebugValue ?? value
                if let encodable = debugValue as? Encodable {
                    return encodable
                }
                if let description = (debugValue as? CustomDebugStringConvertible)?.debugDescription {
                    return description
                }
                if let style = Mirror(reflecting: debugValue).displayStyle, style == .enum {
                    return String(describing: value)
                }
                return nil
            }
            
            internal func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfPresent(name, forKey: .name)
                try container.encode(type, forKey: .type)
                try container.encode(readableType, forKey: .readableType)
                try container.encode(flags, forKey: .flags)
                try container.encodeIfPresent(subattributes, forKey: .subattributes)
                if let value = value as? Encodable {
                    try container.encode(value, forKey: .value)
                }
            }
            
            internal struct Flags: OptionSet, Encodable {
                
                internal let rawValue : Int
                internal static let empty = Flags([])
                internal static let view = Flags(rawValue: 0x1)
                internal static let viewModifier = Flags(rawValue: 0x2)
            }
            
            internal enum CodingKeys: CodingKey, Hashable {
                
                case name
                
                case type
                
                case readableType
                
                case flags
                
                case value
                
                case subattributes
            }
        }
        
    }
}

@available(iOS 13.0, *)
extension _ViewDebug {
    internal static func serializedData(_ viewDebugData: [Data]) -> Foundation.Data? {
        let encoder = JSONEncoder()
        encoder.nonConformingFloatEncodingStrategy = .convertToString(positiveInfinity: "inf", negativeInfinity: "-inf", nan: "nan")
        do {
            let data = try encoder.encode(viewDebugData)
            return data
        } catch {
            let dic = ["error": error.localizedDescription]
            return try? encoder.encode(dic)
        }
    }
}

@available(iOS 13.0, *)
extension _ViewDebug.Data : Encodable {
    internal func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let customData = customData {
            try customData.encode(to: encoder)
        } else {
            try container.encode(serializedProperties(), forKey: .properties)
            let child = reversedChild ? self.childData.reversed() : self.childData
            try container.encode(child, forKey: .children)
        }
    }
}

@available(iOS 13.0, *)
extension _ViewDebug.Data {
    private var customData: _ViewDebug.Data? {
        if let custom = data[.custom] {
            let modifier = CustomViewDebugModifier(data: custom)
            var childData = self
            childData.data[.custom] = nil
            return _ViewDebug.Data(data: [.type: CustomViewDebugModifier.self, .value: modifier], childData: [childData])
        }
        return nil
    }
    
    private var reversedChild: Bool {
        if let anyType = data[.type] as? Any.Type {
            let type = _typeName(anyType)
            return type.hasPrefix("DanceUI._VStackLayout") || type.hasPrefix("DanceUI._HStackLayout")
        }
        return false
    }
}

@available(iOS 13.0, *)
internal struct CustomViewDebugModifier: PrimitiveViewModifier, CustomViewDebugReflectable {
    internal var data: Any
    
    var customViewDebugMirror: Mirror? {
        Mirror(self, children: ["": data])
    }
}

private protocol ValueWrapper {
    
    var wrappedValue: Any? { get }
}

extension Optional: ValueWrapper {
    fileprivate var wrappedValue: Any? {
        return self.flatMap { $0 }
    }
}

@available(iOS 13.0, *)
extension ViewGraph {
    internal func viewDebugData() -> [_ViewDebug.Data] {
        let root = DGTreeElement(data.rootSubgraph.treeRoot)
        var data = [_ViewDebug.Data]()
        _ViewDebug.appendDebugData(from: root, to: &data)
        return data
    }
}

@available(iOS 13.0, *)
extension _UIHostingView {
    final internal func _viewDebugData() -> [_ViewDebug.Data] {
        viewGraph.viewDebugData()
    }
}

@available(iOS 13.0, *)
private enum ViewDebugTreeValueKey: String {
    
    case transform
    
    case position
    
    case size
    
    case environment
    
    case phase
    
    case layoutComputer
    
    case displayList
    
    case custom
}

@available(iOS 13.0, *)
extension DGSubgraphRef {
    
    @inline(__always)
    fileprivate static func addTreeValue<Value>(_ attribute: Attribute<Value>, forKey key: ViewDebugTreeValueKey) {
        addTreeValue(attribute, forKey: key.rawValue, flags: 0)
    }
}

extension DGAttribute {
    fileprivate func `as`<A>(_ type: A.Type) -> A {
        Attribute<A>(identifier: self).value
    }
}

#endif

@available(iOS 13.0, *)
extension View {
#if DEBUG || DANCE_UI_INHOUSE
    @_optimize(none)
    static private func _workaroundOpenExistential(inputs: _ViewInputs) -> _ViewInputs {
        var newInputs = inputs
        func project<T: ViewDebugResolving>(_ type: T.Type) {
            let factory = ViewDebugCustomValueFactory {
                type.viewDebugFlag.makeCustomValue($0)
            }
            newInputs.viewDebugCustomValue = OptionalAttribute(Attribute(value: factory))
        }
        
        if let type = Self.self as? any ViewDebugResolving.Type {
            _openExistential(type, do: project)
        }
        return newInputs
    }
#endif  
    @inline(__always)
    internal static func makeDebuggableView(value: _GraphValue<Self>,
                                            inputs: _ViewInputs) -> _ViewOutputs {
#if DEBUG || DANCE_UI_INHOUSE
        var newInputs = _ViewInputs(inputs)
        if DGSubgraphRef.shouldRecordTree {
            DGSubgraphRef.beginTreeElement(value: value.value, flags: 0)
        }
        
        var outputs = newInputs.performWithChangedDebugProperties(of: inputs) { inputs in
            _makeView(view: value, inputs: inputs)
        }
        
        if DGSubgraphRef.shouldRecordTree {
            newInputs = _workaroundOpenExistential(inputs: newInputs)
            _ViewDebug.reallyWrap(&outputs, value: value, inputs: &newInputs)
            DGSubgraphRef.endTreeElement(value: value.value)
        }
        
        return outputs
#else
        return _makeView(view: value, inputs: inputs)
#endif
    }

    @inline(__always)
    internal static func makeDebuggableViewList(value: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
#if DEBUG || DANCE_UI_INHOUSE
        defer {
            if DGSubgraphRef.shouldRecordTree {
                DGSubgraphRef.endTreeElement(value: value.value)
            }
        }
        if DGSubgraphRef.shouldRecordTree {
            DGSubgraphRef.beginTreeElement(value: value.value, flags: 1)
        }
#endif
        return Self._makeViewList(view: value, inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension _VariadicView_ViewRoot {
    
    @inline(__always)
    internal static func makeDebuggableView(value: _GraphValue<Self>,
                                            inputs: _ViewInputs,
                                            body: (_Graph, _ViewInputs) -> _ViewListOutputs) -> _ViewOutputs {
#if DEBUG || DANCE_UI_INHOUSE
        var newInputs = _ViewInputs(inputs)
        if DGSubgraphRef.shouldRecordTree {
            DGSubgraphRef.beginTreeElement(value: value.value, flags: 0)
        }
        
        var outputs = newInputs.performWithChangedDebugProperties(of: inputs) { inputs in
            _makeView(root: value, inputs: inputs, body: body)
        }
        
        func project<T: ViewDebugResolving>(_ type: T.Type) {
            let factory = ViewDebugCustomValueFactory {
                type.viewDebugFlag.makeCustomValue($0)
            }
            newInputs.viewDebugCustomValue = OptionalAttribute(Attribute(value: factory))
        }
        
        if DGSubgraphRef.shouldRecordTree {
            if let type = Self.self as? any ViewDebugResolving.Type {
                _openExistential(type, do: project)
            }
            _ViewDebug.reallyWrap(&outputs, value: value, inputs: &newInputs)
            DGSubgraphRef.endTreeElement(value: value.value)
        }
        
        return outputs
#else
        return _makeView(root: value, inputs: inputs, body: body)
#endif
    }
}

@available(iOS 13.0, *)
extension ViewModifier {
    
    @inline(__always)
    internal static func makeDebuggableViewModifier(value: _GraphValue<Self>,
                                                    inputs: _ViewInputs,
                                                    body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
#if DEBUG || DANCE_UI_INHOUSE
    var childViewInputs = _ViewInputs(inputs)
    
    if DGSubgraphRef.shouldRecordTree {
        DGSubgraphRef.beginTreeElement(value: value.value, flags: 0)
    }
    
    var outputs = childViewInputs.performWithChangedDebugProperties(of: inputs) { inputs in
        _makeView(modifier: value, inputs: inputs, body: body)
    }
    
    func project<T: ViewDebugResolving>(_ type: T.Type) {
        let factory = ViewDebugCustomValueFactory {
            type.viewDebugFlag.makeCustomValue($0)
        }
        childViewInputs.viewDebugCustomValue = OptionalAttribute(Attribute(value: factory))
    }
    
    if DGSubgraphRef.shouldRecordTree {
        if let type = Self.self as? any ViewDebugResolving.Type {
            _openExistential(type, do: project)
        }
        _ViewDebug.reallyWrap(&outputs, value: value, inputs: &childViewInputs)
        DGSubgraphRef.endTreeElement(value: value.value)
    }
    
    return outputs
#else
    return _makeView(modifier: value, inputs: inputs, body: body)
#endif
    }
    
    @inline(__always)
    internal static func makeDebuggableViewList(value: _GraphValue<Self>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
#if DEBUG || DANCE_UI_INHOUSE
        defer {
            if DGSubgraphRef.shouldRecordTree {
                DGSubgraphRef.endTreeElement(value: value.value)
            }
        }
        if DGSubgraphRef.shouldRecordTree {
            DGSubgraphRef.beginTreeElement(value: value.value, flags: 1)
        }
#endif
        return Self._makeViewList(modifier: value, inputs: inputs, body: body)
    }
}
