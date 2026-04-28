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
import UIKit

@frozen
@available(iOS 13.0, *)
public struct _FlipForRTLEffect: PrimitiveViewModifier, MultiViewModifier, Equatable {

    public var isEnabled: Bool
    
    @inlinable
    public init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
    
    public static func ==(a: _FlipForRTLEffect, b: _FlipForRTLEffect) -> Bool {
        a.isEnabled == b.isEnabled
    }
    
    public static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var newInputs = inputs
        let flipForRTLTransform = Attribute(
            FlipForRTLTransform(
                effect: modifier.value,
                size: inputs.animatedSize,
                position: inputs.animatedPosition,
                transform: inputs.transform,
                layoutDirection: inputs.environmentAttribute(keyPath: \.layoutDirection)
            )
        )

        let flipForRTLFrame = Attribute(
            FlipForRTLFrame(
                effect: modifier.value,
                position: inputs.position,
                size: inputs.size,
                layoutDirection: inputs.environmentAttribute(keyPath: \.layoutDirection),
                pixelLength: inputs.environmentAttribute(keyPath: \.pixelLength))
        )
        
        let flipForRTLContainerPosition = Attribute(
            FlipForRTLContainerPosition(
                effect: modifier.value,
                containerPosition: inputs.containerPosition,
                layoutDirection: inputs.environmentAttribute(keyPath: \.layoutDirection)
            )
        )
        newInputs = inputs
        newInputs.transform = flipForRTLTransform
        newInputs.position = flipForRTLFrame.origin()
        newInputs.containerPosition = flipForRTLContainerPosition
        newInputs.size = flipForRTLFrame.size()
        
        var outputs = body(_Graph(), newInputs)
        
        guard inputs.preferences.requiresDisplayList else {
            return outputs
        }
        let id: DisplayList.Identity = .make()
        let displayList = FlipForRTLDisplayList(effect: modifier.value,
                                                position: inputs.animatedPosition,
                                                size: inputs.animatedSize,
                                                layoutDirection: inputs.environmentAttribute(keyPath: \.layoutDirection),
                                                containerPosition: inputs.containerPosition,
                                                content: .init(outputs.displayList),
                                                identity: id)
        outputs.displayList = Attribute(displayList)
        return outputs
    }
}

@available(iOS 13.0, *)
private struct FlipForRTLEnvironment: Rule { //BDCOV_EXCL_BLOCK 没有调用点

    @Attribute
    fileprivate var effect: _FlipForRTLEffect

    @Attribute
    fileprivate var environment: EnvironmentValues

    fileprivate static var initialValue: EnvironmentValues? {
        EnvironmentValues.init()
    }

    fileprivate var value: EnvironmentValues {
        var environment = environment
        if effect.isEnabled {
            environment.layoutDirection = .leftToRight
        }
        environment.resetTracker()
        return environment
    }
}

@available(iOS 13.0, *)
fileprivate struct FlipForRTLTransform: Rule {

    @Attribute
    fileprivate var effect: _FlipForRTLEffect
    
    @Attribute
    fileprivate var size: ViewSize

    @Attribute
    fileprivate var position: ViewOrigin
    
    @Attribute
    fileprivate var transform: ViewTransform

    @Attribute
    fileprivate var layoutDirection: LayoutDirection
    
    fileprivate static var initialValue: ViewTransform? {
        nil
    }
    
    var value: ViewTransform {
        if effect.isEnabled && layoutDirection == .rightToLeft {
            var tmpTransform = transform
            let adjustedPosition = position.value - tmpTransform.positionAdjustment
            if adjustedPosition.width != 0 && adjustedPosition.height != 0 && adjustedPosition.width.isNormal && adjustedPosition.height.isNormal {
                tmpTransform.appendTranslation(adjustedPosition * -1.0)
            }
            tmpTransform.appendAffineTransform(CGAffineTransform.init(a: -1.0, b: 0, c: 0, d: 1.0, tx: size.value.width, ty: 0), inverse: true)
            return tmpTransform
        } else {
            return transform
        }
    }
}

@available(iOS 13.0, *)
fileprivate func - (left: CGPoint, right: CGSize) -> CGSize {
    return CGSize(width: left.x - right.width, height: left.y - right.height)
}

@available(iOS 13.0, *)
fileprivate func * (left: CGSize, right: Double) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

@available(iOS 13.0, *)
fileprivate struct FlipForRTLFrame: Rule {
    @Attribute
    fileprivate var effect: _FlipForRTLEffect
    @Attribute
    fileprivate var position: ViewOrigin
    @Attribute
    fileprivate var size: ViewSize
    @Attribute
    fileprivate var layoutDirection: LayoutDirection
    @Attribute
    fileprivate var pixelLength: CGFloat
    
    fileprivate var value: ViewFrame {
        let size = self.size
        if effect.isEnabled && layoutDirection == .rightToLeft {
            var rect = CGRect(origin: position.value, size: size.value)
            rect.roundCoordinatesToNearestOrUp(toMultipleOf: pixelLength)
            return ViewFrame(origin: ViewOrigin(value: .zero), size: ViewSize(value: rect.size, _proposal: size._proposal))
        } else {
            return ViewFrame(origin: position, size: size)
        }
    }

}

@available(iOS 13.0, *)
fileprivate struct FlipForRTLContainerPosition: Rule {
   
    @Attribute
    fileprivate var effect: _FlipForRTLEffect
    
    @Attribute
    fileprivate var containerPosition: ViewOrigin
    
    @Attribute
    fileprivate var layoutDirection: LayoutDirection
    
    fileprivate var value: ViewOrigin {
        if effect.isEnabled && layoutDirection == .rightToLeft {
            return .zero
        } else {
            return containerPosition
        }
    }

}

@available(iOS 13.0, *)
internal struct FlipForRTLDisplayList: Rule {
    
    internal typealias Value = DisplayList
    @Attribute
    internal var effect: _FlipForRTLEffect
    @Attribute
    internal var position: ViewOrigin
    @Attribute
    internal var size: ViewSize
    @Attribute
    internal var layoutDirection: LayoutDirection
    @Attribute
    internal var containerPosition: ViewOrigin
    @OptionalAttribute
    internal var content: DisplayList?
    internal let identity: DisplayList.Identity
    
    internal var value: DisplayList {
        
        let displayList = content ?? .empty
        
        guard !displayList.items.isEmpty else {
            return displayList
        }
        let size = self.size.value
        
        if effect.isEnabled && layoutDirection == .rightToLeft {
            
            let displayListEffect: DisplayList.Effect = .affine(CGAffineTransform(
                a: -1.0,
                b: 0,
                c: 0,
                d: 1.0,
                tx: size.width,
                ty: 0.0
            ))
            var item = DisplayList.Item(
                frame: CGRect(origin: CGPoint(x: position.value.x - containerPosition.value.x,
                                              y: position.value.y - containerPosition.value.y),
                              size: size),
                version: .make(),
                value: .effect(displayListEffect, displayList),
                identity: identity
            )
            item.canonicalize()
            return DisplayList(item: item)
        } else {
            return displayList
        }
    }
}

@available(iOS 13.0, *)
extension View {

    /// Sets whether this view mirrors its contents horizontally when the layout
    /// direction is right-to-left.
    ///
    /// Use `flipsForRightToLeftLayoutDirection(_:)` when you need the system to
    /// horizontally mirror the contents of the view when presented in
    /// a right-to-left layout.
    ///
    /// To override the layout direction for a specific view, use the
    /// ``View/environment(_:_:)`` view modifier to explicitly override
    /// the ``EnvironmentValues/layoutDirection`` environment value for
    /// the view.
    ///
    /// - Parameter enabled: A Boolean value that indicates whether this view
    ///   should have its content flipped horizontally when the layout
    ///   direction is right-to-left. By default, views will adjust their layouts
    ///   automatically in a right-to-left context and do not need to be mirrored.
    ///
    /// - Returns: A view that conditionally mirrors its contents
    ///   horizontally when the layout direction is right-to-left.
    @inlinable public func flipsForRightToLeftLayoutDirection(_ enabled: Bool) -> some View {
        modifier(_FlipForRTLEffect(isEnabled: enabled))
    }

}
