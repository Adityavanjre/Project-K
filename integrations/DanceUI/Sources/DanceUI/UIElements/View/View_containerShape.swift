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
    /// Sets the container shape to use for any container relative shape
    /// within this view.
    ///
    /// The example below defines a view that shows its content with a rounded
    /// rectangle background and the same container shape. Any
    /// ``ContainerRelativeShape`` within the `content` matches the rounded
    /// rectangle shape from this container inset as appropriate.
    ///
    ///     struct PlatterContainer<Content: View> : View {
    ///         @ViewBuilder var content: Content
    ///         var body: some View {
    ///             content
    ///                 .padding()
    ///                 .containerShape(shape)
    ///                 .background(shape.fill(.background))
    ///         }
    ///         var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 20) }
    ///     }
    ///
    @inlinable
    public func containerShape<T>(_ shape: T) -> some View where T: InsettableShape {
        modifier(_ContainerShapeModifier(shape: shape))
    }
}

@available(iOS 13.0, *)
@frozen
public struct _ContainerShapeModifier<Shape>: MultiViewModifier, PrimitiveViewModifier where Shape: InsettableShape {
    
    public var shape: Shape
    
    @inlinable
    public init(shape: Shape) {
        self.shape = shape
    }
    
    public static func _makeView(modifier: _GraphValue<_ContainerShapeModifier<Shape>>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var copyInputs = inputs
        let shape = modifier[{.of(&$0.shape)}]
        let shapeAttribute = Shape.makeAnimatable(value: shape, inputs: copyInputs.base)
        copyInputs.setContainerShape(shapeAttribute, isSystemShape: false)
        return body(_Graph(), copyInputs)
    }
}
