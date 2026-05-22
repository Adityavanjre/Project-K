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

@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct ABSettings<Value> : DynamicProperty {
    
    public var wrappedValue: Value {
        store.getValue()
    }
    
    @usableFromInline
    internal var store: Store
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer,
                                                container: _GraphValue<Container>,
                                                fieldOffset: Int,
                                                name: String?,
                                                inputs: inout _GraphInputs) {
        let signal = WeakAttribute(Attribute(value: Void()))
        let box = ABSettingsPropertyBox<Value>(host: .currentHost, signal: signal)
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
    @usableFromInline
    internal final class Store {
        
        internal let key: String
        
        internal let getter: () -> Value
        
        fileprivate var cachedValue: Value?
            
        internal var wasRead: Bool
        
        internal var changeSignal: WeakAttribute<Void>?
        
        fileprivate init(key: String, _ getter: @escaping () -> Value) {
            self.key = key
            self.cachedValue = nil
            self.wasRead = false
            self.changeSignal = nil
            self.getter = getter
        }
        
        internal func getValue() -> Value {
            if GraphHost.isUpdating {
                wasRead = true
            }
            
            let value: Value
            
            if let cachedValue = cachedValue {
                value = cachedValue
            } else {
                value = getter()
            }
            
            if cachedValue == nil {
                cachedValue = value
            }
            
            return value
        }
    }
}

@available(iOS 13.0, *)
public protocol ABSettingsValueTransform {
    
    associatedtype Key: SettingsKey
    
    associatedtype Value

    static func transform(input: Key.Value) -> Value
}

@available(iOS 13.0, *)
extension ABSettings {
    
    public init<K: SettingsKey>(_ key: K.Type) where Value == K.Value {
        self.store = Store(key: K.key) {
            ABSettingsService.impl?.value(key: K.self) ?? K.defaultValue
        }
    }
    
    public init<T: ABSettingsValueTransform>(_ transform: T.Type) where Value == T.Value {
        self.store = Store(key: T.Key.key) {
            let inputValue = ABSettingsService.impl?.value(key: T.Key.self) ?? T.Key.defaultValue
            return T.transform(input: inputValue)
        }
    }
    
    internal init(_ key: String, defaultValue: Value) where Value: SettingsValue {
        self.store = Store(key: key) {
            ABSettingsService.impl?.value(key: key, defaultValue: defaultValue) ?? defaultValue
        }
    }
}

@available(iOS 13.0, *)
private final class ABSettingsServiceObserver: NSObject {
    
    private enum State {
        
        case subscribed(key: String)
        
        case uninitialized
    }
    
    private var state: ABSettingsServiceObserver.State
    
    private weak var host: GraphHost?
    
    fileprivate let signal: WeakAttribute<Void>
    

    fileprivate override init() {
        _unimplementedInitializer(className: "DanceUI.ABSettingsServiceObserver")
    }
    
    fileprivate init(host: GraphHost, signal: WeakAttribute<Void>) {
        self.state = .uninitialized
        self.signal = signal
        self.host = host
        super.init()
    }
    
    deinit {
        unobserve()
    }
    
    fileprivate func observeService(key: String) {
        switch state {
        case .uninitialized:
            break
        case .subscribed(let observedKey):
            if observedKey == key {
                return
            }
            unobserve()
            invalidateAttribute()
        }
        
        observe(key: key)
    }
    
    private func invalidateAttribute() {
        let host = self.host
        let signal = self.signal
        
        performOnMainThread {
            Update.ensure {
                host?.asyncTransaction(.current, mutation: InvalidatingGraphMutation(attribute: signal), style: .ignoresFlushWhenUpdating, mayDeferUpdate: false)
            }
        }
    }
    
    @objc
    private func settingsDidChange(_ notification: Notification) {
        guard case .subscribed(_) = state else {
            return
        }
        
        invalidateAttribute()
    }
    
    private func observe(key: String) {
        NotificationCenter.default.addObserver(self, selector: #selector(ABSettingsServiceObserver.settingsDidChange(_:)), name: ABSettingsService.didChangeNotification, object: nil)
        state = .subscribed(key: key)
    }
    
    fileprivate func unobserve() {
        NotificationCenter.default.removeObserver(self, name: ABSettingsService.didChangeNotification, object: nil)
        state = .uninitialized
    }
    
    fileprivate static var observationContext: Int = 0
    
}

@available(iOS 13.0, *)
private struct ABSettingsPropertyBox<Value>: DynamicPropertyBox {
    
    fileprivate typealias Property = ABSettings<Value>
    
    fileprivate let observer: ABSettingsServiceObserver
        
    fileprivate init(host: GraphHost, signal: WeakAttribute<Void>) {
        observer = ABSettingsServiceObserver(host: host, signal: signal)
    }
    
    fileprivate func destroy() {
        _intentionallyLeftBlank()
    }
    
    fileprivate mutating func reset() {
        observer.unobserve()
    }
    
    fileprivate mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
        observer.observeService(key: property.store.key)
        
        
        defer {
            property.store.changeSignal = observer.signal
        }

        guard let signal = observer.signal.attribute, signal.changedValue().changed else {
            return false
        }
        
        property.store.cachedValue = nil
        
        return property.store.wasRead
    }
    
}
