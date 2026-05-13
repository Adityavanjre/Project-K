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

@frozen
@available(iOS 13.0, *)
public struct _OffsetEffect: GeometryEffect, Equatable {
    
    public typealias AnimatableData = AnimatablePair<CGFloat, CGFloat>
    
    public var offset: CGSize
    
    @inlinable
    public init(offset: CoreGraphics.CGSize) {
        self.offset = offset
    }
    
    public var animatableData: AnimatableData {
        get {
            .init(offset.width, offset.height)
        }
        
        set {
            offset.width = newValue.first
            offset.height = newValue.second
        }
    }
    
    public static func _makeView(modifier: _GraphValue<_OffsetEffect>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        newInputs.position = Attribute(OffsetPosition(effect: modifier.value,
                                                      position: inputs.position,
                                                      layoutDirection: inputs.environmentAttribute(keyPath: \.layoutDirection)))
        return body(_Graph(), newInputs)
    }
    
    public func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = CGAffineTransform(translationX: offset.width, y: offset.height)
        return .init(m11: translation.a, m12: translation.b, m13: 0,
                     m21: translation.c, m22: translation.d, m23: 0,
                     m31: translation.tx, m32: translation.ty, m33: .infinity)
    }
    
    public static func == (a: _OffsetEffect, b: _OffsetEffect) -> Bool {
        a.offset == b.offset
    }

}

@available(iOS 13.0, *)
extension View {
    
    /// Offset this view by the horizontal and vertical amount specified in the
    /// offset parameter.
    ///
    /// Use `offset(_:)` to shift the displayed contents by the amount
    /// specified in the `offset` parameter.
    ///
    /// The original dimensions of the view aren't changed by offsetting the
    /// contents; in the example below the gray border drawn by this view
    /// surrounds the original position of the text:
    ///
    ///     Text("Offset by passing CGSize()")
    ///         .border(Color.green)
    ///         .offset(CGSize(width: 20, height: 25))
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameter offset: The distance to offset this view.
    ///
    /// - Returns: A view that offsets this view by `offset`.
    @inlinable
    public func offset(_ offset: CGSize) -> some View {
        return modifier(_OffsetEffect(offset: offset))
    }
    
    
    /// Offset this view by the specified horizontal and vertical distances.
    ///
    /// Use `offset(x:y:)` to shift the displayed contents by the amount
    /// specified in the `x` and `y` parameters.
    ///
    /// The original dimensions of the view aren't changed by offsetting the
    /// contents; in the example below the gray border drawn by this view
    /// surrounds the original position of the text:
    ///
    ///     Text("Offset by passing horizontal & vertical distance")
    ///         .border(Color.green)
    ///         .offset(x: 20, y: 50)
    ///         .border(Color.gray)
    ///
    ///
    /// - Parameters:
    ///   - x: The horizontal distance to offset this view.
    ///   - y: The vertical distance to offset this view.
    ///
    /// - Returns: A view that offsets this view by `x` and `y`.
    @inlinable
    public func offset(x: CGFloat = 0, y: CGFloat = 0) -> some View {
        return offset(CGSize(width: x, height: y))
    }
    
}

@available(iOS 13.0, *)
internal struct OffsetPosition: Rule {
    
    internal typealias Value = ViewOrigin
    
    @Attribute
    internal var effect: _OffsetEffect

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var layoutDirection: LayoutDirection
    
    internal var value: ViewOrigin {
        var position = self.position
        position.value.x += layoutDirection == .leftToRight ? effect.offset.width : -effect.offset.width
        position.value.y += effect.offset.height
        return position
    }
}
