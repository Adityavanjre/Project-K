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
extension LookinConfiguration {
    internal static var viewFactoryMap: [LookinViewFactory.Type] {
        [StackViewFactory.self,
         TextFactory.self,
         ImageFactory.self]
    }
}

@available(iOS 13.0, *)
internal protocol LookinViewFactory {
    
    static func isValid(_ view: String) -> Bool
    
    static func makeLookinView(_ title: String, frame: CGRect, properties: [LookinProperties]?) -> LookinView
}

@available(iOS 13.0, *)
private struct StackViewFactory: LookinViewFactory {
    
    internal static func isValid(_ view: String) -> Bool {
        for title in ["VStack", "HStack", "ZStack"] {
            if view.hasPrefix(title) {
                return true
            }
        }
        return false
    }
    
    internal static func makeLookinView(_ title: String, frame: CGRect, properties: [LookinProperties]?) -> LookinView {
        var newTitle = ["VStack", "HStack", "ZStack"].reduce(into: "") { partialResult, stack in
            if title.hasPrefix(stack) {
                partialResult = stack
            }
        }
        
        if let alignment = properties?.value(for: "alignment") {
            newTitle.append(" - \(alignment)")
        }
        
        return LookinView(title: newTitle, frame: frame, properties: properties)
    }
}

@available(iOS 13.0, *)
private struct TextFactory: LookinViewFactory {
    
    internal static func isValid(_ view: String) -> Bool {
        view == "Text"
    }
    
    internal static func makeLookinView(_ title: String, frame: CGRect, properties: [LookinProperties]?) -> LookinView {
        var title = title
        if let text = properties?.value(for: "verbatim") {
            title.append(" - \(text)")
        }
        return LookinView(title: title, frame: frame, properties: properties)
    }
}

@available(iOS 13.0, *)
private struct ImageFactory: LookinViewFactory {
    
    internal static func isValid(_ view: String) -> Bool {
        view == "Image"
    }
    
    internal static func makeLookinView(_ title: String, frame: CGRect, properties: [LookinProperties]?) -> LookinView {
        var title = title
        if let name = properties?.value(for: "name") {
            title.append(" - \(name)")
        }
        return LookinView(title: title, frame: frame, properties: properties)
    }
}

@available(iOS 13.0, *)
extension Array where Element == LookinProperties {
    
    internal func value(for key: String) -> String? {
        var value: String? = nil
        self.forEach { lookinProperties in
            if let result = lookinProperties.value(for: key) {
                value = result
            }
        }
        return value
    }
}

@available(iOS 13.0, *)
extension LookinProperties {
    
    internal func value(for key: String) -> String? {
        switch property {
        case .value(let value):
            if self.key == key {
                return value as? String
            }
        case .keyValue(let properties):
            var value: String? = nil
            properties.forEach { lookinProperties in
                if let result = lookinProperties.value(for: key) {
                    value = result
                }
            }
            return value
        }
        return nil
    }
}

#endif
