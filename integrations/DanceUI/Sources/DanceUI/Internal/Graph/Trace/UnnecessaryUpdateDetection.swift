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

#if DEBUG || DANCE_UI_INHOUSE

internal import DanceUIGraph

internal enum DirtifyActionKind: UInt8, Hashable {
    
    case create = 0
    
    case invalidate = 1
    
    case setValue = 2
    
    case mutateBody = 3
    
}

internal enum DirtifyAction: CustomStringConvertible, Hashable {
    
    case create(DGWeakAttribute)
    
    case invalidate(DGWeakAttribute)
    
    case setValue(DGWeakAttribute)
    
    case mutateBody(DGWeakAttribute, invalidating: Bool)
    
    @inlinable
    internal var kind: DirtifyActionKind {
        switch self {
        case .create:       return .create
        case .invalidate:   return .invalidate
        case .setValue:     return .setValue
        case .mutateBody:   return .mutateBody
        }
    }
    
    @inlinable
    internal var isInvalidation: Bool {
        switch self {
        case .invalidate:   return true
        default:            return false
        }
    }
    
    internal var narration: String {
        switch self {
        case .create:
            "creation"
        case .invalidate:
            "invalidation"
        case .setValue:
            "setting value"
        case .mutateBody(_, let invalidating):
            if invalidating {
                "mutating body (invalidating=true)"
            } else {
                "mutating body (invalidating=false)"
            }
        }
    }
    
    internal var description: String {
        switch self {
        case .create(let weakAttribute):
            return "<DirtifyAction: Create; \(weakAttribute.debugDescriptionComponents)>"
        case .invalidate(let weakAttribute):
            return "<DirtifyAction: Invalidate; \(weakAttribute.debugDescriptionComponents)>"
        case .setValue(let weakAttribute):
            return "<DirtifyAction: Set Value: \(weakAttribute.debugDescriptionComponents)>"
        case .mutateBody(let weakAttribute, let invalidating):
            return "<DirtifyAction: Mutate Body: \(weakAttribute.debugDescriptionComponents); invalidating = \(invalidating)>"
        }
    }
    
    @inlinable
    internal var attribute: DGAttribute? {
        switch self {
        case .create(let weakAttribute):        weakAttribute.attribute
        case .invalidate(let weakAttribute):    weakAttribute.attribute
        case .setValue(let weakAttribute):      weakAttribute.attribute
        case .mutateBody(let weakAttribute, _): weakAttribute.attribute
        }
    }
    
    /// Does this action effectively dirtify the attribute dependency
    /// graph?
    ///
    @inlinable
    internal var isEffective: Bool {
        switch self {
        case .create:                           true
        case .invalidate:                       true
        case .setValue:                         true
        case .mutateBody(_, let invalidating):  invalidating
        }
    }
    
}

@dynamicMemberLookup
internal struct VersionedDirtifyAction: CustomStringConvertible, Hashable {
    
    internal var action: DirtifyAction
    
    internal let seed: Seed = Seed()
    
    @inlinable
    internal subscript<T>(dynamicMember keyPath: KeyPath<DirtifyAction, T>) -> T {
        action[keyPath: keyPath]
    }
    
    internal var description: String {
        switch action {
        case .create(let weakAttribute):
            return "<VersionedDirtifyAction: Seed = \(seed); Create; \(weakAttribute.debugDescriptionComponents)>"
        case .invalidate(let weakAttribute):
            return "<VersionedDirtifyAction: Seed = \(seed); Invalidate; \(weakAttribute.debugDescriptionComponents)>"
        case .setValue(let weakAttribute):
            return "<VersionedDirtifyAction: Seed = \(seed); Set Value: \(weakAttribute.debugDescriptionComponents)>"
        case .mutateBody(let weakAttribute, let invalidating):
            return "<VersionedDirtifyAction: Seed = \(seed); Mutate Body: \(weakAttribute.debugDescriptionComponents); invalidating = \(invalidating)>"
        }
    }
    
    internal struct Seed: Equatable, Hashable {
        
        /// The dirtify action seed is 1-based.
        ///
        /// Each attribute filters unused dirtify actions from its input
        /// edges. This filter memorize the historical max dirtify action
        /// seed and start from `0`.
        ///
        private static var next: UInt64 = 1
        
        internal let rawValue: UInt64
        
        @inline(__always)
        fileprivate init() {
            defer {
                Self.next &+= 1
            }
            self.rawValue = Self.next
        }
        
    }
    
}

internal struct UnnecessaryUpdateDetectionSubEntry: TableEntry {
    
    // Dual-buffer-like design to avoid frequent allocation
    internal var dirtifyActions: Set<VersionedDirtifyAction>
    
    private var dirtifyActions2: Set<VersionedDirtifyAction>
    
    fileprivate var maxGlobalDirtifySeed: UInt64 = 0
    
    internal init() {
        self.dirtifyActions = []
        self.dirtifyActions2 = []
    }
    
    internal mutating func didCreate() {
        
    }
    
    internal mutating func didRemove() {
        let dirtifyActions = self.dirtifyActions // Retain the old heap buffer
        let dirtifyActions2 = self.dirtifyActions2 // Retain the old heap buffer
        self.dirtifyActions = [] // Assigning the empty singleton to avoid thread safety issues
        self.dirtifyActions2 = [] // Assigning the empty singleton to avoid thread safety issues
        DispatchQueue.global(qos: .background).async { // try release off the running thread
            let _ = dirtifyActions
            let _ = dirtifyActions2
        }
    }
    
    internal mutating func didResolve() {
        
    }
    
    internal mutating func prepareForResolvingInheritedDirtifyActions() -> (UInt64, Set<VersionedDirtifyAction>) {
        var yieldDirtifyActions = Set<VersionedDirtifyAction>()
        dirtifyActions2.reserveCapacity(dirtifyActions.count)
        swap(&yieldDirtifyActions, &dirtifyActions2)
        return (maxGlobalDirtifySeed, yieldDirtifyActions)
    }
    
    internal mutating func finishResolvingInheritedDirtifyActions(_ updatedMaxGlobalDirtifySeed: UInt64, _ yieldDirtifyActions: inout Set<VersionedDirtifyAction>) {
        swap(&yieldDirtifyActions, &dirtifyActions2)
        swap(&dirtifyActions, &dirtifyActions2)
        dirtifyActions2.removeAll(keepingCapacity: true)
        maxGlobalDirtifySeed = updatedMaxGlobalDirtifySeed
    }
    
}

@available(iOS 13.0, *)
internal final class UnnecessaryUpdateDetectionPass {
    
    private let context: ViewInfoTraceContext
    
    internal var shouldReportUnchangedValueUpdates: Bool = true
    
    internal init(context: ViewInfoTraceContext) {
        self.context = context
    }
    
    // MARK: Inferring Unnecessary Updates
    
    @discardableResult
    private func registerDirtifyAction(_ action: DirtifyAction, for attribute: DGAttribute) -> VersionedDirtifyAction {
        let versionedAction = VersionedDirtifyAction(action: action)
        context[AttributeKey(attribute)].uud.dirtifyActions = [versionedAction]
        return versionedAction
    }
    
    private func resolveInheritedDirtifyActions(for attribute: DGAttribute) {
        var (existedMaxGlobalSeed, yieldDirtifyActions) = context[AttributeKey(attribute)].uud.prepareForResolvingInheritedDirtifyActions()
        var updatedMaxGlobalDirtifySeed = existedMaxGlobalSeed
        
        attribute.forEachDependency(policy: .dependenciesUsedInUpdate) { [unowned context] dep in
            let inputIdentifier: DGAttribute?
            switch dep {
            case .attribute(let identifier, _):
                inputIdentifier = identifier
            case .offsetAttribute(_, let nodeAttribute, _, _):
                inputIdentifier = nodeAttribute
            case .indirectAttributeSource(_, let nodeAttribute, _):
                inputIdentifier = nodeAttribute
            case .indirectAttributeDependency(_, let nodeAttribute, _):
                inputIdentifier = nodeAttribute
            }
            if let inputIdentifier {
                for eachAction in context[AttributeKey(inputIdentifier)].uud.dirtifyActions where eachAction.seed.rawValue > existedMaxGlobalSeed {
                    yieldDirtifyActions.insert(eachAction)
                    updatedMaxGlobalDirtifySeed = max(updatedMaxGlobalDirtifySeed, eachAction.seed.rawValue)
                }
            }
        }
        
        context[AttributeKey(attribute)].uud.finishResolvingInheritedDirtifyActions(updatedMaxGlobalDirtifySeed, &yieldDirtifyActions)
    }
    
    internal func dirtifyActions(for attribute: DGAttribute) -> AnySequence<VersionedDirtifyAction> {
        let iterator = context[AttributeKey(attribute)].uud.dirtifyActions.makeIterator()
        return AnySequence {
            return iterator
        }
    }
    
    internal func reportPotentialOptimizationOpportunityForObservation(attribute: DGAttribute, changed: Bool) {
        for dirtifyAction in dirtifyActions(for: attribute) {
            reportPotentialOptimizationOpportunityForObservation(
                attribute: attribute,
                dirtifyAction: dirtifyAction,
                changed: changed
            )
        }
    }

    private func reportPotentialOptimizationOpportunityForObservation(attribute: DGAttribute, dirtifyAction: VersionedDirtifyAction, changed: Bool) {
        func selfType(for attribute: DGAttribute) -> Any.Type {
            unsafeBitCast(attribute.info.attributeType.pointee.self_id, to: Any.Type.self)
        }
        func selfTypeName(for attribute: DGAttribute) -> String {
            _typeName(unsafeBitCast(attribute.info.attributeType.pointee.self_id, to: Any.Type.self), qualified: true)
        }
        func resultTypeName(for attribute: DGAttribute) -> String {
            _typeName(unsafeBitCast(attribute.info.attributeType.pointee.value_id, to: Any.Type.self), qualified: true)
        }
#if DEBUG
        let debugBodyAttributeSelfType = selfTypeName(for: attribute)
        let debugBodyAttributeResultType = resultTypeName(for: attribute)
#endif
        guard let signalAttribute = dirtifyAction.attribute else {
            return
        }
        let dirtifiedAttributeRole = context.role(for: signalAttribute)
        guard dirtifyAction.isInvalidation && dirtifiedAttributeRole.contains(.observableObject) else {
            return
        }
        let signalOutputs = signalAttribute.outputs
        guard signalOutputs.count == 1 else {
            // ObservableObject's signal shall have unique output: body accessor
            return
        }
        // Source view is the view declares a @StateObject/ObservedObject/EnvironmentObject...
        let sourceViewAttribute = signalOutputs[0]
        guard case .defObservableObjectSignal(let fieldName, let fieldType) = context.association(for: signalAttribute) else {
            return
        }
        let bodyTypeOrNil: Any.Type?
        // The attribute must be a body accessor then we can report optimization opportunity
        if case .bodyAccessor(let bodyAttributeContainerType)  = context.association(for: attribute) {
            bodyTypeOrNil = bodyAttributeContainerType
        } else {
            bodyTypeOrNil = nil
        }
        guard let bodyViewType = bodyTypeOrNil else {
            return
        }
        let containerTypeModuleName = Tracing.libraryName(defining: bodyViewType)
        Signpost.viewInfoTrace.traceEvent(
            "%{public}@ attribute update : attribute = %{public}d : %{public}@; invalidation-seed = %{public}d; signal-attribute = %{public}d; module-name = %{public}@; view-type = %{public}@; field-name = %{public}@; field-type = %{public}@; source-view-attribute = %{public}d : %{public}@ (%{public}d)",
            [
                changed ? "changed" : "unchanged",
                attribute.rawValue, // attribute
                selfTypeName(for: attribute), // attribute self-type
                dirtifyAction.seed.rawValue, // invalidation seed
                signalAttribute.rawValue, // signal attribute
                containerTypeModuleName, // module-name
                _typeName(bodyViewType, qualified: false), // view type
                fieldName, // source view field name
                _typeName(fieldType, qualified: true), // source view field-type
                sourceViewAttribute.rawValue, // source view attribute
                selfTypeName(for: sourceViewAttribute),  // source view attribute self type
                context.role(for: sourceViewAttribute).rawValue,  // source view attribute role
            ]
        )
    }
    
    // MARK: Delegated Graph Tracing
    
    internal func beginUpdateValue(_ attribute: DGAttribute) {
        // The attribute value update function may use the info of
        // the inherited dirtify actions. Reolsve before the functino
        // call.
        resolveInheritedDirtifyActions(for: attribute)
    }
    
    internal func endUpdateValue(_ attribute: DGAttribute, changed: Bool) {
        if shouldReportUnchangedValueUpdates {
            reportPotentialOptimizationOpportunityForObservation(attribute: attribute, changed: changed)
        }
    }
    
    internal func attributeWillInvalidateValue(_ attribute: DGAttribute) {
        let outputs = attribute.outputs
        guard outputs.count == 1 else {
            return
        }
        let signalUserAttribute = outputs[0]
        
        let defRole = context.role(for: attribute)
        let defAssociation = context.association(for: attribute)
        let userAssociation = context.association(for: signalUserAttribute)
        switch (defRole, defAssociation, userAssociation) {
        case (.signalForObservableObject, .defObservableObjectSignal(let fieldName, let observableObjectType), .bodyAccessor(let containerType)):
            let action = registerDirtifyAction(.invalidate(DGWeakAttribute(attribute)), for: attribute)
            
            Signpost.viewInfoTrace.traceEvent(
                "invalidate signal attribute for observable object: %{public}d; seed = %{public}d; container-type = %{public}@, field-name = %{public}@, field-type = %{public}@",
                [
                    attribute.rawValue,
                    action.seed.rawValue,
                    _typeName(containerType, qualified: true),
                    fieldName,
                    _typeName(observableObjectType, qualified: true)
                ]
            )
        default:
            break
        }
    }
    
    internal func attributeWillSetValue(_ attribute: DGAttribute) {
        registerDirtifyAction(.setValue(DGWeakAttribute(attribute)), for: attribute)
    }
    
    internal func attributeWillMutateBody(_ attribute: DGAttribute, _ invalidating: Bool) {
        registerDirtifyAction(.mutateBody(DGWeakAttribute(attribute), invalidating: invalidating), for: attribute)
    }
    
}

extension DGAttribute {
    
    @inline(__always)
    internal var dirtifyActions: AnySequence<VersionedDirtifyAction> {
        viewInfoTrace?.dirtifyActions(for: self) ?? AnySequence {
            EmptyCollection().makeIterator()
        }
    }
    
}

extension Attribute {
    
    @inline(__always)
    internal var dirtifyActions: AnySequence<VersionedDirtifyAction> {
        identifier.dirtifyActions
    }
    
}

extension DGWeakAttribute {
    
    fileprivate var debugDescriptionComponents: String {
        if let attribute = attribute {
            let description = DanceUIGraphAttributeDescription(attribute, [:])!
            return "0x\(String(attribute.rawValue, radix: 16));  @Attribute \(description.first!.value[.selfDescription]!)"
        } else {
            return "0x\(String(__attribute.rawValue, radix: 16)); DEAD" // BDCOV_EXCL_LINE
        }
    }
    
}

#endif // DEBUG || DANCE_UI_INHOUSE
