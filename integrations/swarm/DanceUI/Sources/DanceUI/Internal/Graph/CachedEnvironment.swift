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

@available(iOS 13.0, *)
internal struct CachedEnvironment {

    internal var environment: Attribute<EnvironmentValues>

    internal var items: [Item]

    internal var constants: [HashableConstant: DGAttribute]

    fileprivate var animatedFrame: AnimatedFrame?

    fileprivate var resolvedFgStyles: [ResolvedFgStyle: Attribute<_ShapeStyle_Shape.ResolvedStyle>]
    
    internal struct Item: Equatable {
        internal var key: PartialKeyPath<EnvironmentValues>

        internal var value: DGAttribute
    }
    
    internal init(_ attribute: Attribute<EnvironmentValues>) {
        self.environment = attribute
        items = []
        constants = [:]
        animatedFrame = nil
        resolvedFgStyles = [:]
    }
    
    internal mutating func animatedSize(for inputs: _ViewInputs) -> Attribute<ViewSize> {
        var animatedFrame = _createAnimatedFrameIfNeeded(for: inputs)
        return animatedFrame.animatedSize(for: inputs)
    }
    
    internal mutating func animatedPosition(for inputs: _ViewInputs) -> Attribute<ViewOrigin> {
        var animatedFrame = _createAnimatedFrameIfNeeded(for: inputs)
        return animatedFrame.animatedPosition(for: inputs)
    }
    
    @inline(__always)
    private mutating func _createAnimatedFrameIfNeeded(for inputs: _ViewInputs) -> AnimatedFrame {
        let inputsTransaction = inputs.geometryTransaction()
        let pixelLength = attribute(keyPath: \EnvironmentValues.pixelLength)
        
        guard let animatedFrame = animatedFrame,
              animatedFrame.viewPhase == inputs.phase,
              animatedFrame.transaction == inputsTransaction,
              animatedFrame.time == inputs.time,
              animatedFrame.pixelLength == pixelLength,
              animatedFrame.position == inputs.position,
              animatedFrame.size == inputs.size else {
                  
                  let animationsDisabled = inputs.disableAnimations
                  let animatableFrameAttribute = AnimatableFrameAttribute(position: inputs.position,
                                                                          size: inputs.size,
                                                                          pixelLength: pixelLength, 
                                                                          environment: self.environment,
                                                                          phase: inputs.phase,
                                                                          time: inputs.time,
                                                                          transaction: inputsTransaction,
                                                                          animationsDisabled: animationsDisabled)
                  let attr = Attribute(animatableFrameAttribute)
                  attr.flags = DGAttributeFlags.active
                  let animatedFrame = AnimatedFrame(position: inputs.position,
                                                    size: inputs.size,
                                                    pixelLength: pixelLength,
                                                    time: inputs.time,
                                                    transaction: inputs.geometryTransaction(),
                                                    viewPhase: inputs.phase,
                                                    animatedFrame: attr,
                                                    animatedPosition: nil,
                                                    animatedSize: nil)
                  self.animatedFrame = animatedFrame
                  return animatedFrame
              }
        return animatedFrame
    }
    
    @inlinable
    internal mutating func attribute<Member>(keyPath: KeyPath<EnvironmentValues, Member>) -> Attribute<Member> {
        if let item: Item = items.first(where: { $0.key == keyPath }) {
            return Attribute<Member>(identifier: item.value)
        }
        let result = environment[keyPath]
        items.append(Item(key: keyPath, value: result.identifier))
        return result
    }
    
    // internal mutating func attribute<A>(id: CachedEnvironment.ID, _ transform : (EnvironmentValues) -> A) -> Attribute<A>
    
    internal mutating func intern<ValueType>(_ value: ValueType, id: Int) -> Attribute<ValueType> {
        let hashableConstant = HashableConstant(value, id: id)
        if let attribute = constants[hashableConstant] {
            return Attribute<ValueType>(identifier: attribute)
        } else {
            let attribute = Attribute<ValueType>(value: value)
            constants[hashableConstant] = attribute.identifier
            return attribute
        }
    } 
    
    @inlinable
    internal mutating func resolvedForegroundStyle(for inputs: _ViewInputs,
                                                   role: ShapeRole,
                                                   mode: Attribute<ShapeStyle_ResolverMode>?) -> Attribute<_ShapeStyle_Shape.ResolvedStyle> {
        let resolvedFgStyle = ResolvedFgStyle(environment: self.environment,
                                              time: inputs.time,
                                              transaction:inputs.transaction,
                                              viewPhase: inputs.phase,
                                              mode: OptionalAttribute<ShapeStyle_ResolverMode>(mode),
                                              role: role,
                                              animationsDisabled: inputs.disableAnimations)
        
        if let resolvedStyle = resolvedFgStyles[resolvedFgStyle] {
            return resolvedStyle
        }
        
        let style = resolvedFgStyle.makeStyle()
        self.resolvedFgStyles[resolvedFgStyle] = style
        return style
    }
}

@available(iOS 13.0, *)
private struct ResolvedFgStyle: Hashable {

    fileprivate let environment: Attribute<EnvironmentValues>

    fileprivate let time: Attribute<Time>

    fileprivate let transaction: Attribute<Transaction>

    fileprivate let viewPhase: Attribute<_GraphInputs.Phase>

    fileprivate let mode: OptionalAttribute<ShapeStyle_ResolverMode>

    fileprivate let role: ShapeRole

    fileprivate let animationsDisabled: Bool
    
    fileprivate func makeStyle() -> Attribute<_ShapeStyle_Shape.ResolvedStyle> {
        let helper = AnimatableAttributeHelper<_ShapeStyle_Shape.ResolvedStyle>(phase: self.viewPhase,
                                                                                time: self.time,
                                                                                transaction: self.transaction)
        let resolvedStyle = ShapeStyleResolver<AnyShapeStyle>(style: OptionalAttribute<AnyShapeStyle>(nil),
                                                              mode: self.mode,
                                                              environment: self.environment,
                                                              role: self.role,
                                                              animationsDisabled: self.animationsDisabled,
                                                              helper: helper)
        let attribute = Attribute(resolvedStyle)
        attribute.flags = [.active]
        return attribute
    }
}

@available(iOS 13.0, *)
private struct AnimatedFrame {

    internal var position: Attribute<ViewOrigin>

    internal var size: Attribute<ViewSize>

    internal var pixelLength: Attribute<CGFloat>

    internal var time: Attribute<Time>

    internal var transaction: Attribute<Transaction>

    internal var viewPhase: Attribute<_GraphInputs.Phase>

    internal var animatedFrame: Attribute<ViewFrame>

    internal var animatedPosition: Attribute<ViewOrigin>?

    internal var animatedSize: Attribute<ViewSize>?
    
    internal mutating func animatedSize(for inputs: _ViewInputs) -> Attribute<ViewSize> {
        if let size = animatedSize {
            return size
        }
        let animatedSize = animatedFrame[{.of(&$0.size)}]
        self.animatedSize = animatedSize
        return animatedSize
    }
    
    internal mutating func animatedPosition(for inputs: _ViewInputs) -> Attribute<ViewOrigin> {
        if let position = animatedPosition {
            return position
        }
        let animatedPosition = animatedFrame[{.of(&$0.origin)}]
        self.animatedPosition = animatedPosition
        return animatedPosition
    }
}

@available(iOS 13.0, *)
internal struct ViewFrame: Animatable, Equatable {
    
    internal typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
    
    internal var origin: ViewOrigin
    
    internal var size: ViewSize
    
    internal static let zero: ViewFrame = .init(origin: .zero, size: .zero)
    
    internal var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
        get {
            AnimatablePair(origin.animatableData, size.animatableData)
        }
        
        set {
            origin.animatableData = newValue.first
            size.animatableData = newValue.second
        }
    }
    
}

@available(iOS 13.0, *)
extension Attribute where Value == ViewFrame {
    
    internal func origin() -> Attribute<ViewOrigin> {
        self[\ViewFrame.origin]
    }
    
    internal func size() -> Attribute<ViewSize> {
        self[\ViewFrame.size]
    }
    
}
