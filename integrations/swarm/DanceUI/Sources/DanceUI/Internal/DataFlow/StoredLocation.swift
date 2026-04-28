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

internal import Dispatch
internal import DanceUIGraph
internal import DanceUIRuntime

@available(iOS 13.0, *)
internal class StoredLocationBase<Value>: AnyLocation<Value>, Location {
    
    private struct LockedData {
        
        internal var currentValue: Value
        
        internal var savedValues: [Value]
        
        internal var cache: LocationProjectionCache = LocationProjectionCache()
        
    }
    
    @UnsafeLockedPointer
    private var data: LockedData
    
    internal var _wasRead: Bool
    
    internal init(initialValue: Value) {
        _wasRead = false
        data = LockedData(currentValue: initialValue, savedValues: [])
        super.init()
    }
    
    deinit {
        $data.destroy()
    }
    
    internal override func get() -> Value {
        data.currentValue
    }
    
    internal override func set(_ value: Value, transaction: Transaction) {
        let trace = Trace(module: .dataFlow, component: .state)
        
        guard !isUpdating else {
            runtimeIssue(type: .warning, "Modifying state during view update, this will cause undefined behavior.")
            return
        }
        
        let needsCommitMutation = $data.withMutableData { (data) -> Bool in
            guard !DGCompareValues(lhs: data.currentValue, rhs: value) else {
                return false
            }
            
            data.savedValues.append(data.currentValue)
            trace.emitEvent(subject: .storedLocationSavedValues, name: .did(.append))
            
            data.currentValue = value
            
            return true
        }
        
        guard needsCommitMutation else {
            return
        }
        
        let newTransaction = transaction.byOverriding(with: .current)
        
        performOnMainThread { [weak self] in
            guard let self = self else {
                return
            }
            
            trace.emitEvent(subject: .storedLocation, name: .will(.commitGraphMutation), StoredLocationBeginUpdateTraceMetadata())
            self.commit(transaction: newTransaction, mutation: BeginUpdate(box: self))
            trace.emitEvent(subject: .storedLocation, name: .did(.commitGraphMutation), StoredLocationBeginUpdateTraceMetadata())
        }
    }
    
    internal override var wasRead: Bool {
        get {
            _wasRead
        }
        set {
            _wasRead = newValue
        }
    }
    
    internal override func update() -> (Value, Bool) {
        (updateValue, true)
    }
    
    internal var updateValue: Value {
        $data.withMutableData { data in
            guard let firstSavedValue = data.savedValues.first else {
                return data.currentValue
            }
            return firstSavedValue
        }
    }
    
    fileprivate var isUpdating: Bool {
        _abstract(self)
    }

    fileprivate func beginUpdate() {
        let trace = Trace(module: .dataFlow, component: .state)
        
        trace.withIntervalTrace(subject: .storedLocationBeginUpdate, name: .access) {
            data.savedValues.removeFirst()
            trace.emitEvent(subject: .storedLocationSavedValues, name: .did(.removeFirst))
            notifyObservers()
        }
        trace.emitEvent(subject: .storedLocationBeginUpdate, name: .did(.access))
    }
    
    fileprivate func commit(transaction: Transaction, mutation: BeginUpdate) {
        _abstract(self)
    }

    fileprivate func notifyObservers() {
        _abstract(self)
    }
    
    fileprivate struct BeginUpdate: GraphMutation {

        internal weak var box: StoredLocationBase?

#if DEBUG || DANCE_UI_INHOUSE
        internal let file: StaticString

        internal let line: UInt

        internal let function: StaticString
        
        @inlinable
        internal init(box: StoredLocationBase?, file: StaticString = #fileID, line: UInt = #line, function: StaticString = #function) {
            self.box = box
            self.file = file
            self.line = line
            self.function = function
        }
#else
        @inlinable
        internal init(box: StoredLocationBase?) {
            self.box = box
        }
#endif
        
        internal func apply() {
            box?.beginUpdate()
        }
        
        internal func combine<T: GraphMutation>(with mutation: T) -> Bool {
            guard let another = mutation as? BeginUpdate,
                  let selfBox = box,
                  let anotherBox = another.box,
                  anotherBox === selfBox else {
                      return false
                  }
            
            selfBox.$data.withMutableData { data in
                _ = data.savedValues.removeLast()
            }
            
            Trace.emitEvent(module: .dataFlow, component: .state, subject: .storedLocationBeginUpdateCombine, name: .did(.combine))
            return true
        }
        
    }
    
    internal override func projecting<P>(_ projection: P) -> AnyLocation<P.Projected> where Value == P.Base, P : Projection {
        data.cache.reference(for: projection, on: self)
    }
}

@available(iOS 13.0, *)
internal final class StoredLocation<Value>: StoredLocationBase<Value> {
    
    internal weak var host: GraphHost?
    
    @WeakAttribute
    internal var signal: Void?
    
    internal override weak var _host: GraphHost? {
        host
    }
    
    @inlinable
    internal init(initialValue: Value,
                  host: GraphHost?,
                  signal: WeakAttribute<Void>) {
        self.host = host
        self._signal = signal
        super.init(initialValue: initialValue)
        Trace.emitEvent(module: .dataFlow, component: .state, subject: .storedLocation, name: .did(.create))
    }
    
    fileprivate override var isUpdating: Bool {
        host?.isUpdating ?? false
    }
    
    fileprivate override func notifyObservers() {
        let signalOrNil = $signal
        guard let signal = signalOrNil else {
            return
        }
        signal.invalidateValue()
        Trace.emitEvent(module: .dataFlow, component: .state, subject: .storedLocationSignal, name: .did(.invalidateValue), SignalAttributeInvalidateValueTraceMetadata(attribute: signal))
    }
    
    internal override func update() -> (Value, Bool) {
        guard let signal = $signal else {
            return super.update()
        }
        defer {
            Trace.emitEvent(module: .dataFlow, component: .state, subject: .storedLocation, name: .did(.update))
        }
        return (updateValue, signal.changedValue().changed)
    }
    
    fileprivate override func commit(transaction: Transaction, mutation: StoredLocationBase<Value>.BeginUpdate) {
        host?.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlush, mayDeferUpdate: true)
    }
    
}

@available(iOS 13.0, *)
private struct StoredLocationBeginUpdateTraceMetadata: GraphMutationTraceMetadata {
    
    fileprivate var name: String = "StoredLocationBase.BeginUpdate"
    
}
