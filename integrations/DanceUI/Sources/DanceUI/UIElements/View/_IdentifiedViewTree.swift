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

@available(iOS 13.0, *)
public enum _IdentifiedViewTree {

    case proxy(_IdentifiedViewProxy)

    case array([_IdentifiedViewTree])

    case empty
    
    public func forEach(_ body: (_IdentifiedViewProxy) -> ()) {
        switch self {
        case let .proxy(proxy):
            body(proxy)
            break
        case let .array(trees):
            for tree in trees {
                if case .empty = tree {
                    continue
                }
                tree.forEach(body)
            }
            break
        case .empty:
            break
        }
    }
}

@available(iOS 13.0, *)
internal struct _IdentifiedViewsKey: PreferenceKey, HostPreferenceKey {
    internal typealias Value = _IdentifiedViewTree
    
    internal static var defaultValue: _IdentifiedViewTree {
        .empty
    }
    
    internal static func reduce(value: inout Value, nextValue: () -> Value) {
        
        let newValue = nextValue()
        
        switch (value, newValue) {
        case (_, .empty):
            break
        case (.empty, _):
            value = newValue
        case let (.proxy(oldProxy), .proxy(newProxy)):
            value = .array([.proxy(oldProxy)] + [.proxy(newProxy)])
        case let (.array(oldArray), .proxy(newProxy)):
            value = .array(oldArray + [.proxy(newProxy)])
        case let (.proxy(oldProxy), .array(newArray)):
            value = .array([.proxy(oldProxy)] + newArray)
        case let (.array(oldArray), .array(newArray)):
            value = .array(oldArray + newArray)
        }
    }
    
    internal static var _includesRemovedValues: Bool {
        _isReadableByHost
    }
}
