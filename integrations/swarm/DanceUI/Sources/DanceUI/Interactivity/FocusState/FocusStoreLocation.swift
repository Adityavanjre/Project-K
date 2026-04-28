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
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal final class FocusStoreLocation<Value: Hashable>: AnyLocation<Value> {
    
    internal var store: FocusStore

    internal private(set) weak var host: GraphHost?

    internal private(set) var resetValue: Value

    internal var focusSeed: VersionSeed

    internal private(set) var failedAssignment: (Value, VersionSeed)?

    internal private(set) var resolvedEntry: FocusStore.Entry<Value>?

    internal private(set) var resolvedVersion: DisplayList.Version

    private var _wasRead: Bool
    
    @inlinable
    internal var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }
    
    @inlinable
    internal init(host: GraphHost, resetValue: Value) {
        self.store = FocusStore()
        self.host = host
        self.resetValue = resetValue
        self.focusSeed = .zero
        self.failedAssignment = nil
        self.resolvedEntry = nil
        self.resolvedVersion = .zero
        self._wasRead = false
    }
    
    internal override var wasRead: Bool {
        get {
            _wasRead
        }
        set {
            _wasRead = newValue
        }
    }
    
    internal override weak var _host: GraphHost? {
        host
    }
    
    internal override func get() -> Value {
        getValue(forReading: false)
    }
    
    internal func getValue(forReading isReading: Bool) -> Value {
        if GraphHost.isUpdating && isReading {
            _wasRead = true
        }
        
        if  resolvedEntry == nil || resolvedVersion != store.version {
            resolvedEntry = findFocusedEntry()
            resolvedVersion = store.version
        }
        
        return resolvedEntry?.prototype ?? resetValue
    }
    
    internal override func set(_ value: Value, transaction: Transaction) {
#if DEBUG || DANCE_UI_INHOUSE
        if !isMainThread {
            runtimeIssue(type: .error, "Modifying focus state from background threads is not allowed; make sure to modify focus state from the main thread (via operators like receive(on:)) on model updates.")
        }
#endif
        guard let host = host else {
            return
        }
        let resetValue = self.resetValue
        let mutation = CustomGraphMutation { [weak self] in
            guard let strongSelf = self else {
                return
            }
            if value == resetValue && strongSelf.getValue(forReading: false) != resetValue,
                let bridge = strongSelf.resolvedEntry?.bridge {
                bridge.dismissFocus(in: strongSelf.resolvedEntry?.focusScopes.last)
            } else {
                let entryOrNil = strongSelf.findEntry(with: value)
                if let entry = entryOrNil, let bridge = entry.bridge {
                    entry.responder.visitFocusResponders { focusResponder in
                        guard let item = focusResponder.focusItem else {
                            return .continue
                        }
                        bridge.moveFocus(to: item, designatedPlatformResponder: nil)
                        return .stop
                    }
                } else {
                    strongSelf.failedAssignment = (value, strongSelf.focusSeed)
                }
            }
        }
        host.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
    }
    
    internal override func update() -> (Value, Bool) {
        let oldValue = resolvedEntry?.prototype
        let value = get()
        let isEqual = DGCompareValues(lhs: oldValue, rhs: value)
        return (value, !isEqual)
    }
    
    internal func retryFailedAssignmentIfNecessary() {
        guard let (value, versionSeed) = failedAssignment else {
            return
        }
        
        guard versionSeed.isVaild && focusSeed.isVaild, focusSeed != versionSeed else {
            failedAssignment = nil
            return
        }
        
        set(value, transaction: .current)
    }
    
    private func findFocusedEntry() -> FocusStore.Entry<Value>? {
        if store.version == .zero {
            return nil
        }
        
        guard let plist = store.plist(forObject: self) else {
            return nil
        }
        
        var entry: FocusStore.Entry<Value>?
        
        plist.forEach(keyType: FocusStore.Key<Value>.self) { (valueOrNil, shouldStop) in
            guard let value = valueOrNil else {
                return
            }
            
            guard store.focusedResponders.contains(where: {$0 === value.responder}) else {
                return
            }
            
            entry = value
            shouldStop = true
        }
        
        return entry
    }
    
    private func findEntry(with value: Value) -> FocusStore.Entry<Value>? {
        if store.version == .zero {
            return nil
        }
        
        guard let plist = store.plist(forObject: self) else {
            return nil
        }
        
        var foundEntry: FocusStore.Entry<Value>?
        
        plist.forEach(keyType: FocusStore.Key<Value>.self) { (entryOrNil, shouldStop) in
            guard let entry = entryOrNil else {
                return
            }
            
            guard entry.prototype == value else {
                return
            }
            
            foundEntry = entry
            shouldStop = true
        }
        
        return foundEntry
    }
    
}
