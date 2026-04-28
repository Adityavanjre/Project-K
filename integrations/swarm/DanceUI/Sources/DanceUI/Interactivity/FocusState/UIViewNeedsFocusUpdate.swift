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

internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct UIViewNeedsFocusUpdate<Provider: UIViewFocusableViewProvider>: StatefulRule {
    
    internal typealias Value = Void
    
    internal var provider: Provider

    @Attribute
    internal var focusedItem: FocusItem?

    internal var isFocusable: Bool
    
    internal init(provider: Provider,
                  focusedItem: Attribute<FocusItem?>,
                  isFocusable: Bool = false) {
        self.provider = provider
        self._focusedItem = focusedItem
        self.isFocusable = isFocusable
    }
    
    @inline(__always)
    private func shouldSetNeedsFocusUpdate(focusedItem: FocusItem?, shouldBeFocusable: Bool) -> Bool {
        if let focusedItem = focusedItem {
            if focusedItem.platformItem !== provider.focusableView {
                if let platformResponder = focusedItem.platformResponder,
                   provider.focusableView === platformResponder {
                    return !shouldBeFocusable
                }
            } else if !shouldBeFocusable {
                return true
            }
        } else if shouldBeFocusable {
            return true
        }
        
        return false
    }
    
    internal mutating func updateValue() {
        let (focusedItem, isFocusedItemChanged) = $focusedItem.changedValue()
        
        let wasFocusable = isFocusable
        let shouldBeFocusable = provider.isFocusable
        isFocusable = shouldBeFocusable
        
        guard shouldBeFocusable != wasFocusable || isFocusedItemChanged || !hasValue else {
            return
        }
        
        if shouldSetNeedsFocusUpdate(focusedItem: focusedItem, shouldBeFocusable: shouldBeFocusable) {
            ViewGraph.current.needsFocusUpdate = true
        }
    }
    
}

@available(iOS 13.0, *)
internal protocol UIViewFocusableViewProvider {

    var focusableView: UIView { get }

    var isFocusable: Bool { get }
    
}

@available(iOS 13.0, *)
extension UIViewFocusableViewProvider {
    
    internal var isFocusable: Bool {
        let view = focusableView
        
        if view.canBecomeFirstResponder {
            return true
        }
        
        if view.isFocused {
            return false
        }
        
        return view.canBecomeFocused
    }
}

