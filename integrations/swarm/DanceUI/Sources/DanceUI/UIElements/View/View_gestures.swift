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

@available(iOS 13.0, *)
extension View {
    
    /// Attaches a gesture to the view with a lower precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to attach a gesture to a view. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture``
    /// handler that also prints a message to the console, and blue rectangle
    /// with no custom gesture handlers. Tapping or clicking the image
    /// prints a message to the console from the tap gesture handler on the
    /// image, while tapping or clicking  the rectangle inside the ``VStack``
    /// prints a message in the console from the enclosing vertical stack
    /// gesture handler.
    ///
    ///     struct GestureExample: View {
    ///         @State private var message = "Message"
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .gesture(newGesture)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    @_disfavoredOverload
    public func gesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        modifier(AddGestureModifier(gesture: gesture, gestureMask: mask))
    }
    
    @_disfavoredOverload
    public func gesture<T>(_ gesture: T, name: String, including mask: GestureMask = .all) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        modifier(AddGestureModifier(gesture: gesture, name: name, gestureMask: mask))
    }
    
    /// Attaches a gesture to the view with a lower precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to attach a gesture to a view. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture``
    /// handler that also prints a message to the console, and blue rectangle
    /// with no custom gesture handlers. Tapping or clicking the image
    /// prints a message to the console from the tap gesture handler on the
    /// image, while tapping or clicking  the rectangle inside the ``VStack``
    /// prints a message in the console from the enclosing vertical stack
    /// gesture handler.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    ///     struct GestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .gesture(newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - isEnabled: Whether the added gesture is enabled.
    public func gesture<T>(_ gesture: T, isEnabled: Bool = true) -> some View where T : Gesture {
        self.gesture(gesture, isCancellable: false, isEnabled: isEnabled)
    }
    
    public func gesture<T>(_ gesture: T, isCancellable: Bool, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(AddGestureModifier(gesture: gesture, name: nil, gestureMask: isEnabled ? .all : .none, isCancellable: isCancellable))
    }
    
    /// Attaches a gesture to the view with a lower precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to attach a gesture to a view. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture``
    /// handler that also prints a message to the console, and blue rectangle
    /// with no custom gesture handlers. Tapping or clicking the image
    /// prints a message to the console from the tap gesture handler on the
    /// image, while tapping or clicking  the rectangle inside the ``VStack``
    /// prints a message in the console from the enclosing vertical stack
    /// gesture handler.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    ///     struct GestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .gesture(newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - name: A string that identifies the gesture. In iOS, the name can be
    ///      used to set up failure relationships between UIKit gesture
    ///      recognizers and this gesture.
    ///    - isEnabled: Whether the added gesture is enabled. The default value
    ///      is `true`.
    public func gesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture {
        self.gesture(gesture, name: name, isCancellable: false, isEnabled: isEnabled)
    }
    
    public func gesture<T>(_ gesture: T, name: String, isCancellable: Bool, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(AddGestureModifier(gesture: gesture, name: name, gestureMask: isEnabled ? .all : .none, isCancellable: isCancellable))
    }
    
    
    /// Attaches a gesture to the view with a higher precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define a high priority gesture
    /// to take precedence over the view's existing gestures. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture`` handler that
    /// also prints a message to the console, and a blue rectangle
    /// with no custom gesture handlers. Tapping or clicking any of the
    /// views results in a console message from the high priority gesture
    /// attached to the enclosing ``VStack``.
    ///
    ///     struct HighPriorityGestureExample: View {
    ///         @State private var message = "Message"
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .highPriorityGesture(newGesture)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    @_disfavoredOverload
    public func highPriorityGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture {
        modifier(HighPriorityGestureModifier(gesture: gesture, gestureMask: mask))
    }
    
    // DanceUI addition
    @_disfavoredOverload
    public func highPriorityGesture<T>(_ gesture: T, name: String, including mask: GestureMask = .all) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        modifier(HighPriorityGestureModifier(gesture: gesture, name: name, gestureMask: mask))
    }
    
    /// Attaches a gesture to the view with a higher precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define a high priority gesture
    /// to take precedence over the view's existing gestures. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture`` handler that
    /// also prints a message to the console, and a blue rectangle
    /// with no custom gesture handlers. Tapping or clicking any of the
    /// views results in a console message from the high priority gesture
    /// attached to the enclosing ``VStack``.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    ///     struct HighPriorityGestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .highPriorityGesture(
    ///                 newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - isEnabled: Whether the added gesture is enabled.
    public func highPriorityGesture<T>(_ gesture: T, isEnabled: Bool = true) -> some View where T : Gesture {
        highPriorityGesture(gesture, isCancellable: false, isEnabled: isEnabled)
    }
    
    public func highPriorityGesture<T>(_ gesture: T, isCancellable: Bool, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(HighPriorityGestureModifier(gesture: gesture, name: nil, gestureMask: isEnabled ? .all : .none, isCancellable: isCancellable))
    }
    
    /// Attaches a gesture to the view with a higher precedence than gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define a high priority gesture
    /// to take precedence over the view's existing gestures. The
    /// example below defines a custom gesture that prints a message to the
    /// console and attaches it to the view's ``VStack``. Inside the ``VStack``
    /// a red heart ``Image`` defines its own ``TapGesture`` handler that
    /// also prints a message to the console, and a blue rectangle
    /// with no custom gesture handlers. Tapping or clicking any of the
    /// views results in a console message from the high priority gesture
    /// attached to the enclosing ``VStack``.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    ///     struct HighPriorityGestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Tap on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Tap on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .highPriorityGesture(
    ///                 newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - name: A string that identifies the gesture. In iOS, the name can be
    ///      used to set up failure relationships between UIKit gesture
    ///      recognizers and this gesture.
    ///    - isEnabled: Whether the added gesture is enabled. The default value
    ///      is `true`.
    public func highPriorityGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        highPriorityGesture(gesture, name: name, isCancellable: false, isEnabled: isEnabled)
    }
    
    public func highPriorityGesture<T>(_ gesture: T, name: String, isCancellable: Bool, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(HighPriorityGestureModifier(gesture: gesture, name: name, gestureMask: isEnabled ? .all : .none, isCancellable: isCancellable))
    }


    /// Attaches a gesture to the view to process simultaneously with gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define and process  a view specific
    /// gesture simultaneously with the same priority as the
    /// view's existing gestures. The example below defines a custom gesture
    /// that prints a message to the console and attaches it to the view's
    /// ``VStack``. Inside the ``VStack`` is a red heart ``Image`` defines its
    /// own ``TapGesture`` handler that also prints a message to the console
    /// and a blue rectangle with no custom gesture handlers.
    ///
    /// Tapping or clicking the "heart" image sends two messages to the
    /// console: one for the image's tap gesture handler, and the other from a
    /// custom gesture handler attached to the enclosing vertical stack.
    /// Tapping or clicking on the blue rectangle results only in the single
    /// message to the console from the tap recognizer attached to the
    /// ``VStack``:
    ///
    ///     struct SimultaneousGestureExample: View {
    ///         @State private var message = "Message"
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Gesture on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Gesture on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .simultaneousGesture(newGesture)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - mask: A value that controls how adding this gesture to the view
    ///      affects other gestures recognized by the view and its subviews.
    ///      Defaults to ``DanceUI/GestureMask/all``.
    @_disfavoredOverload
    public func simultaneousGesture<T>(_ gesture: T, including mask: GestureMask = .all) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        modifier(SimultaneousGestureModifier(gesture: gesture, gestureMask: mask))
    }
    
    // DanceUI addition
    @_disfavoredOverload
    public func simultaneousGesture<T>(_ gesture: T, name: String, including mask: GestureMask = .all) -> some View where T : Gesture { // BDCOV_EXCL_BLOCK
        modifier(SimultaneousGestureModifier(gesture: gesture, name: name, gestureMask: mask))
    }
    
    /// Attaches a gesture to the view to process simultaneously with gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define and process  a view specific
    /// gesture simultaneously with the same priority as the
    /// view's existing gestures. The example below defines a custom gesture
    /// that prints a message to the console and attaches it to the view's
    /// ``VStack``. Inside the ``VStack`` is a red heart ``Image`` defines its
    /// own ``TapGesture`` handler that also prints a message to the console
    /// and a blue rectangle with no custom gesture handlers.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    /// Tapping or clicking the "heart" image sends two messages to the
    /// console: one for the image's tap gesture handler, and the other from a
    /// custom gesture handler attached to the enclosing vertical stack.
    /// Tapping or clicking on the blue rectangle results only in the single
    /// message to the console from the tap recognizer attached to the
    /// ``VStack``:
    ///
    ///     struct SimultaneousGestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Gesture on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Gesture on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .simultaneousGesture(
    ///                 newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - isEnabled: Whether the added gesture is enabled.
    public func simultaneousGesture<T>(_ gesture: T, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(SimultaneousGestureModifier(gesture: gesture, name: nil, gestureMask: isEnabled ? .all : .none))
    }
    
    /// Attaches a gesture to the view to process simultaneously with gestures
    /// defined by the view.
    ///
    /// Use this method when you need to define and process  a view specific
    /// gesture simultaneously with the same priority as the
    /// view's existing gestures. The example below defines a custom gesture
    /// that prints a message to the console and attaches it to the view's
    /// ``VStack``. Inside the ``VStack`` is a red heart ``Image`` defines its
    /// own ``TapGesture`` handler that also prints a message to the console
    /// and a blue rectangle with no custom gesture handlers.
    ///
    /// You can also use the ``isEnabled`` parameter to conditionally disable
    /// the gesture.
    ///
    /// Tapping or clicking the "heart" image sends two messages to the
    /// console: one for the image's tap gesture handler, and the other from a
    /// custom gesture handler attached to the enclosing vertical stack.
    /// Tapping or clicking on the blue rectangle results only in the single
    /// message to the console from the tap recognizer attached to the
    /// ``VStack``:
    ///
    ///     struct SimultaneousGestureExample: View {
    ///         @State private var message = "Message"
    ///         var isGestureEnabled: Bool
    ///         let newGesture = TapGesture().onEnded {
    ///             print("Gesture on VStack.")
    ///         }
    ///
    ///         var body: some View {
    ///             VStack(spacing:25) {
    ///                 Image(systemName: "heart.fill")
    ///                     .resizable()
    ///                     .frame(width: 75, height: 75)
    ///                     .padding()
    ///                     .foregroundColor(.red)
    ///                     .onTapGesture {
    ///                         print("Gesture on image.")
    ///                     }
    ///                 Rectangle()
    ///                     .fill(Color.blue)
    ///             }
    ///             .simultaneousGesture(
    ///                 newGesture, isEnabled: isGestureEnabled)
    ///             .frame(width: 200, height: 200)
    ///             .border(Color.purple)
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///    - gesture: A gesture to attach to the view.
    ///    - name: A string that identifies the gesture. In iOS, the name can be
    ///      used to set up failure relationships between UIKit gesture
    ///      recognizers and this gesture.
    ///    - isEnabled: Whether the added gesture is enabled. The default value
    ///      is `true`.
    public func simultaneousGesture<T>(_ gesture: T, name: String, isEnabled: Bool = true) -> some View where T : Gesture {
        modifier(SimultaneousGestureModifier(gesture: gesture, name: name, gestureMask: isEnabled ? .all : .none))
    }
    
}

@available(iOS 13.0, *)
internal struct AddGestureModifier<ContentGesture: Gesture>: GestureViewModifier {
        
    internal typealias Combiner = DefaultGestureCombiner
    
    internal typealias Body = Never
    
    internal var gesture: ContentGesture

    internal var name: String?
    
    internal var gestureMask: GestureMask
    
    internal var extendedConfigs: GestureExtendedConfigs = .empty
    
    internal var isCancellable: Bool = false
    
}

@available(iOS 13.0, *)
internal struct HighPriorityGestureModifier<ContentGesture: Gesture>: GestureViewModifier {
    
    internal typealias Combiner = HighPriorityGestureCombiner
    
    internal typealias Body = Never

    internal var gesture: ContentGesture

    internal var name: String?
    
    internal var gestureMask: GestureMask
    
    internal var extendedConfigs: GestureExtendedConfigs = .empty
    
    internal var isCancellable: Bool = false
}

@available(iOS 13.0, *)
internal struct SimultaneousGestureModifier<A: Gesture>: GestureViewModifier {
    
    internal typealias Combiner = SimultaneousGestureCombiner
    
    internal typealias Body = Never
    
    internal var gesture: A
    
    internal var name: String?

    internal var gestureMask: GestureMask
    
    internal var extendedConfigs: GestureExtendedConfigs = .empty

}

public var isGestureContainerEnabled: Bool {
    DanceUIFeature.gestureContainer.isEnable
}

// swift-format-ignore: AlwaysUseLowerCamelCase
@_silgen_name("MyIsGestureContainerEnabled")
@_spi(Unexported)
public func MyIsGestureContainerEnabled() -> Bool {
    isGestureContainerEnabled
}

extension View {
    
    public func migrateToGestureContainer<Then: View, Else: View>(
        _ trueBody: @escaping (_ content: PlaceholderContentView<Self>) -> Then,
        else falseBody: @escaping (_ content: PlaceholderContentView<Self>) -> Else) -> some View {
        modifier(StaticIf(DanceUIFeature.gestureContainer.self, then: GestureContainerMigrationModifier(makeBody: trueBody), else: GestureContainerMigrationModifier(makeBody: falseBody)))
    }
    
}

public struct MigrateToGestureContainer<TrueBody: View, FalseBody: View>: View {
    
    public let trueBody: TrueBody
    
    public let falseBody: FalseBody
    
    public init(@ViewBuilder then trueBody: () -> TrueBody, @ViewBuilder else falseBody: () -> FalseBody) {
        self.trueBody = trueBody()
        self.falseBody = falseBody()
    }
    
    public var body: some View {
        StaticIf(DanceUIFeature.gestureContainer.self) {
            trueBody
        } `else`: {
            falseBody
        }
    }
    
}

private struct GestureContainerMigrationModifier<Input: View, Result: View>: ViewModifier {
    
    fileprivate var makeBody: (PlaceholderContentView<Input>) -> Result
    
    fileprivate func body(content: Content) -> some View {
        makeBody(PlaceholderContentView())
    }
    
}
