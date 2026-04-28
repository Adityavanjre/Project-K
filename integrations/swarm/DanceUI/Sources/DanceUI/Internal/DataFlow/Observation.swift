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
@_spi(DanceUI) import DanceUIObservation

// MARK: Observe the Access

/// Observe access in the `body` closure and store the access info to
/// `ObservationRegistrar.latestAccessLists`
///
/// - Parameter body: The scope to build observation dependencies.
///
// swift-format-ignore: NoBlockComments
@available(iOS 13.0, *)
@discardableResult
internal func _withObservation<A>(do body: () throws -> A) rethrows -> (value: A, accessList: ObservationTracking._AccessList?) {
    guard DanceUIFeature.observation.isEnable else {
        return (try body(), nil)
    }
    
    var localList: ObservationTracking._AccessList?
    
    let value = try withUnsafeMutablePointer(to: &localList) { localList in
        let globalList = systemAccessList
        systemAccessList = localList
        defer {
            systemAccessList = globalList
        }
        return try body()
    }
    
    if let localList {
        ObservationRegistrar.latestAccessLists.append(localList)
    }
    
    return (value, localList)
}

/// Observe access in the `body` closure and install an observation
/// tracking to the access that invalidates given `attribute` when the
/// accessed properties were set.
///
/// - Parameter trackings: An array of `ObservationTracking` that manages
/// the cancellation of the observation trackings.
///
/// - Parameter attribute: The attribute to invalidate when the depdencies
/// observed in `body` closure changed.
///
/// - Parameter body: The scope to build observation dependencies.
///
// swift-format-ignore: NoBlockComments
@available(iOS 13.0, *)
@discardableResult
private func _withObservation<A, B>(trackings: inout [ObservationTracking]?, attribute: Attribute<A>, do body: () throws -> B) rethrows -> (value: B, accessList: ObservationTracking._AccessList?) {
    
    let previousLatestAccessLists = ObservationRegistrar.latestAccessLists
    
    ObservationRegistrar.latestAccessLists = []
    
    var localList: ObservationTracking._AccessList?
    
    defer {
        ObservationRegistrar.latestAccessLists = previousLatestAccessLists
    }
    
    let value = try withUnsafeMutablePointer(to: &localList, { localList in
        let globalList = systemAccessList
        systemAccessList = localList
        defer {
            systemAccessList = globalList
        }
        return try body()
    })
    
    if let localList {
        ObservationRegistrar.latestAccessLists.append(localList)
    }
    
    trackings = _installObservation(ObservationRegistrar.latestAccessLists, attribute)
    
    return (value, localList)
}

// MARK: ObservationAttribute

/// An attribute that builds cancellable observation trackings.
///
/// - Warning: `@Attribute`s of `ObservationAttribute` shall set its flags
/// to contain `removable`. The `removable` flag shall ultimiately be
/// replaced by `invalidatable` if DanceUI was fully migrated to invoke
/// `DGSubgraph.willInvalidate` instead of `DGSubgraph.willRemove`.
///
@available(iOS 13.0, *)
internal protocol ObservationAttribute: _AttributeBody {
    
    /// Stores previous observation trackings such that we can cancel them
    /// in time.
    ///
    /// - Note: Attributes that employ DanceUIObservation to build
    /// dependencies require a piece of memory to store built dependencies
    /// such that they can cancel it when: 1) upstream depdendencies were
    /// changed or 2) the subgraph containing these attributes were off
    /// the subgraph hierarchy.
    ///
    /// Technically, DanceUIGraph shall offer a kind of technology to
    /// provide this storage which in order to make attribute users to
    /// declare stored properties in their rule definitions, which is much
    /// like what the `extraBytes` does in the Objective-C runtime
    /// function `objc_allocateClassPair(_ superclass: _ name: _ extraBytes:)`
    /// or `objc_get/setAssociatedObject`. However, we don't have this
    /// kind of technology now. This is the reason why
    /// `ObservationAttribute` only has an extension to `StatefulRule` at
    /// the moment.
    ///
    var previousObservationTrackings: [ObservationTracking]? { get set }
    
    var deferredObservationGraphMutation: DeferredObservationGraphMutation? { get set }
    
}

@available(iOS 13.0, *)
extension ObservationAttribute {
    
    fileprivate static func deferObservationGraphMutation(attribute: DGAttribute, viewGraph: ViewGraph, trackings: [DanceUIObservation.ObservationTracking]) {
        attribute.mutateBody(as: Self.self, invalidating: false) { body in
            let keyPaths = Set(trackings.compactMap(\.changed))
            trackings.cancel()
            if body.deferredObservationGraphMutation != nil {
                body.deferredObservationGraphMutation!.keyPaths.formUnion(keyPaths)
            } else {
                body.deferredObservationGraphMutation = DeferredObservationGraphMutation(viewGraph: viewGraph, attribute: DGWeakAttribute(attribute), keyPaths: keyPaths)
            }
        }
    }
    
    internal static func scheduleDeferredObservationGraphMutation(attribute: DGAttribute) {
        guard DanceUIFeature.observation.isEnable else {
            return
        }
        
        attribute.mutateBody(as: Self.self, invalidating: false) { body in
            body.deferredObservationGraphMutation?.schedule()
            body.deferredObservationGraphMutation = nil
        }
    }
    
}

@available(iOS 13.0, *)
internal typealias ObservationInstaller = (DanceUIObservation.ObservationTracking._AccessList) -> [ObservationTracking]

// swift-format-ignore: NoBlockComments
@available(iOS 13.0, *)
extension ObservationAttribute where Self: StatefulRule {
    
    /// Observe access in the `body` closure and install an observation
    /// tracking to the will-set access which invalidates the rule
    /// attribute when the accessed properties were set.
    ///
    /// - Parameter shouldCancelPrevious: This parameter is an autoclosure
    /// to ensure the argument evaluate would not be executed when the
    /// `observation` feature is disabled.
    ///
    @inline(__always)
    internal mutating func withObservation<A>(shouldCancelPrevious: @autoclosure () -> Bool, do body: () throws -> A) rethrows -> A {
        if DanceUIFeature.observation.isEnable {
            if shouldCancelPrevious() {
                previousObservationTrackings?.cancel()
            }
            var trackings: [ObservationTracking]? = []
            defer {
                previousObservationTrackings = trackings
            }
            return try _withObservation(trackings: &trackings, attribute: context.attribute, do: body).value
        } else {
            return try body()
        }
    }
    
    /// An escapable observation installer that invalidates the rule's
    /// attribute when the rule's subgraph is alive and change happended.
    ///
    /// - Note: Protected with fileprivate before the Observation feature
    /// is validated.
    ///
    fileprivate /* internal */ var observationInstaller: ObservationInstaller {
        let weakAttribute = WeakAttribute(context.attribute)
        return { accessList in
            guard let attribute = weakAttribute.attribute else {
                return []
            }
            let subgraph = attribute.subgraph
            guard subgraph.isValid else {
                return []
            }
            
            return subgraph.apply {
                _installObservation([accessList], attribute)
            }
        }
    }
    
#if DEBUG
    internal var testableObservationInstaller: ObservationInstaller {
        observationInstaller
    }
#endif
    
}

@available(iOS 13.0, *)
extension Sequence where Element == ObservationTracking {
    
    fileprivate func cancel() {
        for each in self {
            each.cancel()
        }
    }
    
}

// MARK: Implementation Details

extension ObservationRegistrar {

    internal static var latestAccessLists : [ObservationTracking._AccessList] = []
    
    /// For body change debugging purpose.
    internal static var latestTriggers : [AnyKeyPath] = []
    
}

// swift-format-ignore: NoBlockComments
@discardableResult
@available(iOS 13.0, *)
internal func _installObservation<Value>(_ accessList: [ObservationTracking._AccessList], _ attribute: Attribute<Value>) -> [ObservationTracking] {
    guard DanceUIFeature.observation.isEnable else {
        return []
    }
    
    guard !accessList.isEmpty else {
        return []
    }
    
    var trackings: [ObservationTracking] = []
    
    for each in accessList {
        let eachBatch = installObservationSlow(each, attribute)
        trackings.append(contentsOf: eachBatch)
    }
    
    return trackings
}

@available(iOS 13.0, *)
private func installObservationSlow<Value>(_ accessList: ObservationTracking._AccessList, _ attribute: Attribute<Value>) -> [ObservationTracking] {
    
    let viewGraph = ViewGraph.current
    
    let tracking = ObservationTracking(accessList)
    
    let weakAttribute = DGWeakAttribute(attribute.identifier)
    
    let trackings = [tracking]
    
    ObservationTracking._installTracking(
        tracking,
        willSet: { [weak viewGraph] tracking in
            Update.perform {
                guard let attribute = weakAttribute.attribute,
                      let viewGraph = viewGraph else {
                    for eachTracking in trackings {
                        eachTracking.cancel()
                    }
                    return
                }
                
                let transaction = Transaction.current
                
                let wrapped = InvalidatingGraphMutation(attribute: weakAttribute)
                let mutation = ObservationGraphMutation(invalidatingMutation: wrapped, observationTracking: trackings)
                
                if !attribute.isVisible(in: viewGraph) {
                    if let observationType = attribute._bodyType.type as? ObservationAttribute.Type {
                        observationType.deferObservationGraphMutation(attribute: attribute, viewGraph: viewGraph, trackings: trackings)
                    }
                } else {
                    viewGraph.asyncTransaction(transaction, mutation: mutation, style: .ignoresFlushWhenUpdating, mayDeferUpdate: true)
                }
            }
        },
        didSet: nil
    )
    
    return trackings
}

@available(iOS 13.0, *)
extension DGAttribute {
    
    @inline(__always)
    fileprivate func isVisible(in viewGraph: ViewGraph) -> Bool {
        viewGraph.data.globalSubgraph.isAncestor(subgraph)
    }
    
}

@available(iOS 13.0, *)
private var systemAccessList: UnsafeMutablePointer<DanceUIObservation.ObservationTracking._AccessList?>? {
    get {
        _ThreadLocal.value?.withMemoryRebound(to: DanceUIObservation.ObservationTracking._AccessList?.self, capacity: 1, {$0})
    }
    set {
        _ThreadLocal.value = UnsafeMutableRawPointer(newValue)
    }
}

@available(iOS 13.0, *)
internal struct DeferredObservationGraphMutation {
    
    /// This property shall be weak cause the life-cycle of the view-graph
    /// and the subgraph owning the attribute may not be aligned.
    internal weak var viewGraph: ViewGraph?
    
    internal let attribute: DGWeakAttribute
    
    internal var keyPaths: Set<AnyKeyPath>
    
    internal func schedule() {
        guard DanceUIFeature.observation.isEnable else {
            return
        }
        
        guard let viewGraph else {
            return
        }
        let wrapped = InvalidatingGraphMutation(attribute: attribute)
        let mutation = PreCancelledObservationGraphMutation(invalidatingMutation: wrapped, keyPaths: keyPaths)
        viewGraph.asyncTransaction(Transaction(), mutation: mutation, style: .ignoresFlushWhenUpdating, mayDeferUpdate: true)
    }
    
}

@available(iOS 13.0, *)
private struct PreCancelledObservationGraphMutation: GraphMutation {
    
    fileprivate let invalidatingMutation: InvalidatingGraphMutation
    
    fileprivate var keyPaths: Set<AnyKeyPath> = []
    
#if DEBUG || DANCE_UI_INHOUSE
    fileprivate var file: StaticString
    
    fileprivate var line: UInt
    
    fileprivate var function: StaticString
#endif
#if DEBUG || DANCE_UI_INHOUSE
    fileprivate init(invalidatingMutation: InvalidatingGraphMutation,
                  keyPaths: Set<AnyKeyPath>,
                  file: StaticString = #file,
                  line: UInt = #line,
                  function: StaticString = #function
    ) {
        self.invalidatingMutation = invalidatingMutation
        self.keyPaths = keyPaths
        self.file = file
        self.line = line
        self.function = function
    }
#else
    fileprivate init(invalidatingMutation: InvalidatingGraphMutation, keyPaths: Set<AnyKeyPath>) {
        self.invalidatingMutation = invalidatingMutation
        self.keyPaths = keyPaths
    }
#endif
    
    fileprivate mutating func apply() {
        // Remove the latest triggers only when graph mutation was
        // applied. The `changedBodyProperties` function would filter
        // Observation-affected `View` by testing if the state of the
        // attribute contains `.wasModified`.
        ObservationRegistrar.latestTriggers.removeAll(keepingCapacity: true)
        
        ObservationRegistrar.latestTriggers.append(contentsOf: keyPaths)
        
        invalidatingMutation.apply()
    }
    
    fileprivate mutating func combine<Another: GraphMutation>(with another: Another) -> Bool {
        if invalidatingMutation.combine(with: another) {
            if let another = another as? PreCancelledObservationGraphMutation {
                keyPaths.formUnion(another.keyPaths)
            }
            return true
        }
        return false
    }

}

@available(iOS 13.0, *)
private struct ObservationGraphMutation: GraphMutation {
    
#if DEBUG || DANCE_UI_INHOUSE
    fileprivate var file: StaticString
    
    fileprivate var line: UInt
    
    fileprivate var function: StaticString
#endif
    
    fileprivate var invalidatingMutation : InvalidatingGraphMutation
    
    fileprivate var observationTracking : [ObservationTracking]
    
#if DEBUG || DANCE_UI_INHOUSE
    fileprivate init(invalidatingMutation: InvalidatingGraphMutation,
                     observationTracking: [ObservationTracking],
                     file: StaticString = #file,
                     line: UInt = #line,
                     function: StaticString = #function
    ) {
        self.invalidatingMutation = invalidatingMutation
        self.observationTracking = observationTracking
        self.file = file
        self.line = line
        self.function = function
    }
#else
    fileprivate init(invalidatingMutation: InvalidatingGraphMutation, observationTracking: [ObservationTracking]) {
        self.invalidatingMutation = invalidatingMutation
        self.observationTracking = observationTracking
    }
#endif
    
    fileprivate mutating func apply() {
        // Remove the latest triggers only when graph mutation was
        // applied. The `changedBodyProperties` function would filter
        // Observation-affected `View` by testing if the state of the
        // attribute contains `.wasModified`.
        ObservationRegistrar.latestTriggers.removeAll(keepingCapacity: true)
        
        for each in observationTracking {
            if let changed = each.changed {
                ObservationRegistrar.latestTriggers.append(changed)
            }
            each.cancel()
        }
        invalidatingMutation.apply()
    }
    
    fileprivate mutating func combine<Another: GraphMutation>(with another: Another) -> Bool {
        if invalidatingMutation.combine(with: another) {
            if let another = another as? ObservationGraphMutation {
                observationTracking.append(contentsOf: another.observationTracking)
            }
            return true
        }
        return false
    }

}

