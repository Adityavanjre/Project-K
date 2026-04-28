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

import UIKit
internal import DanceUIGraph

@available(iOS 13.0, *)
internal protocol FocusBridgeProvider {
    
    var focusBridge: FocusBridge { get }
    
}

@available(iOS 13.0, *)
internal final class FocusBridge {

    internal var flags: Flags

    internal weak var host: (UIView & FocusBridgeProvider & ViewRendererHost)?

    internal var currentFocusStore: FocusStore {
        didSet {
            host!.invalidateProperties(.focusStore, mayDeferUpdate: true)
        }
    }

    internal var currentEnvironment: EnvironmentValues

    internal var _focusedItem: FocusItem? {
        didSet {
            didChangeFocusItem(from: oldValue, to: _focusedItem)
        }
    }
    
    internal weak var parentFocusBridge: FocusBridge?

    internal var requestedFocusItem: UIFocusItem?

    internal var defaultFocusNamespace: Namespace.ID?
    
    @inlinable
    internal init() {
        flags = Flags()
        host = nil
        currentFocusStore = FocusStore()
        currentEnvironment = EnvironmentValues()
        _focusedItem = nil
        parentFocusBridge = nil
        requestedFocusItem = nil
        defaultFocusNamespace = nil
    }
    
    @inlinable
    internal var evaluatesDefaultFocus: Bool {
        get {
            flags.contains(.evaluatesDefaultFocus)
        }
        set {
            if newValue {
                flags.insert(.evaluatesDefaultFocus)
            } else {
                flags.remove(.evaluatesDefaultFocus)
            }
        }
    }
    
    @inlinable
    internal var shouldEvaluateDefaultFocus: Bool {
        guard !evaluatesDefaultFocus else {
            return true
        }
        return host!.window?.my_firstResponder == nil
    }
    
    internal func moveFocus(to item: FocusItem, designatedPlatformResponder: UIView?) {

        let focusedItem = focusedItem
        
        guard FocusItem.isFocusChanged(from: focusedItem, to: item) else {
            return
        }
        
        if focusedItem == nil,
           let parentFocusBridge = parentFocusBridge,
           let represented = FocusBridge.representedFocusItem(item, in: host!) {
            let item = FocusItem(item: represented, responder: nil)
            parentFocusBridge.moveFocus(to: item, designatedPlatformResponder: nil)
            return
        }
        
        guard canTakeFocus else {
            return
        }
        
        let focusablePlatformResponder = item.platformResponder != nil && item.isFocusable ? item.platformResponder : nil
        
        let platformResponderOrNil: UIResponder?
        
        if item.viewItem != nil {
            _focusedItem = updatedFocusItem(item)
            platformResponderOrNil = designatedPlatformResponder ?? host
        } else {
            platformResponderOrNil = focusablePlatformResponder
        }
        
        if let platformResponder = platformResponderOrNil {
            Update.enqueueAction {
                platformResponder.becomeFirstResponder()
            }
        } else if #available(iOS 11.0, *) {
            guard let platformItem = item.platformItem else {
                return
            }
            
            requestedFocusItem = platformItem
            host!.setNeedsFocusUpdate()
            platformItem.platformFocusSystem?.my_requestFocusUpdate(to: host!)
        }
    }
    
    internal var canTakeFocus: Bool {
        get {
            if hasHostingController {
                return flags.contains(.canTakeFocus)
            } else {
                return currentEnvironment.canTakeFocus
            }
        }
        set {
            if newValue {
                flags.insert(.canTakeFocus)
            } else {
                flags.remove(.canTakeFocus)
            }
            
            guard hasHostingController else {
                return
            }
            host!.invalidateProperties(.environment, mayDeferUpdate: true)
        }
    }
    
    internal func dismissFocus(in namespace: Namespace.ID?) {
        host!.my_firstResponder?.resignFirstResponder()
    }
    
    private func updatedFocusItem(_ item: FocusItem?) -> FocusItem? {
        guard var updatedItem = item else {
            return nil
        }
        updatedItem.seed = .makeFocusSeed()
        return updatedItem
    }
    
    private func didChangeFocusItem(from fromItem: FocusItem?, to toItem: FocusItem?) {
        guard FocusItem.isFocusChanged(from: fromItem, to: toItem) else {
            return
        }
        fromItem?.focusDidChange(isFocused: false)
        toItem?.focusDidChange(isFocused: true)
        host!.invalidateProperties(.focusedItem, mayDeferUpdate: true)
    }
    
    internal func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
    }
    
    internal var preferredFocusEnvironments: [UIFocusEnvironment] {
        return []
    }
    
    internal var focusedItem : FocusItem? {
        if let item = _focusedItem {
            if item.isExpired {
                _focusedItem = nil
            }
        }
        return _focusedItem
    }
    
    internal func addPreferences() {
        guard let host = host else {
            return
        }
        
        host.viewGraph.addPreference(FocusedValueList.Key.self)
        
        host.viewGraph.addPreference(FocusStoreList.Key.self)

    }
    
    internal func removePreferences() {
        guard let host = host else {
            return
        }
        
        host.viewGraph.removePreference(FocusedValueList.Key.self)
        
        host.viewGraph.removePreference(FocusStoreList.Key.self)

    }
    
    internal func focusDidChange(rootResponder: ResponderNode?) {
        host!.setNeedsFocusUpdate()
        focusDidChange_PhoneWatch(rootResponder: rootResponder)
    }
    
    internal var focusedResponder: ResponderNode? {
        focusedItem?.responder
    }
    
    internal func updateEnvironment(_ environment: inout EnvironmentValues) {
        parentFocusBridge = environment.focusBridge
        environment.focusBridge = self
        
        if #available(iOS 11.0, *) {
            if !environment.isFocused {
                environment.isFocused = isHostContainedInFocusedItem
            }
            
            if let window = host!.window {
                environment.isPlatformFocusSystemEnabled = window.platformFocusSystem != nil
            }
        }
        
        if hasHostingController {
            environment.canTakeFocus = canTakeFocus
        }
        
        if environment.preferenceBridge == nil {
            addPreferences()
        } else {
            removePreferences()
        }
        
        currentEnvironment = environment
    }
    
    @inlinable
    internal func effectiveFocusedView(for responder: UIResponder?) -> UIView? {
        responder as? UIView
    }
    
    @inlinable
    internal var hasHostingController : Bool {
        host!.uiViewController != nil
    }
    
    internal var acceptsFirstResponder : Bool {
        guard canTakeFocus else {
            return false
        }
        
        var acceptsFirstResponder = false
        
        host!.responderNode?.visitFocusResponders { responder in
            guard responder.focusItem?.isFocusable == true else {
                return .continue
            }
            acceptsFirstResponder = true
            return .stop
        }
        
        return acceptsFirstResponder
    }
    
    internal func firstResponderDidChange(to responder: UIResponder?, rootResponder: ResponderNode?) {
        guard let effectiveFocusedView = self.effectiveFocusedView(for: responder) else {
            _focusedItem = updatedFocusItem(nil)
            return
        }
        
        let responder = platformResponder(for: focusedItem)
        
        guard effectiveFocusedView !== responder else {
            return
        }
        
        let effectivePlatformResponder = effectiveFocusedView.platformViewResponder
        
        var focusedItem: FocusItem?
        
        if let rootResponder = rootResponder {
            rootResponder.visitFocusResponders { responder in
                guard let responderFocusItem = responder.focusItem else {
                    return .continue
                }
                
                if responderFocusItem.isFocusable,
                   let platformResponder = responderFocusItem.platformResponder ?? self.host,
                   platformResponder === effectiveFocusedView {
                    focusedItem = responderFocusItem
                    return .stop
                } else if let responderPlatformResponder = responderFocusItem.platformResponder,
                          effectivePlatformResponder?.isDescendant(of: responderPlatformResponder) == true {
                    focusedItem = FocusItem(platformResponder: effectiveFocusedView, responder: responder)
                    return .stop
                } else {
                    return .continue
                }
            }
        }
        
        _focusedItem = updatedFocusItem(focusedItem)
    }
    
    internal func focusDidChange_PhoneWatch(rootResponder: ResponderNode?) {
        guard canTakeFocus else {
        return
        }
        
        var respondingFocusedItem: FocusItem?
        
        rootResponder?.visitFocusResponders { focusResponder in
            let focusedItem = focusResponder.focusItem
            if focusedItem?.platformResponder?.isFirstResponder == true {
                respondingFocusedItem = focusedItem
                return .stop
            }
            return .continue
        }
        
        let oldItem = self.focusedItem
        
        _focusedItem = updatedFocusItem(respondingFocusedItem ?? oldItem)
        
        if let focusedItem = self.focusedItem {
            platformResponder(for: focusedItem)?.becomeFirstResponder()
        } else {
            platformResponder(for: oldItem)?.resignFirstResponder()
        }
    }
    
    internal func hostDidBecomeFirstResponder(in namespace: Namespace.ID?) {
        if shouldEvaluateDefaultFocus {
            _ = host!.responderNode
        }
        
        guard let focusedItem = focusedItem else {
            return
        }
        
        moveFocus(to: focusedItem, designatedPlatformResponder: nil)
    }
    
    @inlinable
    internal var isHostContainedInFocusedItem : Bool {
        guard let item = host!.platformFocusSystem?.my_focusedItem else {
            return false
        }
        return item.contains(host!)
    }
    
    private func prepareForFocusPhase0IfNeeded() {
        // We needs to put setting `canTakeFocus` in
        // `hostingControllerWillAppear` to ensure `View.onAppear` works on
        // transitions from UIKit view-controller to DanceUI's
        // `UIHostingController`.
        guard !canTakeFocus else {
        return
        }
        
        canTakeFocus = true
    }
    
    private func prepareForFocusPhase1() {
        if focusedItem == nil {
            evaluatesDefaultFocus = true
        }
        
        hostDidBecomeFirstResponder(in: nil)
        
        evaluatesDefaultFocus = false
    }
    
    private func discardForFocusIfNeeded() {
        guard canTakeFocus else {
            return
        }
        
        canTakeFocus = false
        
        platformResponder(for: focusedItem)?.resignFirstResponder()
    }
    
    internal func hostingControllerWillAppear() {
        prepareForFocusPhase0IfNeeded()
    }
    
    internal func hostingControllerDidAppear() {
        prepareForFocusPhase1()
    }
    
    internal func hostingControllerWillDisappear() {
        discardForFocusIfNeeded()
    }
    
    internal func preferencesDidChange(_ preferenceList: PreferenceList) {
        let storeList = preferenceList[FocusStoreList.Key.self]
        if storeList.value.version != currentFocusStore.version {
            _ = host!.responderNode
            currentFocusStore = FocusStore.make(list: storeList.value)
        }
        
        let valueList = preferenceList[FocusedValueList.Key.self]
        
        if host!.focusedValues.version != valueList.value.version {
            let newFocusedValues = FocusedValues(valueList.value)
            // newVersion would be used with AppGraph
            // let newVersion = newFocusedValues.version
            host!.focusedValues = newFocusedValues
            if !host!.isRootHost {
            }
        }

    }
    
    @inline(__always)
    private func platformResponder(for item: FocusItem?) -> UIView? {
        return item?.platformResponder ?? host!
    }
    
    internal static func representedFocusItem(_ item: FocusItem, in host: UIView & ViewRendererHost) -> UIFocusItem? {
        return nil
    }
    
    fileprivate static var nextSeedValue : UInt32 = 1

    internal struct Flags: OptionSet {

        internal var rawValue: Int
        
        /// When a FocusBridge has no `focusedItem` set, it should evaluates
        /// default focus.
        internal static let evaluatesDefaultFocus = Flags(rawValue: 0x1)
        
        internal static let canTakeFocus = Flags(rawValue: 0x2)

    }
    
}

@available(iOS 13.0, *)
extension VersionSeed {
    
    @inline(__always)
    fileprivate static func makeFocusSeed() -> VersionSeed {
        defer {
            FocusBridge.nextSeedValue &+= 1
        }
        return VersionSeed(value: FocusBridge.nextSeedValue)
    }
    
}

@available(iOS 13.0, *)
extension FocusStore {
    
    @inline(__always)
    fileprivate static func make(list: FocusStoreList) -> FocusStore {
        var store = FocusStore()
        store.makeStoreContent(list)
        return store
    }
    
    fileprivate mutating func makeStoreContent(_ list: FocusStoreList) {
        version = list.version
        list.forEachItem { eachItem in
            var plist = plist(forObjectID: eachItem.propertyID) ?? PropertyList()
            eachItem.storeUpdateAction.update(&plist)
            setPlist(plist, forObjectID: eachItem.propertyID)
            
            if eachItem.isFocused {
                focusedResponders.append(eachItem.responder)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension UIFocusEnvironment {
    
    @inline(__always)
    internal var platformFocusSystem: UIFocusSystem? {
        if #available(iOS 15.0, *) {
            return UIFocusSystem.focusSystem(for: self)
        } else if #available(iOS 12.0, *) {
            return UIFocusSystem(for: self)
        } else {
            // iOS versions that lower than iOS 12.0 cannot initialize
            // UIFocusSystem from public API.
            return UIFocusSystem.my_focusSystem(for: self)
        }
    }
    
}
