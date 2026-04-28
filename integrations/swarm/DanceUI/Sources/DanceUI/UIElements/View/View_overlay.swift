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
internal import DanceUIRuntime

@frozen
@available(iOS 13.0, *)
public struct _OverlayModifier<Overlay: View> : MultiViewModifier, PrimitiveViewModifier, Equatable {

    public typealias Body = Never
    
    public var overlay: Overlay
    
    public var alignment: Alignment
    
    @inlinable
    public init(overlay: Overlay, alignment: Alignment = .center) {
        self.overlay = overlay
        self.alignment = alignment
    }
    
    public static func _makeView(modifier: _GraphValue<_OverlayModifier<Overlay>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let overlay = modifier[{ .of(&$0.overlay) }]
        let alignment = modifier[{ .of(&$0.alignment) }]
        
        return makeSecondaryLayerView(secondaryLayer: overlay.value,
                                      alignment: alignment.value,
                                      inputs: inputs,
                                      body: body,
                                      flipOrder: false)
    }
    
    public static func == (lhs: _OverlayModifier<Overlay>,
                           rhs: _OverlayModifier<Overlay>) -> Bool {
        lhs.alignment == rhs.alignment && DGCompareValues(lhs: lhs.overlay,
                                                          rhs: rhs.overlay)
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Layers a secondary view in front of this view.
    ///
    /// When you apply an overlay to a view, the original view continues to
    /// provide the layout characteristics for the resulting view. In the
    /// following example, the heart image is shown overlaid in front of, and
    /// aligned to the bottom of the folder image.
    ///
    ///     Image(systemName: "folder")
    ///         .font(.system(size: 55, weight: .thin))
    ///         .overlay(Text("❤️"), alignment: .bottom)
    ///
    ///
    /// - Parameters:
    ///   - overlay: The view to layer in front of this view.
    ///   - alignment: The alignment for `overlay` in relation to this view.
    ///
    /// - Returns: A view that layers `overlay` in front of the view.
    @available(iOS, deprecated: 100000.0, message: "Use `overlay(alignment:content:)` instead.")
    @inlinable
    @_disfavoredOverload
    public func overlay<Overlay: View>(_ overlay: Overlay, alignment: Alignment = .center) -> some View {
        modifier(_OverlayModifier(overlay: overlay, alignment: alignment))
    }
    
    /// Layers the views that you specify in front of this view.
    ///
    /// Use this modifier to place one or more views in front of another view.
    /// For example, you can place a group of stars on a ``RoundedRectangle``:
    ///
    ///     RoundedRectangle(cornerRadius: 8)
    ///         .frame(width: 200, height: 100)
    ///         .overlay(alignment: .topLeading) { Star(color: .red) }
    ///         .overlay(alignment: .topTrailing) { Star(color: .yellow) }
    ///         .overlay(alignment: .bottomLeading) { Star(color: .green) }
    ///         .overlay(alignment: .bottomTrailing) { Star(color: .blue) }
    ///
    /// The example above assumes that you've defined a `Star` view with a
    /// parameterized color:
    ///
    ///     struct Star: View {
    ///         var color = Color.yellow
    ///
    ///         var body: some View {
    ///             Image(systemName: "star.fill")
    ///                 .foregroundStyle(color)
    ///         }
    ///     }
    ///
    /// By setting different `alignment` values for each modifier, you make the
    /// stars appear in different places on the rectangle:
    ///
    ///
    /// If you specify more than one view in the `content` closure, the modifier
    /// collects all of the views in the closure into an implicit ``ZStack``,
    /// taking them in order from back to front. For example, you can place a
    /// star and a ``Circle`` on a field of ``ShapeStyle/blue``:
    ///
    ///     Color.blue
    ///         .frame(width: 200, height: 200)
    ///         .overlay {
    ///             Circle()
    ///                 .frame(width: 100, height: 100)
    ///             Star()
    ///         }
    ///
    /// Both the overlay modifier and the implicit ``ZStack`` composed from the
    /// overlay content --- the circle and the star --- use a default
    /// ``Alignment/center`` alignment. The star appears centered on the circle,
    /// and both appear as a composite view centered in front of the square:
    ///
    ///
    /// If you specify an alignment for the overlay, it applies to the implicit
    /// stack rather than to the individual views in the closure. You can see
    /// this if you add the ``Alignment/bottom`` alignment:
    ///
    ///     Color.blue
    ///         .frame(width: 200, height: 200)
    ///         .overlay(alignment: .bottom) {
    ///             Circle()
    ///                 .frame(width: 100, height: 100)
    ///             Star()
    ///         }
    ///
    /// The circle and the star move down as a unit to align the stack's bottom
    /// edge with the bottom edge of the square, while the star remains
    /// centered on the circle:
    ///
    ///
    /// To control the placement of individual items inside the `content`
    /// closure, either use a different overlay modifier for each item, as the
    /// earlier example of stars in the corners of a rectangle demonstrates, or
    /// add an explicit ``ZStack`` inside the content closure with its own
    /// alignment:
    ///
    ///     Color.blue
    ///         .frame(width: 200, height: 200)
    ///         .overlay(alignment: .bottom) {
    ///             ZStack(alignment: .bottom) {
    ///                 Circle()
    ///                     .frame(width: 100, height: 100)
    ///                 Star()
    ///             }
    ///         }
    ///
    /// The stack alignment ensures that the star's bottom edge aligns with the
    /// circle's, while the overlay aligns the composite view with the square:
    ///
    /// You can achieve layering without an overlay modifier by putting both the
    /// modified view and the overlay content into a ``ZStack``. This can
    /// produce a simpler view hierarchy, but changes the layout priority that
    /// DanceUI applies to the views. Use the overlay modifier when you want the
    /// modified view to dominate the layout.
    ///
    /// If you want to specify a ``ShapeStyle`` like a ``Color`` or a
    /// ``Material`` as the overlay, use
    /// ``View/overlay(_:ignoresSafeAreaEdges:)`` instead. To specify a
    /// ``Shape``, use ``View/overlay(_:in:fillStyle:)``.
    ///
    /// - Parameters:
    ///   - alignment: The alignment that the modifier uses to position the
    ///     implicit ``ZStack`` that groups the foreground views. The default
    ///     is ``Alignment/center``.
    ///   - content: A ``ViewBuilder`` that you use to declare the views to
    ///     draw in front of this view, stacked in the order that you list them.
    ///     The last view that you list appears at the front of the stack.
    ///
    /// - Returns: A view that uses the specified content as a foreground.
    @inlinable
    public func overlay<V>(alignment: Alignment = .center, @ViewBuilder content: () -> V) -> some View where V : View {
        modifier(_OverlayModifier(overlay: content(), alignment: alignment))
    }
}
