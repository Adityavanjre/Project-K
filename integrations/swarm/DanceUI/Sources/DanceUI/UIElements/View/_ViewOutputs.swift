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

@available(iOS 13.0, *)
public struct _ViewOutputs {
    
    internal static let initialOutputs = _ViewOutputs()
    
    internal var preferences: PreferencesOutputs = .init()
    
    internal private(set) var layout: OptionalAttribute<LayoutComputer>
    
    @inline(__always)
    internal init() {
        preferences = .init()
        layout = .init()
    }
    
    @inline(__always)
    internal init(preferences: PreferencesOutputs) {
        self.preferences = preferences
        layout = .init()
    }
    
    @inline(__always)
    internal init(preferences: PreferencesOutputs,
                  layout: Attribute<LayoutComputer>?) {
        self.preferences = preferences
        self.layout = OptionalAttribute(layout)
    }
    
    @inline(__always)
    internal subscript<Key: PreferenceKey>(_ key: Key.Type) -> Attribute<Key.Value>? {
        get {
            preferences[key.self]
        }
        set {
            preferences[Key.self] = newValue
        }
    }
    
    @inline(__always)
    internal subscript(anyKey: AnyPreferenceKey.Type) -> DGAttribute? {
        get {
            preferences[anyKey]
        }
        
        set {
            preferences[anyKey] = newValue
        }
    }
    
    @inline(__always)
    internal mutating func setLayout(_ inputs: _ViewInputs, _ body: () -> (Attribute<LayoutComputer>)) {
        guard inputs.enableLayouts else {
            return
        }
        layout.attribute = body()
    }
    
    @inline(__always)
    internal mutating func overrideLayout(_ layout: OptionalAttribute<LayoutComputer>) {
        self.layout = layout
    }
    
    @inline(__always)
    internal mutating func resetLayout() {
        layout.attribute = nil
    }
    
    @inline(__always)
    internal mutating func appendPreference<Key: PreferenceKey>(_ key: Key.Type, value: Attribute<Key.Value>) {
        preferences.appendPreference(key, value: value)
    }
    
    internal func setIndirectDependency(_ attribute: DGAttribute?)  {
        preferences.setIndirectDependency(attribute)
        layout.attribute?.identifier.indirectDependency = attribute
    }
    
    @inline(__always)
    internal func attachIndirectOutputs(to indirectOutputs: _ViewOutputs) {
        if DanceUIFeature.gestureContainer.isEnable {
            preferences.attachIndirectOutputs(to: indirectOutputs.preferences)
            guard let layoutIdentifier = layout.attribute?.identifier,
                  let newLayoutIdentifier = indirectOutputs.layout.attribute?.identifier else {
                return
            }
            layoutIdentifier.source = newLayoutIdentifier
        } else {
            preferences.forEach { key, value in
                indirectOutputs.preferences.forEach { indirectOutputsKey, indirectOutputsValue in
                    if key == indirectOutputsKey {
                        value.source = indirectOutputsValue
                    }
                }
            }
            
            guard let layoutIdentifier = layout.attribute?.identifier,
                  let newLayoutIdentifier = indirectOutputs.layout.attribute?.identifier else {
                return
            }
            layoutIdentifier.source = newLayoutIdentifier
        }
    }
    
    fileprivate struct ResetPreference: PreferenceKeyVisitor {
        
        internal let dst: DGAttribute
        
        internal func visit<Key>(key: Key.Type) where Key : PreferenceKey {
            let graphHost: GraphHost = dst.graph.graphHost()
            let internAttribute = graphHost.intern(key.defaultValue, id: .zero)
            dst.source = internAttribute.identifier
        }
        
    }
    
    @inline(__always)
    internal func detachIndirectOutputs() {
        if DanceUIFeature.gestureContainer.isEnable {
            preferences.detachIndirectOutputs()
            if let layoutComputer = layout.projectedValue {
                // Apples sets .nil in iOS 18.5
                layoutComputer.identifier.source = layoutComputer.graph.viewGraph().$defaultLayoutComputer.identifier
            }
        } else {
            preferences.forEach { key, value in
                var visitor = ResetPreference(dst: value)
                key.visitKey(&visitor)
            }
            if let layoutComputer = layout.projectedValue {
                layoutComputer.identifier.source = layoutComputer.graph.viewGraph().$defaultLayoutComputer.identifier
            }
        }
    }
    
    @inline(__always)
    internal mutating func makePreferenceWriter<Key: PreferenceKey>(inputs: _ViewInputs, key: Key.Type, value: @autoclosure () -> Attribute<Key.Value>) {
        preferences.makePreferenceWriter(inputs: inputs.preferences, key: key, value: value())
    }
    
    @inline(__always)
    internal mutating func makePreferenceTransformer<Key: PreferenceKey>(inputs: _ViewInputs, key: Key.Type, transform: @autoclosure () -> Attribute<(inout Key.Value) -> Void>) {
        preferences.makePreferenceTransformer(inputs: inputs.preferences, key: key, transform: transform())
    }
    
}

@available(iOS 13.0, *)
internal struct PreferencesOutputs {
    
    private var preferences: [KeyValue] = []
    
    internal var debugProperties: _ViewDebug.Properties = .invalid
    
    @inlinable
    internal var isEmpty: Bool {
        preferences.isEmpty
    }
    
    @inlinable
    internal func forEach(_ body: (AnyPreferenceKey.Type, DGAttribute) -> Void) {
        for keyValue in preferences {
            body(keyValue.key, keyValue.value)
        }
    }
    
    @inlinable
    internal func contains(_ key: AnyPreferenceKey.Type) -> Bool {
        preferences.first { $0.key == key } != nil
    }
    
    @inlinable
    internal func contains<Key: PreferenceKey>(_ key: Key.Type) -> Bool {
        contains(_AnyPreferenceKey<Key>.self)
    }
    
    @inlinable
    internal subscript(anyKey: AnyPreferenceKey.Type) -> DGAttribute? {
        get {
            preferences.first { $0.key == anyKey }?.value
        }
        set {
            if anyKey == _AnyPreferenceKey<DisplayList.Key>.self && !debugProperties.contains(.displayList) {
                debugProperties.insert(.displayList)
            }
            if let index: Int = preferences.firstIndex(where: { $0.key == anyKey }) {
                if let value = newValue {
                    preferences[index].value = value
                } else {
                    preferences.remove(at: index)
                }
            } else {
                if let value = newValue {
                    preferences.append(KeyValue(key: anyKey, value: value))
                }
            }
        }
    }
    
    @inlinable
    internal subscript<Key: PreferenceKey>(_: Key.Type) -> Attribute<Key.Value>? {
        get {
            if let preference: KeyValue = preferences.first(where: { $0.key == _AnyPreferenceKey<Key>.self }) {
                return Attribute<Key.Value>(identifier: preference.value)
            } else {
                return nil
            }
        }
        set {
            self[_AnyPreferenceKey<Key>.self] = newValue?.identifier
        }
    }
    
    @inlinable
    internal mutating func appendPreference<Key: PreferenceKey>(_ key: Key.Type, value: Attribute<Key.Value>) {
        preferences.append(KeyValue(key: _AnyPreferenceKey<Key>.self, value: value.identifier))
    }
    
    @inlinable
    internal mutating func makePreferenceWriter<Key: PreferenceKey>(inputs: PreferencesInputs, key: Key.Type, value: @autoclosure () -> Attribute<Key.Value>) {
        
        if inputs.keys.contains(key) {
            self[key] = value()
        }
        
        guard Key._isReadableByHost, inputs.requiresHostPreferences else {
            return
        }
        
        let writerRule = HostPreferencesWriter<Key>(keyValue: value(),
                                                      keys: inputs.hostKeys,
                                                      childValues: OptionalAttribute(self[HostPreferencesKey.self]))
        
        self[HostPreferencesKey.self] = Attribute(writerRule)
    }
    
    internal mutating func makePreferenceTransformer<Key: PreferenceKey>(inputs: PreferencesInputs,
                                                                         key: Key.Type,
                                                                         transform: @autoclosure () -> Attribute<(inout Key.Value) -> Void>) {
        let transformVal = transform()
        if inputs.keys.contains(key) {
            let transformChild = OptionalAttribute(self[key])
            @Attribute(PreferenceTransform<Key>(transform: transformVal, child: transformChild))
            var preferenceTransform
            $preferenceTransform.flags = .removable
            self[key] = $preferenceTransform
        }
        
        guard Key._isReadableByHost, inputs.requiresHostPreferences else {
            return
        }
        
        let attribute = self[HostPreferencesKey.self]
        let childValues = OptionalAttribute<PreferenceList>(attribute)
        let nodeId = HostPreferencesKey.makeNodeId()
        let hostPreferencesTransform = HostPreferencesTransform<Key>(transform: transformVal,
                                                                     keys: inputs.hostKeys,
                                                                     childValues: childValues,
                                                                     keyRequested: false,
                                                                     wasEmpty: false,
                                                                     delta: 0,
                                                                     nodeId: nodeId)
        
        self[HostPreferencesKey.self] = Attribute(hostPreferencesTransform)
    }
    
    @inline(__always)
    internal func attachIndirectOutputs(to preferences: PreferencesOutputs) {
        self.forEach { key, value in
            preferences.forEach { anotherKey, anotherValue in
                if key == anotherKey {
                    value.source = anotherValue
                }
            }
        }
    }
    
    internal func setIndirectDependency(_ attribute: DGAttribute?) {
        assert(DanceUIFeature.gestureContainer.isEnable)
        for each in preferences {
            each.value.indirectDependency = attribute
        }
    }
    
    private struct ResetPreference: PreferenceKeyVisitor {
        
        fileprivate let dst: DGAttribute
        
        fileprivate func visit<Key>(key: Key.Type) where Key : PreferenceKey {
            let graphHost: GraphHost = dst.graph.graphHost()
            let internAttribute = graphHost.intern(key.defaultValue, id: .zero)
            dst.source = internAttribute.identifier
        }
        
    }
    
    internal func detachIndirectOutputs() {
        assert(DanceUIFeature.gestureContainer.isEnable)
        forEach { key, value in
            var visitor = ResetPreference(dst: value)
            key.visitKey(&visitor)
        }
    }
    
}

@available(iOS 13.0, *)
extension PreferencesOutputs {
    
    fileprivate struct KeyValue {
        
        internal var key: AnyPreferenceKey.Type
        
        internal var value: DGAttribute
    }
    
}

@available(iOS 13.0, *)
private struct HostPreferencesWriter<Key: PreferenceKey>: StatefulRule {
    
    fileprivate typealias Value = PreferenceList
    
    @Attribute
    fileprivate var keyValue: Key.Value
    
    @Attribute
    fileprivate var keys: PreferenceKeys
    
    @OptionalAttribute
    fileprivate var childValues: PreferenceList?
    
    fileprivate var keyRequested: Bool
    
    fileprivate var wasEmpty: Bool
    
    fileprivate var delta: UInt32
    
    fileprivate let nodeId: UInt32
    
    fileprivate mutating func setValue(_ value: Value) {
        self.value = value
    }
    
    fileprivate init(keyValue: Attribute<Key.Value>, keys: Attribute<PreferenceKeys>, childValues: OptionalAttribute<PreferenceList>) {
        _keyValue = keyValue
        _keys = keys
        _childValues = childValues
        self.keyRequested = false
        self.wasEmpty = false
        self.delta = 0
        self.nodeId = HostPreferencesKey.makeNodeId()
    }
    
    fileprivate mutating func updateValue() {
        var (preferenceList, preferenceListChanged) = (PreferenceList(), !self.wasEmpty) // OptionalAttribute 为空时的默认值
        if let childValuesAttr = $childValues {
            self.wasEmpty = false
            (preferenceList, preferenceListChanged) = childValuesAttr.changedValue()
        } else {
            self.wasEmpty = true
        }
        
        let (keysValue, keysChanged) = _keys.changedValue()
        guard keysChanged else {
            guard !keyRequested else {
                return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
            }
            
            if preferenceListChanged || !self.hasValue {
                setValue(preferenceList)
            }
            return
        }
        
        let containsKey = keysValue.contains(Key.self)
        guard self.keyRequested == containsKey else {
            self.keyRequested = containsKey
            if containsKey {
                return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
            } else {
                setValue(preferenceList)
                return
            }
        }
        
        guard containsKey else {
            if preferenceListChanged || !self.hasValue {
                setValue(preferenceList)
            }
            return
        }
        
        return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
    }
    
    @inline(__always)
    private mutating func _updateValue(preferenceList: PreferenceList, preferenceListChanged: Bool) {
        var preferenceList = preferenceList
        let (keyValue, keyValueChanged) = _keyValue.changedValue()
        guard keyValueChanged || preferenceListChanged else {
            if !self.hasValue {
                setValue(preferenceList)
            }
            return
        }
        
        var delta = self.delta
        if keyValueChanged {
            delta &+= 1
            self.delta = delta
        }
        
        let mergedValue = merge32(a: self.nodeId, b: delta)
        let transform = PreferenceList.Value(value: keyValue, seed: VersionSeed(value: mergedValue))
        preferenceList[Key.self] = transform
        setValue(preferenceList)
    }
}

@available(iOS 13.0, *)
private struct PreferenceTransform<Key: PreferenceKey>: StatefulRule, ObservationAttribute {
    
    @Attribute
    internal var transform: (inout Key.Value) -> Void

    @OptionalAttribute
    internal var childValue: Key.Value?
    
    fileprivate var previousObservationTrackings: [ObservationTracking]?
    
    fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    @inline(__always)
    fileprivate init(transform: Attribute<(inout Key.Value) -> Void>,
                     child: OptionalAttribute<Key.Value>) {
        _transform = transform
        _childValue = child
    }
    
    internal static var initialValue: Key.Value? {
        nil
    }

    internal mutating func updateValue() {
        var childValue = self.childValue ?? Key.defaultValue
        let (transform, isTransformChanged) = $transform.changedValue()
        
        withObservation(shouldCancelPrevious: isTransformChanged) {
            transform(&childValue)
        }
        
        value = childValue
    }
}

@available(iOS 13.0, *)
private struct HostPreferencesTransform<Key: PreferenceKey>: StatefulRule {

    @Attribute
    internal var transform: (inout Key.Value) -> Void

    @Attribute
    internal var keys: PreferenceKeys

    @OptionalAttribute
    internal var childValues: PreferenceList?

    internal var keyRequested: Bool

    internal var wasEmpty: Bool

    internal var delta: UInt32

    internal let nodeId: UInt32
    
    internal init(transform: Attribute<(inout Key.Value) -> Void>,
                  keys: Attribute<PreferenceKeys>,
                  childValues: OptionalAttribute<PreferenceList>,
                  keyRequested: Bool,
                  wasEmpty: Bool,
                  delta: UInt32,
                  nodeId: UInt32) {
        _transform = transform
        _keys = keys
        _childValues = childValues
        self.keyRequested = keyRequested
        self.wasEmpty = wasEmpty
        self.delta = delta
        self.nodeId = nodeId
    }
    
    internal static var initialValue: PreferenceList? {
        nil
    }
    
    internal mutating func updateValue() {
        var (preferenceList, preferenceListChanged) = (PreferenceList(), !self.wasEmpty)
        if let childValuesAttr = $childValues {
            self.wasEmpty = false
            (preferenceList, preferenceListChanged) = childValuesAttr.changedValue()
        } else {
            self.wasEmpty = true
        }
        
        let (keysValue, keysChanged) = _keys.changedValue()
        guard keysChanged else {
            guard !self.keyRequested else {
                return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
            }
            
            if preferenceListChanged || !self.hasValue {
                self.value = preferenceList
            }
            return
        }
        
        let containsKey = keysValue.contains(Key.self)
        guard self.keyRequested == containsKey else {
            self.keyRequested = containsKey
            if containsKey {
                return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
            } else {
                self.value = preferenceList
                return
            }
        }
        
        guard containsKey else {
            if preferenceListChanged || !self.hasValue {
                self.value = preferenceList
            }
            return
        }
        
        return _updateValue(preferenceList: preferenceList, preferenceListChanged: preferenceListChanged)
    }
    
    @inline(__always)
    private mutating func _updateValue(preferenceList: PreferenceList, preferenceListChanged: Bool) {
        var newPreferenceList = preferenceList
        let (transformValue, transformChanged) = _transform.changedValue()
        guard transformChanged || preferenceListChanged else {
            if !self.hasValue {
                self.value = newPreferenceList
            }
            return
        }
        
        var delta = self.delta
        if transformChanged {
            delta &+= 1
            self.delta = delta
        }
        let mergedValue = merge32(a: self.nodeId, b: delta)
        let newTransformValue: (inout Key.Value) -> Void = { value in
            transformValue(&value)
        }
        let transform = PreferenceList.Value(value: newTransformValue, seed: VersionSeed(value: mergedValue))
        newPreferenceList.modifyValue(for: Key.self, transform: transform)
        self.value = newPreferenceList
    }

}

@available(iOS 13.0, *)
internal struct SelectionBehaviorVisualStyleModifier: PrimitiveViewModifier, UnaryViewModifier {

    internal struct Transform: Rule {

        internal typealias Value = (inout PlatformItemList) -> Void

        @Attribute
        internal var modifier: SelectionBehaviorVisualStyleModifier
        
        internal var value: (inout PlatformItemList) -> Void {
            { _ in }
        }

    }
    
    typealias Body = Never
    
    internal let visualStyle: PlatformItemList.Item.SelectionBehavior.VisualStyle
    
    internal static func _makeView(modifier: _GraphValue<SelectionBehaviorVisualStyleModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        var outputs = body(_Graph(), inputs)
        
        guard inputs.preferences.keys.contains(_AnyPreferenceKey<PlatformItemList.Key>.self) else {
            return outputs
        }
        
        let transformAttr = Attribute(Transform(modifier: modifier.value))
        let child = OptionalAttribute(outputs[PlatformItemList.Key.self])
        
        let platformItemList = PreferenceTransform<PlatformItemList.Key>(transform: transformAttr, child: child)
        let platformItemListAttr = Attribute(platformItemList)
        outputs[PlatformItemList.Key.self] = platformItemListAttr
        return outputs
    }

}

@available(iOS 13.0, *)
internal struct MergePlatformItemsModifier : PrimitiveViewModifier, UnaryViewModifier {
        
    internal static func _makeView(modifier: _GraphValue<MergePlatformItemsModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var outputs = body(_Graph(), inputs)
        if inputs.preferences.requiresPlatformItemList {
            let transform = Attribute(Transform(modifier: modifier.value))
            let preferenceTransform = PreferenceTransform<PlatformItemList.Key>(transform: transform, child: OptionalAttribute(outputs[PlatformItemList.Key.self]))
            outputs.platformItemList = Attribute(preferenceTransform)
        }
        return outputs
    }

    internal struct Transform : Rule {

        internal typealias Value = (inout PlatformItemList) -> Void
        
        @Attribute
        internal var modifier: MergePlatformItemsModifier
        
        internal var value: (inout PlatformItemList) -> Void {
            return { platformItemList in
                var item = PlatformItemList.Item(text: nil, image: nil, selectionBehavior: nil, accessibility: nil)
                platformItemList.items.forEach { platformItemListItem in
                    if item.text == nil {
                        item.text = platformItemListItem.text
                    }
                    if item.resolvedImage?.label == nil {
                        item.resolvedImage = platformItemListItem.resolvedImage
                    }
                    if item.accessibility == nil {
                        item.accessibility = platformItemListItem.accessibility
                    }
                    if item.children == nil {
                        item.children = platformItemListItem.children
                    }
                    if item.systemItem == nil {
                        item.systemItem = platformItemListItem.systemItem
                    }
                }
                platformItemList = PlatformItemList(items: [item])
            }
        }
    }
}
