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

#if DEBUG || DANCE_UI_INHOUSE

@propertyWrapper
@available(iOS 13.0, *)
internal struct ProxyCodable<Content>: Equatable where Content: CodableByProxy {
    
    internal var wrappedValue: Content
}

@available(iOS 13.0, *)
extension ProxyCodable: Encodable {
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.codingProxy)
    }
    
}

#else

@propertyWrapper
@available(iOS 13.0, *)
internal struct ProxyCodable<Content: Equatable>: Equatable {
    
    internal var wrappedValue: Content
}

#endif
