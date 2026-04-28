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

#if DEBUG || DANCE_UI_INHOUSE

import Foundation

@available(iOS 13.0, *)
private typealias SerializedAttribute = _ViewDebug.Data.SerializedAttribute
@available(iOS 13.0, *)
private typealias SerializedProperty = _ViewDebug.Data.SerializedProperty

@available(iOS 13.0, *)
enum LookinConfiguration {
    
    fileprivate static var serializedTypeMap: [String: Decodable.Type] {
        ["CGSize": CGSize.self,
         "CGPoint": CGPoint.self,
         "CGRect": CGRect.self,
         "Int": Int.self,
         "Int8": Int8.self,
         "UInt8": UInt8.self,
         "UInt16": UInt16.self,
         "UInt32": UInt32.self,
         "Double": Double.self,
         "CGFloat": CGFloat.self,
         "Bool": Bool.self,
         "String": String.self,
        ]
    }
    
    private static var ignoreViewTypeMap: [String] {
        ["ModifiedContent", "_VariadicView.Tree", "_ViewModifier_Content"]
    }
    
    internal static func isValid(view: String) -> Bool {
        return ignoreViewTypeMap.reduce(into: true) { partialResult, type in
            if view.hasPrefix(type) {
                partialResult = false
            }
        }
    }
 
    fileprivate static var ignoreViewModifierTypeMap: [String] {
        ["_EnvironmentKey"]
    }
    
    internal static func isValid(viewModifier: String) -> Bool {
        return ignoreViewModifierTypeMap.reduce(into: true) { partialResult, type in
            if viewModifier.hasPrefix(type) {
                partialResult = false
            }
        }
    }
    
    fileprivate static func simplifyTitle(_ name: String) -> String {
        if name.hasSuffix("Modifier") {
            let regex = try! NSRegularExpression(pattern: "[A-Z]", options: [])
            let range = NSRange(location: 0, length: name.count)
            let modifiedString = regex.stringByReplacingMatches(in: name, options: [], range: range, withTemplate: " $0")
            
            return modifiedString.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "Modifier", with: "")
        }
        return name
    }
    
    fileprivate static func simplifyView(_ name: String) -> String {
        if name.contains("<"), let simplifyName = name.split(separator: "<").first?.description {
            return simplifyName
        }
        return name
    }
}

@available(iOS 13.0, *)
extension SerializedAttribute: Decodable {
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try? container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        readableType = try container.decode(String.self, forKey: .readableType)
        let flagsValue = try container.decode(Int.self, forKey: .flags)
        flags = .init(rawValue: flagsValue)
        subattributes = try container.decodeIfPresent([Self].self, forKey: .subattributes)
        func project<T: Decodable>(type: T.Type) {
            value = try? container.decode(type, forKey: .value)
        }
        if let valueType = LookinConfiguration.serializedTypeMap[readableType] {
            _openExistential(valueType, do: project)
        } else {
            value = try? container.decode(String.self, forKey: .value)
        }
    }
    
    internal func tranform() -> LookinProperties? {
        let key = name ?? ""
        if let value = value {
            return .init(key: key, desc: readableType, property: .value(value))
        }
        let keyValue = subattributes?.compactMap { attributes in
            attributes.tranform()
        } ?? []
        if !keyValue.isEmpty {
            return .init(key: key, desc: readableType, property: .keyValue(keyValue))
        }
        return nil
    }
}

@available(iOS 13.0, *)
extension SerializedProperty: Decodable {
    
    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(_ViewDebug.Property.self, forKey: .id)
        attribute = try container.decode(SerializedAttribute.self, forKey: .attribute)
    }
}

@available(iOS 13.0, *)
extension Array where Element == SerializedProperty {
    
    fileprivate var createLookinValue: LookinValue {
        
        var readableType = ""
        var isView = false
        var isViewModifier = false
        var size = CGSize.zero
        var position = CGPoint.zero
        var properties: [LookinProperties]? = nil
        
        forEach {
            switch $0.id {
            case .type:
                readableType = $0.attribute.readableType
                isView = $0.attribute.flags == .view
                isViewModifier = $0.attribute.flags == .viewModifier
            case .size:
                size = $0.attribute.value as! CGSize
            case .position:
                position = $0.attribute.value as! CGPoint
            case .value:
                properties = $0.attribute.subattributes?.compactMap {
                    $0.tranform()
                }
            default:
                break
            }
        }
        
        if isView, LookinConfiguration.isValid(view: readableType) {
            if let factory = LookinConfiguration.viewFactoryMap.first(where: { $0.isValid(readableType) }) {
                return .view(factory.makeLookinView(readableType, frame: CGRect(origin: position, size: size), properties: properties))
            }
            let title = LookinConfiguration.simplifyView(readableType)
            return .view(LookinView(title: title, frame: CGRect(origin: position, size: size), properties: properties))
        } else if isViewModifier, LookinConfiguration.isValid(viewModifier: readableType), let properties = properties {
            let modifierTitle = LookinConfiguration.simplifyTitle(readableType)
            return .viewModifier(LookinViewModifier(title: modifierTitle, properties: properties))
        } else {
            return .empty
        }
    }
    
}

@available(iOS 13.0, *)
internal struct LookinView {
    
    internal var title: String
    
    internal var frame: CGRect
    
    internal var properties: [LookinProperties]?
    
    internal var customProperties: [String: String]? {
        guard let properties = properties, let value = properties.json, !value.isEmpty, !properties.isEmpty else {
            return nil
        }
        return ["section": "View", "title": title, "value": value, "valueType": "json"]
    }
}

@available(iOS 13.0, *)
internal struct LookinViewModifier {

    internal var title: String
    
    internal var properties: [LookinProperties]
    
    internal var customProperties: [String: String]? {
        guard let value = properties.json, !value.isEmpty, !properties.isEmpty else {
            return nil
        }
        return ["section": "Modifier", "title": title, "value": value, "valueType": "json"]
    }
}

@available(iOS 13.0, *)
internal enum LookinValue {
    case empty
    case view(LookinView)
    case viewModifier(LookinViewModifier)
}

@available(iOS 13.0, *)
internal struct LookinProperties {
    
    internal var key: String
    
    internal var desc: String
    
    internal var property: LookinProperty
     
    internal indirect enum LookinProperty {
        case value(Any)
        case keyValue([LookinProperties])
        
    }

    internal var jsonValue: [String: Any]? {
        switch property {
        case .value(let value):
            if let serializedValue = Self.serialize(value) {
                return ["title": key, "desc": serializedValue]
            }
            return nil
        case .keyValue(let properties):
            let values = properties.compactMap {
                $0.jsonValue
            }
            return ["title": key, "details": values, "desc": desc]
        }
    }
    
    internal static func serialize(_ value: Any) -> String? {
        if let encodable = value as? Encodable {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(encodable) {
                return String(data: data, encoding: .utf8)
            }
        }
        if let description = (value as? CustomDebugStringConvertible)?.debugDescription {
            return description
        }
        if let style = Mirror(reflecting: value).displayStyle, style == .enum {
            return String(describing: value)
        }
        return nil
    }
}

@available(iOS 13.0, *)
extension Array where Element == LookinProperties {
    fileprivate var json: String? {
        let jsonValue = reduce(into: [[String: Any]]()) { result, properties in
            if let value = properties.jsonValue {
                result.append(value)
            }
        }
        guard let theJSONData = try? JSONSerialization.data(withJSONObject: jsonValue, options: []) else {
            return nil
        }
        return String(data: theJSONData, encoding: .utf8)
    }
}

@available(iOS 13.0, *)
internal struct LookinDebugData: Decodable {
    internal var value: LookinValue
    internal var children: [LookinDebugData]
    
    private enum CodingKeys: CodingKey, Hashable {
        case properties
        case children
    }

    internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serializedProperties = try container.decode([SerializedProperty].self, forKey: .properties)
        value = serializedProperties.createLookinValue
        children = try container.decode([LookinDebugData].self, forKey: .children)
    }
    
    internal var customProperties: [[String: String]] {
        switch value {
        case .empty:
            return []
        case .view(let lookinView):
            return lookinView.customProperties.map { [$0] } ?? []
        case .viewModifier(let lookinViewModifier):
            return lookinViewModifier.customProperties.map { [$0] } ?? []
        }
    }

    internal func customSubviews(_ tranform: ViewTransform) -> [String: Any] {
        switch value {
        case .view(let lookinView):
            var frame = lookinView.frame
            if !frame.isEmpty {
                frame.origin.convert(to: .global, transform: tranform)
            }
            return ["title": lookinView.title, "frameInWindow": frame]
        default:
            return [:]
        }
    }
}

#endif
