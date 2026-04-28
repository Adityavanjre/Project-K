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
extension DisplayList: Encodable {
    
    fileprivate enum CodingKeys: CodingKey, Hashable {
        case items
        case features
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(features.rawValue, forKey: .features)
    }
}

@available(iOS 13.0, *)
extension DisplayList.Item: Encodable {
    
    private enum CodingKeys: CodingKey, Hashable {

        case kind

        case value

        case frame

        case identity

        case list
    }
    
    private enum CodingKind: UInt8 {
        
        case empty
        
        case content
        
        case effect
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frame.codable, forKey: .frame)
        try container.encode(identity, forKey: .identity)
        switch value {
        case .content(let content):
            try container.encode(content, forKey: .value)
            try container.encode(CodingKind.content.rawValue, forKey: .kind)
        case .effect(let effect, let displayList):
            try container.encode(displayList, forKey: .list)
            try container.encode(CodingKind.effect.rawValue, forKey: .kind)
        case .empty:
            try container.encode(CodingKind.empty.rawValue, forKey: .kind)
        }
    }
}

#endif
