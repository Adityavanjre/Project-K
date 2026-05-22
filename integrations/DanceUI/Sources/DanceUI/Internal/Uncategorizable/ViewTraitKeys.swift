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
internal struct ViewTraitKeys {
    internal var types: Set<ObjectIdentifier>

    internal var isDataDependent: Bool
    
    internal init() {
        types = []
        isDataDependent = false
    }
    
    internal mutating func insert<A: _ViewTraitKey>(_ type: A.Type) {
        types.insert(ObjectIdentifier(type))
    }
    
    internal func contains<A: _ViewTraitKey>(_ type: A.Type) -> Bool {
        types.contains(ObjectIdentifier(type))
    }
}

@usableFromInline
@available(iOS 13.0, *)
internal struct TagValueTraitKey<ValueType>: _ViewTraitKey {
    
    @inlinable
    internal static var defaultValue: Value {
        .untagged
    }
    
    @usableFromInline
    @frozen
    internal enum Value {
        case tagged(ValueType)
        case untagged
    }
    
}

