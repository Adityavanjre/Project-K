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
internal struct ToolbarStorage {
    
    internal struct Item {
    
        internal var identifier: String?
    
        internal var placement: ToolbarItemPlacement.Role
    
        internal var showsByDefault: Bool
    
        internal var view: _ViewList_View
    
    }
    
    internal var identifier: String?
    
    internal var items: [Item]
    
}

@available(iOS 13.0, *)
internal struct ToolbarKey: HostPreferenceKey {

    internal typealias Value = ToolbarStorage
    
    internal static var defaultValue: ToolbarStorage {
        ToolbarStorage(identifier: nil, items: [])
    }
    
    internal static func reduce(value: inout ToolbarStorage, nextValue: () -> ToolbarStorage) {
        // TODO: _notImplemented
    }
}

