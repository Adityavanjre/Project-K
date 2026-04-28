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
@_spi(DanceUICompose) import DanceUI

@available(iOS 13, *)
class ComposeDisplayListIdentityContainer {
    typealias Value = DisplayList.Identity
    
    @ValueBuilder
    private var builder: Value
    
    init(root: DisplayList.Identity = .make()) {
        let id = Signpost.compose.tracePoiBegin("IentityContainer:init", [])
        _builder = ValueBuilder(initialValue: root, factory: {
            .make()
        })
        Signpost.compose.tracePoiEnd(id: id, "IentityContainer:init", [])
    }
    
    var value: Value {
        builder
    }
    
    func getValue(forReading: Bool) -> Value {
        Signpost.compose.tracePoi("IentityContainer:getValue", []) {
            _builder.getValue(forReading: forReading)
        }
        
    }
    
    func reset() {
        Signpost.compose.tracePoi("IentityContainer:rest", []) {
            _builder.reset()
        }
    }
    
    func resetIndex() {
        Signpost.compose.tracePoi("IentityContainer:getValue", []) {
            _builder.resetIndex()
        }
    }
}

@available(iOS 13, *)
@propertyWrapper
private struct ValueBuilder<Value> {
    init(initialValue: Value, factory: @escaping () -> Value) {
        self.initialValue = initialValue
        self.factory = factory
        self.storage = Storage(initialValue: initialValue)
    }
    
    private var initialValue: Value
    private let factory: () -> Value
    
    private let storage: Storage
    
    private class Storage {
        var initialValue: Value
        var index: Int
        var children: [Value]
        
        init(initialValue: Value, index: Int = -1, children: [Value] = []) {
            self.initialValue = initialValue
            self.index = index
            self.children = children
        }
        
        func reset() {
            resetIndex()
            children.removeAll(keepingCapacity: true)
        }
        
        func resetIndex() {
            index = -1
        }
    }

    @inline(__always)
    private var index: Int? {
        get {
            storage.index < 1 ? nil : storage.index &- 1
        }
        nonmutating set {
            if let newValue {
                storage.index = newValue &+ 1
            } else {
                storage.index = -1
            }
        }
    }
    
    var wrappedValue: Value {
        getValue(forReading: false)
    }
    
    func getValue(forReading: Bool) -> Value {
        if !forReading {
            storage.index += 1
        }
        if let index {
            if index < storage.children.count {
                return storage.children[index]
            } else if index == storage.children.count {
                let value = factory()
                storage.children.append(value)
                return value
            } else {
//                runtimeIssue(type: .error, "Should not be reachable")
                return initialValue
            }
        } else {
            return initialValue
        }
    }
    
    func reset() {
        storage.initialValue = factory()
        storage.reset()
    }
    
    func resetIndex() {
        storage.resetIndex()
    }
}

