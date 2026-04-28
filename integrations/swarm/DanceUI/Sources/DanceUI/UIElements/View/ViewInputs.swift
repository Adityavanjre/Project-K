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
public struct _GraphInputs {
    
    internal var customInputs: PropertyList
    
    internal var time: Attribute<Time>
    
    fileprivate var cachedEnvironment: MutableBox<CachedEnvironment>
    
    internal var phase: Attribute<Phase> {
        didSet {
            changedDebugProperties.insert(.phase)
        }
    }
    
    internal var transaction: Attribute<Transaction>
    
    internal var changedDebugProperties: _ViewDebug.Properties
    
    internal var options: Options
    
    fileprivate var mergedInputs: Set<DGAttribute>
    
    
    internal static var invalid: _GraphInputs {
        _GraphInputs(time: .init(identifier: .nil),
                     environment: .init(identifier: .nil),
                     phase: .init(identifier: .nil),
                     transaction: .init(identifier: .nil))
    }
        
    @inline(__always)
    internal init(_ customInputs: PropertyList = PropertyList(),
                  time: Attribute<Time>,
                  environment: Attribute<EnvironmentValues>,
                  phase: Attribute<Phase>,
                  transaction: Attribute<Transaction>,
                  changedDebugProperties: _ViewDebug.Properties = .all,
                  options: Options = Options(),
                  mergedInputs: Set<DGAttribute> = Set()) {
        self.customInputs = customInputs
        self.time = time
        self.cachedEnvironment = MutableBox(CachedEnvironment(environment))
        self.phase = phase
        self.transaction = transaction
        self.changedDebugProperties = changedDebugProperties
        self.options = options
        self.mergedInputs = mergedInputs
    }
    
    @inline(__always)
    internal init(_ inputs: _GraphInputs) {
        self.customInputs = inputs.customInputs
        self.time = inputs.time
        self.cachedEnvironment = inputs.cachedEnvironment
        self.phase = inputs.phase
        self.transaction = inputs.transaction
        self.changedDebugProperties = .init()
        self.options = inputs.options
        self.mergedInputs = inputs.mergedInputs
    }
    
    @inline(__always)
    internal init(deepCopy inputs: _GraphInputs) {
        self.customInputs = inputs.customInputs
        self.time = inputs.time
        self.cachedEnvironment = MutableBox(inputs.cachedEnvironment.value)
        self.phase = inputs.phase
        self.transaction = inputs.transaction
        self.changedDebugProperties = inputs.changedDebugProperties
        self.options = inputs.options
        self.mergedInputs = inputs.mergedInputs
    }
    
    
    @inline(__always)
    internal mutating func withMutableCustomInputs<R>(_ body: (_: inout PropertyList) -> R) -> R {
        body(&customInputs)
    }
    
    @inline(__always)
    internal func withCustomInputs<R>(_ body: (_: PropertyList) -> R) -> R {
        body(customInputs)
    }
    
    
    @inline(__always)
    internal var environment: Attribute<EnvironmentValues> {
        cachedEnvironment.value.environment
    }
    
    @inline(__always)
    internal mutating func updateCachedEnvironment(_ box: MutableBox<CachedEnvironment>) {
        cachedEnvironment = box
        changedDebugProperties.insert(.environment)
    }
    
    @inline(__always)
    internal mutating func updateCachedEnvironment(attribute: Attribute<EnvironmentValues>) {
        cachedEnvironment.value.environment = attribute
        changedDebugProperties.insert(.environment)
    }
    
    @inline(__always)
    internal mutating func intern<ValueType>(_ inputs: ValueType, id: ConstantID) -> Attribute<ValueType> {
        cachedEnvironment.value.intern(inputs, id: id)
    }
    
    
    internal struct Options: OptionSet, ExpressibleByArrayLiteral {
        
        internal static let disableAnimations = Options(rawValue: 0x1)
        
        internal static let enableLayouts = Options(rawValue: 0x2)
        
        internal static let hasMajorAxis = Options(rawValue: 0x4)
        
        internal static let horizontalAxis = Options(rawValue: 0x8)
        
        internal static let accessibilityTransform = Options(rawValue: 0x10)
        
        internal static let reposition = Options(rawValue: 0x20)
        
        internal static let flag0x40 = Options(rawValue: 0x40)
        
        internal static let flag0x80 = Options(rawValue: 0x80)
        
        internal static var isRecognizingPlatformViewGesture: Options {
            Options(rawValue: 0x100)
        }
        
        internal let rawValue: UInt32
        
    }
    
    @inline(__always)
    internal var disableAnimations: Bool {
        get {
            options.contains(.disableAnimations)
        }
        set {
            guard newValue else {
                options.remove(.disableAnimations)
                return
            }
            options.insert(.disableAnimations)
        }
    }
    
    @inline(__always)
    internal var enableLayouts: Bool {
        get {
            options.contains(.enableLayouts)
        }
        set {
            guard newValue else {
                options.remove(.enableLayouts)
                return
            }
            options.insert(.enableLayouts)
        }
    }
    
    @inline(__always)
    internal var hasMajorAxis: Bool {
        get {
            options.contains(.hasMajorAxis)
        }
        set {
            guard newValue else {
                options.remove(.hasMajorAxis)
                return
            }
            options.insert(.hasMajorAxis)
        }
    }
    
    @inline(__always)
    internal var majorAxis: Axis {
        get {
            options.contains(.horizontalAxis) ? .horizontal : .vertical
        }
        set {
            guard newValue == .horizontal else {
                options.remove(.horizontalAxis)
                return
            }
            options.insert(.horizontalAxis)
        }
    }
    
    @inline(__always)
    internal var enableAccessibilityTransform: Bool {
        get {
            options.contains(.accessibilityTransform)
        }
        set {
            if newValue {
                options.insert(.accessibilityTransform)
            } else {
                options.remove(.accessibilityTransform)
            }
        }
    }
    
    @inline(__always)
    internal var reposition: Bool {
        get {
            options.contains(.reposition)
        }
        set {
            if newValue {
                options.insert(.reposition)
            } else {
                options.remove(.reposition)
            }
        }
    }
    
    @inline(__always)
    internal var enableFlag0x40: Bool {
        get {
            options.contains(.flag0x40)
        }
        set {
            if newValue {
                options.insert(.flag0x40)
            } else {
                options.remove(.flag0x40)
            }
        }
    }
    
    
    @inline(__always)
    internal var enableFlag0x80: Bool {
        get {
            options.contains(.flag0x80)
        }
        set {
            if newValue {
                options.insert(.flag0x80)
            } else {
                options.remove(.flag0x80)
            }
        }
    }
    
    @inline(__always)
    internal var isRecognizingPlatformViewGesture: Bool {
        get {
            options.contains(.isRecognizingPlatformViewGesture)
        }
        set {
            if newValue {
                options.insert(.isRecognizingPlatformViewGesture)
            } else {
                options.remove(.isRecognizingPlatformViewGesture)
            }
        }
    }
    
    @inline(__always)
    internal var styleContextType: AnyStyleContextType {
        get {
            self[StyleContextInput.self]
        }
        
        set {
            self[StyleContextInput.self] = newValue
        }
    }
    
    
    @inline(__always)
    internal subscript<A: GraphInput>(_ valueType: A.Type) -> A.Value {
        get {
            customInputs[valueType]
        }
        set {
            customInputs[valueType] = newValue
        }
    }
    
    @inline(__always)
    internal mutating func append<InputKey, Value>(value: Value, for valueType: InputKey.Type) where InputKey: GraphInput, InputKey.Value == [Value] {
        self[valueType].append(value)
    }
    
    @inline(__always)
    internal mutating func popLast<InputKey, Value> (for valueType: InputKey.Type) -> Value? where InputKey: GraphInput, InputKey.Value == [Value] {
        self[valueType].popLast()
    }
    
    
    internal mutating func merge(inputs: _GraphInputs, ignoringPhase: Bool) {
        self.customInputs.merge(inputs.customInputs)
        var mergedInputs = self.mergedInputs
        _GraphInputs.merge(attribute: self.environment, mergedAttribute: inputs.environment, mergedInputs: &mergedInputs) {
            let mergedEnvionment = MergedEnvironment(lhs: WeakAttribute(inputs.environment), rhs: self.environment)
            self.updateCachedEnvironment(MutableBox(CachedEnvironment(Attribute(mergedEnvionment))))
        }
        
        _GraphInputs.merge(attribute: self.transaction, mergedAttribute: inputs.transaction, mergedInputs: &mergedInputs) {
            self.transaction = Attribute(MergedTransaction(lhs: WeakAttribute(inputs.transaction), rhs: self.transaction))
        }
        
        if !ignoringPhase {
            _GraphInputs.merge(attribute: self.phase, mergedAttribute: inputs.phase, mergedInputs: &mergedInputs) {
                self.phase = Attribute(MergedPhase(lhs: WeakAttribute(inputs.phase), rhs: self.phase))
            }
        }
        mergedInputs.formUnion(inputs.mergedInputs)
        self.mergedInputs = mergedInputs
        if inputs.disableAnimations {
            self.disableAnimations = true
        }
    }
    
    @_transparent
    fileprivate static func merge<Value>(attribute: Attribute<Value>, mergedAttribute: Attribute<Value>, mergedInputs: inout Set<DGAttribute>, body: () -> Void) {
        guard attribute.identifier != mergedAttribute.identifier else {
            return
        }
        let result = mergedInputs.insert(mergedAttribute.identifier)
        guard result.inserted else {
            return
        }
        body()
    }
    
    @_transparent
    internal mutating func merge<Value>(attribute: Attribute<Value>, mergedAttribute: Attribute<Value>, body: () -> Void) {
        _GraphInputs.merge(attribute: attribute,
                           mergedAttribute: mergedAttribute,
                           mergedInputs: &self.mergedInputs,
                           body: body)
    }
    
    
    internal func tryToReuse(by inputs: _GraphInputs, indirectMap: _ViewList_IndirectMap, testOnly: Bool) -> Bool {
        
        guard time.tryToReuse(by: inputs.time, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        guard phase.tryToReuse(by: inputs.phase, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        guard cachedEnvironment.value.environment.tryToReuse(by: inputs.environment, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        guard transaction.tryToReuse(by: inputs.transaction, indirectMap: indirectMap, testOnly: testOnly) else {
            return false
        }
        return !customInputs.mayNotBeEqual(to: inputs.customInputs)
    }
    
    internal mutating func makeReusable(indirectMap: _ViewList_IndirectMap?) {
        
        guard let map = indirectMap else {
            return
        }
        
        time.makeReusable(indirectMap: map)
        phase.makeReusable(indirectMap: map)
        
        updateCachedEnvironment(MutableBox(CachedEnvironment(environment)))
        cachedEnvironment.value.environment.makeReusable(indirectMap: map)
        
        transaction.makeReusable(indirectMap: map)
    }
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    @inline(__always)
    internal var focusStore: OptionalAttribute<FocusStore> {
        get {
            self[FocusStoreInputKey.self]
        }
        set {
            self[FocusStoreInputKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    @inline(__always)
    internal var focusedItem: OptionalAttribute<FocusItem?> {
        get { self[FocusedItemInputKey.self] }
        set { self[FocusedItemInputKey.self] = newValue }
    }
    
}

@available(iOS 13.0, *)
extension _GraphInputs {
    
    public struct Phase: Equatable {
        
        @usableFromInline
        internal var value: UInt32
        
        @usableFromInline
        internal init(seed: UInt32 = 0,
                      invisible: Bool = false) {
            value = 0
            self.seed = seed
            self.invisible = invisible
        }
        
        @usableFromInline
        internal var seed: UInt32 {
            get {
                value >> 0x1
            }
            set {
                let oldVisible = invisible
                value = (newValue << 0x1) | (oldVisible ? 0x1 : 0x0)
            }
        }
        
        @usableFromInline
        internal var invisible: Bool {
            get {
                value & 0x1 != 0x0
            }
            set {
                value &= ~(0x1)
                value |= newValue ? 0x1 : 0x0
            }
        }
        
        @inline(__always)
        internal func merge(rhs: Self) -> Self {
            Phase(seed: seed &+ rhs.seed, invisible: invisible || rhs.invisible)
        }
    }
    
    internal typealias ConstantID = Int
    
    fileprivate struct SavedTransactionKey: PropertyKey {
        
        fileprivate typealias Value = [SavedTransaction]
        
        @inline(__always)
        fileprivate static var defaultValue: [SavedTransaction]  { [] }
    }
    
    internal mutating func pushTransaction(_ affectsGeometry: Bool) {
        var savedTranscations = customInputs[SavedTransactionKey.self]
        savedTranscations.append(SavedTransaction(transaction: _GraphValue(transaction), affectsGeometry: affectsGeometry))
        
        customInputs[SavedTransactionKey.self] = savedTranscations
    }
    
    internal mutating func popTransaction() {
        let savedTranscations = customInputs[SavedTransactionKey.self]
        _danceuiPrecondition(!savedTranscations.isEmpty)
        let last = savedTranscations[(savedTranscations.count - 1)]
        self.transaction = last.transaction.value
        customInputs[SavedTransactionKey.self] = savedTranscations.dropLast(1)
    }
}

@available(iOS 13.0, *)
extension _GraphInputs.ConstantID {
    
    internal var internedID: _GraphInputs.ConstantID {
        return self & 0b1
    }
    
}

@available(iOS 13.0, *)
private struct SavedTransaction {
    internal var transaction: _GraphValue<Transaction>
    
    internal var affectsGeometry: Bool
}

@available(iOS 13.0, *)
public struct _ViewInputs {
    
    internal fileprivate(set) var base: _GraphInputs
    
    internal var preferences: PreferencesInputs
    
    internal var transform: Attribute<ViewTransform> {
        didSet {
            base.changedDebugProperties.insert(.transform)
        }
    }
    
    internal var position: Attribute<ViewOrigin> {
        didSet {
            base.changedDebugProperties.insert(.position)
        }
    }
    
    internal var containerPosition: Attribute<ViewOrigin>
    
    internal var size: Attribute<ViewSize> {
        didSet {
            base.changedDebugProperties.insert(.size)
        }
    }
    
    internal var safeAreaInsets: OptionalAttribute<SafeAreaInsets>
    
    internal var scrollableContainerSize: OptionalAttribute<ViewSize>
    
    
    @inline(__always)
    internal var time: Attribute<Time> {
        get {
            base.time
        }
        set {
            base.time = newValue
        }
    }
    
    
    @inline(__always)
    private var cachedEnvironment: CachedEnvironment {
        get {
            base.cachedEnvironment.value
        }
        nonmutating set {
            base.cachedEnvironment.value = newValue
        }
    }
    
    @inline(__always)
    internal func resolvedForegroundStyle(role: ShapeRole,
                                          mode: Attribute<ShapeStyle_ResolverMode>?) -> Attribute<_ShapeStyle_Shape.ResolvedStyle> {
        cachedEnvironment.resolvedForegroundStyle(for: self, role: role, mode: mode)
    }
    
    @inline(__always)
    internal mutating func updateCachedEnvironment(_ box: MutableBox<CachedEnvironment>) {
        base.updateCachedEnvironment(box)
    }
    
    @inline(__always)
    internal mutating func updateCachedEnvironment(attribute: Attribute<EnvironmentValues>) {
        updateCachedEnvironment(MutableBox<CachedEnvironment>(CachedEnvironment(attribute)))
    }
    
    @inline(__always)
    internal var environment: Attribute<EnvironmentValues> {
        cachedEnvironment.environment
    }
    
    @inline(__always)
    internal func environmentAttribute<Value>(keyPath: KeyPath<EnvironmentValues, Value>) -> Attribute<Value> {
        cachedEnvironment.attribute(keyPath: keyPath)
    }
    
    @inline(__always)
    internal var animatedPosition: Attribute<ViewOrigin> {
        cachedEnvironment.animatedPosition(for: self)
    }
    
    @inline(__always)
    internal var animatedSize: Attribute<ViewSize> {
        cachedEnvironment.animatedSize(for: self)
    }
    
    @inline(__always)
    internal var phase: Attribute<_GraphInputs.Phase> {
        get {
            base.phase
        }
        set {
            base.phase = newValue
        }
    }
    
    @inline(__always)
    internal var transaction: Attribute<Transaction> {
        get {
            base.transaction
        }
        set {
            base.transaction = newValue
        }
    }
    
    @inline(__always)
    internal var disableAnimations: Bool {
        get {
            base.disableAnimations
        }
        set {
            base.disableAnimations = newValue
        }
    }
    
    @inline(__always)
    internal var enableLayouts: Bool {
        get {
            base.enableLayouts
        }
        set {
            base.enableLayouts = newValue
        }
    }
    
    @inline(__always)
    internal var hasMajorAxis: Bool {
        get {
            base.hasMajorAxis
        }
        set {
            base.hasMajorAxis = newValue
        }
    }
    
    @inline(__always)
    internal var majorAxis: Axis {
        get {
            base.majorAxis
        }
        set {
            base.majorAxis = newValue
        }
    }
    
    @inline(__always)
    internal var enableAccessibilityTransform: Bool {
        get {
            base.enableAccessibilityTransform
        }
        set {
            base.enableAccessibilityTransform = newValue
        }
    }
    
    @inline(__always)
    internal var needReposition: Bool {
        get {
            base.reposition
        }
        set {
            base.reposition = newValue
        }
    }
    
    @inline(__always)
    internal var enableFlag0x40: Bool {
        get {
            base.enableFlag0x40
        }
        set {
            base.enableFlag0x40 = newValue
        }
    }
    
    @inline(__always)
    internal var enableFlag0x80: Bool {
        get {
            base.enableFlag0x80
        }
        set {
            base.enableFlag0x80 = newValue
        }
    }
    
    @inline(__always)
    internal var isRecognizingPlatformViewGesture: Bool {
        get {
            base.isRecognizingPlatformViewGesture
        }
        set {
            base.isRecognizingPlatformViewGesture = newValue
        }
    }
    
    internal var withoutGeometryDependencies : _ViewInputs {
        var inputs = self
        inputs.position = ViewGraph.current.$zeroPoint
        inputs.transform = inputs.cachedEnvironment.intern(ViewTransform(), id: 0)
        inputs.size = Attribute(value: .zero)
        inputs.enableLayouts = false
        return inputs
    }
    
    internal var implicitRootBodyInputs: _ViewListInputs {
        var options = self.viewListOptions
        if !options.contains(.requiresDepthAndSections) {
            options.insert(.requiresDepthAndSections)
        }
        return _ViewListInputs(base: self.base, implicitID: 0, options: options, traitKeys: .init())
    }
    
    @inline(__always)
    internal init(base: _GraphInputs,
                  preferences: PreferencesInputs,
                  transform: Attribute<ViewTransform>,
                  position: Attribute<ViewOrigin>,
                  containerPosition: Attribute<ViewOrigin>,
                  size: Attribute<ViewSize>,
                  safeAreaInsets: OptionalAttribute<SafeAreaInsets>) {
        self.base = base
        self.preferences = preferences
        self.transform = transform
        self.position = position
        self.containerPosition = containerPosition
        self.size = size
        self.safeAreaInsets = safeAreaInsets
        self.scrollableContainerSize = .init(nil)
    }
    
    @inline(__always)
    internal init(_ inputs: _ViewInputs) {
        base = _GraphInputs(inputs.base)
        preferences = inputs.preferences
        transform = inputs.transform
        position = inputs.position
        containerPosition = inputs.containerPosition
        size = inputs.size
        safeAreaInsets = inputs.safeAreaInsets
        scrollableContainerSize = inputs.scrollableContainerSize
    }
    
    @inline(__always)
    internal init(deepCopy inputs: _ViewInputs) {
        base = _GraphInputs(deepCopy: inputs.base)
        preferences = inputs.preferences
        transform = inputs.transform
        position = inputs.position
        containerPosition = inputs.containerPosition
        size = inputs.size
        safeAreaInsets = inputs.safeAreaInsets
        scrollableContainerSize = inputs.scrollableContainerSize
    }
    
    @inline(__always)
    internal mutating func performWithChangedDebugProperties<R>(of inputs: _ViewInputs, body: (_ViewInputs) -> R) -> R {
        
        self.base.changedDebugProperties = _ViewDebug.Properties()
        
        let retVal = body(self)
        
        self.base.changedDebugProperties = inputs.base.changedDebugProperties
        
        return retVal
        
    }
    
    internal subscript<A: ViewInput>(_ view: A.Type) -> A.Value {
        get {
            base[view]
        }
        set {
            base[view] = newValue
        }
    }
    
    internal mutating func append<A: ViewInput, B>(_ value: B, for viewInput: A.Type) where A.Value == [B] {
        base.append(value: value, for: viewInput)
    }
    
    internal mutating func popLast<A: ViewInput, B>(for input: A.Type) -> B? where A.Value == [B] {
        base.popLast(for: input)
    }
    
    internal mutating func consume<Input: ViewInput, Value>(_ input: Input.Type) -> Value? where Input.Value == Value? {
        let result = base[input]
        base[input] = nil
        return result
    }
    
    internal func makeIndirectOutputs() -> _ViewOutputs {
        if DanceUIFeature.gestureContainer.isEnable {
            struct AddPreferenceVisitor: PreferenceKeyVisitor {
                
                internal var outputs: _ViewOutputs = .init()
                
                internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
                    let source = GraphHost.currentHost.intern(Key.defaultValue, id: 0)
                    outputs.appendPreference(key, value: IndirectAttribute(source: source).projectedValue)
                }
            }
            var visitor = AddPreferenceVisitor()
            for key in preferences.keys {
                key.visitKey(&visitor)
            }
            var outputs = _ViewOutputs(preferences: preferences.makeIndirectOutputs(), layout: nil)
            outputs.setLayout(self) {
                let viewGraph: ViewGraph = ViewGraph.current
                let indirectLayoutComputer = IndirectAttribute(source: viewGraph.$defaultLayoutComputer)
                return Attribute<LayoutComputer>(identifier: indirectLayoutComputer.identifier)
            }
            
            return outputs
        }
        struct AddPreferenceVisitor: PreferenceKeyVisitor {
            
            internal var outputs: _ViewOutputs = .init()
            
            internal mutating func visit<Key>(key: Key.Type) where Key : PreferenceKey {
                let source = GraphHost.currentHost.intern(Key.defaultValue, id: 0)
                outputs.appendPreference(key, value: IndirectAttribute(source: source).projectedValue)
            }
        }
        var visitor = AddPreferenceVisitor()
        for key in preferences.keys {
            key.visitKey(&visitor)
        }
        var outputs = visitor.outputs
        outputs.setLayout(self) {
            let viewGraph: ViewGraph = ViewGraph.current
            let indirectLayoutComputer = IndirectAttribute(source: viewGraph.$defaultLayoutComputer)
            return Attribute<LayoutComputer>(identifier: indirectLayoutComputer.identifier)
        }
        
        return outputs
    }
    
    internal mutating func intern<ValueType>(_ value: ValueType, id: _GraphInputs.ConstantID) -> Attribute<ValueType> {
        let id: Int = Int(UInt8(id) & 0x1)
        return base.intern(value, id: id)
    }
    
    @inline(__always)
    internal func geometryTransaction() -> Attribute<Transaction> {
        let savedTransaction = self.base.customInputs[_GraphInputs.SavedTransactionKey.self]
        guard !savedTransaction.isEmpty else {
            return base.transaction
        }
        guard let index = savedTransaction.lastIndex(where: {$0.affectsGeometry}) else {
            return savedTransaction[0].transaction.value
        }
        guard index < (savedTransaction.count - 1) else {
            return base.transaction
        }
        return savedTransaction[index + 1].transaction.value
    }
    
    @inline(__always)
    internal mutating func merge(inputs: _GraphInputs, ignoringPhase: Bool) {
        base.merge(inputs: inputs, ignoringPhase: ignoringPhase)
    }
    
    @inline(__always)
    internal mutating func merge<Value>(attribute: Attribute<Value>, mergedAttribute: Attribute<Value>, body: () -> Void) {
        base.merge(attribute: attribute, mergedAttribute: mergedAttribute, body: body)
    }
    
    @inline(__always)
    internal mutating func merge(transaction: Attribute<Transaction>) {
        self.transaction = transaction
        base.mergedInputs.insert(transaction.identifier)
    }
    
    @inline(__always)
    internal mutating func merge(size: Attribute<ViewSize>) {
        self.size = size
        base.mergedInputs.insert(size.identifier)
    }
    
    @inline(__always)
    internal mutating func merge(phase: Attribute<_GraphInputs.Phase>) {
        self.phase = phase
        base.mergedInputs.insert(phase.identifier)
    }
    
    @inline(__always)
    internal mutating func withMutableGraphInputs<R>(_ body: (inout _GraphInputs) -> R) -> R {
        return body(&self.base)
    }
    
    @inline(__always)
    internal mutating func withMutableCustomInputs<R>(_ body: (inout PropertyList) -> R) -> R {
        self.base.withMutableCustomInputs(body)
    }
    
    @inline(__always)
    internal func withCustomInputs<R>(_ body: (PropertyList) -> R) -> R {
        self.base.withCustomInputs(body)
    }
    
    @inline(__always)
    internal func makePreferenceWriter<Key: PreferenceKey>(key: Key.Type, value: Attribute<Key.Value>, body: (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        var childInputs = self
        childInputs.preferences.remove(key)
        var outputs = body(_Graph(), childInputs)
        outputs.makePreferenceWriter(inputs: self, key: key, value: value)
        return outputs
    }
    
}

@inline(__always)
@available(iOS 13.0, *)
internal func withMutableViewInputs<R>(_ inputs: inout _ViewInputs,
                                       body: (inout _GraphInputs) -> R) -> R {
    return body(&inputs.base)
}



// MARK: ViewInputs properties
@available(iOS 13.0, *)
private struct ViewListOptionsInput: ViewInput {
    
    internal typealias Value = _ViewListInputs.Options
    
    @inline(__always)
    internal static var defaultValue: _ViewListInputs.Options { .init(rawValue: 0) }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var viewListOptions: _ViewListInputs.Options {
        get {
            self[ViewListOptionsInput.self]
        }
        set {
            self[ViewListOptionsInput.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _ViewListInputs {
    
    @inline(__always)
    internal var viewListOptions: _ViewListInputs.Options {
        get {
            self[ViewListOptionsInput.self]
        }
        set {
            self[ViewListOptionsInput.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewListCountInputs {
    
    @inline(__always)
    internal var viewListOptions: _ViewListInputs.Options {
        get {
            self.customInputs[ViewListOptionsInput.self]
        }
        set {
            self.customInputs[ViewListOptionsInput.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    fileprivate struct ImplicitRootType: ViewInput {
        
        internal typealias Value = _VariadicView_AnyImplicitRoot.Type
        
        internal static var defaultValue: _VariadicView_AnyImplicitRoot.Type {
            _VStackLayout.self
        }
    }
    
    @inline(__always)
    internal var implicitRootType: _VariadicView_AnyImplicitRoot.Type {
        get {
            self[ImplicitRootType.self]
        }
        set {
            self[ImplicitRootType.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    fileprivate struct ScrollableViewInput: ViewInput {
        
        internal typealias Value = Attribute<Scrollable>?
        
        internal static var defaultValue: Attribute<Scrollable>? { nil }
        
    }
    
    @inline(__always)
    internal var scrollableView: Attribute<Scrollable>? {
        get {
            self[ScrollableViewInput.self]
        }
        set {
            self[ScrollableViewInput.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var matchedGeometryScope: MatchedGeometryScope? {
        get {
            self[MatchedGeometryScope.self]
        }
        set {
            self[MatchedGeometryScope.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
internal struct FocusStoreInputKey: ViewInput {

    internal typealias Value = OptionalAttribute<FocusStore>
    
    internal static var defaultValue: Value {
        OptionalAttribute()
    }
    
}

@available(iOS 13.0, *)
private struct FocusedItemInputKey: ViewInput {
    
    fileprivate typealias Value = OptionalAttribute<FocusItem?>
    
    fileprivate static var defaultValue: OptionalAttribute<FocusItem?> {
        return OptionalAttribute()
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var focusStore: OptionalAttribute<FocusStore> {
        get {
            self[FocusStoreInputKey.self]
        }
        
        set {
            self[FocusStoreInputKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension _ViewInputs {
    
    @inline(__always)
    internal var focusedItem: OptionalAttribute<FocusItem?> {
        get {
            self[FocusedItemInputKey.self]
        }
        set {
            self[FocusedItemInputKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    @inline(__always)
    internal func input<A1: ViewInputFlag>(_ inputFlagType: A1.Type) -> some View {
        modifier(inputFlagType.init())
    }
    
}

@available(iOS 13.0, *)
internal protocol ViewInputFlag: _GraphInputsModifier, ViewInputPredicate, PrimitiveViewModifier where Input.Value: Equatable {
    
    associatedtype Input: ViewInput
    
    init()
    
    static var value: Input.Value { get }
    
}

@available(iOS 13.0, *)
extension ViewInputFlag {
    
    internal static func _makeInputs(modifier: _GraphValue<Self>, inputs: inout _GraphInputs) {
        inputs[Input.self] = value
    }
    
    internal static func evaluate(inputs: _GraphInputs) -> Bool {
        inputs[Input.self] == value
    }
    
}

@available(iOS 13.0, *)
internal protocol ViewInputBoolFlag: ViewInputFlag, ViewInput where Input == Self, Value == Bool {
    
}

@available(iOS 13.0, *)
extension ViewInputBoolFlag {
    
    internal static var defaultValue: Value { false }
    
    internal static var value: Value { true }
    
}

@available(iOS 13.0, *)
internal struct ViewDebugCustomValueFactory {
    internal var makeValue: (Any) -> Any?
}

@available(iOS 13.0, *)
private struct ViewDebugCustomValueKey: ViewInput {
    
    internal typealias Value = OptionalAttribute<ViewDebugCustomValueFactory>
    
    internal static var defaultValue: Value = .init(nil)
}


@available(iOS 13.0, *)
extension _ViewInputs {
    internal var viewDebugCustomValue: OptionalAttribute<ViewDebugCustomValueFactory> {
        get {
            self[ViewDebugCustomValueKey.self]
        }
        set {
            self[ViewDebugCustomValueKey.self] = newValue
            base.changedDebugProperties.insert(.custom)
        }
    }
}
