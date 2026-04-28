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
internal final class PreferenceBridge {
    
    internal struct BridgedPreference {
        
        internal var key: AnyPreferenceKey.Type
        
        internal var combiner: DGWeakAttribute
        
    }
    
    internal unowned let viewGraph: ViewGraph

    internal var children: [Unmanaged<ViewGraph>]

    internal var requestedPreferences: PreferenceKeys

    internal var bridgedViewInputs: PropertyList

    @WeakAttribute
    internal var hostPreferenceKeys: PreferenceKeys?

    @WeakAttribute
    internal var hostPreferencesCombiner: PreferenceList?

    internal var bridgedPreferences: [BridgedPreference]
    
    internal init(viewGraph: ViewGraph) {
        self.viewGraph = viewGraph
        children = []
        requestedPreferences = PreferenceKeys()
        bridgedViewInputs = PropertyList()
        bridgedPreferences = []
    }
    
    internal func wrapInputs(inputs: inout _ViewInputs) {
        inputs.withMutableCustomInputs {
            $0 = bridgedViewInputs
        }
        
        inputs.preferences.merge(another: requestedPreferences)
        inputs.preferences.hostKeys = Attribute(MergePreferenceKeys(lhs: inputs.preferences.hostKeys, rhs: _hostPreferenceKeys))
    }
    
    internal func wrapOutputs(outputs: inout _ViewOutputs, inputs: _ViewInputs) {
        
        struct MakeCombiner: PreferenceKeyVisitor {
            
            internal var result: DGAttribute?
            
            @inline(__always)
            internal init() {
                
            }
            
            @inline(__always)
            internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
                result = Attribute(PreferenceCombiner<Key>(attributes: [])).identifier
            }
            
        }
        
        bridgedViewInputs = inputs.withCustomInputs({$0})
        
        for eachKey in inputs.preferences.keys {
            if eachKey == _AnyPreferenceKey<HostPreferencesKey>.self {
                let preferenceList = OptionalAttribute(outputs.hostPreferences)
                
                let combiner = Attribute(HostPreferencesCombiner(keys: inputs.preferences.hostKeys, values: preferenceList, children: []))
                
                outputs.hostPreferences = combiner
                $hostPreferenceKeys = inputs.preferences.hostKeys
                $hostPreferencesCombiner = combiner
                
            } else {
                guard !outputs.preferences.contains(eachKey) else {
                    continue
                }
                
                var visitor = MakeCombiner()
                
                eachKey.visitKey(&visitor)
                
                guard let combiner = visitor.result else {
                    continue
                }
                
                if !self.requestedPreferences.contains(eachKey) {
                    self.requestedPreferences.add(eachKey)
                }
                
                bridgedPreferences.append(BridgedPreference(key: eachKey, combiner: DGWeakAttribute(combiner)))
                
                outputs[eachKey] = combiner
            }
            
        }
    }
    
    internal func addValue(_ value: DGAttribute, for key: AnyPreferenceKey.Type) {
        guard let idx = bridgedPreferences.firstIndex(where: { element in
            element.key == key
        }) else {
            return
        }
        guard let combinerAttribute = bridgedPreferences[idx].combiner.attribute else {
            return
        }
        
        struct AddValue: PreferenceKeyVisitor {
            
            internal let combinerAttribute: DanceUIGraph.DGAttribute
            
            internal let value: DanceUIGraph.DGAttribute
            
            func visit<Key: PreferenceKey>(key: Key.Type) {
                combinerAttribute.mutateBody(as: PreferenceCombiner<Key>.self, invalidating: true) { combiner in
                    combiner.attributes.append(WeakAttribute(Attribute<Key.Value>(identifier: value)))
                }
            }
        }
        var visitor = AddValue(combinerAttribute: combinerAttribute,
                               value: value)
        key.visitKey(&visitor)
#if DEBUG || DANCE_UI_INHOUSE
        value.addRole(.bridgedPreference)
#endif // DEBUG || DANCE_UI_INHOUSE
        viewGraph.graphInvalidation(from: value)
    }
    
    internal func removeValue(_ value: DGAttribute, for key: AnyPreferenceKey.Type) {
        guard let idx = bridgedPreferences.firstIndex(where: { element in
            element.key == key
        }) else {
            return
        }
        guard let combinerAttribute = bridgedPreferences[idx].combiner.attribute else {
            return
        }
        
        struct RemoveValue: PreferenceKeyVisitor {
            
            internal let combinerAttribute: DanceUIGraph.DGAttribute
            
            internal let value: DanceUIGraph.DGAttribute
            
            internal var isRemoved: Bool = false
            
            internal mutating func visit<Key: PreferenceKey>(key: Key.Type) {
                combinerAttribute.mutateBody(as: PreferenceCombiner<Key>.self, invalidating: true) { combiner in
                    guard let index = combiner.attributes.firstIndex(where: { $0.base.attribute == value }) else {
                        return
                    }
                    combiner.attributes.remove(at: index)
                    self.isRemoved = true
                }
            }
        }
        var visitor = RemoveValue(combinerAttribute: combinerAttribute,
                                  value: value)
        key.visitKey(&visitor)
        
        guard visitor.isRemoved else {
            return
        }
        viewGraph.graphInvalidation(from: value)
    }
    
    internal func addHostValues(_ hostValues: Attribute<PreferenceList>,
                                for keys: Attribute<PreferenceKeys>) {
        guard let hostPreferencesCombiner = $hostPreferencesCombiner else {
            return
        }
        hostPreferencesCombiner.mutateBody(as: HostPreferencesCombiner.self, invalidating: true) { combiner in
#if DEBUG || DANCE_UI_INHOUSE
            keys.role = .bridgedPreference
            hostValues.role = .bridgedPreference
#endif
            let child = HostPreferencesCombiner.Child(keys: WeakAttribute(keys), values: WeakAttribute(hostValues))
            combiner.children.append(child)
        }
        viewGraph.graphInvalidation(from: keys.identifier)
    }
    
    internal func removeHostValues(for keys: Attribute<PreferenceKeys>, isInvalidating: Bool) {
        guard let hostPreferencesCombinerAttr = $hostPreferencesCombiner else {
            return
        }
        
        hostPreferencesCombinerAttr.mutateBody(as: HostPreferencesCombiner.self,
                                               invalidating: true) { combiner in
            if let index = combiner.children.firstIndex(where: { $0.$keys == keys }) {
                combiner.children.remove(at: index)
            }
        }
        viewGraph.graphInvalidation(from: isInvalidating ? nil : keys.identifier)
    }
    
    internal func addChild(viewGraph: ViewGraph) {
        guard children.firstIndex(where: { element in
            element.takeUnretainedValue() === viewGraph
        }) == nil else {
            return
        }
        children.append(.passUnretained(viewGraph))
    }
    
    internal func removeChild(viewGraph: ViewGraph) {
        guard let idx = children.firstIndex(where: { element in
            element.takeUnretainedValue() === viewGraph
        }) else {
            return
        }
        children.remove(at: idx)
    }
    
    internal func removeStateDidChange() {
        for child in children {
            let viewGraph: ViewGraph = child.takeUnretainedValue()
            viewGraph.updateRemovedState()
        }
    }
    
}

@available(iOS 13.0, *)
private struct MergePreferenceKeys: Rule {
    
    fileprivate typealias Value = PreferenceKeys
    
    @Attribute
    fileprivate var lhs: PreferenceKeys
    
    @WeakAttribute
    fileprivate var rhs: PreferenceKeys?
    
    @inline(__always)
    fileprivate init(lhs: Attribute<PreferenceKeys>, rhs: WeakAttribute<PreferenceKeys>) {
        self._lhs = lhs
        self._rhs = rhs
    }
    
    fileprivate var value: Value {
        guard let rhs else {
            return lhs
        }
        return lhs.merging(rhs)
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var preferenceBridge: PreferenceBridge? {
        get {
            self[PreferenceBridgeKey.self].value
        }
        set {
            self[PreferenceBridgeKey.self] = PreferenceBridgeKey.Value(value: newValue)
        }
    }
    
    private struct PreferenceBridgeKey: EnvironmentKey {
        
        internal static var defaultValue: Value {
            Value(value: nil)
        }
        
        internal struct Value {
            
            internal weak var value: PreferenceBridge?
            
            internal init(value: PreferenceBridge?) {
                self.value = value
            }
            
        }
    }
    
}

@available(iOS 13.0, *)
internal struct HostPreferencesCombiner: Rule {
    
    internal typealias Value = PreferenceList
    
    private struct CombineValues: PreferenceKeyVisitor {

        internal var children: [Child]

        /// Child outputs
        internal var values: PreferenceList

        internal mutating func visit<Key: PreferenceKey>(key: Key.Type) {
            guard !values.contains(key) else {
                // Return if parent outputs does not require the key.
                return
            }
            
            var hasNothingCombined = true
            var combinedValue = key.defaultValue
            var combinedSeed = VersionSeed(value: 0)
            
            for child in children {
                
                guard let keys = child.keys else {
                    return
                }
                guard !keys.contains(key) else {
                    continue
                }
                
                guard let values = child.values else {
                    return
                }
                guard let valueForKey = values.valueIfPresent(for: key) else {
                    continue
                }
                
                Key.reduce(value: &combinedValue) {
                    if let mergedSeed = valueForKey.seed.merge(combinedSeed) {
                        combinedSeed = mergedSeed
                    }
                    return valueForKey.value
                }
                
                hasNothingCombined = false
                
                break
            }

            guard !hasNothingCombined else {
                return
            }
            
            values[key] = PreferenceList.Value(value: combinedValue, seed: combinedSeed)
        }
    }

    internal struct Child {

        @WeakAttribute
        internal var keys: PreferenceKeys?

        @WeakAttribute
        internal var values: PreferenceList?

    }

    @Attribute
    internal var keys: PreferenceKeys

    @OptionalAttribute
    internal var values: PreferenceList?

    internal var children: [Child]
    
    internal var value: Value {
        var visitor = CombineValues(children: children,
                                    values: values ?? PreferenceList())
        let keys = keys
        
        for key in keys {
            key.visitKey(&visitor)
        }
        return visitor.values
    }

}
