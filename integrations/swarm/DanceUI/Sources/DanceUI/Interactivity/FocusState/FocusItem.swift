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
internal struct FocusItem: Equatable {

    private var base: Base

    internal weak var responder: FocusResponder?

    internal var seed: VersionSeed
    
    @inlinable
    internal init(item: UIFocusItem, responder: FocusResponder?) {
        self.base = .platformItem(WeakBox(item))
        self.responder = responder
        self.seed = .zero
    }
    
    @inlinable
    internal init(platformResponder: UIView, responder: FocusResponder?) {
        self.base = .platformResponder(WeakBox(platformResponder))
        self.responder = responder
        self.seed = .zero
    }
    
    internal var viewItem: ViewItem? {
        guard case .view(let item) = base else {
            return nil
        }
        
        return item
    }
    
    internal var viewID: ViewIdentity? {
        guard case .view(let item) = base else {
            return nil
        }
        
        return item.id
    }
    
    internal var platformItem: UIFocusItem? {
        guard case .platformItem(let box) = base else {
            return nil
        }
        
        return box.base
    }
    
    internal var platformResponder: UIView? {
        guard case .platformResponder(let box) = base else {
            return nil
        }
        
        return box.base
    }
    
    internal var isExpired: Bool {
        switch base {
        case .view: return false
        case .platformItem(let $box):
            return $box.base == nil
        case .platformResponder(let $box):
            return $box.base == nil
        }
    }
    
    internal var isFocusable: Bool {
        switch base {
        case .view(let item):
            return item.isFocusable
        case .platformItem(let $box):
            return $box.base?.canBecomeFocused ?? false
        case .platformResponder(let $box):
            return $box.base?.canBecomeFirstResponder ?? false
        }
    }
    
    internal func hasEqualIdentity(to item: FocusItem) -> Bool {
        switch (self.base, item.base) {
        case (.view(let selfItem), .view(let item)):
            return selfItem.id == item.id
        case (.platformItem(let selfItem), .platformItem(let item)):
            return selfItem.base === item.base
        case (.platformResponder(let selfItem), .platformResponder(let item)):
            return selfItem.base === item.base
        default:
            return false
        }
    }
    
    internal func focusDidChange(isFocused: Bool) {
        guard case .view(let item) = base else {
            return
        }
        
        item.onFocusChange(isFocused)
    }
    
    @inlinable
    internal static func == (lhs: FocusItem, rhs: FocusItem) -> Bool {
        false // Yes, it is.
    }
    
    internal static func isFocusChanged(from fromItem: FocusItem?, to toItem: FocusItem?) -> Bool {
        switch (fromItem, toItem) {
        case (.some(let fromItem), .some(let toItem)):
            return !fromItem.hasEqualIdentity(to: toItem)
        case (.some, .none), (.none, .some):
            return true
        case (.none, .none):
            return false
        }
    }
    
    internal enum Base {

        case view(ViewItem)

        case platformItem(WeakBox<UIFocusItem>)

        case platformResponder(WeakBox<UIView>)

    }

    internal struct ViewItem {

        internal var id: ViewIdentity

        internal var isFocusable: Bool

        internal var options: FocusableOptions

        internal var onFocusChange: (Bool) -> Void

    }

}

@available(iOS 13.0, *)
internal struct FocusableOptions: OptionSet {
    
    internal typealias RawValue = Int

    internal let rawValue: RawValue
    
    @inlinable
    internal init(rawValue: RawValue) {
        self.rawValue = rawValue
    }

}
