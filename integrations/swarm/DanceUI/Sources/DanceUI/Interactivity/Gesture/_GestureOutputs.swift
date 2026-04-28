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
public struct _GestureOutputs<A> {
    
    internal var phase: Attribute<GesturePhase<A>>
    
    @OptionalAttribute
    internal var debugData: GestureDebug.Data?

    internal var preferences: PreferencesOutputs
    
    private var legacyPreferences: LegacyPreferences

    private struct LegacyPreferences {

        fileprivate var gestureRecognitionWitness: OptionalAttribute<GestureRecognitionWitness>
        
        fileprivate var platformGestureRecognizerList: OptionalAttribute<PlatformGestureRecognizerList>
        
        fileprivate var activeGestureRecognizerObservers: OptionalAttribute<[AnyUIGestureRecognizerObserver]>
        
        fileprivate init() {
            gestureRecognitionWitness = OptionalAttribute()
            platformGestureRecognizerList = OptionalAttribute()
            activeGestureRecognizerObservers = OptionalAttribute()
        }
        
    }
    
    private var _gestureRecognitionWitness: OptionalAttribute<GestureRecognitionWitness> {
        get {
            if DanceUIFeature.gestureContainer.isEnable {
                // Shall not work when gesture container is enabled
                return OptionalAttribute()
            } else {
                return legacyPreferences.gestureRecognitionWitness
            }
        }
        set {
            if DanceUIFeature.gestureContainer.isEnable {
                // Shall not work when gesture container is enabled
            } else {
                legacyPreferences.gestureRecognitionWitness = newValue
            }
        }
    }
    
    private var _platformGestureRecognizerList: OptionalAttribute<PlatformGestureRecognizerList> {
        get {
            if DanceUIFeature.gestureContainer.isEnable {
                // Shall not work when gesture container is enabled
                return OptionalAttribute()
            } else {
                return legacyPreferences.platformGestureRecognizerList
            }
        }
        set {
            if DanceUIFeature.gestureContainer.isEnable {
                // Shall not work when gesture container is enabled
            } else {
                legacyPreferences.platformGestureRecognizerList = newValue
            }
        }
    }
    
    private var _activeGestureRecognizerObservers: OptionalAttribute<[AnyUIGestureRecognizerObserver]> {
        get {
            if DanceUIFeature.gestureContainer.isEnable {
                return preferences.activeGestureRecognizerObservers
            } else {
                return legacyPreferences.activeGestureRecognizerObservers
            }
        }
        set {
            if DanceUIFeature.gestureContainer.isEnable {
                preferences.activeGestureRecognizerObservers = newValue
            } else {
                legacyPreferences.activeGestureRecognizerObservers = newValue
            }
        }
    }
    
    @inline(__always)
    internal var gestureRecognitionWitness: Attribute<GestureRecognitionWitness>? {
        _gestureRecognitionWitness.attribute
    }
    
    @inline(__always)
    internal var platformGestureRecognizerList: Attribute<PlatformGestureRecognizerList>? {
        _platformGestureRecognizerList.attribute
    }
    
    @inline(__always)
    internal var activeGestureRecognizerObservers: Attribute<[AnyUIGestureRecognizerObserver]>? {
        _activeGestureRecognizerObservers.attribute
    }
    
    internal init(inputs: _GestureInputs) {
        self.phase = GraphHost.currentHost.intern(GesturePhase<A>.failed, id: 0)
        self._debugData = OptionalAttribute()
        self.preferences = PreferencesOutputs()
        self.legacyPreferences = LegacyPreferences()
    }
    
    /// Instantiates a `_GestureOutputs`
    ///
    /// - Note: Keeping DanceUI extension attributes optional and assembling
    /// a `_GestureOutputs` with dot-syntax builder pattern makes compilation
    /// condition separation easier.
    @inline(__always)
    private init(phase: Attribute<GesturePhase<A>>) {
        self.phase = phase
        self._debugData = .init()
        self.preferences = PreferencesOutputs()
        self.legacyPreferences = LegacyPreferences()
    }

    @inline(__always)
    internal init(phase: Attribute<GesturePhase<A>>, preferences: PreferencesOutputs) {
        self.phase = phase
        self._debugData = .init()
        self.preferences = preferences
        self.legacyPreferences = LegacyPreferences()
    }
    
    internal func setIndirectDependency(_ attribute: DGAttribute?) {
        if DanceUIFeature.gestureContainer.isEnable {
            phase.identifier.indirectDependency = attribute
            preferences.setIndirectDependency(attribute)
        } else {
            phase.identifier.indirectDependency = attribute

            gestureRecognitionWitness?.identifier.indirectDependency = attribute
            platformGestureRecognizerList?.identifier.indirectDependency = attribute
            activeGestureRecognizerObservers?.identifier.indirectDependency = attribute
        }
    }
    
    internal func detachIndirectOutputs() {
        if DanceUIFeature.gestureContainer.isEnable {
            let phase = GraphHost.currentHost.intern(GesturePhase<A>.defaultValue, id: _GraphInputs.ConstantID())
            self.phase.identifier.source = phase.identifier
            preferences.detachIndirectOutputs()
        } else {
            @inline(__always)
            func detachOptionalIndirect<Value>(keyPath: KeyPath<_GestureOutputs, Attribute<Value>?>, value: Value) {
                if let dest = self[keyPath: keyPath]?.identifier {
                    dest.source = GraphHost.currentHost.intern(value, id: _GraphInputs.ConstantID()).identifier
                }
            }

            @inline(__always)
            func detachOptionalIndirect<Value: Defaultable>(keyPath: KeyPath<_GestureOutputs, Attribute<Value>?>) where Value.Value == Value {
                detachOptionalIndirect(keyPath: keyPath, value: Value.defaultValue)
            }
            
            let phase = GraphHost.currentHost.intern(GesturePhase<A>.defaultValue, id: _GraphInputs.ConstantID())
            self.phase.identifier.source = phase.identifier

            detachOptionalIndirect(keyPath: \.gestureRecognitionWitness)
            detachOptionalIndirect(keyPath: \.platformGestureRecognizerList)
            detachOptionalIndirect(keyPath: \.activeGestureRecognizerObservers, value: [])
        }
    }
    
    internal func attachIndirectOutputs(_ gesture: _GestureOutputs<A>) {
        if DanceUIFeature.gestureContainer.isEnable {
            phase.identifier.source = gesture.phase.identifier
            preferences.attachIndirectOutputs(to: gesture.preferences)
        } else {
            @inline(__always)
            func attachOptionalIndirect<Value>(keyPath: KeyPath<_GestureOutputs, Attribute<Value>?>) {
                if let src = gesture[keyPath: keyPath]?.identifier {
                    self[keyPath: keyPath]?.identifier.source = src
                }
            }
            
            phase.identifier.source = gesture.phase.identifier

            attachOptionalIndirect(keyPath: \.gestureRecognitionWitness)
            attachOptionalIndirect(keyPath: \.platformGestureRecognizerList)
            attachOptionalIndirect(keyPath: \.activeGestureRecognizerObservers)
        }
    }
    
    /// Makes a gesture outputs with given phase. No other optional outputs.
    @inline(__always)
    internal static func make(phase: Attribute<GesturePhase<A>>) -> _GestureOutputs {
        _GestureOutputs(phase: phase)
    }
    
    @inline(__always)
    internal func withPhase<T>(_ phase: Attribute<GesturePhase<T>>) -> _GestureOutputs<T> {
        var casted = _GestureOutputs<T>(phase: phase)
        if DanceUIFeature.gestureContainer.isEnable {
            casted.preferences = self.preferences
            return casted
        } else {
            return casted
                .withGestureRecognitionWitness(_gestureRecognitionWitness.attribute)
                .withPlatformGestureRecognizerList(_platformGestureRecognizerList.attribute)
                .withActiveGestureRecognizerObservers(_activeGestureRecognizerObservers.attribute)
        }
    }
    
    @inline(__always)
    internal func withGestureRecognitionWitness(_ attribute: Attribute<GestureRecognitionWitness>?) -> _GestureOutputs {
        var result = self
        result._gestureRecognitionWitness.projectedValue = attribute
        return result
    }
    
    @inline(__always)
    internal func withPlatformGestureRecognizerList(_ attribute: Attribute<PlatformGestureRecognizerList>?) -> _GestureOutputs {
        var result = self
        result._platformGestureRecognizerList.projectedValue = attribute
        return result
    }
    
    @inline(__always)
    internal func withActiveGestureRecognizerObservers(_ attribute: Attribute<[AnyUIGestureRecognizerObserver]>?) -> _GestureOutputs {
        var result = self
        result._activeGestureRecognizerObservers.projectedValue = attribute
        return result
    }
    
    internal func overrideDefaultValues(_ childOutputs: _GestureOutputs<A>) {
        phase.overrideDefaultValue(childOutputs.phase, type: GesturePhase<A>.self)
#if DEBUG || DANCE_UI_INHOUSE
        if let debugData = $debugData, let childDebugData = childOutputs.$debugData {
            debugData.overrideDefaultValue(childDebugData, type: GestureDebug.Data.self)
        }
#endif
        preferences.attachIndirectOutputs(to: childOutputs.preferences)
    }
}

@available(iOS 13.0, *)
extension _GestureOutputs {
    
    internal mutating func wrapDebugOutputs<A1>(_: A1.Type, properties: Attribute<ArrayWith2Inline<(String, String)>>?, inputs: _GestureInputs) {
#if DEBUG || DANCE_UI_INHOUSE
        if inputs.includeDebugOutput {
            let wrappedPhase = phase
            let wrappingPhase = DebugPrintGesturePhase(gestureType: A1.self, gesturePhase: wrappedPhase).makeAttribute()
            wrappingPhase.addInput(wrappedPhase, options: .sentinel, token: 0)
            phase = wrappingPhase
        }
#endif
    }
    
    internal mutating func wrapDebugOutputs<WrapperType, PhaseValue1, PhaseValue2>(_: WrapperType.Type, kind: GestureDebug.Kind, properties: Attribute<ArrayWith2Inline<(String, String)>>?, inputs: _GestureInputs, combiningOutputs: (_GestureOutputs<PhaseValue1>, _GestureOutputs<PhaseValue2>)) {
#if DEBUG || DANCE_UI_INHOUSE
        if inputs.includeDebugOutput {
            let wrappedPhase = phase
            let wrappingPhase = DebugPrintGesturePhase(gestureType: WrapperType.self, gesturePhase: wrappedPhase).makeAttribute()
            wrappingPhase.addInput(wrappedPhase, options: .sentinel, token: 0)
            phase = wrappingPhase
        }
#endif
    }
}

/// Add the input excplicitly.
@available(iOS 13.0, *)
internal struct DebugPrintGesturePhase<Value>: Rule {
    
    @Attribute
    internal var gesturePhase: GesturePhase<Value>
    
    internal let gestureType: Any.Type
    
    internal init(gestureType: Any.Type, gesturePhase: Attribute<GesturePhase<Value>>) {
        self._gesturePhase = gesturePhase
        self.gestureType = gestureType
    }
    
    internal var value: GesturePhase<Value> {
        DGGraphRef.withoutUpdate {
            let phase = gesturePhase
            print("[DEBUG] [\(_typeName(gestureType, qualified: false))] $gesturePhase = \($gesturePhase); gesturePhase = \(phase)")
            return phase
        }
    }
    
}

@available(iOS 13.0, *)
extension PreferencesOutputs {
    
    fileprivate var activeGestureRecognizerObservers: OptionalAttribute<[AnyUIGestureRecognizerObserver]> {
        get {
            OptionalAttribute(self[AnyUIGestureRecognizerObserversKey.self])
        }
        set {
            self[AnyUIGestureRecognizerObserversKey.self] = newValue.attribute
        }
    }
    
}

@available(iOS 13.0, *)
private struct AnyUIGestureRecognizerObserversKey: PreferenceKey {
    
    static var defaultValue: [AnyUIGestureRecognizerObserver] {
        []
    }
    
    static func reduce(value: inout [AnyUIGestureRecognizerObserver], nextValue: () -> [AnyUIGestureRecognizerObserver]) {
        value.append(contentsOf: nextValue())
    }
    
    typealias Value = [AnyUIGestureRecognizerObserver]
    
}

// Currently are placeholders
internal enum GestureDebug {
    internal struct Data {
    }
    internal struct Kind {
    }
}

extension GestureDebug.Data: Defaultable {
    internal static let defaultValue: GestureDebug.Data = .init()
}
