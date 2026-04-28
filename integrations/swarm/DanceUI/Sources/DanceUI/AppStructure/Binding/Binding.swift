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

/// A property wrapper type that can read and write a value owned by a source of
/// truth.
///
/// Use a binding to create a two-way connection between a property that stores
/// data, and a view that displays and changes the data. A binding connects a
/// property to a source of truth stored elsewhere, instead of storing data
/// directly. For example, a button that toggles between play and pause can
/// create a binding to a property of its parent view using the `Binding`
/// property wrapper.
///
///     struct PlayButton: View {
///         @Binding var isPlaying: Bool
///
///         var body: some View {
///             Button(isPlaying ? "Pause" : "Play") {
///                 isPlaying.toggle()
///             }
///         }
///     }
///
/// The parent view declares a property to hold the playing state, using the
/// ``State`` property wrapper to indicate that this property is the value's
/// source of truth.
///
///     struct PlayerView: View {
///         var episode: Episode
///         @State private var isPlaying: Bool = false
///
///         var body: some View {
///             VStack {
///                 Text(episode.title)
///                     .foregroundStyle(isPlaying ? .primary : .secondary)
///                 PlayButton(isPlaying: $isPlaying) // Pass a binding.
///             }
///         }
///     }
///
/// When `PlayerView` initializes `PlayButton`, it passes a binding of its state
/// property into the button's binding property. Applying the `$` prefix to a
/// property wrapped value returns its ``State/projectedValue``, which for a
/// state property wrapper returns a binding to the value.
///
/// Whenever the user taps the `PlayButton`, the `PlayerView` updates its
/// `isPlaying` state.
@frozen
@propertyWrapper
@dynamicMemberLookup
@available(iOS 13.0, *)
public struct Binding<Value>: DynamicProperty {
    
    /// The binding's transaction.
    ///
    /// The transaction captures the information needed to update the view when
    /// the binding value changes.
    public var transaction: Transaction

    internal var location: AnyLocation<Value>

    fileprivate var _value: Value
    
    /// Creates a binding with closures that read and write the binding value.
    ///
    /// - Parameters:
    ///   - get: A closure that retrieves the binding value. The closure has no
    ///     parameters, and returns a value.
    ///   - set: A closure that sets the binding value. The closure has the
    ///     following parameter:
    ///       - newValue: The new value of the binding value.
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void) {
        let location = FunctionalLocation(getValue: get, setValue: { v, _ in set(v) })
        self.init(value: get(), location: LocationBox(location))
    }
    
    /// Creates a binding with a closure that reads from the binding value, and
    /// a closure that applies a transaction when writing to the binding value.
    ///
    /// - Parameters:
    ///   - get: A closure to retrieve the binding value. The closure has no
    ///     parameters, and returns a value.
    ///   - set: A closure to set the binding value. The closure has the
    ///     following parameters:
    ///       - newValue: The new value of the binding value.
    ///       - transaction: The transaction to apply when setting a new value.
    public init(get: @escaping () -> Value, set: @escaping (Value, Transaction) -> Void) {
        let location = FunctionalLocation(getValue: get, setValue: set)
        self.init(value: get(), location: LocationBox(location))
    }
    
    /// Creates a binding with an immutable value.
    ///
    /// Use this method to create a binding to a value that cannot change.
    /// This can be useful when using a ``PreviewProvider`` to see how a view
    /// represents different values.
    ///
    ///     // Example of binding to an immutable value.
    ///     PlayButton(isPlaying: Binding.constant(true))
    ///
    /// - Parameter value: An immutable value.
    public static func constant(_ value: Value) -> Binding<Value> {
        let location = ConstantLocation(value: value)
        let box = LocationBox(location)
        return Binding(value: value, location: box)
    }
    
    /// Creates a binding from the value of another binding.
    public init(projectedValue: Binding<Value>) {
        self = projectedValue
    }
    
    /// The underlying value referenced by the binding variable.
    ///
    /// This property provides primary access to the value's data. However, you
    /// don't access `wrappedValue` directly. Instead, you use the property
    /// variable created with the ``Binding`` attribute. In the
    /// following code example, the binding variable `isPlaying` returns the
    /// value of `wrappedValue`:
    ///
    ///     struct PlayButton: View {
    ///         @Binding var isPlaying: Bool
    ///
    ///         var body: some View {
    ///             Button(isPlaying ? "Pause" : "Play") {
    ///                 isPlaying.toggle()
    ///             }
    ///         }
    ///     }
    ///
    /// When a mutable binding value changes, the new value is immediately
    /// available. However, updates to a view displaying the value happens
    /// asynchronously, so the view may not show the change immediately.
    public var wrappedValue: Value {
        get {
            readValue()
        }
        nonmutating set {
            location.set(newValue, transaction: transaction)
        }
    }
    
    /// A projection of the binding value that returns a binding.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the `projectedValue`, prefix the property variable with `$`. For
    /// example, in the following code example `PlayerView` projects a binding
    /// of the state property `isPlaying` to the `PlayButton` view using
    /// `$isPlaying`.
    ///
    ///     struct PlayerView: View {
    ///         var episode: Episode
    ///         @State private var isPlaying: Bool = false
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Text(episode.title)
    ///                     .foregroundStyle(isPlaying ? .primary : .secondary)
    ///                 PlayButton(isPlaying: $isPlaying)
    ///             }
    ///         }
    ///     }
    ///
    public var projectedValue: Binding<Value> {
        self
    }
    
    /// Returns a binding to the resulting value of a given key path.
    ///
    /// - Parameter keyPath: A key path to a specific resulting value.
    ///
    /// - Returns: A new binding.
    public subscript<Subject>(dynamicMember keyPath: WritableKeyPath<Value, Subject>) -> Binding<Subject> {
        projecting(keyPath)
    }
    
    // MARK: DynamicProperty
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        buffer.append(Box(), fieldOffset: fieldOffset)
    }
    
    internal weak var _host: GraphHost? {
        location._host
    }
    
}

@available(iOS 13.0, *)
extension Binding : Identifiable where Value : Identifiable {
    
    /// The stable identity of the entity associated with this instance,
    /// corresponding to the `id` of the binding's wrapped value.
    public var id: Value.ID {
        wrappedValue.id
    }
    
    /// A type representing the stable identity of the entity associated with
    /// an instance.
    public typealias ID = Value.ID
    
}

@available(iOS 13.0, *)
extension Binding : Sequence where Value : MutableCollection {
    
    /// A type representing the sequence's elements.
    public typealias Element = Binding<Value.Element>
    
    /// A type that provides the sequence's iteration interface and
    /// encapsulates its iteration state.
    public typealias Iterator = IndexingIterator<Binding<Value>>
    
    /// A collection representing a contiguous subrange of this collection's
    /// elements. The subsequence shares indices with the original collection.
    ///
    /// The default subsequence type for collections that don't define their own
    /// is `Slice`.
    public typealias SubSequence = Slice<Binding<Value>>
    
}

@available(iOS 13.0, *)
extension Binding : Collection where Value : MutableCollection {
    
    /// A type that represents a position in the collection.
    ///
    /// Valid indices consist of the position of every element and a
    /// "past the end" position that's not valid for use as a subscript
    /// argument.
    public typealias Index = Value.Index
    
    /// A type that represents the indices that are valid for subscripting the
    /// collection, in ascending order.
    public typealias Indices = Value.Indices
    
    /// The position of the first element in a nonempty collection.
    ///
    /// If the collection is empty, `startIndex` is equal to `endIndex`.
    public var startIndex: Binding<Value>.Index {
        wrappedValue.startIndex
    }
    
    /// The collection's "past the end" position---that is, the position one
    /// greater than the last valid subscript argument.
    ///
    /// When you need a range that includes the last element of a collection, use
    /// the half-open range operator (`..<`) with `endIndex`. The `..<` operator
    /// creates a range that doesn't include the upper bound, so it's always
    /// safe to use with `endIndex`. For example:
    ///
    ///     let numbers = [10, 20, 30, 40, 50]
    ///     if let index = numbers.firstIndex(of: 30) {
    ///         print(numbers[index ..< numbers.endIndex])
    ///     }
    ///     // Prints "[30, 40, 50]"
    ///
    /// If the collection is empty, `endIndex` is equal to `startIndex`.
    public var endIndex: Binding<Value>.Index {
        wrappedValue.endIndex
    }
    
    /// The indices that are valid for subscripting the collection, in ascending
    /// order.
    ///
    /// A collection's `indices` property can hold a strong reference to the
    /// collection itself, causing the collection to be nonuniquely referenced.
    /// If you mutate the collection while iterating over its indices, a strong
    /// reference can result in an unexpected copy of the collection. To avoid
    /// the unexpected copy, use the `index(after:)` method starting with
    /// `startIndex` to produce indices instead.
    ///
    ///     var c = MyFancyCollection([10, 20, 30, 40, 50])
    ///     var i = c.startIndex
    ///     while i != c.endIndex {
    ///         c[i] /= 5
    ///         i = c.index(after: i)
    ///     }
    ///     // c == MyFancyCollection([2, 4, 6, 8, 10])
    public var indices: Value.Indices {
        wrappedValue.indices
    }
    
    /// Returns the position immediately after the given index.
    ///
    /// The successor of an index must be well defined. For an index `i` into a
    /// collection `c`, calling `c.index(after: i)` returns the same index every
    /// time.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    /// - Returns: The index value immediately after `i`.
    public func index(after i: Binding<Value>.Index) -> Binding<Value>.Index {
        wrappedValue.index(after: i)
    }
    
    /// Replaces the given index with its successor.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be less than
    ///   `endIndex`.
    public func formIndex(after i: inout Binding<Value>.Index) {
        wrappedValue.formIndex(after: &i)
    }
    
    /// Accesses the element at the specified position.
    ///
    /// The following example accesses an element of an array through its
    /// subscript to print its value:
    ///
    ///     var streets = ["Adams", "Bryant", "Channing", "Douglas", "Evarts"]
    ///     print(streets[1])
    ///     // Prints "Bryant"
    ///
    /// You can subscript a collection with any valid index other than the
    /// collection's end index. The end index refers to the position one past
    /// the last element of a collection, so it doesn't correspond with an
    /// element.
    ///
    /// - Parameter position: The position of the element to access. `position`
    ///   must be a valid index of the collection that is not equal to the
    ///   `endIndex` property.
    ///
    /// - Complexity: O(1)
    public subscript(position: Binding<Value>.Index) -> Binding<Value>.Element {
        Binding<Value.Element>(get: {
            wrappedValue[position]
        }, set:{ newValue in
            wrappedValue[position] = newValue
        })
    }
    
}

@available(iOS 13.0, *)
extension Binding : BidirectionalCollection where Value : BidirectionalCollection, Value : MutableCollection {
    
    /// Returns the position immediately before the given index.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be greater than
    ///   `startIndex`.
    /// - Returns: The index value immediately before `i`.
    public func index(before i: Binding<Value>.Index) -> Binding<Value>.Index {
        wrappedValue.index(before: i)
    }
    
    /// Replaces the given index with its predecessor.
    ///
    /// - Parameter i: A valid index of the collection. `i` must be greater than
    ///   `startIndex`.
    public func formIndex(before i: inout Binding<Value>.Index) {
        wrappedValue.formIndex(before: &i)
    }
    
}

@available(iOS 13.0, *)
extension Binding : RandomAccessCollection where Value : MutableCollection, Value : RandomAccessCollection {
}

@available(iOS 13.0, *)
extension Binding {
    
    internal func projecting<ProjectionType: Projection>(_ projection: ProjectionType) -> Binding<ProjectionType.Projected> where Value == ProjectionType.Base {
        let projectedValue = projection.get(base: _value)
        let projectedLocation = location.projecting(projection)
        return Binding<ProjectionType.Projected>(value: projectedValue, location: projectedLocation, transaction: transaction)
    }
    
    internal func zip<AnotherValue>(with binding: Binding<AnotherValue>) -> Binding<ZippedValue<Value, AnotherValue>> {
        let location = ZipLocation(self.location, binding.location)
        let box = LocationBox(location)
        return Binding<ZippedValue<Value, AnotherValue>>(value: ZippedValue(first: _value, second: binding._value),
                                                         location: box,
                                                         transaction: transaction)
    }
    
    @usableFromInline
    internal init(value: Value, location: AnyLocation<Value>, transaction: Transaction = .init()) {
        self._value = value
        self.location = location
        self.transaction = transaction
    }
    
    private func readValue() -> Value {
        if GraphHost.isUpdating {
            location.wasRead = true
            return _value
        } else {
            return location.get()
        }
    }
    
    internal init<ObservableObjectType: ObservableObject>(_ object: ObservableObjectType, keyPath: ReferenceWritableKeyPath<ObservableObjectType, Value>) {
        let location = ObservableObjectLocation(base: object, keyPath: keyPath)
        let value = location.get()
        self.init(value: value, location: LocationBox(location))
    }
    
    /// Creates a binding by projecting the base value to an optional value.
    ///
    /// - Parameter base: A value to project to an optional value.
    public init<V>(_ base: Binding<V>) where Value == V? {
        self = base.projecting(BindingOperations.ToOptional<V>())
    }
    
    /// Creates a binding by projecting the base value to a hashable value.
    ///
    /// - Parameters:
    ///   - base: A `Hashable` value to project to an `AnyHashable` value.
    public init<V: Hashable>(_ base: Binding<V>) where Value == AnyHashable {
        self = base.projecting(BindingOperations.ToAnyHashable<V>())
    }
    
    /// Creates a binding by projecting the base value to an unwrapped value.
    ///
    /// - Parameter base: A value to project to an unwrapped value.
    ///
    /// - Returns: A new binding or `nil` when `base` is `nil`.
    public init?(_ base: Binding<Value?>) {
        guard let _ = base.wrappedValue else {
            return nil
        }
        self = base.projecting(BindingOperations.ForceUnwrapping())
    }
    
}

@available(iOS 13.0, *)
extension Binding {
    
    /// Specifies a transaction for the binding.
    ///
    /// - Parameter transaction  : An instance of a ``Transaction``.
    ///
    /// - Returns: A new binding.
    public func transaction(_ transaction: Transaction) -> Binding<Value> {
        return Binding(value: _value, location: location, transaction: transaction)
    }
    
    /// Specifies an animation to perform when the binding value changes.
    ///
    /// - Parameter animation: An animation sequence performed when the binding
    ///   value changes.
    ///
    /// - Returns: A new binding.
    @inlinable
    public func animation(_ animation: Animation? = .default) -> Binding<Value> {
        var copied = self
        copied.transaction.animation = animation
        return copied
    }
    
}

@available(iOS 13.0, *)
extension Binding {
    
    private struct Box: DynamicPropertyBox {
        
        internal typealias Property = Binding<Value>
        
        private var location: LocationBox<ScopedLocation>?
        
        @inline(__always)
        internal init() {
            location = nil
        }
        
        internal func reset() {
            
        }
        
        internal func destroy() {
            
        }
        
        internal mutating func update(property: inout Property, phase: _GraphInputs.Phase) -> Bool {
            let updatedLocation: LocationBox<ScopedLocation>
            if let location {
                if location.location.base !== property.location {
                    updatedLocation = LocationBox(ScopedLocation(property.location))
                    self.location = updatedLocation
                    if location.wasRead {
                        updatedLocation.wasRead = true
                    }
                } else {
                    updatedLocation = location
                }
            } else {
                updatedLocation = LocationBox(ScopedLocation(property.location))
                self.location = updatedLocation
            }
            let (value, isUpdated) = updatedLocation.update()
            property.location = updatedLocation
            property._value = value
            return isUpdated ? updatedLocation.wasRead : false
        }
    }
    
}

@available(iOS 13.0, *)
extension Binding {
    
    private struct ScopedLocation: Location {
        
        internal var base: AnyLocation<Value>
        
        internal var wasRead: Bool
        
        @inline(__always)
        internal init(_ base: AnyLocation<Value>) {
            self.base = base
            self.wasRead = base.wasRead
        }
        
        internal func get() -> Value {
            return base.get()
        }
        
        internal func set(_ value: Value, transaction: Transaction) {
            base.set(value, transaction: transaction)
        }
        
        internal func update() -> (Value, Bool) {
            base.update()
        }
        
        internal func projecting<P>(_ projection: P) -> AnyLocation<P.Projected> where P : Projection, Self.Value == P.Base {
            LocationBox(ProjectedLocation(location: self, projection: projection))
        }
        
    }
    
}

@available(iOS 13.0, *)
fileprivate struct ProjectedLocation<A: Location, B: Projection>: Location where B.Base == A.Value {
    
    fileprivate typealias Value = B.Projected
    
    fileprivate var location: A
    
    fileprivate var projection: B
    
    @inline(__always)
    fileprivate init(location: A, projection: B) {
        self.location = location
        self.projection = projection
    }
    
    @inline(__always)
    fileprivate var wasRead: Bool {
        get { location.wasRead }
        set { location.wasRead = newValue }
    }
    
    @inline(__always)
    fileprivate func get() -> Value {
        let value = location.get()
        return projection.get(base: value)
    }
    
    @inline(__always)
    fileprivate mutating func set(_ value: Value, transaction: Transaction) {
        var baseValue = location.get()
        
        projection.set(base: &baseValue, newValue: value)
        
        location.set(baseValue, transaction: transaction)
    }
    
    @inline(__always)
    fileprivate func update() -> (B.Projected, Bool) {
        let (baseValue, flag) = location.update()
        
        let projectedValue = projection.get(base: baseValue)
        
        return (projectedValue, flag)
        
    }
    
}

@available(iOS 13.0, *)
internal struct LocationProjectionCache {
    
    private var cache: [AnyHashable : Entry]
    
    @inlinable
    internal init() {
        cache = [:]
    }
    
    internal mutating func reference<P: Projection, L: Location>(for projection: P, on location: L) -> AnyLocation<P.Projected> where P.Base == L.Value {
        let key = AnyHashable(projection)
        
        if let value = cache[key], let projectedLocation = value.box as? AnyLocation<P.Projected> {
            return projectedLocation
        } else {
            let projectedLocation = ProjectedLocation(location: location, projection: projection)
            let box = LocationBox(projectedLocation)
            cache[key] = Entry(box: box)
            return box
        }
    }
    
    private struct Entry {
        
        internal weak var box: AnyLocationBase?
    }
}

@available(iOS 13.0, *)
extension Binding {

    @inline(__always)
    internal func makeWeak() -> WeakBinding<Value> {
        WeakBinding(transaction: transaction, location: location, _value: _value)
    }
    
}

/// A pure stored data that holds a weak reference to the location and maintains
/// the encapsulation of `Binding`.
///
@available(iOS 13.0, *)
internal struct WeakBinding<Value> {
    
    internal var transaction: Transaction
    
    internal weak var location: AnyLocation<Value>?
    
    internal var _value: Value
    
    @inlinable
    internal func makeStrong() -> Binding<Value>? {
        guard let location else {
            return nil
        }
        return Binding(value: _value, location: location, transaction: transaction)
    }
    
}
