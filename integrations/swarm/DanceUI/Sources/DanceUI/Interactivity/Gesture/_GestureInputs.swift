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
public struct _GestureInputs {
    
    public var viewInputs: _ViewInputs

    private var viewSubgraph: DGSubgraphRef
    
    /// Dedicated for gesture container feature
    internal mutating func setViewSubgraph(_ viewSubgraph: DGSubgraphRef) {
        self.viewSubgraph = viewSubgraph
    }
    
    internal var preferences: PreferencesInputs

    internal var events: Attribute<[EventID: EventType]>

    internal var resetSeed: Attribute<UInt32>

    internal var inheritedPhase: Attribute<InheritedPhase>

    internal var options: Options

    internal var platformInputs: PlatformGestureInputs

    internal var multiFingerContinuityDisabled: OptionalAttribute<Bool>
    
    internal var preconvertedEventLocations: Bool {
        get {
            options.contains(.preconvertedEventLocations)
        }
        set {
            options.set(.preconvertedEventLocations, to: newValue)
        }
    }
    
    internal var allowsIncompleteEventSequences: Bool {
        get {
            options.contains(.allowsIncompleteEventSequences)
        }
        set {
            options.set(.allowsIncompleteEventSequences, to: newValue)
        }
    }
    
    internal var skipCombiners: Bool {
        get {
            options.contains(.skipCombiners)
        }
        set {
            options.set(.skipCombiners, to: newValue)
        }
    }
    
    internal var includeDebugOutput: Bool {
        get {
            options.contains(.includeDebugOutput)
        }
        set {
            options.set(.includeDebugOutput, to: newValue)
        }
    }
    
    internal var gestureGraph: Bool {
        get {
            options.contains(.gestureGraph)
        }
        set {
            options.set(.gestureGraph, to: newValue)
        }
    }
    
    @inline(__always)
    internal var requiresGestureRecognitionWitness: Bool {
        options.contains(.requiresGestureRecognitionWitness)
    }
    
    @inline(__always)
    internal func setRequiresGestureRecognitionWitness(_ flag: Bool) -> _GestureInputs {
        var result = self
        result.options.set(.requiresGestureRecognitionWitness, to: flag)
        return result
    }
    
    @inline(__always)
    internal var requiresPlatformGestureRecognizerList: Bool {
        options.contains(.requiresPlatformGestureRecognizerList)
    }
    
    @inline(__always)
    internal func setRequiresPlatformGestureRecognizerList(_ flag: Bool) -> _GestureInputs {
        var result = self
        result.options.set(.requiresPlatformGestureRecognizerList, to: flag)
        return result
    }
    
    @inline(__always)
    internal var requiresActiveGestureRecognizerObservers: Bool {
        options.contains(.requiresActiveGestureRecognizerObservers)
    }
    
    @inline(__always)
    internal func setRequiresActiveGestureRecognizerObservers(_ flag: Bool) -> _GestureInputs {
        var result = self
        result.options.set(.requiresActiveGestureRecognizerObservers, to: flag)
        return result
    }
    
    @inline(__always)
    internal init(viewInputs: _ViewInputs,
                  viewSubgraph: DGSubgraphRef,
                  preferences: PreferencesInputs,
                  events: Attribute<[EventID : EventType]>,
                  resetSeed: Attribute<UInt32>,
                  inheritedPhase: Attribute<_GestureInputs.InheritedPhase>,
                  options: Options = .default,
                  platformInputs: PlatformGestureInputs) {
        self.viewInputs = viewInputs
        self.viewSubgraph = viewSubgraph
        self.preferences = preferences
        self.events = events
        self.resetSeed = resetSeed
        self.inheritedPhase = inheritedPhase
        self.options = options
        self.platformInputs = platformInputs
        self.multiFingerContinuityDisabled = OptionalAttribute()
    }
    
    @inline(__always)
    internal init(deepCopy inputs: _GestureInputs) {
        self.viewInputs = _ViewInputs(deepCopy: inputs.viewInputs)
        self.viewSubgraph = inputs.viewSubgraph
        self.preferences = inputs.preferences
        self.events = inputs.events
        self.resetSeed = inputs.resetSeed
        self.inheritedPhase = inputs.inheritedPhase
        self.options = inputs.options
        self.platformInputs = inputs.platformInputs
        self.multiFingerContinuityDisabled = inputs.multiFingerContinuityDisabled
    }
    
    // swift-format-ignore: UseSynthesizedInitializer
    internal struct Options: OptionSet {
        
        internal typealias RawValue = UInt32
        
        internal var rawValue: RawValue
        
        @inlinable
        internal init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        internal static var `default`: Options = []
        
        internal static var preconvertedEventLocations: Options {
            Options(rawValue: 0x1)
        }
        
        internal static var allowsIncompleteEventSequences: Options {
            Options(rawValue: 0x1 << 1)
        }
        
        internal static var skipCombiners: Options {
            Options(rawValue: 0x1 << 2)
        }
        
        internal static var includeDebugOutput: Options {
            Options(rawValue: 0x1 << 3)
        }
        
        internal static var gestureGraph: Options {
            Options(rawValue: 0x1 << 4)
        }
        
        internal static var hasChangedCallbacks: Options {
            Options(rawValue: 0x1 << 5)
        }
        
        internal static var requiresGestureRecognitionWitness: Options {
            Options(rawValue: 0x1 << 16)
        }
        
        internal static var requiresPlatformGestureRecognizerList: Options {
            Options(rawValue: 0x1 << 17)
        }
        
        internal static var requiresActiveGestureRecognizerObservers: Options {
            Options(rawValue: 0x1 << 18)
        }
        
    }
    
    internal struct InheritedPhase: OptionSet, Defaultable, CustomStringConvertible {
        
        internal typealias RawValue = Int
        
        internal var rawValue: RawValue
        
        internal init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        internal static let failed = InheritedPhase(rawValue: 0x1)
        
        internal static let active = InheritedPhase(rawValue: 0x2)
        
        internal static var defaultValue: InheritedPhase {
            InheritedPhase(rawValue: 0x1) // failed
        }
        
        internal var description: String {
            var componentDescriptions = [String]()
            if contains(.failed) {
                componentDescriptions.append("failed")
            }
            if contains(.active) {
                componentDescriptions.append("active")
            }
            if componentDescriptions.isEmpty {
                return "<\(type(of: self)); empty >"
            } else {
                return "<\(type(of: self)); \(componentDescriptions.joined(separator: ", ")) >"
            }
        }
        
    }
    
    internal func makeIndirectOutputs<A>() -> _GestureOutputs<A> {
        if DanceUIFeature.gestureContainer.isEnable {
            let graphHost = GraphHost.currentHost
            @IndirectAttribute(source: graphHost.intern(GesturePhase<A>.defaultValue, id: _GraphInputs.ConstantID()))
            var phase
            
            var outputs = _GestureOutputs.make(phase: $phase)
            
            outputs.preferences = preferences.makeIndirectOutputs()
            
            return outputs
        } else {
            let graphHost = GraphHost.currentHost
            @IndirectAttribute(source: graphHost.intern(GesturePhase<A>.defaultValue, id: _GraphInputs.ConstantID()))
            var phase
            
            var outputs = _GestureOutputs.make(phase: $phase)
            
            if requiresGestureRecognitionWitness {
                let attribute = IndirectAttribute(source: graphHost.intern(GestureRecognitionWitness.defaultValue, id: _GraphInputs.ConstantID()))
                outputs = outputs.withGestureRecognitionWitness(attribute.projectedValue)
            }

            if requiresPlatformGestureRecognizerList {
                let attribute = IndirectAttribute(source: graphHost.intern(PlatformGestureRecognizerList.defaultValue, id: _GraphInputs.ConstantID()))
                outputs = outputs.withPlatformGestureRecognizerList(attribute.projectedValue)
            }

            if requiresActiveGestureRecognizerObservers {
                let attribute = IndirectAttribute(source: graphHost.intern([AnyUIGestureRecognizerObserver](), id: _GraphInputs.ConstantID()))
                outputs = outputs.withActiveGestureRecognizerObservers(attribute.projectedValue)
            }
            
            return outputs
        }
    }
    
    @inline(__always)
    internal var transform: Attribute<ViewTransform> {
        get {
            viewInputs.transform
        }
        set {
            viewInputs.transform = newValue
        }
    }
    
    @inline(__always)
    internal var position: Attribute<ViewOrigin> {
        get {
            viewInputs.position
        }
        set {
            viewInputs.position = newValue
        }
    }
    
    @inline(__always)
    internal var size: Attribute<ViewSize> {
        get {
            viewInputs.size
        }
        set {
            viewInputs.size = newValue
        }
    }
    
    @inline(__always)
    internal var hitTestInsets: Attribute<EdgeInsets?>? {
        get {
            viewInputs.hitTestInsets
        }
        set {
            viewInputs.hitTestInsets = newValue
        }
    }
    
    @inline(__always)
    internal var time: Attribute<Time> {
        get {
            viewInputs.time
        }
        set {
            viewInputs.time = newValue
        }
    }
    
    @inline(__always)
    internal var environment: Attribute<EnvironmentValues> {
        viewInputs.environment
    }
    
    @inline(__always)
    internal var phase: Attribute<_GraphInputs.Phase> {
        get {
            viewInputs.phase
        }
        set {
            viewInputs.phase = newValue
        }
    }
    
    @inline(__always)
    internal func animatedPosition() -> Attribute<ViewOrigin> {
        if DanceUIFeature.gestureContainer.isEnable {
            viewSubgraph.apply {
                viewInputs.animatedPosition
            }
        } else {
            viewInputs.animatedPosition
        }
    }
    
    @inline(__always)
    internal func animatedSize() -> Attribute<ViewSize> {
        if DanceUIFeature.gestureContainer.isEnable {
            viewSubgraph.apply {
                viewInputs.animatedSize
            }
        } else {
            viewInputs.animatedSize
        }
    }
    
    internal mutating func mergeViewInputs(_ inputs: _ViewInputs, viewSubgraph: DGSubgraphRef) {
        // Byte-to-byte copy with MutableBox<CachedEnvironment> created.
        self.viewInputs = _ViewInputs(deepCopy: inputs)
        self.viewSubgraph = viewSubgraph
    }
    
    internal mutating func copyCaches() {
        self = _GestureInputs(deepCopy: self)
    }
    
    /// An un-optimal version of `mapEnvironment`
    @inline(__always)
    internal mutating func attribute<Member>(keyPath: KeyPath<EnvironmentValues, Member>) -> Attribute<Member> {
        if DanceUIFeature.gestureContainer.isEnable {
            viewSubgraph.apply {
                self.viewInputs.environmentAttribute(keyPath: keyPath)
            }
        } else {
            self.viewInputs.environmentAttribute(keyPath: keyPath)
        }
    }
    
    internal func makeDefaultOutputs<A>() -> _GestureOutputs<A> {
        return _GestureOutputs(phase: Attribute(DefaultRule<GesturePhase<A>>()), preferences: preferences.makeIndirectOutputs())
    }
    
    internal mutating func intern<ValueType>(_ value: ValueType, id: _GraphInputs.ConstantID) -> Attribute<ValueType> {
        if DanceUIFeature.gestureContainer.isEnable {
            viewSubgraph.apply {
                viewInputs.intern(value, id: id)
            }
        } else {
            viewInputs.intern(value, id: id)
        }
    }
    
#if DEBUG
    internal var testableViewSubgraph: DGSubgraphRef {
        viewSubgraph
    }
#endif
    
}

internal struct PlatformGestureInputs {
    
}
