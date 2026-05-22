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

@available(iOS 13.0, *)
public protocol ViewDebugResolving {
    
    static var viewDebugFlag: ViewDebugFlag<Self> { get }
}

@available(iOS 13.0, *)
public enum ViewDebugFlag<Object: ViewDebugResolving> {
    case all
    case keyPath([PartialKeyPath<Object>])
}

#if DEBUG || DANCE_UI_INHOUSE

@available(iOS 13.0, *)
extension ViewDebugFlag {
    internal func makeCustomValue(_ object: Any) -> Any? {
        if let value = object as? Object {
            return CustomViewDebugData(value: value, flag: self)
        }
        return nil
    }
}

@available(iOS 13.0, *)
internal struct CustomViewDebugData<T: ViewDebugResolving>: CustomViewDebugReflectable {
    private let value: T
    private let flag: ViewDebugFlag<T>
    
    internal init(value: T, flag: ViewDebugFlag<T>) {
        self.value = value
        self.flag = flag
    }

    internal var customViewDebugMirror: Mirror? {
        switch flag {
        case .all:
            return Mirror(reflecting: value)
        case .keyPath(let array):
            let children: [(String?, Any)] = array.map { keyPath in
                if #available(iOS 16.4, *) {
                    if let customString = keyPath as? CustomDebugStringConvertible {
                        var key = customString.debugDescription
                        if let range = key.range(of: ".") {
                            key = String(key[range.upperBound...])
                        }
                        return (key, value[keyPath: keyPath])
                    }
                }
                return (keyPath._kvcKeyPathString, value[keyPath: keyPath])
            }
            return Mirror(value, children: children)
        }
    }
}

#endif
