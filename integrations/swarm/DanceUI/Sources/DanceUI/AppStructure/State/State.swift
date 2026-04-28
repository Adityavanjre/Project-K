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

@_exported import OpenCombine
@_exported import OpenCombineFoundation
@_exported import OpenCombineDispatch
internal import DanceUIGraph

public typealias Publishers = OpenCombine.Publishers

/// A property wrapper type that can read and write a value managed by DanceUI.
///
/// Use state as the single source of truth for a given value type that you
/// store in a view hierarchy. Create a state value in an ``App``, ``Scene``,
/// or ``View`` by applying the `@State` attribute to a property declaration
/// and providing an initial value. Declare state as private to prevent setting
/// it in a memberwise initializer, which can conflict with the storage
/// management that DanceUI provides:
///
///     struct PlayButton: View {
///         @State private var isPlaying: Bool = false // Create the state.
///
///         var body: some View {
///             Button(isPlaying ? "Pause" : "Play") { // Read the state.
///                 isPlaying.toggle() // Write the state.
///             }
///         }
///     }
///
/// DanceUI manages the property's storage. When the value changes, DanceUI
/// updates the parts of the view hierarchy that depend on the value.
/// To access a state's underlying value, you use its ``wrappedValue`` property.
/// However, as a shortcut Swift enables you to access the wrapped value by
/// referring directly to the state instance. The above example reads and
/// writes the `isPlaying` state property's wrapped value by referring to the
/// property directly.
///
/// Declare state as private in the highest view in the view hierarchy that
/// needs access to the value. Then share the state with any subviews that also
/// need access, either directly for read-only access, or as a binding for
/// read-write access. You can safely mutate state properties from any thread.
///
/// ### Share state with subviews
///
/// If you pass a state property to a subview, DanceUI updates the subview
/// any time the value changes in the container view, but the subview can't
/// modify the value. To enable the subview to modify the state's stored value,
/// pass a ``Binding`` instead.
///
/// For example, you can remove the `isPlaying` state from the play button in
/// the above example, and instead make the button take a binding:
///
///     struct PlayButton: View {
///         @Binding var isPlaying: Bool // Play button now receives a binding.
///
///         var body: some View {
///             Button(isPlaying ? "Pause" : "Play") {
///                 isPlaying.toggle()
///             }
///         }
///     }
///
/// Then you can define a player view that declares the state and creates a
/// binding to the state. Get the binding to the state value by accessing the
/// state's ``projectedValue``, which you get by prefixing the property name
/// with a dollar sign (`$`):
///
///     struct PlayerView: View {
///         @State private var isPlaying: Bool = false // Create the state here now.
///
///         var body: some View {
///             VStack {
///                 PlayButton(isPlaying: $isPlaying) // Pass a binding.
///
///                 // ...
///             }
///         }
///     }
///
/// Like you do for a ``StateObject``, declare `State` as private to prevent
/// setting it in a memberwise initializer, which can conflict with the storage
/// management that DanceUI provides. Unlike a state object, always
/// initialize state by providing a default value in the state's
/// declaration, as in the above examples. Use state only for storage that's
/// local to a view and its subviews.
///
/// ### Store observable objects
///
/// You can also store observable objects that you create with the
/// <doc://com.apple.documentation/documentation/Observation/Observable()>
/// macro in `State`; for example:
///
///     @Observable
///     class Library {
///         var name = "My library of books"
///         // ...
///     }
///
///     struct ContentView: View {
///         @State private var library = Library()
///
///         var body: some View {
///             LibraryView(library: library)
///         }
///     }
///
/// A `State` property always instantiates its default value when DanceUI
/// instantiates the view. For this reason, avoid side effects and
/// performance-intensive work when initializing the default value. For
/// example, if a view updates frequently, allocating a new default object each
/// time the view initializes can become expensive. Instead, you can defer the
/// creation of the object using the ``View/task(priority:_:)`` modifier, which
/// is called only once when the view first appears:
///
///     struct ContentView: View {
///         @State private var library: Library?
///
///         var body: some View {
///             LibraryView(library: library)
///                 .task {
///                     library = Library()
///                 }
///         }
///     }
///
/// Delaying the creation of the observable state object ensures that
/// unnecessary allocations of the object doesn't happen each time DanceUI
/// initializes the view. Using the ``View/task(priority:_:)`` modifier is also
/// an effective way to defer any other kind of work required to create the
/// initial state of the view, such as network calls or file access.
///
/// > Note: It's possible to store an object that conforms to the
/// <doc://com.apple.documentation/documentation/Combine/ObservableObject>
/// protocol in a `State` property. However the view will only update when
/// the reference to the object changes, such as when setting the property with
/// a reference to another object. The view will not update if any of the
/// object's published properties change. To track changes to both the reference
/// and the object's published properties, use ``StateObject`` instead of
/// ``State`` when storing the object.
///
/// ### Share observable state objects with subviews
///
/// To share an <doc://com.apple.documentation/documentation/Observation/Observable>
/// object stored in `State` with a subview, pass the object reference to
/// the subview. DanceUI updates the subview anytime an observable property of
/// the object changes, but only when the subview's ``View/body`` reads the
/// property. For example, in the following code `BookView` updates each time
/// `title` changes but not when `isAvailable` changes:
///
///     @Observable
///     class Book {
///         var title = "A sample book"
///         var isAvailable = true
///     }
///
///     struct ContentView: View {
///         @State private var book = Book()
///
///         var body: some View {
///             BookView(book: book)
///         }
///     }
///
///     struct BookView: View {
///         var book: Book
///
///         var body: some View {
///             Text(book.title)
///         }
///     }
///
/// `State` properties provide bindings to their value. When storing an object,
/// you can get a ``Binding`` to that object, specifically the reference to the
/// object. This is useful when you need to change the reference stored in
/// state in some other subview, such as setting the reference to `nil`:
///
///     struct ContentView: View {
///         @State private var book: Book?
///
///         var body: some View {
///             DeleteBookView(book: $book)
///                 .task {
///                     book = Book()
///                 }
///         }
///     }
///
///     struct DeleteBookView: View {
///         @Binding var book: Book?
///
///         var body: some View {
///             Button("Delete book") {
///                 book = nil
///             }
///         }
///     }
///
/// However, passing a ``Binding`` to an object stored in `State` isn't
/// necessary when you need to change properties of that object. For example,
/// you can set the properties of the object to new values in a subview by
/// passing the object reference instead of a binding to the reference:
///
///     struct ContentView: View {
///         @State private var book = Book()
///
///         var body: some View {
///             BookCheckoutView(book: book)
///         }
///     }
///
///     struct BookCheckoutView: View {
///         var book: Book
///
///         var body: some View {
///             Button(book.isAvailable ? "Check out book" : "Return book") {
///                 book.isAvailable.toggle()
///             }
///         }
///     }
///
/// If you need a binding to a specific property of the object, pass either the
/// binding to the object and extract bindings to specific properties where
/// needed, or pass the object reference and use the ``Bindable`` property
/// wrapper to create bindings to specific properties. For example, in the
/// following code `BookEditorView` wraps `book` with `@Bindable`. Then the
/// view uses the `$` syntax to pass to a ``TextField`` a binding to `title`:
///
///     struct ContentView: View {
///         @State private var book = Book()
///
///         var body: some View {
///             BookView(book: book)
///         }
///     }
///
///     struct BookView: View {
///         let book: Book
///
///         var body: some View {
///             BookEditorView(book: book)
///         }
///     }
///
///     struct BookEditorView: View {
///         @Bindable var book: Book
///
///         var body: some View {
///             TextField("Title", text: $book.title)
///         }
///     }
///
@frozen
@propertyWrapper
@available(iOS 13.0, *)
public struct State<Value>: DynamicProperty {

    @usableFromInline
    internal var _value: Value

    @usableFromInline
    internal var _location: AnyLocation<Value>?
    
    /// Creates the state with an initial wrapped value.
    ///
    /// Don't call this initializer directly. Instead, declare a property
    /// with the ``State`` attribute, and provide an initial value:
    ///
    ///     @State private var isPlaying: Bool = false
    ///
    /// - Parameter wrappedValue: An initial wrappedValue for a state.
    @inlinable
    public init(wrappedValue value: Value) {
        _value = value
        _location = nil
    }
    
    // internal init(wrappedValue thunk: @autoclosure @escaping () -> Value) where Value : AnyObject, Value : DanceUIObservation.Observable
    
    /// Creates the state with an initial value.
    ///
    /// - Parameter value: An initial value of the state.
    public init(initialValue value: Value) {
        _value = value
    }
    
    /// The underlying value referenced by the state variable.
    ///
    /// This property provides primary access to the value's data. However, you
    /// don't access `wrappedValue` directly. Instead, you refer to the property
    /// variable created with the ``State`` attribute. In the following example,
    /// the button's label depends on the value of `isPlaying` and its action
    /// toggles the value of `isPlaying`. Both of these accesses implicitly
    /// rely on the state property's wrapped value.
    ///
    ///     struct PlayButton: View {
    ///         @State private var isPlaying: Bool = false
    ///
    ///         var body: some View {
    ///             Button(isPlaying ? "Pause" : "Play") {
    ///                 isPlaying.toggle()
    ///             }
    ///         }
    ///     }
    ///
    public var wrappedValue: Value {
        get {
            getValue(forReading: true)
        }
        nonmutating set {
            guard let location = _location else {
                return
            }
            location.set(newValue, transaction: Transaction())
        }
    }
    
    /// A binding to the state value.
    ///
    /// Use the projected value to pass a binding value down a view hierarchy.
    /// To get the `projectedValue`, prefix the property variable with a dollar
    /// sign (`$`). In the following example, `PlayerView` projects a binding
    /// of the state property `isPlaying` to the `PlayButton` view using
    /// `$isPlaying`:
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
        let value = getValue(forReading: false)
        
        if let location = _location {
            return Binding(value: value, location: location, transaction: Transaction())
        } else {
            return Binding.constant(value)
        }
    }
    
    public static func _makeProperty<V>(in buffer: inout _DynamicPropertyBuffer, container: _GraphValue<V>, fieldOffset: Int, name: String?, inputs: inout _GraphInputs) {
        let signal = Attribute(value: Void())
#if DEBUG || DANCE_UI_INHOUSE
        signal.role = .signalForState
#endif
        
        let weakSignal = WeakAttribute(signal)
        
        let box = StatePropertyBox<Value>(signal: weakSignal, location: nil)
        
        buffer.append(box, fieldOffset: fieldOffset)
    }
    
}

@available(iOS 13.0, *)
extension State {
    
    internal func getValue(forReading isReading: Bool) -> Value {
        guard let location = _location else {
            return _value
        }
        
        if GraphHost.isUpdating {
            if isReading {
                location.wasRead = true
            }
            return _value
        } else {
            return location.get()
        }
    }
    
}

@available(iOS 13.0, *)
extension State where Value : ExpressibleByNilLiteral {
    
    /// Creates a state without an initial value.
    @inlinable
    public init() {
        self.init(wrappedValue: nil)
    }
    
}
