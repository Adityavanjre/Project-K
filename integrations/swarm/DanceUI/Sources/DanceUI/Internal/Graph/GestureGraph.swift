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

internal protocol GestureGraphDelegate: AnyObject {
    
    func enqueueAction(_ action: @escaping () -> Void)
    
}

internal struct GestureCategory: OptionSet, Defaultable {
    
    internal static var defaultValue: GestureCategory {
        GestureCategory(rawValue: 0)
    }
    
    internal let rawValue: Int
    
    internal struct Key: PreferenceKey {
        
        static var defaultValue: GestureCategory {
            GestureCategory.defaultValue
        }
        
        static func reduce(value: inout GestureCategory, nextValue: () -> GestureCategory) {
            value = GestureCategory(rawValue: value.rawValue | nextValue().rawValue)
        }
        
    }
    
}

@available(iOS 13.0, *)
internal protocol EventGraphHost: AnyObject {

    var eventBindingManager : EventBindingManager { get }

    var responderNode : ResponderNode? { get }

    var focusedResponder : ResponderNode? { get }

    var nextGestureUpdateTime : Time { get }

    func setInheritedPhase(_ phase: _GestureInputs.InheritedPhase)

    func sendEvents(_ events: [EventID : EventType], rootNode: ResponderNode, at time: Time) -> EventOutputs

    func resetEvents()

    func gestureCategory() -> GestureCategory?

}

@available(iOS 13.0, *)
internal protocol UIKitEventGraphHost: EventGraphHost {

    var gestureRecognizerConfiguration: UIHostingGestureRecognizerConfiguration { get }

    var rootGestureRecognitionWitness: GestureRecognitionWitness? { get }

    var gestureRecognizerList: PlatformGestureRecognizerList? { get }

}

@available(iOS 13.0, *)
internal class GestureGraph: GraphHost, EventGraphHost, CustomStringConvertible {

    internal weak var rootResponder: AnyGestureResponder_FeatureGestureContainer?

    internal weak var delegate: GestureGraphDelegate?

    internal let eventBindingManager: EventBindingManager

    @Attribute
    private var gestureTime: Time

    @Attribute
    private var gestureEvents: [EventID: EventType]

    @Attribute
    private var inheritedPhase: _GestureInputs.InheritedPhase

    @Attribute
    private var gestureResetSeed: UInt32

    @OptionalAttribute
    private var rootPhase: GesturePhase<()>?

    @OptionalAttribute
    private var gestureCategoryAttr: GestureCategory?

    @OptionalAttribute
    private var gestureLabelAttr: String??

    @OptionalAttribute
    private var isCancellableAttr: Bool?

    @OptionalAttribute
    private var requiredTapCountAttr: Int??

    @OptionalAttribute
    private var gestureDependencyAttr: GestureDependency?

    @Attribute
    private var gesturePreferenceKeys: PreferenceKeys

    internal var nextUpdateTime: Time

    /// The storage of `gestureRecognizerObservers`. Inherited from view
    /// hierarchy and overriden by
    /// `_UIHostingView.localGestureRecognizerObservers`.
    ///
    @Attribute
    internal var gestureObservers: GestureObservers

    @OptionalAttribute
    private var isCompanionGestureAttr: Bool?
    
    internal init(rootResponder: AnyGestureResponder_FeatureGestureContainer) {
        self.eventBindingManager = EventBindingManager()
        nextUpdateTime = .distantFuture
        let data = GraphHost.Data(false)
        (
            self.rootResponder,
            _gestureTime,
            _gestureEvents,
            _inheritedPhase,
            _gestureResetSeed,
            _gesturePreferenceKeys,
            _gestureObservers
        ) = data.globalSubgraph.apply {
            (
                rootResponder,
                Attribute(value: .zero),
                Attribute(value: [:]),
                Attribute(value: .failed),
                Attribute(value: 0),
                Attribute(value: PreferenceKeys()),
                Attribute(value: GestureObservers())
            )
        }
        super.init(data: data)
        self.eventBindingManager.host = self
    }
    
    internal override init(data: GraphHost.Data) {
        _unimplementedInitializer(className: "GestureGraph")
    }
    
    /// The return value EventOutputs is a DanceUI addition.
    internal func sendEvents(_ events: [EventID : EventType], rootNode: ResponderNode, at time: Time) ->  EventOutputs {
        guard let rootResponder = rootResponder,
              rootResponder.isValid else {
            return EventOutputs()
        }
        
        instantiateIfNeeded()
        
        return withTransaction {
            if data.time != time {
                setTime(time)
            }

            gestureEvents = events

            let eventSubgraph = data.globalSubgraph

            var result = EventOutputs()
            var currentEvents = events
            var shouldContinue = true
#if DEBUG
            var updateCount = 0
#endif
            repeat {
#if DEBUG
                defer {
                    updateCount += 1
                }
#endif
                let currentContinuations = dequeueContinuations()
                currentContinuations.forEach { body in
                    body()
                }
                eventSubgraph.update(.active)
                shouldContinue = true
                if continuations.isEmpty {
                    shouldContinue = false
                    result.gesturePhase = rootPhase!
                } else {
                    if !currentEvents.isEmpty {
                        gestureEvents = [:]
                        currentEvents = [:]
                    }
                }
                
            } while shouldContinue

            return result
        }
    }
    
    internal var nextGestureUpdateTime : Time {
        nextUpdateTime
    }
    
    @inlinable
    internal func scheduleNextGestureUpdate(byTime time: Time) {
        nextUpdateTime = min(time, nextUpdateTime)
    }
    
    internal var description : String {
        "<GestureGraph: \(ObjectIdentifier(self))>"
    }
    
    internal func resetEvents() {
        uninstantiate(immediately: false)
    }
    
    internal func enqueueAction(_ action: @escaping () -> Void) {
        delegate?.enqueueAction(action)
    }
    
    internal var responderNode : ResponderNode? {
        rootResponder
    }
    
    internal override func timeDidChange() {
        super.timeDidChange()
        self.nextUpdateTime = .distantFuture
    }
    
    internal func gestureCategory() -> GestureCategory? {
        guard let rootResponder else {
            return nil
        }
        guard rootResponder.isValid else {
            return nil
        }
        return Update.perform {
            gestureCategoryAttr
        }
    }
    
    @inline(__always)
    private func evaluate<V>(_ body: () -> V) -> V {
        Update.perform {
            instantiateIfNeeded()
            return body()
        }
    }
    
    @inline(__always)
    internal var isCancellable: Bool {
        evaluate {
            isCancellableAttr ?? false
        }
    }
    
    @inline(__always)
    internal var gestureLabel: String? {
        evaluate {
            gestureLabelAttr ?? nil
        }
    }
    
    @inline(__always)
    internal var requiredTapCount: Int? {
        evaluate {
            requiredTapCountAttr ?? nil
        }
    }
    
    @inline(__always)
    internal var gestureDependency: GestureDependency {
        evaluate {
            gestureDependencyAttr ?? .none
        }
    }
    
    @inline(__always)
    internal var isCompanionGesture: Bool {
        evaluate {
            isCompanionGestureAttr ?? false
        }
    }
    
    internal var focusedResponder: ResponderNode? {
        guard let rootResponder else {
            return nil
        }

        guard let host = rootResponder.host else {
            return nil
        }
        guard let eventGraphHost = host.`as`(EventGraphHost.self) else {
            return nil
        }
        return eventGraphHost.focusedResponder
    }
    
    internal func setInheritedPhase(_ value: _GestureInputs.InheritedPhase) {
        inheritedPhase = value
    }
    
    internal override func instantiateOutputs() {
        guard let rootResponder else {
            return
        }
        
        let viewSugraph = rootResponder.viewSubgraph
        
        var viewInputs = rootResponder.inputs
        
        viewInputs.time = data.$time
        
        var gestureInputs = _GestureInputs(viewInputs: viewInputs, viewSubgraph: viewSugraph, preferences: PreferencesInputs(hostKeys: $gesturePreferenceKeys), events: $gestureEvents, resetSeed: $gestureResetSeed, inheritedPhase: $inheritedPhase, platformInputs: PlatformGestureInputs())
        
        gestureInputs.skipCombiners = true
        gestureInputs.gestureGraph = true
#if DEBUG
        // gestureInputs.includeDebugOutput = true
#endif
        gestureInputs.requiresGestureLabel = true
        gestureInputs.requiresGestureCategory = true
        gestureInputs.requiresIsCancellableGesture = true
        gestureInputs.requiresRequiredTapCount = true
        gestureInputs.requiresGestureDependency = true
        gestureInputs.requiresIsCompanionGesture = true
        
        let gestureOutputs = data.rootSubgraph.apply {
            rootResponder.makeGesture(inputs: gestureInputs)
        }
        
        $rootPhase = gestureOutputs.phase
        $gestureCategoryAttr = gestureOutputs.gestureCategory
        $gestureLabelAttr = gestureOutputs.gestureLabel
        $isCancellableAttr = gestureOutputs.isCancellableGesture
        $requiredTapCountAttr = gestureOutputs.requiredTapCount
        $gestureDependencyAttr = gestureOutputs.gestureDependency
        $isCompanionGestureAttr = gestureOutputs.isCompanionGesture
    }
    
    internal override func uninstantiateOutputs() {
        $rootPhase = nil
        gestureEvents = [:]
        inheritedPhase = .failed
        gestureResetSeed = .zero
        gesturePreferenceKeys = PreferenceKeys()
        guard let rootResponder else {
            return
        }
        rootResponder.resetGesture()
    }
    
    internal static var current: GestureGraph {
        currentHost as! GestureGraph
    }
    
}

#if DEBUG

// MARK: - Testable
@available(iOS 13.0, *)
extension GestureGraph {

    internal var gestureTimeForTesting: Time {
        get {
            gestureTime
        }
        set {
            gestureTime = newValue
        }
    }

    internal var gestureEventsForTesting: [EventID: EventType] {
        get {
            gestureEvents
        }
        set {
            gestureEvents = newValue
        }
    }

    internal var inheritedPhaseForTesting: _GestureInputs.InheritedPhase {
        get {
            inheritedPhase
        }
        set {
            inheritedPhase = newValue
        }
    }

    internal var gestureResetSeedForTesting: UInt32 {
        get {
            gestureResetSeed
        }
        set {
            gestureResetSeed = newValue
        }
    }

    internal var rootPhaseForTesting: GesturePhase<()>? {
        rootPhase
    }

    internal var gestureCategoryAttrForTesting: GestureCategory? {
        gestureCategoryAttr
    }

    internal var gestureLabelAttrForTesting: String?? {
        gestureLabelAttr
    }

    internal var isCancellableAttrForTesting: Bool? {
        isCancellableAttr
    }

    internal var requiredTapCountAttrForTesting: Int?? {
        requiredTapCountAttr
    }

    internal var gestureDependencyAttrForTesting: GestureDependency? {
        gestureDependencyAttr
    }

    internal var gesturePreferenceKeysForTesting: PreferenceKeys {
        get {
            gesturePreferenceKeys
        }
        set {
            gesturePreferenceKeys = newValue
        }
    }
}

#endif

@available(iOS 13.0, *)
extension _GestureInputs {
    
    internal var requiresGestureLabel: Bool {
        get {
            preferences.contains(GestureLabelKey.self)
        }
        set {
            if newValue {
                preferences.add(GestureLabelKey.self)
            } else {
                preferences.remove(GestureLabelKey.self)
            }
        }
    }
    
    internal var requiresGestureCategory: Bool {
        get {
            preferences.contains(GestureCategory.Key.self)
        }
        set {
            if newValue {
                preferences.add(GestureCategory.Key.self)
            } else {
                preferences.remove(GestureCategory.Key.self)
            }
        }
    }
    
    internal var requiresIsCancellableGesture: Bool {
        get {
            preferences.contains(IsCancellableGestureKey.self)
        }
        set {
            if newValue {
                preferences.add(IsCancellableGestureKey.self)
            } else {
                preferences.remove(IsCancellableGestureKey.self)
            }
        }
    }
    
    internal var requiresRequiredTapCount: Bool {
        get {
            preferences.contains(RequiredTapCountKey.self)
        }
        set {
            if newValue {
                preferences.add(RequiredTapCountKey.self)
            } else {
                preferences.remove(RequiredTapCountKey.self)
            }
        }
    }
    
    internal var requiresGestureDependency: Bool {
        get {
            preferences.contains(GestureDependency.Key.self)
        }
        set {
            if newValue {
                preferences.add(GestureDependency.Key.self)
            } else {
                preferences.remove(GestureDependency.Key.self)
            }
        }
    }
    
    internal var requiresIsCompanionGesture: Bool {
        get {
            preferences.contains(IsCompanionGestureKey.self)
        }
        set {
            if newValue {
                preferences.add(IsCompanionGestureKey.self)
            } else {
                preferences.remove(IsCompanionGestureKey.self)
            }
        }
    }
    
}

@available(iOS 13.0, *)
extension _GestureOutputs {
    
    internal var gestureLabel: Attribute<String?>? {
        get {
            preferences[GestureLabelKey.self]
        }
        set {
            preferences[GestureLabelKey.self] = newValue
        }
    }
    
    internal var gestureCategory: Attribute<GestureCategory>? {
        get {
            preferences[GestureCategory.Key.self]
        }
        set {
            preferences[GestureCategory.Key.self] = newValue
        }
    }
    
    internal var isCancellableGesture: Attribute<Bool>? {
        get {
            preferences[IsCancellableGestureKey.self]
        }
        set {
            preferences[IsCancellableGestureKey.self] = newValue
        }
    }
    
    internal var requiredTapCount: Attribute<Int?>? {
        get {
            preferences[RequiredTapCountKey.self]
        }
        set {
            preferences[RequiredTapCountKey.self] = newValue
        }
    }
    
    internal var gestureDependency: Attribute<GestureDependency>? {
        get {
            preferences[GestureDependency.Key.self]
        }
        set {
            preferences[GestureDependency.Key.self] = newValue
        }
    }
    
    internal var isCompanionGesture: Attribute<Bool>? {
        get {
            preferences[IsCompanionGestureKey.self]
        }
        set {
            preferences[IsCompanionGestureKey.self] = newValue
        }
    }
    
}

internal struct GestureLabelKey: PreferenceKey {
    
    internal static var defaultValue: String? {
        nil
    }
    
    internal static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue()
    }
    
}

internal struct IsCancellableGestureKey: PreferenceKey {
    
    internal static var defaultValue: Bool {
        false
    }
    
    internal static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func cancellable() -> some Gesture<Value> {
        truePreference(IsCancellableGestureKey.self)
    }
    
    internal func truePreference<A: PreferenceKey>(_ preference: A.Type) -> some Gesture<Value> where A.Value == Bool {
        modifier(TruePreferenceWritingGestureModifier<A, Self>())
    }
}

@available(iOS 13.0, *)
internal struct TruePreferenceWritingGestureModifier<A: PreferenceKey, B: Gesture>: GestureModifier where A.Value == Bool {
    
    internal typealias Value = B.Value
    
    internal typealias BodyValue = B.Value
    
    internal static func _makeGesture(modifier: _GraphValue<Self>, inputs: _GestureInputs, body: (_GestureInputs) -> _GestureOutputs<BodyValue>) -> _GestureOutputs<BodyValue> {
        var outputs = body(inputs)
        outputs.preferences[A.self] = Attribute(value: true)
        return outputs
    }
    
}

internal struct RequiredTapCountKey: PreferenceKey {
    
    internal static var defaultValue: Int? {
        nil
    }
    
    internal static func reduce(value: inout Int?, nextValue: () -> Int?) {
        let next = nextValue()
        switch (value, next) {
        case (nil, nil):
            value = nil
        case (nil, .some(let next)):
            value = next
        case (.some(_), nil):
            break
        case (.some(let val), .some(let next)):
            value = max(val, next)
        }
    }
    
}

internal struct IsCompanionGestureKey: PreferenceKey {
    
    internal static var defaultValue: Bool {
        false
    }
    
    internal static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
    
}

@available(iOS 13.0, *)
extension Gesture {
    
    internal func isCompanion() -> some Gesture<Value> {
        truePreference(IsCompanionGestureKey.self)
    }
}
