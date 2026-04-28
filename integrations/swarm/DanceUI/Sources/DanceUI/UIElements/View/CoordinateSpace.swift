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

import Foundation
internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {
    
    /// Assigns a name to the view's coordinate space, so other code can operate
    /// on dimensions like points and sizes relative to the named space.
    ///
    /// Use `coordinateSpace(name:)` to allow another function to find and
    /// operate on a view and operate on dimensions relative to that view.
    ///
    /// The example below demonstrates how a nested view can find and operate on
    /// its enclosing view's coordinate space:
    ///
    ///     struct ContentView: View {
    ///         @State var location = CGPoint.zero
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Color.red.frame(width: 100, height: 100)
    ///                     .overlay(circle)
    ///                 Text("Location: \(Int(location.x)), \(Int(location.y))")
    ///             }
    ///             .coordinateSpace(name: "stack")
    ///         }
    ///
    ///         var circle: some View {
    ///             Circle()
    ///                 .frame(width: 25, height: 25)
    ///                 .gesture(drag)
    ///                 .padding(5)
    ///         }
    ///
    ///         var drag: some Gesture {
    ///             DragGesture(coordinateSpace: .named("stack"))
    ///                 .onChanged { info in location = info.location }
    ///         }
    ///     }
    ///
    /// Here, the ``VStack`` in the `ContentView` named “stack” is composed of a
    /// red frame with a custom ``Circle`` view ``View/overlay(_:alignment:)``
    /// at its center.
    ///
    /// The `circle` view has an attached ``DragGesture`` that targets the
    /// enclosing VStack's coordinate space. As the gesture recognizer's closure
    /// registers events inside `circle` it stores them in the shared `location`
    /// state variable and the ``VStack`` displays the coordinates in a ``Text``
    /// view.
    ///
    ///
    /// - Parameter name: A name used to identify this coordinate space.
    @inlinable
    public func coordinateSpace<T: Hashable>(name: T) -> some View {
        self.modifier(_CoordinateSpaceModifier(name: name))
    }
    
}

@frozen
@available(iOS 13.0, *)
public struct _CoordinateSpaceModifier<Name: Hashable>: ViewInputsModifier, MultiViewModifier, Equatable {
    
    public typealias Body = Never
    
    public var name: Name
    
    @inlinable
    public init(name: Name) {
        self.name = name
    }
    
    public static func _makeViewInputs(modifier: _GraphValue<_CoordinateSpaceModifier<Name>>, inputs: inout _ViewInputs) {
        let coordinateSpaceTransform = CoordinateSpaceTransform(modifier: modifier.value,
                                                                transform: inputs.transform,
                                                                position: inputs.animatedPosition)
        inputs.transform = Attribute(coordinateSpaceTransform)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct CoordinateSpaceTransform<T: Hashable>: Rule {
    
    @Attribute
    internal var modifier: _CoordinateSpaceModifier<T>

    @Attribute
    internal var transform: ViewTransform

    @Attribute
    internal var position: ViewOrigin
    
    internal var value: ViewTransform {
        var transform = self.transform
        transform.appendViewOrigin(self.position)
        transform.appendCoordinateSpace(name: self.modifier.name)
        return transform
    }

}
