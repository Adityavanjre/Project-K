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

/// A property wrapper type that reflects a value from `UserDefaults` and
/// invalidates a view on a change in value in that user default.
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct AppStorage<Value> : DynamicProperty {
    
    public var wrappedValue: Value {
        get {
            location.getValue(forReading: true)
        }
        nonmutating set {
            location.set(newValue, transaction: Transaction())
        }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(value: location.getValue(forReading: false),
                location: LocationBox(location))
    }
    
    @usableFromInline
    internal var location: UserDefaultLocation<Value>
    
    public static func _makeProperty<Container>(in buffer: inout _DynamicPropertyBuffer,
                                                container: _GraphValue<Container>,
                                                fieldOffset: Int,
                                                name: String?,
                                                inputs: inout _GraphInputs) {
        let signal = Attribute(value: Void())
#if DEBUG || DANCE_UI_INHOUSE
        signal.role = .signalForAppStroage
#endif
        let weakSignal = WeakAttribute(signal)
        let box = UserDefaultPropertyBox<Value>(host: .currentHost, environment: inputs.environment, signal: weakSignal)
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
    fileprivate init(key: String, transform: UserDefaultsValueTransform.Type, store: UserDefaults?, defaultValue: Value) {
        self.location = UserDefaultLocation(key: key, transform: transform, store: store, defaultValue: defaultValue)
    }
    
}

@available(iOS 13.0, *)
extension AppStorage {
    
    /// Creates a property that can read and write to a boolean user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a boolean value is not specified
    ///     for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Bool {
        self.init(key: key, transform: PropertyListTransform<Bool>.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to an integer user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if an integer value is not specified
    ///     for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Int {
        self.init(key: key, transform: PropertyListTransform<Int>.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to a double user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a double value is not specified
    ///     for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Double {
        self.init(key: key, transform: PropertyListTransform<Double>.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to a string user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a string value is not specified
    ///     for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == String {
        self.init(key: key, transform: StringTransform.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to a url user default.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a url value is not specified for
    ///     the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == URL {
        self.init(key: key, transform: URLTransform.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to a user default as data.
    ///
    /// Avoid storing large data blobs in user defaults, such as image data,
    /// as it can negatively affect performance of your app. On tvOS, a
    /// `NSUserDefaultsSizeLimitExceededNotification` notification is posted
    /// if the total user default size reaches 512kB.
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a data value is not specified for
    ///    the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value == Data {
        self.init(key: key, transform: PropertyListTransform<Data>.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to an integer user default,
    /// transforming that to `RawRepresentable` data type.
    ///
    /// A common usage is with enumerations:
    ///
    ///    enum MyEnum: Int {
    ///        case a
    ///        case b
    ///        case c
    ///    }
    ///    struct MyView: View {
    ///        @AppStorage("MyEnumValue") private var value = MyEnum.a
    ///        var body: some View { ... }
    ///    }
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if an integer value
    ///     is not specified for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == Int {
        self.init(key: key, transform: RawRepresentableTransform<Value>.self, store: store, defaultValue: wrappedValue)
    }
    
    /// Creates a property that can read and write to a string user default,
    /// transforming that to `RawRepresentable` data type.
    ///
    /// A common usage is with enumerations:
    ///
    ///    enum MyEnum: String {
    ///        case a
    ///        case b
    ///        case c
    ///    }
    ///    struct MyView: View {
    ///        @AppStorage("MyEnumValue") private var value = MyEnum.a
    ///        var body: some View { ... }
    ///    }
    ///
    /// - Parameters:
    ///   - wrappedValue: The default value if a string value
    ///     is not specified for the given key.
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(wrappedValue: Value, _ key: String, store: UserDefaults? = nil) where Value : RawRepresentable, Value.RawValue == String {
        self.init(key: key, transform: RawRepresentableTransform<Value>.self, store: store, defaultValue: wrappedValue)
    }
    
}

@available(iOS 13.0, *)
extension AppStorage where Value : ExpressibleByNilLiteral {
    
    /// Creates a property that can read and write an Optional boolean user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == Bool? {
        self.init(key: key, transform: PropertyListTransform<Bool>.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can read and write an Optional integer user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == Int? {
        self.init(key: key, transform: PropertyListTransform<Int>.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can read and write an Optional double user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == Double? {
        self.init(key: key, transform: PropertyListTransform<Double>.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can read and write an Optional string user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == String? {
        self.init(key: key, transform: PropertyListTransform<String>.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can read and write an Optional URL user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == URL? {
        self.init(key: key, transform: URLTransform.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can read and write an Optional data user
    /// default.
    ///
    /// Defaults to nil if there is no restored value.
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init(_ key: String, store: UserDefaults? = nil) where Value == Data? {
        self.init(key: key, transform: PropertyListTransform<Data>.self, store: store, defaultValue: nil)
    }
    
}

@available(iOS 13.0, *)
extension AppStorage {
    
    /// Creates a property that can save and restore an Optional string,
    /// transforming it to an Optional `RawRepresentable` data type.
    ///
    /// Defaults to nil if there is no restored value
    ///
    /// A common usage is with enumerations:
    ///
    ///     enum MyEnum: String {
    ///         case a
    ///         case b
    ///         case c
    ///     }
    ///     struct MyView: View {
    ///         @AppStorage("MyEnumValue") private var value: MyEnum?
    ///         var body: some View { ... }
    ///     }
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init<R>(_ key: String, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == String {
        self.init(key: key, transform: RawRepresentableTransform<R>.self, store: store, defaultValue: nil)
    }
    
    /// Creates a property that can save and restore an Optional integer,
    /// transforming it to an Optional `RawRepresentable` data type.
    ///
    /// Defaults to nil if there is no restored value
    ///
    /// A common usage is with enumerations:
    ///
    ///     enum MyEnum: Int {
    ///         case a
    ///         case b
    ///         case c
    ///     }
    ///     struct MyView: View {
    ///         @AppStorage("MyEnumValue") private var value: MyEnum?
    ///         var body: some View { ... }
    ///     }
    ///
    /// - Parameters:
    ///   - key: The key to read and write the value to in the user defaults
    ///     store.
    ///   - store: The user defaults store to read and write to. A value
    ///     of `nil` will use the user default store from the environment.
    public init<R>(_ key: String, store: UserDefaults? = nil) where Value == R?, R : RawRepresentable, R.RawValue == Int {
        self.init(key: key, transform: RawRepresentableTransform<R>.self, store: store, defaultValue: nil)
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// The default store used by `AppStorage` contained within the view.
    ///
    /// If unspecified, the default store for a view hierarchy is
    /// `UserDefaults.standard`, but can be set a to a custom one. For example,
    /// sharing defaults between an app and an extension can override the
    /// default store to one created with `UserDefaults.init(suiteName:_)`.
    ///
    /// - Parameter store: The user defaults to use as the default
    ///   store for `AppStorage`.
    public func defaultAppStorage(_ store: UserDefaults) -> some View {
        environment(\.defaultAppStorageDefaults, store)
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @usableFromInline
    internal var defaultAppStorageDefaults: UserDefaults {
        get {
            self[DefaultAppStorageDefaultsKey.self]
        }
        set {
            self[DefaultAppStorageDefaultsKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
fileprivate struct DefaultAppStorageDefaultsKey: EnvironmentKey {
    
    fileprivate typealias Value = UserDefaults
    
    fileprivate static var defaultValue: UserDefaults {
        .standard
    }
    
}

@available(iOS 13.0, *)
fileprivate protocol UserDefaultsValueTransform {

    static func readValue(from store: UserDefaults, key: String) -> Any?

    static func writeValue(_ value: Any?, to store: UserDefaults, key: String)

}


@usableFromInline
@available(iOS 13.0, *)
internal final class UserDefaultLocation<Value>: Location {

    internal let key: String

    fileprivate let transform: UserDefaultsValueTransform.Type

    internal let defaultValue: Value

    internal let customStore: Optional<UserDefaults>

    fileprivate var cachedValue: Value?

    fileprivate var defaultStore: UserDefaults

    internal var wasRead: Bool

    internal var changeSignal: WeakAttribute<Void>?

    internal var seed: Int
    
    internal var store: UserDefaults {
        customStore ?? defaultStore
    }
    
    fileprivate init(key: String,
                     transform: UserDefaultsValueTransform.Type,
                     store: UserDefaults?,
                     defaultValue: Value) {
        self.cachedValue = nil
        self.defaultStore = .standard
        self.wasRead = false
        self.changeSignal = nil
        self.seed = 0
        self.customStore = store
        self.key = key
        self.transform = transform
        self.defaultValue = defaultValue
    }
    
    internal func get() -> Value {
        getValue(forReading: false)
    }
    
    internal func set(_ value: Value, transaction: Transaction) {
#if DEBUG || DANCE_UI_INHOUSE

        if !isMainThread {
            runtimeIssue(type: .error, "Modifying AppStorage from background threads is not allowed; make sure to modify AppStorage from the main thread (via operators like receive(on:)) on model updates.")
        }

#endif
        

        if let oldValue = cachedValue,
           DGCompareValues(lhs: oldValue, rhs: value) {
            return
        }

        
        let overridenTransaction = transaction.byOverriding(with: .current)
        withTransaction(overridenTransaction) {
            cachedValue = value
            transform.writeValue(value, to: store, key: key)
        }
    }
    
    internal func update() -> (Value, Bool) {
        let isUpdated: Bool
        
        if let (_, isSignalChanged) = changeSignal?.attribute?.changedValue() {
            isUpdated = isSignalChanged
        } else {
            wasRead = true
            isUpdated = true
        }
        
        return (get(), isUpdated)
    }
    
    internal func getValue(forReading isReading: Bool) -> Value {
        if GraphHost.isUpdating && isReading {
            wasRead = true
        }
        
        let value: Value
        
        if let cachedValue = cachedValue {
            value = cachedValue
        } else if let readValue = transform.readValue(from: store, key: key) as? Value {
            value = readValue
        } else {
            value = defaultValue
        }
        
        if cachedValue == nil {
            cachedValue = value
        }
        
        return value
    }
    
    #if DEBUG
    internal static func makeTestable<T: TestableUserDefaultsValueTransformer>(key: String, transform: T.Type) -> UserDefaultLocation<String> {
        UserDefaultLocation<String>(key: key, transform: TestableTransformer<T, StringTransform>.self, store: nil, defaultValue: "")
    }
    #endif
    
}


#if DEBUG
@available(iOS 13.0, *)
internal protocol TestableUserDefaultsValueTransformer {
    
    static func readValue(from store: UserDefaults, key: String) -> Any?
    
    static func writeValue(_ value: Any?, to store: UserDefaults, key: String)
    
}

@available(iOS 13.0, *)
private final class TestableTransformer<T: TestableUserDefaultsValueTransformer, U: UserDefaultsValueTransform>: UserDefaultsValueTransform {

    // Unit test infrastructure
    fileprivate static func readValue(from store: UserDefaults, key: String) -> Any? {
        let _ = T.readValue(from: store, key: key)
        return U.readValue(from: store, key: key)
    }
    
    // Unit test infrastructure
    fileprivate static func writeValue(_ value: Any?, to store: UserDefaults, key: String) {
        T.writeValue(value, to: store, key: key)
        U.writeValue(value, to: store, key: key)
    }
    
}

#endif
@available(iOS 13.0, *)
private final class UserDefaultObserver: NSObject {
    
    fileprivate enum State {
        
        case subscribed(userDefaults: UserDefaults, key: String)
        
        case uninitialized
        
    }
    
    fileprivate var state: UserDefaultObserver.State

    fileprivate weak var host: GraphHost?

    fileprivate let signal: WeakAttribute<Void>

    fileprivate override init() {
        _unimplementedInitializer(className: "DanceUI.UserDefaultObserver")
    }
    
    fileprivate init(host: GraphHost, signal: WeakAttribute<Void>) {
        self.state = .uninitialized
        self.signal = signal
        self.host = host
        super.init()
    }
    
    deinit {
        unobserveDefaults()
    }
    
    fileprivate override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &Self.observationContext,
              case let .subscribed(userDefaults, observedKey) = state,
              userDefaults === (object as AnyObject?),
              observedKey == keyPath else {
            return
        }
        
        invalidateAttribute()
    }
    
    fileprivate func observeDefaults(_ userDefaults: UserDefaults, key: String) {
        switch state {
        case .uninitialized:
            break
        case let .subscribed(userDefaults, observedKey):
            if observedKey == key {
                return
            }
            unobserve(oldDefaults: userDefaults, key: observedKey)
            invalidateAttribute()
        }
        
        observe(userDefaults: userDefaults, key: key)
    }
    
    fileprivate func unobserveDefaults() {
        guard case let .subscribed(userDefaults, key) = state else {
            return
        }
        unobserve(oldDefaults: userDefaults, key: key)
    }
    
    fileprivate func invalidateAttribute() {
        let host = self.host
        let signal = self.signal
        
        performOnMainThread {
            Update.ensure {
                host?.asyncTransaction(.current, mutation: InvalidatingGraphMutation(attribute: signal), style: .ignoresFlushWhenUpdating, mayDeferUpdate: false)
            }
        }
    }
    
    @objc
    fileprivate func userDefaultsDidChange(_ notification: Notification) {
        guard case let .subscribed(userDefaults, observedKey) = state,
              let object = notification.object as AnyObject?,
              userDefaults === object,
              observedKey.contains(".") else {
                  return
              }
        
        invalidateAttribute()
    }
    
    fileprivate func observe(userDefaults: UserDefaults, key: String) {
        if key.contains(".") {
            NotificationCenter.default.addObserver(self, selector: #selector(UserDefaultObserver.userDefaultsDidChange(_:)), name: UserDefaults.didChangeNotification, object: userDefaults)
        } else {
            userDefaults.addObserver(self, forKeyPath: key, options: [], context: &UserDefaultObserver.observationContext)
        }
        state = .subscribed(userDefaults: userDefaults, key: key)
    }
    
    fileprivate func unobserve(oldDefaults: UserDefaults, key: String) {
        if key.contains(".") {
            NotificationCenter.default.removeObserver(self, name: UserDefaults.didChangeNotification, object: oldDefaults)
        } else {
            oldDefaults.removeObserver(self, forKeyPath: key, context: &UserDefaultObserver.observationContext)
        }
        state = .uninitialized
    }
    
    fileprivate static var observationContext: Int = 0
    
}

@available(iOS 13.0, *)
fileprivate struct UserDefaultPropertyBox<Value>: DynamicPropertyBox {

    fileprivate typealias Property = AppStorage<Value>

    @Attribute
    fileprivate var environment: EnvironmentValues

    fileprivate let observer: UserDefaultObserver

    fileprivate var seed: Int
    
    fileprivate init(host: GraphHost, environment: Attribute<EnvironmentValues>, signal: WeakAttribute<Void>) {
        _environment = environment
        observer = UserDefaultObserver(host: host, signal: signal)
        seed = 0
    }
    
    fileprivate func destroy() {
        _intentionallyLeftBlank()
    }
    
    fileprivate mutating func reset() {
        observer.unobserveDefaults()
    }
    
    fileprivate mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
        property.location.defaultStore = environment.defaultAppStorageDefaults
        observer.observeDefaults(property.location.store, key: property.location.key)
        
        var seed = self.seed
        
        defer {
            property.location.seed = seed
            property.location.changeSignal = observer.signal
        }
        guard let signal = observer.signal.attribute, signal.changedValue().changed else {
            return false
        }
        
        seed &+= 1
        
        property.location.cachedValue = nil
        
        return property.location.wasRead
    }
    
}

@available(iOS 13.0, *)
fileprivate struct PropertyListTransform<Value>: UserDefaultsValueTransform {
    
    fileprivate static func readValue(from store: UserDefaults, key: String) -> Any? {
        store.object(forKey: key)
    }
    
    fileprivate static func writeValue(_ value: Any?, to store: UserDefaults, key: String) {
        guard let propertyListValue = value as? Value else {
            store.removeObject(forKey: key)
            return
        }
        store.set(_bridgeAnythingToObjectiveC(propertyListValue), forKey: key)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct StringTransform: UserDefaultsValueTransform {
    
    fileprivate static func readValue(from store: UserDefaults, key: String) -> Any? {
        store.string(forKey: key)
    }
    
    fileprivate static func writeValue(_ value: Any?, to store: UserDefaults, key: String) {
        guard let stringValue = value as? String else {
            store.removeObject(forKey: key)
            return
        }
        store.set(_bridgeAnythingToObjectiveC(stringValue), forKey: key)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct URLTransform: UserDefaultsValueTransform {
    
    fileprivate static func readValue(from store: UserDefaults, key: String) -> Any? {
        store.url(forKey: key)
    }
    
    fileprivate static func writeValue(_ value: Any?, to store: UserDefaults, key: String) {
        guard let url = value as? URL else {
            store.removeObject(forKey: key)
            return
        }
        store.set(url, forKey: key)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct RawRepresentableTransform<RawRepresentableType: RawRepresentable>: UserDefaultsValueTransform {
    
    fileprivate static func readValue(from store: UserDefaults, key: String) -> Any? {
        (store.object(forKey: key) as? RawRepresentableType.RawValue).flatMap {
            RawRepresentableType(rawValue: $0)
        }
    }
    
    fileprivate static func writeValue(_ value: Any?, to store: UserDefaults, key: String) {
        guard let rawRepresentableValue = value as? RawRepresentableType else {
            return
        }
        store.set(_bridgeAnythingToObjectiveC(rawRepresentableValue.rawValue), forKey: key)
    }
    
}
