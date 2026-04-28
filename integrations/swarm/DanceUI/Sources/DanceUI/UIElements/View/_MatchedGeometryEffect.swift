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
public struct _MatchedGeometryEffect<ID: Hashable>: MultiViewModifier, PrimitiveViewModifier {
    
    public var id: ID
    
    public var namespace: Namespace.ID
    
    public var args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)
    
    internal var qualifiedID: Pair<ID, Namespace.ID> {
        .init(first: id, second: namespace)
    }
    
    @inlinable
    public init(id: ID,
                namespace: Namespace.ID,
                args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)) {
        self.id = id
        self.namespace = namespace
        self.args = args
    }
    
    public static func _makeView(modifier: _GraphValue<_MatchedGeometryEffect<ID>>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let argsAttribute = modifier[{.of(&$0.args)}].value
        var newInputs = inputs
        var matchedFrameAttribute: Attribute<ViewFrame>? = nil
        var sharedFrameAttrribute: Attribute<(ViewFrame?, DanceUIGraph.AnyOptionalAttribute)>? = nil
        if let scope = inputs.matchedGeometryScope {
            let sharedFrame = Attribute(MatchedSharedFrame(modifier: modifier.value, args: argsAttribute, transaction: inputs.transaction, phase: inputs.phase, size: inputs.size, position: inputs.position, transform: inputs.transform, scope: scope, frameIndex: nil, selfAttribute: .nil, resetSeed: 0))
            sharedFrame.flags = .removable
            let matchedFrame = Attribute(MatchedFrame(sharedFrame: sharedFrame, args: argsAttribute, size: inputs.size, position: inputs.position, transform: inputs.transform))
            newInputs.position = matchedFrame.origin()
            newInputs.size = matchedFrame.size()
            newInputs.containerPosition = inputs.animatedPosition
            matchedFrameAttribute = matchedFrame
            sharedFrameAttrribute = sharedFrame
        }
        var outputs = body(_Graph(), newInputs)
        if let matchedFrame = matchedFrameAttribute {
            matchedFrame.mutateBody(as: MatchedFrame.self, invalidating: true) { body in
                body.$childLayoutComputer = outputs.layout.attribute
            }
        }
        
        guard inputs.preferences.requiresDisplayList, let sharedFrame = sharedFrameAttrribute, let content = outputs.displayList else {
            return outputs
        }
        let displayList = MatchedDisplayList(sharedFrame: sharedFrame, args: argsAttribute, content: content, position: inputs.animatedPosition, size: inputs.animatedSize, transform: inputs.transform, containerPosition: inputs.containerPosition, identity: .make())
        outputs.displayList = Attribute(displayList)
        return outputs
    }
    
}

@available(iOS 13.0, *)
private struct MatchedFrame: Rule {
    
    internal typealias Value = ViewFrame
    
    @Attribute
    internal var sharedFrame: (ViewFrame?, DanceUIGraph.AnyOptionalAttribute)
    
    @Attribute
    internal var args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var transform: ViewTransform
    
    @OptionalAttribute
    internal var childLayoutComputer: LayoutComputer?
    
    internal var value: ViewFrame {
        let sharedFrame = self.sharedFrame
        guard sharedFrame.1.identifier != $sharedFrame.identifier, let viewFrame = sharedFrame.0 else {
            return ViewFrame(origin: position, size: size)
        }
        
        let args = self.args
        var newPosition = viewFrame.origin
        var size = self.size.value
        var proposal = viewFrame.size.value
        if args.properties.contains(.size) {
            size = viewFrame.size.value
            if let layoutComputer = self.childLayoutComputer {
                proposal = viewFrame.size.value
                size = layoutComputer.engine.sizeThatFits(_ProposedSize(size: proposal))
                newPosition.value.x = (viewFrame.size.value.width - size.width) * args.anchor.x + viewFrame.origin.value.x
                newPosition.value.y = (viewFrame.size.value.height - size.height) * args.anchor.y + viewFrame.origin.value.y
            }
        } else {
            proposal = viewFrame.size._proposal
        }
        guard args.properties.contains(.position) else {
            return ViewFrame(origin: position, size: ViewSize(value: size, _proposal: proposal))
        }
        
        var transform = self.transform
        let position = self.position
        let translationX = position.value.x - transform.positionAdjustment.width
        let translationY = position.value.y - transform.positionAdjustment.height
        
        transform.appendTranslation(CGSize(width: -translationX, height: -translationY))
        
        newPosition.value.convert(from: .global, transform: transform)
        
        newPosition.value.x = position.value.x + (newPosition.value.x - (size.width * args.anchor.x))
        newPosition.value.y = position.value.y + (newPosition.value.y - (size.height * args.anchor.y))
        
        return ViewFrame(origin: newPosition, size: ViewSize(value: size, _proposal: proposal))
    }
}

@available(iOS 13.0, *)
private struct MatchedDisplayList: Rule {
    
    internal typealias Value = DisplayList
    
    @Attribute
    internal var sharedFrame: (ViewFrame?, DanceUIGraph.AnyOptionalAttribute)
    
    @Attribute
    internal var args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)
    
    @Attribute
    internal var content: DisplayList
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var transform: ViewTransform
    
    @Attribute
    internal var containerPosition: ViewOrigin
    
    internal let identity: DisplayList.Identity
    
    internal var value: DisplayList {
        
        assert((args.properties.rawValue & 0x4) == 0)
        
        let position = self.position
        let containerPosition = self.containerPosition
        let origin = CGPoint(x: position.value.x - containerPosition.value.x, y: position.value.y - containerPosition.value.y)
        let content = self.content
        var item = DisplayList.Item(frame: CGRect(origin: origin, size: size.value), version: .make(), value: .effect(.identity, content), identity: identity)
        item.canonicalize()
        
        return DisplayList(item: item)
    }
    
}

@available(iOS 13.0, *)
private struct MatchedSharedFrame<ID: Hashable>: StatefulRule,
                                                 DanceUIGraph.ObservedAttribute,
                                                 RemovableAttribute {
    
    internal typealias Value = (ViewFrame?, DanceUIGraph.AnyOptionalAttribute)
    
    @Attribute
    internal var modifier: _MatchedGeometryEffect<ID>
    
    @Attribute
    internal var args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)
    
    @Attribute
    internal var transaction: Transaction
    
    @Attribute
    internal var phase: _GraphInputs.Phase
    
    @Attribute
    internal var size: ViewSize
    
    @Attribute
    internal var position: ViewOrigin
    
    @Attribute
    internal var transform: ViewTransform
    
    internal let scope: MatchedGeometryScope
    
    internal var frameIndex: Int?
    
    internal var selfAttribute: DGAttribute
    
    internal var resetSeed: UInt32
    
    internal mutating func updateValue() {
        if selfAttribute == .nil {
            selfAttribute = .current!
        }
        
        let phase = self.phase
        if phase.seed != resetSeed {
            resetSeed = phase.seed
            destroy()
        }
        let view = MatchedGeometryScope.Frame.View(attribute: selfAttribute, args: $args, transaction: $transaction, phase: $phase, size: $size, position: $position, transform: $transform)
        value = scope.frame(index: &frameIndex, for: modifier.qualifiedID, view: view)
        
    }
    
    internal static func willRemove(attribute: DGAttribute) {
        let value = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        value.pointee.destroy()
    }
    
    internal static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    internal mutating func destroy() {
        guard let index = frameIndex else {
            return
        }
        scope.releaseFrame(index: index, owner: selfAttribute)
        frameIndex = nil
    }
    
}

@available(iOS 13.0, *)
internal struct SharedFrame: RemovableAttribute,
                             DanceUIGraph.ObservedAttribute,
                             StatefulRule {
    
    internal typealias Value = (ViewFrame?, DanceUIGraph.AnyOptionalAttribute)
    
    internal typealias AnimatableData = AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>>
    
    @Attribute
    internal var time: Time
    
    @Attribute
    internal var environment: EnvironmentValues
    
    internal let scope: MatchedGeometryScope
    
    internal let frameIndex: Int
    
    internal var listeners: [AnimationListener]
    
    internal var animatorState: AnimatorState<AnimatableData>?
    
    internal var resetSeed: UInt32
    
    internal var lastSourceAttribute: DGWeakAttribute
    
    internal mutating func updateValue() {
        var frame = scope.frames[frameIndex]
        guard frame.views.first(where: {$0.args.isSource}) != nil else {
            reset()
            value = (nil, .init())
            return
        }
        
        var time: Time = .never
        if animatorState != nil {
            let timeInfo = self.$time.changedValue()
            if timeInfo.changed {
                time = timeInfo.value
            }
        }
        
        resetIfNeeded()
        
        checkMutiSource()
        
        frame = scope.frames[frameIndex]
        let firstView = frame.views[0]
        if (lastSourceAttribute.attribute == nil || firstView.attribute != lastSourceAttribute.attribute!) && frame.views.count > 1 {
            let transaction = DGGraphRef.withoutUpdate {
                firstView.transaction
            }
            
            if let animation = transaction.animationIgnoringTransitionPhase {
                let matcherAnimationValue = viewAnimationValue(at: 1, frame: frame)
                let sourceAnimationValue = viewAnimationValue(at: 0, frame: frame)
                
                let x = sourceAnimationValue.position.value.x - matcherAnimationValue.position.value.x
                let y = sourceAnimationValue.position.value.y - matcherAnimationValue.position.value.y
                let width = sourceAnimationValue.size.value.width - matcherAnimationValue.size.value.width
                let height = sourceAnimationValue.size.value.height - matcherAnimationValue.size.value.height
                
                let interval = CGRect(x: x, y: y, width: width, height: height).animatableData
                if interval != .zero {
                    time = self.time
                    if let animatorState = animatorState {
                        animatorState.combine(newAnimaition: animation,
                                              newInterval: interval,
                                              at: time,
                                              in: transaction,
                                              environment: _environment)
                    } else {
                        self.animatorState = AnimatorState(animation: animation,
                                                           interval: interval,
                                                           at: time,
                                                           in: transaction)
                    }
                    if let listener = transaction.listener {
                        listeners.append(listener)
                        listener.animationWasAdded()
                    }
                }
            }
        }
        
        lastSourceAttribute = .init(firstView.attribute)
        
        let animationValue = viewAnimationValue(at: 0, frame: frame)
        self.resetSeed = firstView.phase.seed
        var value = ViewFrame(origin: ViewOrigin(value: CGPoint(x: animationValue.position.value.x,
                                                                y: animationValue.position.value.y)),
                              size: animationValue.size)
        guard let animatorState = animatorState else {
            self.value = (value, DanceUIGraph.AnyOptionalAttribute(firstView.attribute))
            return
        }
        if animatorState.update(&value.animatableData,
                                at: time,
                                environment: _environment) {
            self.animatorState = nil
            removeListeners()
        } else {
            ViewGraph.current.scheduleNextViewUpdate(byTime: animatorState.nextTime)
        }
        self.value = (value, DanceUIGraph.AnyOptionalAttribute(nil))
        
    }
    
    @inline(__always)
    private func viewAnimationValue(at index: Int,
                                    frame: MatchedGeometryScope.Frame) -> (position: ViewOrigin, size: ViewSize) {
        let view = frame.views[index]
        let size = view.size
        var transform = view.transform
        var position = view.position
        let translation = CGSize(width: -(position.value.x - transform.positionAdjustment.width),
                                 height: -(position.value.y - transform.positionAdjustment.height))
        
        transform.appendTranslation(translation)
        let args = view.args
        var newPosition = CGPoint(x: size.value.width * args.anchor.x, y: size.value.height * args.anchor.y)
        newPosition.convert(to: .global, transform: transform.applyingPositionAdjustment(CGSize(width: position.value.x, height: position.value.y)))
        position.value = newPosition
        return (position, size)
    }
    
    @inline(__always)
    private mutating func resetIfNeeded() {
        let frame = scope.frames[frameIndex]
        guard let lastSourceAttribute = lastSourceAttribute.attribute,
              let view = frame.views.first(where: {$0.attribute == lastSourceAttribute}),
              view.phase.seed != resetSeed else {
            return
        }
        reset()
    }
    
    @inline(__always)
    private func checkMutiSource() {
        let frame = scope.frames[frameIndex]
        let viewsCount = frame.views.count
        guard viewsCount > 1,
              let firstSourceIndex = frame.views.firstIndex(where: {!$0.phase.invisible && $0.args.isSource}) else {
            return
        }
        let checkBeginIndex = firstSourceIndex &+ 1
        
        defer {
            // bring the source to begin
            if firstSourceIndex != 0 {
                let removedView = scope.frames[frameIndex].views.remove(at: firstSourceIndex)
                scope.frames[frameIndex].views.insert(removedView, at: 0)
            }
        }
        guard checkBeginIndex < viewsCount && !frame.logged else {
            return
        }
        DGGraphRef.withoutUpdate {
            guard checkBeginIndex != viewsCount else {
                return
            }
            for index in checkBeginIndex..<viewsCount {
                let view = frame.views[index]
                guard !view.phase.invisible && view.args.isSource else {
                    continue
                }
                print("Multiple inserted views in matched geometry group \(frame.key.description) have `isSource: true`, results are undefined.")
                scope.frames[frameIndex].logged = true
            }
        }
        
    }
    
    internal mutating func reset() {
        destroy()
        animatorState = nil
        resetSeed = 0
        lastSourceAttribute = .init()
    }
    
    internal mutating func removeListeners() {
        guard !listeners.isEmpty else {
            return
        }
        
        for listener in listeners {
            listener.animationWasRemoved()
        }
        listeners = []
    }
    
    internal static func willRemove(attribute: DGAttribute) {
        let value = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        value.pointee.destroy()
    }
    
    internal static func didReinsert(attribute: DGAttribute) {
        _intentionallyLeftBlank()
    }
    
    internal mutating func destroy() {
        guard !listeners.isEmpty else {
            return
        }
        
        for listener in listeners {
            listener.animationWasRemoved()
        }
        listeners = []
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    /// Defines a group of views with synchronized geometry using an
    /// identifier and namespace that you provide.
    ///
    /// This method sets the geometry of each view in the group from the
    /// inserted view with `isSource = true` (known as the "source" view),
    /// updating the values marked by `properties`.
    ///
    /// If inserting a view in the same transaction that another view
    /// with the same key is removed, the system will interpolate their
    /// frame rectangles in window space to make it appear that there
    /// is a single view moving from its old position to its new
    /// position. The usual transition mechanisms define how each of
    /// the two views is rendered during the transition (e.g. fade
    /// in/out, scale, etc), the `matchedGeometryEffect()` modifier
    /// only arranges for the geometry of the views to be linked, not
    /// their rendering.
    ///
    /// If the number of currently-inserted views in the group with
    /// `isSource = true` is not exactly one results are undefined, due
    /// to it not being clear which is the source view.
    ///
    /// - Parameters:
    ///   - id: The identifier, often derived from the identifier of
    ///     the data being displayed by the view.
    ///   - namespace: The namespace in which defines the `id`. New
    ///     namespaces are created by adding an `@Namespace` variable
    ///     to a ``View`` type and reading its value in the view's body
    ///     method.
    ///   - properties: The properties to copy from the source view.
    ///   - anchor: The relative location in the view used to produce
    ///     its shared position value.
    ///   - isSource: True if the view should be used as the source of
    ///     geometry for other views in the group.
    ///
    /// - Returns: A new view that defines an entry in the global
    ///   database of views synchronizing their geometry.
    ///
    @inlinable
    public func matchedGeometryEffect<ID: Hashable>(id: ID, in namespace: Namespace.ID, properties: MatchedGeometryProperties = .frame, anchor: UnitPoint = .center, isSource: Bool = true) -> some View {
        modifier(_MatchedGeometryEffect(id: id, namespace: namespace, args: (properties: properties, anchor: anchor, isSource: isSource)))
    }
}
