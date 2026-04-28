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

@available(iOS 13.0, *)
extension View {
    
    internal func accessibility<Value>(_ keyPath: WritableKeyPath<AccessibilityProperties, Value>, _ value: Value) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(AccessibilityProperties(keyPath, value))
    }
    
    internal func accessibility(_ properties: AccessibilityProperties) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(.properties(properties))
    }
    
}

@available(iOS 13.0, *)
internal struct AccessibilityProperties: Equatable {

    private var plist: PropertyList
    
    @inlinable
    internal init() {
        self.plist = PropertyList(elements: nil)
    }
    
    @inlinable
    internal init(plist: PropertyList) {
        self.plist = plist
    }
    
    @inlinable
    internal init<A>(_ keyPath: WritableKeyPath<AccessibilityProperties, A>, _ value: A) {
        self.plist = PropertyList(elements: nil)
        self[keyPath: keyPath] = value
    }
    
    static func == (lhs: AccessibilityProperties, rhs: AccessibilityProperties) -> Bool {
        !lhs.plist.mayNotBeEqualWithoutOrdering(to: rhs.plist)
    }
    
    internal func combined(with properties: AccessibilityProperties) -> AccessibilityProperties {
        var properties = properties
        
        if let visibility = visibility {
            properties.visibility = visibility
        }
        
        let traits = self.traits
        if traits != .empty {
            properties.traits = traits.combined(with: properties.traits)
        }
        if let label = label {
            properties.label = label
        }
        
        if let typedValue = typedValue {
            if let propertiesTypedValue = properties.typedValue {
                properties.typedValue = .combine(typedValue, with: propertiesTypedValue)
            } else {
                properties.typedValue = typedValue
            }
        }
        
        if let hint = hint {
            properties.hint = hint
        }
        
        if let roleDescription = roleDescription {
            properties.roleDescription = roleDescription
        }
        
        if let activationPoint = activationPoint {
            properties.activationPoint = activationPoint
        }
        
        if let outline = outline {
            properties.outline = outline
        }
        properties.inputLabels = inputLabels
        
        var actions = self.actions
        if !actions.isEmpty {
            actions.append(contentsOf: properties.actions)
            properties.actions = actions
        }
        
        if let identifier = identifier {
            properties.identifier = identifier
        }
        
        if let selectionIdentifier = selectionIdentifier {
            properties.selectionIdentifier = selectionIdentifier
        }
        
        if let viewTypeBox = viewTypeBox {
            properties.viewTypeBox = viewTypeBox
        }
        
        if let sortPriority = sortPriority {
            properties.sortPriority = sortPriority
        }
        
        if let automationType = automationType {
            properties.automationType = automationType
        }
        
        if let platformFocusable = platformFocusable {
            properties.platformFocusable = platformFocusable
        }
        
        if let focusableDescendantNode = focusableDescendantNode {
            properties.focusableDescendantNode = focusableDescendantNode
        }
        
        if let dataSeriesConfiguration = dataSeriesConfiguration {
            properties.dataSeriesConfiguration = dataSeriesConfiguration
        }
        
        if let incrementalLayoutContext = incrementalLayoutContext {
            properties.incrementalLayoutContext = incrementalLayoutContext
        }
        
        if let linkDestination = linkDestination {
            properties.linkDestination = linkDestination
        }
        
        return properties
    }
    
    internal mutating func combineText(separator: Text, keyPath: WritableKeyPath<AccessibilityProperties, Text?>, childProperties: [AccessibilityProperties], environment: EnvironmentValues) {
        guard childProperties.count >= 1 else {
            return
        }
        
        var text: Text?
        defer {
            self[keyPath: keyPath] = text
        }
        
        for childProperty in childProperties {
            let traits = childProperty.traits
            
            guard !traits.contains(.image) && !traits.contains(.button) else {
                continue
            }
            
            guard let currentText = childProperty[keyPath: keyPath],
                  !currentText.resolvesToEmpty(in: environment, with: .zero) else {
                continue
            }
            
            if let notNilText = text {
                text = notNilText + separator + currentText
            } else {
                text = currentText
            }
            
        }
        
        if text?.resolvesToEmpty(in: environment, with: .zero) == false {
            return
        }
        
        for childProperty in childProperties {
            let traits = childProperty.traits
            
            guard !traits.contains(.button) else {
                continue
            }
            
            guard let currentText = childProperty[keyPath: keyPath],
                    !currentText.resolvesToEmpty(in: environment, with: .zero) else {
                continue
            }
            
            if let notNilText = text {
                text = notNilText + separator + currentText
            } else {
                text = currentText
            }
            
        }
    }

    internal func namedActionFromDefault(in values: EnvironmentValues) -> AnyAccessibilityActionHandler? {
        guard traits[.button] == true else {
            return nil
        }
        
        guard let label = label, !label.resolvesToEmpty(in: values, with: .zero) else {
            return nil
        }
        
        let defaultAction = AccessibilityVoidAction(kind: .default)
        
        guard let matchAction = actions.first(where: { $0.matches(action: defaultAction) } ),
                let handler = matchAction.handler(for: defaultAction) else {
            return nil
        }
        
        return AnyAccessibilityActionHandler(
            action: AccessibilityVoidAction(kind: AccessibilityActionKind(named: label)),
            handler: handler
        )
    }
    
    @inlinable
    internal var actions: [AnyAccessibilityActionHandler] {
        get {
            plist[ActionsKey.self]
        }
        set {
            plist[ActionsKey.self] = newValue
        }
    }
    
    private struct ActionsKey: PropertyKey {
        
        internal typealias Value = [AnyAccessibilityActionHandler]
        
        @inline(__always)
        internal static var defaultValue: [AnyAccessibilityActionHandler] { [] }
        
    }
    
    @inlinable
    internal var activationPoint: AccessibilityActivationPoint? {
        get {
            plist[ActivationPointKey.self]
        }
        set {
            plist[ActivationPointKey.self] = newValue
        }
    }
    
    private struct ActivationPointKey: PropertyKey {
        
        internal typealias Value = AccessibilityActivationPoint?
        
        @inline(__always)
        internal static var defaultValue: AccessibilityActivationPoint? { nil }
        
    }
    
    @inlinable
    internal var dataSeriesConfiguration: AccessibilityDataSeriesConfiguration? {
        get {
            plist[DataSeriesConfigurationKey.self]
        }
        set {
            plist[DataSeriesConfigurationKey.self] = newValue
        }
    }
    
    private struct DataSeriesConfigurationKey: PropertyKey {
        
        internal typealias Value = AccessibilityDataSeriesConfiguration?
        
        @inline(__always)
        internal static var defaultValue: AccessibilityDataSeriesConfiguration? { nil }
    }
    
    @inlinable
    internal var hint: Text? {
        get {
            plist[HintKey.self]
        }
        set {
            plist[HintKey.self] = newValue
        }
    }
    
    private struct HintKey: PropertyKey {
        
        internal typealias Value = Text?
        
        @inline(__always)
        internal static var defaultValue: Text? { nil }
        
    }
    
    @inlinable
    internal var identifier: String? {
        get {
            plist[IdentifierKey.self]
        }
        set {
            plist[IdentifierKey.self] = newValue
        }
    }
    
    private struct IdentifierKey: PropertyKey {
        
        internal typealias Value = String?
        
        @inline(__always)
        internal static var defaultValue: String? { nil }
        
    }
    
    @inlinable
    internal var inputLabels: [Text] {
        get {
            plist[InputLabelsKey.self]
        }
        set {
            plist[InputLabelsKey.self] = newValue
        }
    }
    
    private struct InputLabelsKey: PropertyKey {
        
        internal typealias Value = [Text]
        
        @inline(__always)
        internal static var defaultValue: [Text] { [] }
    }
    
    @inlinable
    internal var label: Text? {
        get {
            plist[LabelKey.self]
        }
        set {
            plist[LabelKey.self] = newValue
        }
    }
    
    private struct LabelKey: PropertyKey {
        
        internal typealias Value = Text?
        
        @inline(__always)
        internal static var defaultValue: Text? { nil }
    }
    
    @inlinable
    internal var linkDestination: LinkDestination.Configuration? {
        get {
            plist[LinkDestinationKey.self]
        }
        set {
            plist[LinkDestinationKey.self] = newValue
        }
    }
    
    private struct LinkDestinationKey: PropertyKey {
        
        internal typealias Value = LinkDestination.Configuration?
        
        @inline(__always)
        internal static var defaultValue: LinkDestination.Configuration? { nil }
        
    }
    
    @inlinable
    internal var roleDescription: Text? {
        get {
            plist[RoleDescriptionKey.self]
        }
        set {
            plist[RoleDescriptionKey.self] = newValue
        }
    }
    
    private struct RoleDescriptionKey: PropertyKey {
        
        internal typealias Value = Text?
        
        @inline(__always)
        internal static var defaultValue: Text? { nil }
        
    }
    
    @inlinable
    internal var selectionIdentifier: AnyHashable? {
        get {
            plist[SelectionIdentifierKey.self]
        }
        set {
            plist[SelectionIdentifierKey.self] = newValue
        }
    }
    
    private struct SelectionIdentifierKey: PropertyKey {
        
        internal typealias Value = AnyHashable?
        
        @inline(__always)
        internal static var defaultValue: AnyHashable? { nil }
        
    }
    
    @inlinable
    internal var sortPriority: Double? {
        get {
            plist[SortPriorityKey.self]
        }
        set {
            plist[SortPriorityKey.self] = newValue
        }
    }
    
    private struct SortPriorityKey: PropertyKey {
        
        internal typealias Value = Double?
        
        @inline(__always)
        internal static var defaultValue: Double? { nil }
        
    }
    
    @inlinable
    internal var traits: AccessibilityTraitStorage {
        get {
            plist[TraitsKey.self]
        }
        set {
            plist[TraitsKey.self] = newValue
        }
    }
    
    private struct TraitsKey: PropertyKey {
        
        internal typealias Value = AccessibilityTraitStorage
        
        @inline(__always)
        internal static var defaultValue: AccessibilityTraitStorage { AccessibilityTraitStorage() }
        
    }
    
    @inlinable
    internal var typedValue: AccessibilityValue? {
        get {
            plist[TypedValueKey.self]
        }
        set {
            plist[TypedValueKey.self] = newValue
        }
    }
    
    private struct TypedValueKey: PropertyKey {
        
        internal typealias Value = AccessibilityValue?
        
        @inline(__always)
        internal static var defaultValue: AccessibilityValue? { nil }
        
    }
    
    @inlinable
    internal var value: Text? {
        get {
            typedValue?.description
        }
        set {
            if var pre = typedValue {
                pre.description = newValue
                typedValue = pre
            } else {
                if let newValue = newValue {
                    typedValue = AccessibilityValue(description: newValue)
                }
            }
        }
    }

    @inlinable
    internal var visibility: _AccessibilityVisibility? {
        get {
            plist[VisibilityKey.self]
        }
        set {
            plist[VisibilityKey.self] = newValue
        }
    }
    
    private struct VisibilityKey: PropertyKey {
        
        internal typealias Value = _AccessibilityVisibility?
        
        @inline(__always)
        internal static var defaultValue: _AccessibilityVisibility? { nil }
        
    }
    
    @inlinable
    internal var focusableDescendantNode: AccessibilityNode? {
        get {
            plist[FocusableDescendantNodeKey.self]?.focusableDescendantNode
        }
        set {
            plist[FocusableDescendantNodeKey.self] = FocusableDescendantNodeWrapper(focusableDescendantNode: newValue)
        }
    }
    
    fileprivate struct FocusableDescendantNodeWrapper {

        fileprivate weak var focusableDescendantNode: AccessibilityNode?

    }
    
    private struct FocusableDescendantNodeKey: PropertyKey {
        
        fileprivate typealias Value = FocusableDescendantNodeWrapper?
        
        @inline(__always)
        fileprivate static var defaultValue: FocusableDescendantNodeWrapper? { nil }
        
    }
    
    @inlinable
    internal var outline: Outline? {
        get {
            plist[OutlineKey.self]
        }
        set {
            plist[OutlineKey.self] = newValue
        }
    }
    
    private struct OutlineKey: PropertyKey {
        
        internal typealias Value = Outline?
        
        @inline(__always)
        internal static var defaultValue: Outline? { nil }
        
    }
    
    internal enum Outline {

        case frame(CGRect)

        case path(Path)

        case defaultFrame

        case ignore

    }
    
    @inlinable
    internal var viewTypeDescription: String? {
        plist[ViewTypeDescription.self]?.typeDescription
    }
    
    @inlinable
    internal var viewTypeBox: AXAnyViewTypeDescribingBox? {
        get {
            plist[ViewTypeDescription.self]
        }
        set {
            plist[ViewTypeDescription.self] = newValue
        }
    }
    
    private struct ViewTypeDescription: PropertyKey {

        internal typealias Value = AXAnyViewTypeDescribingBox?
        
        @inline(__always)
        internal static var defaultValue: AXAnyViewTypeDescribingBox? { nil }
        
    }
    
    @inlinable
    internal var automationType: UInt64? {
        get {
            plist[AutomationTypeKey.self]
        }
        set {
            plist[AutomationTypeKey.self] = newValue
        }
    }

    private struct AutomationTypeKey: PropertyKey {
        
        internal typealias Value = UInt64?
        
        @inline(__always)
        internal static var defaultValue: UInt64? { nil }
        
    }
    
    @inlinable
    internal var platformFocusable: Bool? {
        get {
            plist[PlatformFocusableKey.self]
        }
        set {
            plist[PlatformFocusableKey.self] = newValue
        }
    }

    private struct PlatformFocusableKey: PropertyKey {
        
        internal typealias Value = Bool?
        
        @inline(__always)
        internal static var defaultValue: Bool? { nil }
        
    }
    
    @inlinable
    internal var incrementalLayoutContext: AccessibilityIncrementalLayoutContext? {
        get {
            plist[IncrementalLayoutContextKey.self]
        }
        set {
            plist[IncrementalLayoutContextKey.self] = newValue
        }
    }

    private struct IncrementalLayoutContextKey: PropertyKey {
        
        internal typealias Value = AccessibilityIncrementalLayoutContext?
        
        @inline(__always)
        internal static var defaultValue: AccessibilityIncrementalLayoutContext? { nil }
        
    }
    
}
