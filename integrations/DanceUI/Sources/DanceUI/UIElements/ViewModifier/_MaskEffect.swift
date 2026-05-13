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
public struct _MaskEffect<Mask>: PrimitiveViewModifier, MultiViewModifier where Mask : View {
    
    public var mask: Mask
    
    @inlinable
    public init(mask: Mask) {
        self.mask = mask
    }
    
    public static func _makeView(modifier: _GraphValue<_MaskEffect<Mask>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        .makeMaskView(inputs: inputs, contentBody: { inputsOfContentBody in
            body(_Graph(), inputsOfContentBody)
        }, maskBody: { inputsOfMaskBody in
            let maskValue = modifier[{.of(&$0.mask)}]
            return Mask.makeDebuggableView(value: maskValue, inputs: inputsOfMaskBody)
        }, outputsFromMask: false,
           mayUseForegroundColor: true,
           alignment: nil)
    }
}

@frozen
@available(iOS 13.0, *)
public struct _MaskAlignmentEffect<Mask>: PrimitiveViewModifier, MultiViewModifier where Mask: View {
    
    public var alignment: Alignment
    
    public var mask: Mask
    
    @inlinable
    public init(alignment: Alignment, mask: Mask) {
        self.mask = mask
        self.alignment = alignment
    }
    
    public static func _makeView(modifier: _GraphValue<_MaskAlignmentEffect<Mask>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let alignment = modifier[{.of(&$0.alignment)}]
        return .makeMaskView(inputs: inputs, contentBody: { inputsOfContentBody in
            body(_Graph(), inputsOfContentBody)
        }, maskBody: { inputsOfMaskBody in
            let maskValue = modifier[{.of(&$0.mask)}]
            return Mask.makeDebuggableView(value: maskValue, inputs: inputsOfMaskBody)
        }, outputsFromMask: false,
           mayUseForegroundColor: true,
           alignment: alignment.value)
    }
}

@available(iOS 13.0, *)
extension _MaskEffect: Equatable where Mask: Equatable {
    public static func == (a: _MaskEffect<Mask>, b: _MaskEffect<Mask>) -> Bool {
        a.mask == b.mask
    }
}

@available(iOS 13.0, *)
extension View {
    
    /// Masks this view using the alpha channel of the given view.
    ///
    /// Use `mask(_:)` when you want to apply the alpha (opacity) value of
    /// another view to the current view.
    ///
    /// This example shows an image masked by rectangle with a 10% opacity:
    ///
    ///     Image(systemName: "envelope.badge.fill")
    ///         .foregroundColor(Color.blue)
    ///         .font(.system(size: 128, weight: .regular))
    ///         .mask(Rectangle().opacity(0.1))
    ///
    /// - Parameter mask: The view whose alpha the rendering system applies to
    ///   the specified view.
    @available(iOS, deprecated: 100000.0, message: "Use overload where mask accepts a @ViewBuilder instead.")
    @available(macOS, deprecated: 100000.0, message: "Use overload where mask accepts a @ViewBuilder instead.")
    @available(tvOS, deprecated: 100000.0, message: "Use overload where mask accepts a @ViewBuilder instead.")
    @available(watchOS, deprecated: 100000.0, message: "Use overload where mask accepts a @ViewBuilder instead.")
    @inlinable
    public func mask<Mask>(_ mask: Mask) -> some View where Mask: View {
        modifier(_MaskEffect(mask: mask))
    }
    
    /// Masks this view using the alpha channel of the given view.
    ///
    /// Use `mask(_:)` when you want to apply the alpha (opacity) value of
    /// another view to the current view.
    ///
    /// This example shows an image masked by rectangle with a 10% opacity:
    ///
    ///     Image(systemName: "envelope.badge.fill")
    ///         .foregroundColor(Color.blue)
    ///         .font(.system(size: 128, weight: .regular))
    ///         .mask {
    ///             Rectangle().opacity(0.1)
    ///         }
    ///
    /// - Parameters:
    ///     - alignment: The alignment for `mask` in relation to this view.
    ///     - mask: The view whose alpha the rendering system applies to
    ///       the specified view.
    @inlinable
    public func mask<Mask>(alignment: Alignment = .center,
                           @ViewBuilder _ mask: () -> Mask) -> some View where Mask: View {
        modifier(_MaskAlignmentEffect(alignment: alignment, mask: mask()))
        
    }
}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal static func makeMaskView(inputs: _ViewInputs,
                                      contentBody: (_ViewInputs) -> _ViewOutputs,
                                      maskBody: (_ViewInputs) -> _ViewOutputs,
                                      outputsFromMask: Bool,
                                      mayUseForegroundColor: Bool,
                                      alignment: Attribute<Alignment>?) -> _ViewOutputs {
        
        let requiresDisplayList = inputs.preferences.requiresDisplayList
        
        let animatedPosition = inputs.animatedPosition
        
        let layoutDirection = inputs.environmentAttribute(keyPath: \.layoutDirection)
        
        let geometry = SecondaryLayerGeometryQuery(alignment: OptionalAttribute(alignment),
                                                   layoutDirection: layoutDirection,
                                                   primaryPosition: inputs.position,
                                                   primarySize: inputs.size)
        
        let geometryAttribute = Attribute(geometry)
        
        var maskBodyInputs = inputs
        
        maskBodyInputs.size = geometryAttribute.size()
        
        maskBodyInputs.position = geometryAttribute.origin()
        
        maskBodyInputs.enableLayouts = true
        
        maskBodyInputs.containerPosition = animatedPosition
        
        maskBodyInputs.preferences.removeAll()
        
        if requiresDisplayList && !maskBodyInputs.preferences.requiresDisplayList {
            maskBodyInputs.preferences.requiresDisplayList = true
        }
        
        if mayUseForegroundColor {
            let maskForegroundAttribute = Attribute(MaskDefaultForeground(environment: maskBodyInputs.environment))
            maskBodyInputs.updateCachedEnvironment(attribute: maskForegroundAttribute)
        }
        
        var contentBodyInputs = inputs
        
        contentBodyInputs.enableLayouts = true
        
        contentBodyInputs.containerPosition = animatedPosition
        
        if outputsFromMask {
            swap(&contentBodyInputs, &maskBodyInputs)
        }
        
        let contentBodyOutputs = contentBody(contentBodyInputs)
        
        let maskBodyOutputs = maskBody(maskBodyInputs)
        
        var maskDisplayList: Attribute<DisplayList>? = nil
        
        if requiresDisplayList {
            
            let contentList = contentBodyOutputs.displayList
            
            let maskList = maskBodyOutputs.displayList
            
            maskDisplayList = Attribute(MaskDisplayList(position: animatedPosition,
                                                                     size: inputs.animatedSize,
                                                                     containerPosition: inputs.containerPosition,
                                                                     contentList: contentList,
                                                                     maskList: maskList,
                                                                     identity: .make()))
        }
        
        let outputs: (_ViewOutputs, _ViewOutputs) = outputsFromMask ? (maskBodyOutputs, contentBodyOutputs) : (contentBodyOutputs, maskBodyOutputs)
        
        geometryAttribute.mutateBody(as: SecondaryLayerGeometryQuery.self, invalidating: true) { body in
            body.$primaryLayoutComputer = outputs.0.layout.attribute
            body.$secondaryLayoutComputer = outputs.1.layout.attribute
        }
        
        var resultViewOutputs = outputs.0
        
        resultViewOutputs.displayList = maskDisplayList
        
        return resultViewOutputs
    }
}

@available(iOS 13.0, *)
private struct MaskDisplayList: Rule {
    
    fileprivate typealias Value = DisplayList
    
    @Attribute
    fileprivate var position: ViewOrigin
    
    @Attribute
    fileprivate var size: ViewSize
    
    @Attribute
    fileprivate var containerPosition: ViewOrigin
    
    @OptionalAttribute
    fileprivate var contentList: DisplayList?
    
    @OptionalAttribute
    fileprivate var maskList: DisplayList?
    
    fileprivate let identity: DisplayList.Identity
    
    fileprivate init(position: Attribute<ViewOrigin>,
                     size: Attribute<ViewSize>,
                     containerPosition: Attribute<ViewOrigin>,
                     contentList: Attribute<DisplayList>?,
                     maskList: Attribute<DisplayList>?,
                     identity: DisplayList.Identity) {
        self._position = position
        self._size = size
        self._containerPosition = containerPosition
        self._contentList = OptionalAttribute(contentList)
        self._maskList = OptionalAttribute(maskList)
        self.identity = identity
    }
    
    fileprivate var value: DisplayList {
        
        let contentDisplayList = self.contentList ?? .empty
        
        let maskDisplayList = self.maskList ?? .empty
        
        guard !contentDisplayList.items.isEmpty || !maskDisplayList.items.isEmpty else {
            return .empty
        }
        
        let displayListItemPosition: CGPoint = position.value.subPoint(containerPosition.value)
        
        var item = DisplayList.Item(frame: CGRect(origin: displayListItemPosition, size: size.value),
                                    version: .make(),
                                    value: .effect(.mask(maskDisplayList), contentDisplayList),
                                    identity: identity)
        
        item.canonicalize()
        
        if case .empty = item.value,
           contentDisplayList.features == .empty {
            return.empty
        }
        
        return DisplayList(item: item)
    }
}
