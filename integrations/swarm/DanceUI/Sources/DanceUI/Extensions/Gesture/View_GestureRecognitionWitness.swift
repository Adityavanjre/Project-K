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
    public func gesture<T: Gesture>(_ gesture: T,
                                    including mask: GestureMask = .all,
                                    extendedConfigs: GestureExtendedConfigs) -> some View {
        return modifier(AddGestureModifier(gesture: gesture,
                                           gestureMask: mask,
                                           extendedConfigs: extendedConfigs))
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
    public func highPriorityGesture<T: Gesture>(_ gesture: T,
                                                including mask: GestureMask = .all,
                                                extendedConfigs: GestureExtendedConfigs) -> some View {
        return modifier(HighPriorityGestureModifier(gesture: gesture,
                                                    gestureMask: mask,
                                                    extendedConfigs: extendedConfigs))
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
    public func simultaneousGesture<T: Gesture>(_ gesture: T,
                                                including mask: GestureMask = .all,
                                                extendedConfigs: GestureExtendedConfigs) -> some View {
        return modifier(SimultaneousGestureModifier(gesture: gesture,
                                                    gestureMask: mask,
                                                    extendedConfigs: extendedConfigs))
    }

    
}
