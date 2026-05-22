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

// MARK: - View Info Trace Helper Data

internal struct AttributeKey: Hashable, CustomStringConvertible {
    
    internal let identifier: UInt32
    
    private var id: UInt32 {
        identifier
    }
    
    internal init(_ attribute: DGAttribute) {
        self.identifier = attribute.rawValue
    }
    
    internal var description: String {
        return "<AttributeKey: 0x\(String(identifier, radix: 16))>"
    }
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    internal static func == (lhs: AttributeKey, rhs: AttributeKey) -> Bool {
        return lhs.id == rhs.id
    }
    
}

// swift-format-ignore: UseSynthesizedInitializer
internal struct AttributeRoleNarration: RawRepresentable {
    
    internal var rawValue: String
    
    internal init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    internal static let root = AttributeRoleNarration(rawValue: "root")
    
    internal static let derived = AttributeRoleNarration(rawValue: "derived")
    
    internal static let unspecified = AttributeRoleNarration(rawValue: "unspecified")
    
    internal static let viewStructure = AttributeRoleNarration(rawValue: "view-structure")
    
    internal static let environmental = AttributeRoleNarration(rawValue: "environmental")
    
    internal static let bridgedPreference = AttributeRoleNarration(rawValue: "bridgedPreference")
    
    internal static let state = AttributeRoleNarration(rawValue: "state")
    
    internal static let observableObject = AttributeRoleNarration(rawValue: "observable-object")
    
}

// swift-format-ignore: UseSynthesizedInitializer
internal struct AttributeRole: OptionSet, RawRepresentable, Hashable {
    
    internal var rawValue: UInt16
    
    internal init(rawValue: UInt16) {
        self.rawValue = rawValue
    }
    
    internal var narrations: [AttributeRoleNarration] {
        var narrations: [AttributeRoleNarration] = []
        if self.contains(.root) {
            narrations.append(.root)
        }
        if self.contains(.derived) {
            narrations.append(.derived)
        }
        if self.contains(.unspecified) {
            narrations.append(.unspecified)
        }
        if self.contains(.viewStructure) {
            narrations.append(.viewStructure)
        }
        if self.contains(.state) {
            narrations.append(.state)
        }
        if self.contains(.observableObject) {
            narrations.append(.observableObject)
        }
        if self.contains(.environmental) {
            narrations.append(.environmental)
        }
        if self.contains(.bridgedPreference) {
            narrations.append(.bridgedPreference)
        }
        return narrations
    }
    
    
    internal static let root = AttributeRole(rawValue: 0x1 << 0)
    
    internal static let derived = AttributeRole(rawValue: 0x1 << 1)
    
    internal static let unspecified = AttributeRole(rawValue: 0x1 << 2)
    
    internal static let viewStructure = AttributeRole(rawValue: 0x1 << 3)
    
    internal static let state = AttributeRole(rawValue: 0x1 << 4)
    
    internal static let observableObject = AttributeRole(rawValue: 0x1 << 5)
    
    internal static let appStorage = AttributeRole(rawValue: 0x1 << 6)
    
    internal static let environmental = AttributeRole(rawValue: 0x1 << 7)
    
    internal static let bridgedPreference = AttributeRole(rawValue: 0x1 << 8)
    
    internal static let body = AttributeRole(rawValue: 0x1 << 9)
    
    internal static let programEntry: AttributeRole = [.root, .viewStructure]
    
    internal static let unspeficiedRoot: AttributeRole = [.root, .unspecified]
    
    internal static let signalForState: AttributeRole = [.root, .state]
    
    internal static let signalForObservableObject: AttributeRole = [.root, .observableObject]
    
    internal static let signalForAppStroage: AttributeRole = [.root, .appStorage]
    
    internal static let entryDerived: AttributeRole = [.derived, .viewStructure]
    
    internal static let unspecifiedDerived: AttributeRole = [.derived, .unspecified]
    
}

/// All cases indirect. Make the enum indirect.
internal indirect enum AttributeAssociation {
    
    /// Leave it indirect to make to cost of copy and destroy to be one single
    /// retain/release.
    case defObservableObjectSignal(fieldName: String, observableObjectType: Any.Type)
    
    /// `Any.Type` takes two words. Make it indirect.
    case bodyAccessor(containerType: Any.Type)
    
}

// MARK: - View Info Trace Entry

@dynamicMemberLookup
internal struct ViewInfoTraceEntry: TableEntry, StatefulTableEntry {
    
    internal struct SubEntries {
        
        internal var uud: UnnecessaryUpdateDetectionSubEntry
        
        internal init() {
            uud = UnnecessaryUpdateDetectionSubEntry()
        }
        
    }
    
    internal subscript<T>(dynamicMember keyPath: KeyPath<SubEntries, T>) -> T {
        _read {
            yield subEntries[keyPath: keyPath]
        }
    }
    
    internal subscript<T>(dynamicMember keyPath: WritableKeyPath<SubEntries, T>) -> T {
        _read {
            yield subEntries[keyPath: keyPath]
        }
        _modify {
            yield &subEntries[keyPath: keyPath]
        }
    }
    
    internal var state: TableEntryState
    
    fileprivate var subEntries: SubEntries
    
    fileprivate mutating func create() {
        // `wasCreated` has already been set in `init`.
        assert(wasCreated)
    }
    
    internal mutating func didCreate() {
        subEntries.uud.didCreate()
    }
    
    internal mutating func didRemove() {
        role = AttributeRole()
        association = nil
        subEntries.uud.didCreate()
    }
    
    internal mutating func didResolve() {
        subEntries.uud.didResolve()
    }
    
    internal var role: AttributeRole
    
    internal var association: AttributeAssociation?
    
    internal mutating func addRole(_ role: AttributeRole) {
        self.role.insert(role)
    }
    
    /// Role can only be set when the attribute is initialized
    internal mutating func setRole(_ role: AttributeRole) {
        assert(self.role.isEmpty)
        self.role = role
    }
    
    internal init() {
        self.state = .created
        self.role = AttributeRole()
        self.association = nil
        self.subEntries = SubEntries()
    }
    
}

// MARK: - View Info Trace Context

@available(iOS 13.0, *)
internal class ViewInfoTraceContext {
    
    internal typealias AttributedIterator = [AttributeKey : ViewInfoTraceEntry]
    
    fileprivate var table: Table<ViewInfoTraceEntry>
    
    fileprivate init() {
        table = Table()
    }
    
    internal subscript(_ key: AttributeKey) -> ViewInfoTraceEntry {
        get {
            table[key]
        }
        set {
            table[key] = newValue
        }
    }
    
    internal func add(_ key: AttributeKey) {
        table.add(key)
    }
    
    internal func remove(_ key: AttributeKey) {
        table.remove(key)
    }
    
    internal func contains(_ key: AttributeKey) -> Bool {
        table.contains(key)
    }
    
    internal func wasRemoved(_ key: AttributeKey) -> Bool {
        table.wasRemoved(key)
    }
    
    internal var attributes: AnySequence<(key: AttributeKey, value: ViewInfoTraceEntry)> {
        AnySequence {
            self.table.makeIterator()
        }
    }
    
    // MARK: Attribute Set-up
    
    /// Make it fileprivate to leave the modification accessor to attribute role
    /// only on DGAttribute/Attribute.
    fileprivate func setRole(_ role: AttributeRole, forAttribute attribute: DGAttribute) {
        table[AttributeKey(attribute)].setRole(role)
    }
    
    /// Make it fileprivate to leave the modification accessor to attribute role
    /// only on DGAttribute/Attribute.
    fileprivate func addRole(_ role: AttributeRole, forAttribute attribute: DGAttribute) {
        table[AttributeKey(attribute)].addRole(role)
    }
    
    internal func role(for attribute: DGAttribute) -> AttributeRole {
        table[AttributeKey(attribute)].role
    }
    
    /// Make it fileprivate to leave the modification accessor to attribute
    /// association only on DGAttribute/Attribute.
    fileprivate func setAssociation(_ association: AttributeAssociation?, forAttribute attribute: DGAttribute) {
        table[AttributeKey(attribute)].association = association
    }
    
    internal func association(for attribute: DGAttribute) -> AttributeAssociation? {
        table[AttributeKey(attribute)].association
    }
    
}

#if DEBUG
// Test-only hooks (kept in the same file to allow calling `fileprivate` init).
@available(iOS 13.0, *)
extension ViewInfoTraceContext {

    internal static func testableMake() -> ViewInfoTraceContext {
        ViewInfoTraceContext()
    }

    // Test-only helpers to exercise forwarding from context methods
    // into the underlying ViewInfoTraceEntry table.

    internal func _testSetRole(_ role: AttributeRole, rawAttribute: UInt32) {
        let attribute = DGAttribute(rawValue: rawAttribute)
        setRole(role, forAttribute: attribute)
    }

    internal func _testAddRole(_ role: AttributeRole, rawAttribute: UInt32) {
        let attribute = DGAttribute(rawValue: rawAttribute)
        addRole(role, forAttribute: attribute)
    }

    internal func _testSetAssociation(_ association: AttributeAssociation?, rawAttribute: UInt32) {
        let attribute = DGAttribute(rawValue: rawAttribute)
        setAssociation(association, forAttribute: attribute)
    }

    internal func _testEntry(for rawAttribute: UInt32) -> ViewInfoTraceEntry {
        let attribute = DGAttribute(rawValue: rawAttribute)
        return table[AttributeKey(attribute)]
    }
}
#endif

// MARK: - View Info Trace

@available(iOS 13.0, *)
internal final class ViewInfoTrace: GraphTracing {
    
    internal private(set) static var all: [Unmanaged<ViewInfoTrace>] = []
    
    fileprivate let context: ViewInfoTraceContext
    
    private let unnecessaryUpdateDetectionPass: UnnecessaryUpdateDetectionPass
    
    internal let name: StaticString
    
    internal init(name: StaticString) {
        self.name = name
        self.context = ViewInfoTraceContext()
        unnecessaryUpdateDetectionPass = UnnecessaryUpdateDetectionPass(context: context)
        super.init()
        Self.all.append(.passUnretained(self))
    }
    
    deinit {
        Self.all.removeAll { tracer in
            tracer.takeUnretainedValue() === self
        }
    }
    
    // MARK: Querying Informations From Tracing Results
    
    /// - Note: Do not persist the return values.
    internal func dirtifyActions(for attribute: DGAttribute) -> AnySequence<VersionedDirtifyAction> {
        return unnecessaryUpdateDetectionPass.dirtifyActions(for: attribute)
    }
    
    // MARK: - GraphTracing
    
    // internal override func graphWillStartTrace(_ graph: DGGraphRef)
    
    // internal override func graphDidStopTrace(_ graph: DGGraphRef)
    
    // internal override func subgraphWillUpdate(_ subgraph: DGSubgraphRef, flags: UInt32)
    
    // internal override func subgraphDidUpdate(_ subgraph: DGSubgraphRef)
    
    // internal override func beginUpdateNode(_ attribute: DGAttribute, flags: UInt32)
    
    // internal override func endUpdateNode(_ attribute: DGAttribute, flags: UInt32)
    
    internal override func beginUpdateValue(_ attribute: DGAttribute) {
        unnecessaryUpdateDetectionPass.beginUpdateValue(attribute)
    }
    
    internal override func endUpdateValue(_ attribute: DGAttribute, changed: Bool) {
        unnecessaryUpdateDetectionPass.endUpdateValue(attribute, changed: changed)
    }
    
    // internal override func ignoreUpdateValue(_ attribute: DGAttribute)
    
    // internal override func graphWillUpdate(_ graph: DGGraphRef)
    
    // internal override func graphDidUpdate(_ graph: DGGraphRef)
    
    // internal override func graphWillInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute)
    
    // internal override func graphDidInvalidate(_ graph: DGGraphRef, by attribute: DGAttribute)
    
    // internal override func attributeWillModify(_ attribute: DGAttribute)
    
    // internal override func attributeDidModify(_ attribute: DGAttribute)
    
    // internal override func attributeWillStartEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>)
    
    // internal override func attributeDidEndEvent(_ attribute: DGAttribute, name: UnsafePointer<CChar>)
    
    // internal override func graphDidCreate(_ graph: DGGraphRef)
    
    // internal override func graphWillDestroy(_ graph: DGGraphRef)
    
    // internal override func graphNeedsUpdate(_ graph: DGGraphRef)
    
    // internal override func subgraphDidCreate(_ subgraph: DGSubgraphRef)
    
    internal override func subgraphWillDestroy(_ subgraph: DGSubgraphRef) {
    }
    
    // internal override func subgraph(_ subgraph: DGSubgraphRef, didAdd child: DGSubgraphRef)

    // internal override func subgraph(_ subgraph: DGSubgraphRef, didRemove child: DGSubgraphRef)

    internal override func nodeDidAdd(_ attribute: DGAttribute) {
        // Attribute's subgraph controls the life-cycle of attribute.
#if DEBUG || DANCE_UI_INHOUSE
        // assert(attribute.subgraph.defines(attribute))
#endif
        let key = AttributeKey(attribute)
        context.add(key)
        context[key].create()
    }
    
    // internal override func node(_ attribute: DGAttribute, didAdd inputAttribute: DGAttribute, flags: UInt32)
    
    // internal override func node(_ attribute: DGAttribute, didRemoveEdgeAt index: UInt64)
    
    // internal override func node(_ attribute: DGAttribute, edgeIndex: UInt64, pending: Bool)
    
    // internal override func node(_ attribute: DGAttribute, dirty: Bool)
    
    // internal override func node(_ attribute: DGAttribute, pending: Bool)
    
    // internal override func node(_ attribute: DGAttribute, value: UnsafeRawPointer)
    
    // internal override func attributeDidMarkValue(_ attribute: DGAttribute)

    internal override func indirectNodeDidAdd(_ attribute: DGAttribute) {
        let key = AttributeKey(attribute)
        context.add(key)
        context[key].create()
    }
    
    // internal override func indirectNode(_ attribute: DGAttribute, didSetSource source: DGAttribute)
    
    // internal override func indirectNode(_ attribute: DGAttribute, didSetDependency dependency: DGAttribute)
    
    // internal override func markProfile(with name: UnsafePointer<CChar>)
    
    internal override func attributeWillInvalidateValue(_ attribute: DGAttribute) {
        unnecessaryUpdateDetectionPass.attributeWillInvalidateValue(attribute)
    }
    
    // internal override func attributeDidInvalidateValue(_ attribute: DGAttribute)
    
    internal override func attributeWillSetValue(_ attribute: DGAttribute) {
        unnecessaryUpdateDetectionPass.attributeWillSetValue(attribute)
    }
    
    // internal override func attributeDidSetValue(_ attribute: DGAttribute)
    
    internal override func attributeWillMutateBody(_ attribute: DGAttribute, _ invalidating: Bool) {
        unnecessaryUpdateDetectionPass.attributeWillMutateBody(attribute, invalidating)
    }
    
    // internal override func attributeDidMutateBody(_ attribute: DGAttribute, _ invalidating: Bool)
    
}

// MARK: - GraphHost with View Info Trace

extension GraphHost {

    fileprivate var viewInfoTrace: ViewInfoTrace? {
        data.viewInfoTrace
    }

    fileprivate static var sahredViewInfoTrace: ViewInfoTrace? {
        Data.sahredViewInfoTrace
    }

}

// MARK: - DGAttribute with ViewInfoTrace

@available(iOS 13.0, *)
extension DGAttribute {

    @inline(__always)
    internal var viewInfoTrace: ViewInfoTrace? {
        let subgraph = self.subgraph
        let graph = subgraph.graph
        let graphHost = graph.graphHost()
        return graphHost.viewInfoTrace
    }
    
    @inline(__always)
    internal var role: AttributeRole {
        get {
            viewInfoTrace?.context.role(for: self) ?? AttributeRole()
        }
        nonmutating set {
            viewInfoTrace?.context.setRole(newValue, forAttribute: self)
        }
    }
    
    @inline(__always)
    internal var association: AttributeAssociation? {
        get {
            viewInfoTrace?.context.association(for: self)
        }
        nonmutating set {
            viewInfoTrace?.context.setAssociation(newValue, forAttribute: self)
        }
    }
    
    @inline(__always)
    internal func addRole(_ role: AttributeRole) {
        viewInfoTrace?.context.addRole(role, forAttribute: self)
    }
    
}

// MARK: - Attribute with ViewInfoTrace

@available(iOS 13.0, *)
extension Attribute {

    @inline(__always)
    internal var viewInfoTrace: ViewInfoTrace? {
        identifier.viewInfoTrace
    }
    
    @inline(__always)
    internal var role: AttributeRole {
        get {
            identifier.role
        }
        nonmutating set {
            identifier.role = newValue
        }
    }
    
    @inline(__always)
    internal var association: AttributeAssociation? {
        get {
            identifier.association
        }
        nonmutating set {
            identifier.association = newValue
        }
    }
    
    @inline(__always)
    internal func addRole(_ role: AttributeRole) {
        identifier.addRole(role)
    }
    
}

// MARK: - Table

internal enum TableEntryState {
    
    case created
    
    case resolved
    
    case removed
    
}

internal protocol TableEntry {
    
    init()
    
    mutating func didCreate()
    
    mutating func didRemove()
    
    mutating func didResolve()
    
}

internal protocol StatefulTableEntry: TableEntry {
    
    var state: TableEntryState { get set }
    
}

extension StatefulTableEntry {
    
    internal var wasCreated: Bool {
        state == .created
    }
    
    internal var wasRemoved: Bool {
        state == .removed
    }
    
}

extension StatefulTableEntry {
    
    internal mutating func create() {
        // `wasCreated` has already been set in `init`.
        assert(wasCreated)
        didCreate()
    }
    
    internal mutating func remove() {
        // May be .created or .resovled
        assert(state != .removed)
        state = .removed
        didRemove()
    }
    
    internal mutating func resolve() {
        state = .resolved
        didResolve()
    }
    
}

@available(iOS 13.0, *)
private struct Table<Entry: StatefulTableEntry>: Sequence {
    
    fileprivate typealias Iterator = Dictionary<AttributeKey, Entry>.Iterator
    
    fileprivate func makeIterator() -> Dictionary<AttributeKey, Entry>.Iterator {
        entries.makeIterator()
    }
    
    private var entries: [AttributeKey : Entry]
    
    fileprivate init() {
        self.entries = [:]
    }
    
    fileprivate subscript(key: AttributeKey) -> Entry {
        get {
            guard let _ = entries.index(forKey: key) else {
                preconditionFailure("read but no entry for key: \(key)")
            }
            return entries[key]!
        }
        _modify {
            guard let _ = entries.index(forKey: key) else {
                preconditionFailure("modify but no entry for key: \(key)")
            }
            yield &entries[key]!
        }
    }
    
    fileprivate func contains(_ key: AttributeKey) -> Bool {
        entries.keys.contains(key)
    }
    
    fileprivate func wasRemoved(_ key: AttributeKey) -> Bool {
        entries[key]?.wasRemoved == true
    }
    
}

@available(iOS 13.0, *)
extension Table where Entry: StatefulTableEntry {
    
    fileprivate mutating func add(_ key: AttributeKey) {
        entries[key] = Entry()
    }
    
    fileprivate mutating func remove(_ key: AttributeKey) {
        entries[key]!.remove()
    }
    
}

#endif // DEBUG || DANCE_UI_INHOUSE
