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
internal final class UIKitToolbarCoordinator: NSObject {
    
    internal struct Entry {

        internal var item: ToolbarStorage.Item

        internal var isPlaced: Bool

    }

    internal var targets: [UIBarItemTarget]

    internal var hasUpdatesBasedOnEnvironment: Bool

    internal var lastEnvironment: EnvironmentValues

    internal var previousSeed: VersionSeed

    internal var entries: [Entry]
    
    internal override init() {
        targets = []
        hasUpdatesBasedOnEnvironment = false
        lastEnvironment = EnvironmentValues()
        previousSeed = .invalid
        entries = []
        super.init()
    }
    
    internal func update(in environmentValues: EnvironmentValues) {
        #warning("_notImplemented()")
//        _notImplemented()
    }
    
    internal func updateIfNeeded(storage: PreferenceList.Value<ToolbarStorage>) {
        #warning("_notImplemented()")
//        _notImplemented()
    }
    
    @inlinable
    internal func placeItems(checkReplace: (Entry, inout Bool) -> Bool) -> [ToolbarStorage.Item] {
        var placedItems: [ToolbarStorage.Item] = []
        
        var shouldContinue = true
        for (index, entry) in entries.enumerated() {
            let canReplace = checkReplace(entry, &shouldContinue)
            if !canReplace {
                continue
            }
            
            entries[index].isPlaced = true
            placedItems.append(entry.item)
            
            if !shouldContinue {
                break
            }
        }
        return placedItems
    }

}

@available(iOS 13.0, *)
internal final class UIBarItemTarget {

    internal weak var uiBarItem: UIBarButtonItem?

    internal var host: UIItemHostingView<ModifiedContent<_ViewList_View, _FixedSizeLayout>>

    internal var action: () -> Void
    
    internal init(host: UIItemHostingView<ModifiedContent<_ViewList_View, _FixedSizeLayout>>, _ action: @escaping () -> Void) {
        // TODO: _notImplemented
        self.host = host
        self.action = action
    }

}
