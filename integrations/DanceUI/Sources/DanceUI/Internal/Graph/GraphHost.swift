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
internal protocol GraphDelegate: AnyObject {

    func updateGraph<R>(body: (GraphHost) -> R) -> R

    func graphDidChange()

    func preferencesDidChange()

    func hostingType() -> String

    func hostingState() -> String
}

@available(iOS 13.0, *)
extension GraphDelegate {
    
    func hostingType() -> String {
        ""
    }

    func hostingState() -> String {
        ""
    }
}

@available(iOS 13.0, *)
internal class GraphHost: NonReflectable {
    
    internal struct Data {

        internal var graph: DGGraphRef?

        internal var globalSubgraph: DGSubgraphRef

        internal var rootSubgraph: DGSubgraphRef

        internal var isRemoved: Bool = false

        internal var isHiddenForReuse: Bool = false

        @Attribute
        internal var time: Time

        @Attribute
        internal var environment: EnvironmentValues

        @Attribute
        internal var phase: _GraphInputs.Phase

        @Attribute
        internal var hostPreferenceKeys: PreferenceKeys

        @Attribute
        internal var transaction: Transaction

        internal var inputs: _GraphInputs

        internal let usesNonSharedGraph: Bool
        
#if DEBUG || DANCE_UI_INHOUSE
        internal let viewInfoTrace: ViewInfoTrace?

        /// Tracing infrastructures for the shared graph shall never be
        /// removed.
        fileprivate var standaloneViewInfoTraceID: DGUniqueID?

        internal static let sahredViewInfoTrace: ViewInfoTrace? = {
            if DanceUIFeature.viewInfoTrace.isEnable {
                ViewInfoTrace(name: "shared")
            } else {
                nil
            }
        }()
#endif // DEBUG || DANCE_UI_INHOUSE
        
        /// DanceUI addition
        internal static let sharedGraph: DGGraphRef = {
            let graph = DGGraphCreate()
#if DEBUG || DANCE_UI_INHOUSE
            if EnvValue.isGraphTraceEnabled {
                let _ = graph.add(trace: GraphBehaviorLogTrace(identifier: Unmanaged.passUnretained(graph).toOpaque()))
            }
            if DanceUIFeature.viewInfoTrace.isEnable {
                if let sahredViewInfoTrace {
                    let _ = graph.add(trace: sahredViewInfoTrace)
                }
            }
#endif // DEBUG || DANCE_UI_INHOUSE
            return graph
        }()
        
        internal init(_ usesNonSharedGraph: Bool) {
            let graph: DGGraphRef
            if usesNonSharedGraph {
                graph = DGGraphCreate()
#if DEBUG || DANCE_UI_INHOUSE
                if DanceUIFeature.viewInfoTrace.isEnable {
                    let standaloneTrace = ViewInfoTrace(name: "standalone")
                    viewInfoTrace = standaloneTrace
                    standaloneViewInfoTraceID = graph.add(trace: standaloneTrace)
                } else {
                    viewInfoTrace = nil
                    standaloneViewInfoTraceID = nil
                }
#endif // DEBUG || DANCE_UI_INHOUSE
            } else {
                graph = DGGraphCreateShared(Data.sharedGraph)
#if DEBUG || DANCE_UI_INHOUSE
                if DanceUIFeature.viewInfoTrace.isEnable {
                    viewInfoTrace = Data.sahredViewInfoTrace
                    standaloneViewInfoTraceID = nil
                } else {
                    viewInfoTrace = nil
                    standaloneViewInfoTraceID = nil
                }
#endif // DEBUG || DANCE_UI_INHOUSE
            }
            let globalSubgraph = DGSubgraphCreate(graph)
            DGSubgraphRef.current = globalSubgraph
            self.graph = graph
            self.globalSubgraph = globalSubgraph
            self.isRemoved = false
            self.isHiddenForReuse = false
            self._time = Attribute(value: .zero)
            self._environment = Attribute(value: EnvironmentValues())
            self._phase = Attribute(value: _GraphInputs.Phase())
            self._hostPreferenceKeys = Attribute(value: PreferenceKeys())
            self._transaction = Attribute(value: Transaction())
            self.rootSubgraph = DGSubgraphCreate(graph)
            globalSubgraph.add(child: rootSubgraph)
            DGSubgraphRef.current = nil
            self.inputs = _GraphInputs(time: self._time,
                                       environment: self._environment,
                                       phase: self._phase,
                                       transaction: self._transaction)
            self.usesNonSharedGraph = usesNonSharedGraph
        }
        
    }
    
    internal struct RemovedState: OptionSet {

        internal var rawValue: UInt8

        internal static let `default` = RemovedState()

        internal static let noWindow = RemovedState(rawValue: 0x1 << 0)

        internal static let hiddenForReuse = RemovedState(rawValue: 0x1 << 1)

        internal static let element0x4 = RemovedState(rawValue: 0x1 << 2)
        
        @inlinable
        internal var isRemoved: Bool {
            !isEmpty
        }
        
        @inlinable
        internal init (rawValue: UInt8) {
            self.rawValue = rawValue
        }
        
    }
    
    internal static var currentHost: GraphHost {
        let graph: DGGraphRef
        if let currentAttribute = DGAttribute.current {
            graph = currentAttribute.graph
        } else {
            let currentSubgraph = DGSubgraphRef.current!
            graph = currentSubgraph.graph
        }
        return graph.graphHost()
    }
    
    internal private(set) var data: Data

    internal private(set) var isInstantiated: Bool

    internal private(set) var hostPreferenceValues: WeakAttribute<PreferenceList>

    internal private(set) var lastHostPreferencesSeed: VersionSeed

    internal private(set) var pendingTransactions: [AsyncTransaction]

    internal private(set) var inTransaction: Bool

    internal private(set) var continuations: [() -> Void]

    internal private(set) var mayDeferUpdate: Bool

    internal private(set) var removedState: RemovedState

    internal var frozen: Bool = false
    
    internal init(data: Data) {
        self.isInstantiated = false
        self.lastHostPreferencesSeed = .invalid
        self.pendingTransactions = []
        self.inTransaction = false
        self.continuations = []
        self.mayDeferUpdate = true
        self.removedState = .default
#if DEBUG || DANCE_UI_INHOUSE
        if !isMainThread && !data.usesNonSharedGraph {
            runtimeIssue(type: .error, "calling into DanceUI on a non-main thread is not supported")
        }
#endif
        hostPreferenceValues = WeakAttribute()
        self.data = data
        
        self.graph.onUpdate { [weak self] in
            guard let self else {
                return
            }
            self.graphDelegate?.updateGraph { _ in
                
            }
        }
        
        self.graph.onInvalidation { [weak self] (identifier) in
            guard let self else {
                return
            }
            self.graphInvalidation(from: identifier)
        }
        
        self.graph.setGraphHost(self)
    }
    
    deinit {
        invalidate()
    }
    
    @inlinable
    internal var graph: DGGraphRef {
        data.graph!
    }
    
    // DanceUI addition
    // data.graph is set nil in GraphHost.deinit process. In case that
    // data.graph is accessed in this process, there is an optional
    // version of data.graph.
    @inlinable
    internal var graphOrNil: DGGraphRef? {
        data.graph
    }
    
    @inlinable
    internal var isValid: Bool {
        data.graph != nil
    }
    
    @inlinable
    internal var parentHost: GraphHost? {
        nil
    }

    @inlinable
    internal var isUpdating: Bool {
        guard isMainThread else {
            return false
        }
        guard let graph = data.graph else {
            return false
        }
        return graph.isUpdating
    }
    
    @inlinable
    internal static var isUpdating: Bool {
        sharedGraph.hasCurrentUpdate
    }

    @inlinable
    internal var graphDelegate: GraphDelegate? {
        nil
    }

    @inlinable
    internal var graphInputs: _GraphInputs {
        data.inputs
    }

    @inlinable
    internal var time: Time {
        data.time
    }
    
    @inlinable
    internal func setTime(_ time: Time) {
        guard time != data.time else {
            return
        }
        
        data.time = time
        timeDidChange()
    }

    /// Abstract function
    internal func timeDidChange() {
        _intentionallyLeftBlank()
    }
    
    @inlinable
    internal var environment: EnvironmentValues {
        data.environment
    }
    
    @inlinable
    internal func setEnvironment(values: EnvironmentValues) {
        data.environment = values
    }
    
    // DanceUI imaginary
    @inlinable
    internal var phase: _GraphInputs.Phase {
        data.phase
    }
    
    @inlinable
    internal func setPhase(phase: _GraphInputs.Phase) {
        data.phase = phase
    }

    @inlinable
    internal var hostPreferenceKeys: PreferenceKeys {
        data.hostPreferenceKeys
    }

    @inlinable
    internal var transaction: Transaction {
        data.transaction
    }
    
    // MARK: Transactioning
    
    @inlinable
    internal var hasPendingTransactions: Bool {
        return !pendingTransactions.isEmpty
    }

    @inlinable
    internal func dequeueContinuations() -> [() -> Void] {
        defer {
            continuations = []
        }
        return continuations
    }

    @inlinable
    internal func withTransaction<R>(body: () -> R) -> R {
        inTransaction = true
        
        defer {
            inTransaction = false
        }
        
        return body()
    }


    /// - Warning DO NOT RENAME THIS FUNCTION INTO `withTransaction`. THERE IS
    /// A GLOBAL VERSION OF `withTransaction(_:, do:)` WHICH DUPLICATES THE
    /// SIGNATURE WHEN IS USED WITH TRAILING CLOSURE.
    ///
    @inlinable
    internal func withAsyncTransaction<R>(_ asyncTransaction: AsyncTransaction, body: () -> R) -> R {
        let transaction = asyncTransaction.transaction
        if !transaction.isEmpty {
            data.transaction = transaction
        }
        
        inTransaction = true
        
        defer {
            inTransaction = false
            if !data.transaction.isEmpty {
                let oldTransaction = data.transaction
                data.transaction = Transaction()
                if let listener = oldTransaction.listener {
                    listener.checkDispatched()
                }
                if let listener = oldTransaction.logicalListener {
                    listener.checkDispatched()
                }
            }
        }
        
        return body()
    }
    
    internal static let maxContinuationConvergenceCount = 8
    
    /// Run an `AsyncTransaction` and then converging graph changes by
    /// evaluating the `continuations` and updating active attributes in the
    /// `globalSubgraph` in 8 times. Empty `continuations` could end the
    /// convergence before 8 times was reached.
    ///
    private func runTransaction(_ asyncTransaction: AsyncTransaction) {
        instantiateIfNeeded()
        
        withAsyncTransaction(asyncTransaction) {
            asyncTransaction.apply()
            runTransactions()
        }
    }
    
    /// A better name may be `runContinuations`. However, it takes a lot of jobs
    /// from `runTransactions` in DanceUI prior to 1.0. Let's continue use the
    /// old name instead.
    ///
    internal func runTransactions() {
        var convergenceCount = 0
        
        while convergenceCount <= Self.maxContinuationConvergenceCount {
            
            let continuations: [() -> Void]
            
            (continuations, self.continuations) = (self.continuations, [])
            
            continuations.forEach {
                $0()
            }
            
#if DEBUG || DANCE_UI_INHOUSE
            Signpost.graphHost.traceInterval("GlobalSubgraph.updateActive: hostingState: %s; %s", [graphDelegate?.hostingState() ?? "empty", graphDelegate?.hostingType() ?? "empty"]) {
                graphOrNil.withUpdaterCounter(tag: "Continuations") {
                    data.globalSubgraph.update(.active)
                }
            }
#else
            graphOrNil.withUpdaterCounter(tag: "Continuations") {
                data.globalSubgraph.update(.active)
            }
#endif
            
            if self.continuations.isEmpty {
                break
            }
            
            convergenceCount &+= 1
        }
    }
    
    internal func continueTransaction(_ body: @escaping () -> Void) {
        var currentHost = self
        if !currentHost.inTransaction {
            repeat {
                guard let parent = currentHost.parentHost else {
                    asyncTransaction(Transaction(),
                                     mutation: CustomGraphMutation(body: body),
                                     style: .ignoresFlush,
                                     mayDeferUpdate: true)
                    return
                }
                currentHost = parent
                guard !parent.inTransaction else {
                    break
                }
            } while true
        }
        
        currentHost.continuations.append(body)
    }

    /// `concatenatable` is named after `transaction.mayConcatenate(with:)`.
    @inline(__always)
    private func concatenatableAsyncTransaction(with transaction: Transaction) -> AsyncTransaction? {
        guard let tnx = pendingTransactions.last,
              tnx.canAppendAsyncTransaction(with: transaction) else {
            return nil
        }
        return tnx
    }

    internal func asyncTransaction<Mutation: GraphMutation>(_ transaction: Transaction,
                                                            mutation: Mutation,
                                                            style: _GraphMutation_Style,
                                                            mayDeferUpdate: Bool) {
        guard isValid else {
            return
        }
        
        var ignoreFlush = true
        
        // PerThreadOSCallback.traceEvent("[GraphHost] asyncTransaction pendingTransaction = \(pendingTransactions.count)", identifier: graphDelegate)
        
        if style == .ignoresFlushWhenUpdating {
            ignoreFlush = isUpdating
        }
        
        self.mayDeferUpdate = self.mayDeferUpdate && mayDeferUpdate
        
        if let concatenatableTransaction = concatenatableAsyncTransaction(with: transaction) {
            mutation.traceGraphHostConcat(graphDelegate)
            
            concatenatableTransaction.append(mutation)
            
            guard !ignoreFlush,
                  pendingTransactions.count > 1 else {
                return
            }
            
            pendingTransactions.removeLast()
            flushTransactions()
            pendingTransactions.append(concatenatableTransaction)
        } else {
            mutation.traceGraphHostAppend(graphDelegate)
            
            if !ignoreFlush {
                flushTransactions()
            }
            
            if pendingTransactions.isEmpty {
                if !frozen {
                    RunLoop.performOnMainThread { [weak self] in
                        guard let self else {
                            return
                        }
                        self.graphDelegate?.updateGraph { host in
                            host.flushTransactions()
                        }
                    }
                }
            }
            
            let deferrredAsyncTransaction = AsyncTransaction(transaction: transaction)
            deferrredAsyncTransaction.append(mutation)
            pendingTransactions.append(deferrredAsyncTransaction)
        }
    }
    
    
    internal func flushTransactions() {
        // PerThreadOSCallback.traceEvent("[GraphHost] flush transactions", identifier: graphDelegate)
        
        guard isValid else {
            return
        }
        
        guard !pendingTransactions.isEmpty else {
            // PerThreadOSCallback.traceEvent("[GraphHost] flush no transactions", identifier: graphDelegate)
            return
        }
        
#if DEBUG
        _danceuiPrecondition(!frozen)
#endif
        
        let asyncTransactions: [AsyncTransaction]
        
        (asyncTransactions, pendingTransactions) = (pendingTransactions, [])
        
        if !asyncTransactions.isEmpty {
            for asyncTransaction in asyncTransactions {
                runTransaction(asyncTransaction)
            }
            
            graphDelegate?.graphDidChange()
            
            mayDeferUpdate = true
        }
        
        // PerThreadOSCallback.traceEvent("[GraphHost] flush \(asyncTransactions.count) transactions", identifier: graphDelegate)
    }
    
    // MARK: Preference
    
    @inlinable
    internal func setHostPreferenceValues(_ preferenceValues: Attribute<PreferenceList>?) {
        self.hostPreferenceValues = WeakAttribute(preferenceValues)
    }
    
    internal func addPreference<Key: HostPreferenceKey>(_ keyType: Key.Type) {
        DGGraphRef.withoutUpdate {
            self.data.hostPreferenceKeys.add(keyType)
        }
    }

    internal func removePreference<Key: HostPreferenceKey>(_ keyType: Key.Type) {
        DGGraphRef.withoutUpdate {
            self.data.hostPreferenceKeys.remove(keyType)
        }
    }
    
    internal func updatePreferences() -> Bool {
        let seed = hostPreferenceValues.value?.mergedSeed ?? VersionSeed(value: 0)
        let didUpdate = !seed.isVaild || !lastHostPreferencesSeed.isVaild || seed != lastHostPreferencesSeed
        lastHostPreferencesSeed = seed
        return didUpdate
    }
    
    internal func preferenceValues() -> PreferenceList {
        instantiateIfNeeded()
        return hostPreferenceValues.value ?? PreferenceList()
    }
    
    fileprivate func preferenceValue<Key: HostPreferenceKey>(_ keyType: Key.Type) -> Key.Value {
        if data.hostPreferenceKeys.contains(keyType) {
            return preferenceValues()[keyType].value
        } else {
            defer {
                removePreference(keyType)
            }
            addPreference(keyType)
            return preferenceValues()[keyType].value
        }
    }
    
    // MARK: Instantiating & Uninstantiating
    
    internal func instantiate() {
        guard !isInstantiated else {
            return
        }
        
        graphDelegate?.updateGraph { _ in }
        
        instantiateOutputs()
        isInstantiated = true
    }

    internal func uninstantiate(immediately: Bool) {
        guard isInstantiated else {
            return
        }
        data.inputs.updateCachedEnvironment(MutableBox(CachedEnvironment(data.$environment)))
        uninstantiateOutputs()
        
        data.rootSubgraph.willRemove()
        
        if !data.isRemoved {
            data.globalSubgraph.remove(child: data.rootSubgraph)
        }
        
        let rootSubgraph = self.data.rootSubgraph
        rootSubgraph.willInvalidate(isInserted: false)
        if immediately {
            rootSubgraph.invalidate()
        } else {
            Update.enqueueAction {
                rootSubgraph.invalidate()
            }
        }
        data.rootSubgraph = DGSubgraphCreate(graph)

        if !data.isRemoved {
            data.globalSubgraph.add(child: data.rootSubgraph)
        }
        isInstantiated = false
    }

    /// Abstract function
    internal func instantiateOutputs() {
        _intentionallyLeftBlank()
    }

    /// Abstract function
    internal func uninstantiateOutputs() {
        _intentionallyLeftBlank()
    }
    
    internal func instantiateIfNeeded() {
        guard !isInstantiated else {
            return
        }
        if waitingForPreviewThunks {
            if !blockedGraphHosts.contains(where: {$0 === self}) {
                blockedGraphHosts.append(self)
            }
        } else {
            instantiate()
        }
    }
    
    // MARK: Managing Remove State
    
    @inlinable
    internal func setRemovedState(_ removedState: RemovedState) {
        guard self.removedState != removedState else {
            return
        }
        self.removedState = removedState
        updateRemovedState()
    }
    
    internal func updateRemovedState() {
        if removedState.isRemoved != data.isRemoved {
            if !removedState.isRemoved {
                data.globalSubgraph.add(child: data.rootSubgraph)
                data.rootSubgraph.didReinsert()
            } else {
                data.rootSubgraph.willRemove()
                data.globalSubgraph.remove(child: data.rootSubgraph)
            }
            data.isRemoved = removedState.isRemoved
        }
        
        let hiddenForReuse = removedState == [.hiddenForReuse, .element0x4]
        if hiddenForReuse != data.isHiddenForReuse {
            data.isHiddenForReuse = hiddenForReuse
            isHiddenForReuseDidChange()
        }
    }

    /// Abstract function
    internal func isHiddenForReuseDidChange() {
        _intentionallyLeftBlank()
    }
    
    // MARK: Manipulating Underlying Attribute Graph
    
    internal func intern<ValueType>(_ valueType: ValueType, id: _GraphInputs.ConstantID) -> Attribute<ValueType> {
        let internedID = id.internedID
        return self.data.rootSubgraph.apply {
            self.data.inputs.intern(valueType, id: internedID.internedID)
        }
    }
    
    internal func setNeedsUpdate(mayDeferUpdate: Bool) {
        // Yes, it is!
        self.mayDeferUpdate = self.mayDeferUpdate && mayDeferUpdate
        guard let graph = data.graph else {
            return
        }
        DGGraphSetNeedsUpdate(graph)
    }
    
    internal func graphInvalidation(from attribute: DGAttribute?) {
        guard let attribute = attribute else {
            self.graphDelegate?.graphDidChange()
            return
        }
        
        let attributeHost = attribute.graph.graphHost()
        let transaction = attributeHost.data.transaction

        let canDeferUpdate: Bool
        if mayDeferUpdate {
            canDeferUpdate = attributeHost.mayDeferUpdate
        } else {
            canDeferUpdate = false
        }
        mayDeferUpdate = canDeferUpdate
        
        if transaction.isEmpty {
            self.graphDelegate?.graphDidChange()
        } else {
            self.asyncTransaction(transaction,
                                  mutation: EmptyGraphMutation(),
                                  style: .ignoresFlush,
                                  mayDeferUpdate: true)
        }
    }

    internal func invalidate() {
        if isInstantiated {
            data.globalSubgraph.willInvalidate(isInserted: false)
            self.isInstantiated = false
        }
        if let graph = data.graph {
#if DEBUG || DANCE_UI_INHOUSE
            if let standaloneViewInfoTraceID = data.standaloneViewInfoTraceID {
                data.graph?.remove(traceID: standaloneViewInfoTraceID)
            }
#endif
            data.globalSubgraph.invalidate()
            graph.context = nil
            graph.invalidate()
            data.graph = nil
        }
    }
    
    /// Called by `_ArchivedViewHost.reset() -> ()`. Currently has no work.
    internal func incrementPhase() {
        var data = data
        data.phase.value += 2
        graphDelegate?.graphDidChange()
    }
    
    internal static var sharedGraph: DGGraphRef {
        Data.sharedGraph
    }
    
}

@available(iOS 13.0, *)
extension DGGraphRef {
    
    internal func graphHost() -> GraphHost {
        unsafeBitCast(self.context, to: GraphHost.self)
    }

    internal func viewGraph() -> ViewGraph {
        unsafeDowncast(graphHost(), to: ViewGraph.self)
    }

    internal var viewGraphOrNil: ViewGraph? {
        guard let context = self.context else {
            return nil
        }
        return unsafeBitCast(context, to: ViewGraph.self)
    }

}

@available(iOS 13.0, *)
internal protocol TransactionHostProvider: AnyObject {

    var mutationHost: GraphHost? { get }

}

@available(iOS 13.0, *)
internal var waitingForPreviewThunks: Bool {
    false
}

@available(iOS 13.0, *)
internal var blockedGraphHosts: [GraphHost] = []

@available(iOS 13.0, *)
extension DGGraphRef {
    
    @inline(__always)
    fileprivate func setGraphHost(_ graphHost: GraphHost) {
        let selfPtr = Unmanaged<GraphHost>.passUnretained(graphHost).toOpaque()
        self.context = selfPtr
    }
    
}

@available(iOS 13.0, *)
extension ViewRendererHost {
    
    internal func preferenceValue<Key: HostPreferenceKey>(keyType: Key.Type) -> Key.Value {
        updateViewGraph { viewGraph in
            viewGraph.preferenceValue(keyType)
        }
    }
    
}
