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

import CoreGraphics
internal import DanceUIGraph

@available(iOS 13.0, *)
internal struct EnvironmentPropertyKey<K: EnvironmentKey>: PropertyKey {
    
    internal typealias Value = K.Value
    
    internal static var defaultValue: Value {
        K.defaultValue
    }
}

@available(iOS 13.0, *)
private struct DerivedEnvironmentPropertyKey<K: DerivedPropertyKey>: DerivedPropertyKey where K.Value: Equatable {
    
    internal typealias Value = K.Value
    
    internal static var defaultValue: Value {
        K.defaultValue
    }
    
    internal static func value(in propertyList: PropertyList) -> K.Value {
        K.value(in: propertyList)
    }
    
}


/// A collection of environment values propagated through a view hierarchy.
///
/// DanceUI exposes a collection of values to your app's views in an
/// `EnvironmentValues` structure. To read a value from the structure,
/// declare a property using the ``Environment`` property wrapper and
/// specify the value's key path. For example, you can read the current locale:
///
///     @Environment(\.locale) var locale: Locale
///
/// Use the property you declare to dynamically control a view's layout.
/// DanceUI automatically sets or updates many environment values, like
/// ``EnvironmentValues/pixelLength``, ``EnvironmentValues/scenePhase``, or
/// ``EnvironmentValues/locale``, based on device characteristics, system state,
/// or user settings. For others, like ``EnvironmentValues/lineLimit``, DanceUI
/// provides a reasonable default value.
///
/// You can set or override some values using the ``View/environment(_:_:)``
/// view modifier:
///
///     MyView()
///         .environment(\.lineLimit, 2)
///
/// The value that you set affects the environment for the view that you modify
/// --- including its descendants in the view hierarchy --- but only up to the
/// point where you apply a different environment modifier.
///
/// DanceUI provides dedicated view modifiers for setting some values, which
/// typically makes your code easier to read. For example, rather than setting
/// the ``EnvironmentValues/lineLimit`` value directly, as in the previous
/// example, you should instead use the ``View/lineLimit(_:)-513mb`` modifier:
///
///     MyView()
///         .lineLimit(2)
///
/// In some cases, using a dedicated view modifier provides additional
/// functionality. For example, you must use the
/// ``View/preferredColorScheme(_:)`` modifier rather than setting
/// ``EnvironmentValues/colorScheme`` directly to ensure that the new
/// value propagates up to the presenting container when presenting a view
/// like a popover:
///
///     MyView()
///         .popover(isPresented: $isPopped) {
///             PopoverContent()
///                 .preferredColorScheme(.dark)
///         }
///
/// Create custom environment values by defining a type that
/// conforms to the ``EnvironmentKey`` protocol, and then extending the
/// environment values structure with a new property. Use your key to get and
/// set the value, and provide a dedicated modifier for clients to use when
/// setting the value:
///
///     private struct MyEnvironmentKey: EnvironmentKey {
///         static let defaultValue: String = "Default value"
///     }
///
///     extension EnvironmentValues {
///         var myCustomValue: String {
///             get { self[MyEnvironmentKey.self] }
///             set { self[MyEnvironmentKey.self] = newValue }
///         }
///     }
///
///     extension View {
///         func myCustomValue(_ myCustomValue: String) -> some View {
///             environment(\.myCustomValue, myCustomValue)
///         }
///     }
///
/// Clients of your value then access the value in the usual way, reading it
/// with the ``Environment`` property wrapper, and setting it with the
/// `myCustomValue` view modifier.
@available(iOS 13.0, *)
public struct EnvironmentValues : CustomStringConvertible {

    private var _propertyList: PropertyList

    private let _propertyTracker: PropertyList.Tracker?
    
    @inline(__always)
    internal init(_ environmentValues: EnvironmentValues) {
        _propertyList = environmentValues._propertyList
        _propertyTracker = environmentValues._propertyTracker
    }
    
    @inline(__always)
    internal init(propertyList: PropertyList) {
        _propertyList = propertyList
        _propertyTracker = nil
    }
    
    @inline(__always)
    fileprivate init(propertyList: PropertyList, propertyTracker: PropertyList.Tracker?, resetsTracker: Bool) {
        _propertyList = propertyList
        _propertyTracker = propertyTracker
        if resetsTracker {
            resetTracker()
        }
        _propertyTracker?.initializeValues(from: propertyList)
    }
    
    @inline(__always)
    internal func hasDifferentUsedValues(with tracker: PropertyList.Tracker) -> Bool {
        tracker.hasDifferentUsedValues(_propertyList)
    }
    
    @inline(__always)
    internal func resetTracker() {
        _propertyTracker?.reset()
    }
    
    @inline(__always)
    internal mutating func merge(_ environmentValues: EnvironmentValues) {
        _propertyList.merge(environmentValues._propertyList)
        
        if _propertyList.match(environmentValues._propertyList), let tracker = _propertyTracker {
            tracker.invalidateAllValues(from: _propertyList, to: _propertyList)
        }
    }
    

    @inline(__always)
    internal func withTracker(_ tracker: PropertyList.Tracker?, resets: Bool = true) -> EnvironmentValues {
        EnvironmentValues(propertyList: _propertyList, propertyTracker: tracker, resetsTracker: resets)
    }
    
    @inline(__always)
    internal func mayNotBeEqual(to other: EnvironmentValues) -> Bool {
        _propertyList.mayNotBeEqual(to: other._propertyList)
    }
    
    /// Creates an environment values instance.
    ///
    /// You don't typically create an instance of ``EnvironmentValues``
    /// directly. Doing so would provide access only to default values that
    /// don't update based on system settings or device characteristics.
    /// Instead, you rely on an environment values' instance
    /// that DanceUI manages for you when you use the ``Environment``
    /// property wrapper and the ``View/environment(_:_:)`` view modifier.
    public init() {
        _propertyList = PropertyList()
        _propertyTracker = nil
    }
    
    @inline(__always)
    internal func findDerived<K: DerivedPropertyKey>(key: K.Type) -> K.Value {
        guard let propertyTracker = _propertyTracker else {
            return _propertyList[DerivedEnvironmentPropertyKey<K>.self]
        }
        return propertyTracker.derivedValue(_propertyList,
                                            for: DerivedEnvironmentPropertyKey<K>.self)
    }
    
    @inline(__always)
    internal mutating func setDerived<K: DerivedPropertyKey>(key: K.Type, newValue: K.Value) {
        _propertyList[DerivedEnvironmentPropertyKey<K>.self] = newValue
    }
    
    /// Accesses the environment value associated with a custom key.
    ///
    /// Create custom environment values by defining a key
    /// that conforms to the ``EnvironmentKey`` protocol, and then using that
    /// key with the subscript operator of the ``EnvironmentValues`` structure
    /// to get and set a value for that key:
    ///
    ///     private struct MyEnvironmentKey: EnvironmentKey {
    ///         static let defaultValue: String = "Default value"
    ///     }
    ///
    ///     extension EnvironmentValues {
    ///         var myCustomValue: String {
    ///             get { self[MyEnvironmentKey.self] }
    ///             set { self[MyEnvironmentKey.self] = newValue }
    ///         }
    ///     }
    ///
    /// You use custom environment values the same way you use system-provided
    /// values, setting a value with the ``View/environment(_:_:)`` view
    /// modifier, and reading values with the ``Environment`` property wrapper.
    /// You can also provide a dedicated view modifier as a convenience for
    /// setting the value:
    ///
    ///     extension View {
    ///         func myCustomValue(_ myCustomValue: String) -> some View {
    ///             environment(\.myCustomValue, myCustomValue)
    ///         }
    ///     }
    ///
    @_semantics("optimize.sil.specialize.generic.never")
    public subscript<K: EnvironmentKey>(key: K.Type) -> K.Value {
        get {
            guard let propertyTracker = _propertyTracker else {
                return _propertyList[EnvironmentPropertyKey<K>.self]
            }
            return propertyTracker.value(_propertyList,
                                         for: EnvironmentPropertyKey<K>.self)
        }
        set {
            _propertyList[EnvironmentPropertyKey<K>.self] = newValue
            _propertyTracker?.invalidateValue(for: EnvironmentPropertyKey<K>.self,
                                              from: _propertyList,
                                              to: _propertyList)
        }
    }
    
    /// A string that represents the contents of the environment values
    /// instance.
    public var description: String {
        var nextOrNil = _propertyList.elements
        var components = [String]()
        while let next = nextOrNil {
            components.append(next.description)
            nextOrNil = next.after
        }
        return "<\(type(of: self)); \(components.joined(separator: "; "))>"
    }
    
    @inline(__always)
    internal func byOverriding(with environmentValues: EnvironmentValues?) -> EnvironmentValues {
        guard let environmentValues = environmentValues else {
            return self
        }
        
        let prependedPlist: PropertyList.Element?
        if let elements = _propertyList.elements {
            prependedPlist = elements.byPrepending(environmentValues._propertyList.elements)
        } else {
            prependedPlist = environmentValues._propertyList.elements
        }
        
        return EnvironmentValues(propertyList: PropertyList(elements: prependedPlist))
    }
    
    internal static func reader<A: View>(content: @escaping (EnvironmentValues) -> A) -> EnvironmentReader<A> {
        EnvironmentReader(content: content)
    }
    
}

@available(iOS 13.0, *)
private struct DefaultMinListRowHeightKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0 }
}

@available(iOS 13.0, *)
private struct DefaultMinListHeaderHeight: EnvironmentKey {
    
    internal typealias Value = CGFloat?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The default minimum height of a row in a list.
    //@inline(__always)
    public var defaultMinListRowHeight: CGFloat {
        get {
            self[DefaultMinListRowHeightKey.self]
        }
        set {
            self[DefaultMinListRowHeightKey.self] = newValue
        }
    }
    
    /// The default minimum height of a header in a list.
    ///
    /// When this value is `nil`, the system chooses the appropriate height. The
    /// default is `nil`.
    //@inline(__always)
    public var defaultMinListHeaderHeight: CGFloat? {
        get {
            self[DefaultMinListHeaderHeight.self]
        }
        set {
            self[DefaultMinListHeaderHeight.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct EnabledKey: EnvironmentKey {
    
    internal typealias Value = Bool
    
    @inline(__always)
    internal static var defaultValue: Value { true }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// A Boolean value that indicates whether the view associated with this
    /// environment allows user interaction.
    ///
    /// The default value is `true`.
    //@inline(__always)
    public var isEnabled: Bool {
        get {
            self[EnabledKey.self]
        }
        set {
            self[EnabledKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var fontDefinition: FontDefinition.Type {
        get {
            self[FontDefinitionKey.self].base
        }
        set {
            self[FontDefinitionKey.self].base = newValue
        }
    }
    
    @inline(__always)
    internal var preferredContentSizeCategory: ContentSizeCategory {
        get {
            self[PreferredContentSizeCategoryKey.self]
        }
        set {
            self[PreferredContentSizeCategoryKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var fontResolutionContext: Font.Context {
        get {
            findDerived(key: FontContextKey.self)
        }
        set {
            setDerived(key: FontContextKey.self, newValue: newValue)
        }
    }
    
    @inline(__always)
    internal var fontModifiers: [AnyFontModifier] {
        get {
            self[FontModifiersKey.self]
        }
        set {
            self[FontModifiersKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The current redaction reasons applied to the view hierarchy.
    //@inline(__always)
    public var redactionReasons: RedactionReasons {
        get {
            self[RedactionReasonsKey.self]
        }
        set {
            self[RedactionReasonsKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct SensitiveContentKey: EnvironmentKey {
    
    @inline(__always)
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    //@inline(__always)
    public var sensitiveContent: Bool {
        get {
            self[SensitiveContentKey.self]
        }
        set {
            self[SensitiveContentKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct ShouldRedactContentKey: DerivedEnvironmentKey {
    
    internal typealias Value = SensitiveContentKey.Value
    
    @inline(__always)
    internal static var defaultValue: SensitiveContentKey.Value {
        SensitiveContentKey.defaultValue
    }
    
    internal static func value(in environment: EnvironmentValues) -> Bool {
        let reasons = environment.redactionReasons
        let sensitiveContent = environment.sensitiveContent
        if !sensitiveContent, reasons.contains(.placeholder) {
            return true
        }
        return reasons.contains(.privacy) && sensitiveContent
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var shouldRedactContent: Bool {
        self.findDerived(key: ShouldRedactContentKey.self)
    }
}

@available(iOS 13.0, *)
private struct FontDefinitionKey: EnvironmentKey {
    
    internal typealias Value = FontDefinitionType
    
    @inline(__always)
    internal static var defaultValue: Value { .init(base: DefaultFontDefinition.self) }
}

@available(iOS 13.0, *)
private struct RedactionReasonsKey: EnvironmentKey {
    
    internal typealias Value = RedactionReasons
    
    @inline(__always)
    internal static var defaultValue: RedactionReasons { [] }
}

@available(iOS 13.0, *)
private struct FontModifiersKey: EnvironmentKey {
    
    internal typealias Value = [AnyFontModifier]
    
    @inline(__always)
    internal static var defaultValue: [AnyFontModifier] { [] }
}

@available(iOS 13.0, *)
private struct FontKey: EnvironmentKey {
    
    internal typealias Value = Font?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
private struct BaselineOffsetKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0 }
}

@available(iOS 13.0, *)
private struct TrackingKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0 }
}

@available(iOS 13.0, *)
private struct KerningKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0 }
}

@available(iOS 13.0, *)
private struct PreferredContentSizeCategoryKey: EnvironmentKey {
    
    internal typealias Value = ContentSizeCategory
    
    @inline(__always)
    internal static var defaultValue: Value { .large }
}

@available(iOS 13.0, *)
private struct LayoutDirectionKey : EnvironmentKey {
    
    internal typealias Value = LayoutDirection
    
    @inline(__always)
    internal static var defaultValue: Value { .leftToRight }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The layout direction associated with the current environment.
    ///
    /// Use this value to determine or set whether the environment uses a
    /// left-to-right or right-to-left direction.
    //@inline(__always)
    public var layoutDirection: LayoutDirection {
        get {
            self[LayoutDirectionKey.self]
        }
        set {
            self[LayoutDirectionKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct TextAlignmentKey: EnvironmentKey {
    
    internal typealias Value = TextAlignment
    
    @inline(__always)
    internal static var defaultValue: Value { .leading }
}

@available(iOS 13.0, *)
private struct TruncationModeKey: EnvironmentKey {
    
    internal typealias Value = Text.TruncationMode
    
    @inline(__always)
    internal static var defaultValue: Value { .tail }
}

@available(iOS 13.0, *)
private struct LineSpacingKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0 }
}

@available(iOS 13.0, *)
private struct AllowsTighteningKey: EnvironmentKey {
    
    internal typealias Value = Bool
    
    @inline(__always)
    internal static var defaultValue: Value { false }
}

@available(iOS 13.0, *)
private struct LineLimitKey: EnvironmentKey {
    
    internal typealias Value = Int?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
private struct MinimumScaleFactorKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 1.0 }
}

@available(iOS 13.0, *)
private struct LineHeightMultipleKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
internal struct MaximumLineHeightKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
internal struct MinimumLineHeightKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
private struct HyphenationFactorKey: EnvironmentKey {
    
    internal typealias Value = Float
    
    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
private struct BodyHeadOutdentKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
private struct RestBodyHeadOutdentKey: EnvironmentKey {

    internal typealias Value = CGFloat

    @inline(__always)
    internal static var defaultValue: Value { 0.0 }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// A value that indicates how text instance aligns its lines when the
    /// content wraps or contains newlines.
    ///
    /// Use alignment parameters on a parent view to align ``Text`` with respect
    /// to its parent. Because the horizontal bounds of ``TextField`` never
    /// exceed its graphical extent, this value has little to no effect on
    /// single-line text.
    //@inline(__always)
    public var multilineTextAlignment: TextAlignment {
        get {
            self[TextAlignmentKey.self]
        }
        set {
            self[TextAlignmentKey.self] = newValue
        }
    }
    
    /// A value that indicates how the layout truncates the last line of text to
    /// fit into the available space.
    ///
    /// The default value is ``Text/TruncationMode/tail``. Some controls,
    /// however, might have a different default if appropriate.
    //@inline(__always)
    public var truncationMode: Text.TruncationMode {
        get {
            self[TruncationModeKey.self]
        }
        set {
            self[TruncationModeKey.self] = newValue
        }
    }
    
    /// The distance in points between the bottom of one line fragment and the
    /// top of the next.
    ///
    /// This value is always nonnegative.
    //@inline(__always)
    public var lineSpacing: CGFloat {
        get {
            self[LineSpacingKey.self]
        }
        set {
            self[LineSpacingKey.self] = newValue
        }
    }
    
    /// A Boolean value that indicates whether inter-character spacing should
    /// tighten to fit the text into the available space.
    ///
    /// The default value is `false`.
    //@inline(__always)
    public var allowsTightening: Bool {
        get {
            self[AllowsTighteningKey.self]
        }
        set {
            self[AllowsTighteningKey.self] = newValue
        }
    }
    
    /// The maximum number of lines that text can occupy in a view.
    ///
    /// The maximum number of lines is `1` if the value is less than `1`. If the
    /// value is `nil`, the text uses as many lines as required. The default is
    /// `nil`.
    //@inline(__always)
    public var lineLimit: Int? {
        get {
            self[LineLimitKey.self]
        }
        set {
            guard let value = newValue else {
                self[LineLimitKey.self] = nil
                return
            }
            self[LineLimitKey.self] = max(1, value)
        }
    }
    
    /// The minimum permissible proportion to shrink the font size to fit
    /// the text into the available space.
    ///
    /// In the example below, a label with a `minimumScaleFactor` of `0.5`
    /// draws its text in a font size as small as half of the actual font if
    /// needed to fit into the space next to the text input field:
    ///
    ///     HStack {
    ///         Text("This is a very long label:")
    ///             .lineLimit(1)
    ///             .minimumScaleFactor(0.5)
    ///         TextField("My Long Text Field", text: $myTextField)
    ///             .frame(width: 250, height: 50, alignment: .center)
    ///     }
    ///
    ///
    /// You can set the minimum scale factor to any value greater than `0` and
    /// less than or equal to `1`. The default value is `1`.
    ///
    /// DanceUI uses this value to shrink text that doesn't fit in a view when
    /// it's okay to shrink the text. For example, a label with a
    /// `minimumScaleFactor` of `0.5` draws its text in a font size as small as
    /// half the actual font if needed.
    //@inline(__always)
    public var minimumScaleFactor: CGFloat {
        get {
            self[MinimumScaleFactorKey.self]
        }
        set {
            var minimunScale = newValue
            if _slowPath(!(0.0 < newValue && newValue <= 1.0)) {
                runtimeIssue(type: .warning, "minimumScaleFactor should be in range (0.0, 1.0], provide new value is %02f", newValue)
                minimunScale = min(max(newValue, 0), 1.0)
                if minimunScale == .zero {
                    minimunScale = 1.0
                }
            }
            self[MinimumScaleFactorKey.self] = minimunScale
        }
    }
    
    //@inline(__always)
    public var lineHeightMultiple: CGFloat {
        get {
            self[LineHeightMultipleKey.self]
        }
        set {
            self[LineHeightMultipleKey.self] = newValue
        }
    }
    
    //@inline(__always)
    public var maximumLineHeight: CGFloat {
        get {
            self[MaximumLineHeightKey.self]
        }
        set {
            self[MaximumLineHeightKey.self] = newValue
        }
    }
    
    //@inline(__always)
    public var minimumLineHeight: CGFloat {
        get {
            self[MinimumLineHeightKey.self]
        }
        set {
            self[MinimumLineHeightKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var hyphenationFactor: Float {
        get {
            self[HyphenationFactorKey.self]
        }
        set {
            self[HyphenationFactorKey.self] = newValue
        }
    }
    
    @inline(__always)
    @_spi(DanceUICompose)
    public var bodyHeadOutdent: CGFloat {
        get {
            self[BodyHeadOutdentKey.self]
        }
        set {
            self[BodyHeadOutdentKey.self] = newValue
        }
    }

    @inline(__always)
    @_spi(DanceUICompose)
    public var restBodyHeadOutdent: CGFloat {
        get {
            self[RestBodyHeadOutdentKey.self]
        }
        set {
            self[RestBodyHeadOutdentKey.self] = newValue
        }
    }

    private struct DisplayMode: EnvironmentKey {
        
        @inline(__always)
        static var defaultValue: UISplitViewController.DisplayMode? {
            nil
        }
        
    }
    
    //@inline(__always)
    public var displayMode: UISplitViewController.DisplayMode? {
        get {
            self[DisplayMode.self]
        }
        set {
            self[DisplayMode.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct DisplayScaleKey: EnvironmentKey {
    
    internal typealias Value = CGFloat
    
    @inline(__always)
    internal static var defaultValue: Value { UIScreen.main.scale }
}

@available(iOS 13.0, *)
private struct LocaleKey: EnvironmentKey {
    
    internal typealias Value = Locale
    
    @inline(__always)
    internal static var defaultValue: Value { Locale.current }
}

@available(iOS 13.0, *)
private struct CalendarKey: EnvironmentKey {
    
    internal typealias Value = Calendar
    
    @inline(__always)
    internal static var defaultValue: Value { Calendar.current }
}

@available(iOS 13.0, *)
private struct TimeZoneKey: EnvironmentKey {
    
    internal typealias Value = TimeZone
    
    @inline(__always)
    internal static var defaultValue: Value { TimeZone.current }
}

@available(iOS 13.0, *)
private struct ColorSchemeKey: EnvironmentKey {
    
    internal typealias Value = ColorScheme
    
    @inline(__always)
    internal static var defaultValue: Value { .light }
}

/// A key for specifying the preferred color scheme.
///
/// Don't use this key directly. Instead, set a preferred color scheme for a
/// view using the ``View/preferredColorScheme(_:)`` view modifier. Get the
/// current color scheme for a view by accessing the
/// ``EnvironmentValues/colorScheme`` value.
@available(iOS 13.0, *)
public struct PreferredColorSchemeKey: HostPreferenceKey {
    
    /// The type of value produced by this preference.
    public typealias Value = ColorScheme?
    
    /// Combines a sequence of values by modifying the previously-accumulated
    /// value with the result of a closure that provides the next value.
    ///
    /// This method receives its values in view-tree order. Conceptually, this
    /// combines the preference value from one tree with that of its next
    /// sibling.
    ///
    /// - Parameters:
    ///   - value: The value accumulated through previous calls to this method.
    ///     The implementation should modify this value.
    ///   - nextValue: A closure that returns the next value in the sequence.
    public static func reduce(value: inout Value, nextValue: () -> Value) {
        
        if value == nil {
            value = nextValue()
        }
    }
}

@available(iOS 13.0, *)
private struct ColorSchemeContrastKey: EnvironmentKey {
    
    internal typealias Value = ColorSchemeContrast
    
    @inline(__always)
    internal static var defaultValue: Value { .standard }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The Text baseline offset of this environment.
    @inline(__always)
    internal var baselineOffset: CGFloat {
        get {
            self[BaselineOffsetKey.self]
        }
        set {
            self[BaselineOffsetKey.self] = newValue
        }
    }
    
    /// The Text tracking of this environment.
    @inline(__always)
    internal var tracking: CGFloat {
        get {
            self[TrackingKey.self]
        }
        set {
            self[TrackingKey.self] = newValue
        }
    }
    
    /// The Text kerning of this environment.
    @inline(__always)
    internal var kerning: CGFloat {
        get {
            self[KerningKey.self]
        }
        set {
            self[KerningKey.self] = newValue
        }
    }
    
    /// The default font of this environment.
    //@inline(__always)
    public var font: Font? {
        get {
            self[FontKey.self]
        }
        set {
            self[FontKey.self] = newValue
        }
    }
    
    /// The display scale of this environment.
    //@inline(__always)
    public var displayScale: CGFloat {
        get {
            self[DisplayScaleKey.self]
        }
        set {
            self[DisplayScaleKey.self] = newValue
        }
    }
    
    /// The image scale for this environment.
    //    public var imageScale: Image.Scale
    
    /// The size of a pixel on the screen.
    ///
    /// This value is usually equal to `1` divided by
    /// ``EnvironmentValues/displayScale``.
    //@inline(__always)
    public var pixelLength: CGFloat {
        1 / displayScale
    }
    
    
    /// The current locale that views should use.
    public var locale: Locale {
        get {
            self[LocaleKey.self]
        }
        set {
            self[LocaleKey.self] = newValue
        }
    }
    
    /// The current calendar that views should use when handling dates.
    public var calendar: Calendar {
        get {
            self[CalendarKey.self]
        }
        set {
            self[CalendarKey.self] = newValue
        }
    }
    
    /// The current time zone that views should use when handling dates.
    public var timeZone: TimeZone {
        get {
            self[TimeZoneKey.self]
        }
        set {
            self[TimeZoneKey.self] = newValue
        }
    }
    
    /// The color scheme of this environment.
    ///
    /// Read this environment value from within a view to find out if DanceUI
    /// is currently displaying the view using the ``ColorScheme/light`` or
    /// ``ColorScheme/dark`` appearance. The value that you receive depends on
    /// whether the user has enabled Dark Mode, possibly superseded by
    /// the configuration of the current presentation's view hierarchy.
    ///
    ///     @Environment(\.colorScheme) private var colorScheme
    ///
    ///     var body: some View {
    ///         Text(colorScheme == .dark ? "Dark" : "Light")
    ///     }
    ///
    /// You can set the `colorScheme` environment value directly,
    /// but that usually isn't what you want. Doing so changes the color
    /// scheme of the given view and its child views but *not* the views
    /// above it in the view hierarchy. Instead, set a color scheme using the
    /// ``View/preferredColorScheme(_:)`` modifier, which also propagates the
    /// value up through the view hierarchy to the enclosing presentation, like
    /// a sheet or a window.
    ///
    /// When adjusting your app's user interface to match the color scheme,
    /// consider also checking the ``EnvironmentValues/colorSchemeContrast``
    /// property, which reflects a system-wide contrast setting that the user
    /// controls. For information about using color and contrast in your app,
    /// see [Color and Contrast](https://developer.apple.com/design/human-interface-guidelines/accessibility/overview/color-and-contrast/).
    ///
    /// > Note: If you only need to provide different colors or
    /// images for different color scheme and contrast settings, do that in
    /// your app's Asset Catalog. See
    /// [Asset-Management](https://developer.apple.com/documentation/Xcode/Asset-Management)
    //@inline(__always)
    public var colorScheme: ColorScheme {
        get {
            self[ColorSchemeKey.self]
        }
        set {
            self[ColorSchemeKey.self] = newValue
        }
    }
    
    /// The contrast associated with the color scheme of this environment.
    ///
    /// Read this environment value from within a view to find out if DanceUI
    /// is currently displaying the view using ``ColorSchemeContrast/standard``
    /// or ``ColorSchemeContrast/increased`` contrast. The value that you read
    /// depends entirely on user settings, and you can't change it.
    ///
    ///     @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    ///
    ///     var body: some View {
    ///         Text(colorSchemeContrast == .standard ? "Standard" : "Increased")
    ///     }
    ///
    /// When adjusting your app's user interface to match the contrast,
    /// consider also checking the ``EnvironmentValues/colorScheme`` property
    /// to find out if DanceUI is displaying the view with a light or dark
    /// appearance. For information about using color and contrast in your app,
    /// see [Color and Contrast](https://developer.apple.com/design/human-interface-guidelines/accessibility/overview/color-and-contrast/).
    ///
    /// > Note: If you only need to provide different colors or
    /// images for different color scheme and contrast settings, do that in
    /// your app's Asset Catalog. See
    /// [Asset-Management](https://developer.apple.com/documentation/Xcode/Asset-Management)
    //@inline(__always)
    public var colorSchemeContrast: ColorSchemeContrast {
        get {
            self[ColorSchemeContrastKey.self]
        }
        set {
            self[ColorSchemeContrastKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct DefaultFontKey: EnvironmentKey {
    internal typealias Value = Font?

    @inline(__always)
    internal static var defaultValue: Font? { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    @inline(__always)
    internal var defaultFont: Font? {
        get {
            self[DefaultFontKey.self]
        }
        set {
            self[DefaultFontKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct FontContextKey: DerivedEnvironmentKey {
    
    internal static var defaultValue: Font.Context {
        Font.Context(sizeCategory: PreferredContentSizeCategoryKey.defaultValue,
                     legibilityWeight: LegibilityWeightKey.defaultValue,
                     fontDefinition: FontDefinitionKey.defaultValue)
    }
    
    internal typealias Value = Font.Context
    
    @inline(__always)
    internal static func value(in environment: EnvironmentValues) -> Font.Context {
        Font.Context(sizeCategory: environment.preferredContentSizeCategory,
                     legibilityWeight: environment.legibilityWeight,
                     fontDefinition: .init(base: environment.fontDefinition))
    }
}

@available(iOS 13.0, *)
private struct EffectiveFontKey: DerivedEnvironmentKey {

    internal static var defaultValue: Font { .body }

    internal typealias Value = Font

    @inline(__always)
    internal static func value(in environment: EnvironmentValues) -> Font {
        environment.font ?? environment.defaultFont ?? .body
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var effectiveFont: Font {
        findDerived(key: EffectiveFontKey.self)
    }
}

@available(iOS 13.0, *)
private struct ExplicitPreferredColorSchemeKey: EnvironmentKey {
    
    fileprivate typealias Value = ColorScheme?

    @inline(__always)
    fileprivate static var defaultValue: ColorScheme? { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var explicitPreferredColorScheme: ColorScheme? {
        get {
            self[ExplicitPreferredColorSchemeKey.self]
        }
        set {
            self[ExplicitPreferredColorSchemeKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @usableFromInline
    internal var foregroundColor: Color? {
        get {
            self.foregroundStyle?.fallbackColor(in: self)
        }
        set {
            self.foregroundStyle = newValue.map({ AnyShapeStyle($0) })
        }
    }
}

@available(iOS 13.0, *)
private struct BackgroundColorKey: EnvironmentKey {
    
    internal typealias Value = Color?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var backgroundColor: Color? {
        get {
            self[BackgroundColorKey.self]
        }
        set {
            self[BackgroundColorKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct AccentColorKey: EnvironmentKey {
    
    internal typealias Value = Color?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @usableFromInline
    internal var accentColor: Color? {
        get {
            self[AccentColorKey.self]
        }
        set {
            let safeAccentColor: Color?
            if newValue == .accentColor {
                safeAccentColor = nil
            } else {
                safeAccentColor = newValue
            }
            self[AccentColorKey.self] = safeAccentColor
        }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    @inline(__always)
    internal var defaultForegroundColor: Color? {
        get {
            self.defaultForegroundStyle?.fallbackColor(in: self)
        }
        set {
            self.defaultForegroundStyle = newValue.map({ AnyShapeStyle($0) })
        }
    }
}

@available(iOS 13.0, *)
private struct DefaultBackgroundColorKey: EnvironmentKey {
    
    typealias Value = Color?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    @inline(__always)
    internal var defaultBackgroundColor: Color? {
        get {
            self[DefaultBackgroundColorKey.self]
        }
        set {
            self[DefaultBackgroundColorKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct DefaultPaddingKey: EnvironmentKey {
    
    internal typealias Value = EdgeInsets
    
    @inline(__always)
    internal static var defaultValue: Value {
        .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    var defaultPadding: EdgeInsets {
        get {
            self[DefaultPaddingKey.self]
        }
        set {
            self[DefaultPaddingKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct TintAdjustmentModeKey: EnvironmentKey {
    
    internal typealias Value = TintAdjustmentMode?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    var tintAdjustmentMode: TintAdjustmentMode? {
        get {
            self[TintAdjustmentModeKey.self]
        }
        set {
            self[TintAdjustmentModeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct EditModeKey: EnvironmentKey {
    
    internal typealias Value = Binding<EditMode>?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// An indication of whether the user can edit the contents of a view
    /// associated with this environment.
    ///
    /// Read this environment value to receive a optional binding to the
    /// edit mode state. The binding contains an ``EditMode`` value
    /// that indicates whether edit mode is active, and that you can use to
    /// change the mode. To learn how to read an environment
    /// value, see ``EnvironmentValues``.
    ///
    /// Certain built-in views automatically alter their appearance and behavior
    /// in edit mode. For example, a ``List`` with a ``ForEach`` that's
    /// configured with the ``DynamicViewContent/onDelete(perform:)`` or
    /// ``DynamicViewContent/onMove(perform:)`` modifier provides controls to
    /// delete or move list items while in edit mode. On devices without an
    /// attached keyboard and mouse or trackpad, people can make multiple
    /// selections in lists only when edit mode is active.
    ///
    /// You can also customize your own views to react to edit mode.
    /// The following example replaces a read-only ``Text`` view with
    /// an editable ``TextField``, checking for edit mode by
    /// testing the wrapped value's ``EditMode/isEditing`` property:
    ///
    ///     @Environment(\.editMode) private var editMode
    ///     @State private var name = "Maria Ruiz"
    ///
    ///     var body: some View {
    ///         Form {
    ///             if editMode?.wrappedValue.isEditing == true {
    ///                 TextField("Name", text: $name)
    ///             } else {
    ///                 Text(name)
    ///             }
    ///         }
    ///         .animation(nil, value: editMode?.wrappedValue)
    ///         .toolbar { // Assumes embedding this view in a NavigationView.
    ///             EditButton()
    ///         }
    ///     }
    ///
    /// You can set the edit mode through the binding, or you can
    /// rely on an ``EditButton`` to do that for you, as the example above
    /// demonstrates. The button activates edit mode when the user
    /// taps the Edit button, and disables editing mode when the user taps Done.
    //@inline(__always)
    public var editMode: Binding<EditMode>? {
        get {
            self[EditModeKey.self]
        }
        set {
            self[EditModeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct DefaultRenderingModeKey: EnvironmentKey {
    
    internal typealias Value = Image.TemplateRenderingMode
    
    @inline(__always)
    internal static var defaultValue: Value { .original }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    //@inline(__always)
    public var defaultRenderingMode: Image.TemplateRenderingMode {
        get {
            self[DefaultRenderingModeKey.self]
        }
        set {
            self[DefaultRenderingModeKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    internal func imageMaskColor(renderingMode: Image.TemplateRenderingMode?) -> Color.Resolved? {
        let mode = renderingMode ?? defaultRenderingMode
        switch mode {
        case .template:
            return Color.foreground.resolvePaint(in: self)
        default:
            return nil
        }
    }
}

@available(iOS 13.0, *)
private struct TextCaseKey: EnvironmentKey {
    
    internal typealias Value = Text.Case?
    
    @inline(__always)
    internal static var defaultValue: Text.Case? { nil }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// A stylistic override to transform the case of `Text` when displayed,
    /// using the environment's locale.
    ///
    /// The default value is `nil`, displaying the `Text` without any case
    /// changes.
    //@inline(__always)
    public var textCase: Text.Case? {
        get {
            self[TextCaseKey.self]
        }
        set {
            self[TextCaseKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct UndoManagerKey: EnvironmentKey {
    
    internal typealias Value = UndoManager?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var undoManager: UndoManager? {
        get {
            self[UndoManagerKey.self]
        }
        set {
            self[UndoManagerKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
internal enum DisplayGamut: Int {
    
    case sRGB
    
    case displayP3
    
}

#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 13.0, *)
extension DisplayGamut {
    
    internal init?(_ uiDisplayGamut: UIDisplayGamut) {
        switch uiDisplayGamut {
        case .P3:       self = .displayP3
        case .SRGB:     self = .sRGB
        default:        return nil
        }
    }
    
}

@available(iOS 13.0, *)
extension UIDisplayGamut {
    
    internal init(_ displayGamut: DisplayGamut) {
        switch displayGamut {
        case .displayP3:    self = .P3
        case .sRGB:         self = .SRGB
        }
    }
    
}

#endif
@available(iOS 13.0, *)
private struct DisplayGamutKey: EnvironmentKey {
    
    internal typealias Value = DisplayGamut
    
    @inline(__always)
    internal static var defaultValue: Value { .sRGB }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var displayGamut: DisplayGamut {
        get {
            self[DisplayGamutKey.self]
        }
        set {
            self[DisplayGamutKey.self] = newValue
        }
    }
}

/// A set of values that indicate the visual size available to the view.
///
/// You receive a size class value when you read either the
/// ``EnvironmentValues/horizontalSizeClass`` or
/// ``EnvironmentValues/verticalSizeClass`` environment value. The value tells
/// you about the amount of space available to your views in a given
/// direction. You can read the size class like any other of the
/// ``EnvironmentValues``, by creating a property with the ``Environment``
/// property wrapper:
///
///     @Environment(\.horizontalSizeClass) private var horizontalSizeClass
///     @Environment(\.verticalSizeClass) private var verticalSizeClass
///
/// DanceUI sets the size class based on several factors, including:
///
/// * The current device type.
/// * The orientation of the device.
/// * The appearance of Slide Over and Split View on iPad.
///
/// Several built-in views change their behavior based on the size class.
/// For example, a ``NavigationView`` presents a multicolumn view when
/// the horizontal size class is ``UserInterfaceSizeClass/regular``,
/// but a single column otherwise. You can also adjust the appearance of
/// custom views by reading the size class and conditioning your views.
/// If you do, be prepared to handle size class changes while
/// your app runs, because factors like device orientation can change at
/// runtime.
@available(iOS 13.0, *)
public enum UserInterfaceSizeClass {
    
    /// The compact size class.
    case compact
    
    /// The regular size class.
    case regular
    
}

#if os(iOS) || os(tvOS)
import UIKit

@available(iOS 13.0, *)
extension UserInterfaceSizeClass {
    
    /// Creates a DanceUI size class from the specified UIKit size class.
    public init?(_ uiUserInterfaceSizeClass: UIUserInterfaceSizeClass) {
        switch uiUserInterfaceSizeClass {
        case .compact:  self = .compact
        case .regular:  self = .regular
        default:        return nil
        }
    }
    
}

@available(iOS 13.0, *)
extension UIUserInterfaceSizeClass {
    
    /// Creates a UIKit size class from the specified DanceUI size class.
    public init(_ sizeClass: UserInterfaceSizeClass?) {
        switch sizeClass {
        case .some(.compact):   self = .compact
        case .some(.regular):   self = .regular
        case .none:             self = .unspecified
        }
    }
    
}

#endif
@available(iOS 13.0, *)
private struct HorizontalUserInterfaceSizeClassKey: EnvironmentKey {
    
    internal typealias Value = UserInterfaceSizeClass?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The horizontal size class of this environment.
    ///
    /// You receive a ``UserInterfaceSizeClass`` value when you read this
    /// environment value. The value tells you about the amount of horizontal
    /// space available to the view that reads it. You can read this
    /// size class like any other of the ``EnvironmentValues``, by creating a
    /// property with the ``Environment`` property wrapper:
    ///
    ///     @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    ///
    /// DanceUI sets this size class based on several factors, including:
    ///
    /// * The current device type.
    /// * The orientation of the device.
    /// * The appearance of Slide Over and Split View on iPad.
    ///
    /// Several built-in views change their behavior based on this size class.
    /// For example, a ``NavigationView`` presents a multicolumn view when
    /// the horizontal size class is ``UserInterfaceSizeClass/regular``,
    /// but a single column otherwise. You can also adjust the appearance of
    /// custom views by reading the size class and conditioning your views.
    /// If you do, be prepared to handle size class changes while
    /// your app runs, because factors like device orientation can change at
    /// runtime.
    //@inline(__always)
    public var horizontalSizeClass: UserInterfaceSizeClass? {
        get {
            self[HorizontalUserInterfaceSizeClassKey.self]
        }
        set {
            self[HorizontalUserInterfaceSizeClassKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct VerticalUserInterfaceSizeClassKey: EnvironmentKey {
    
    internal typealias Value = UserInterfaceSizeClass?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The vertical size class of this environment.
    ///
    /// You receive a ``UserInterfaceSizeClass`` value when you read this
    /// environment value. The value tells you about the amount of vertical
    /// space available to the view that reads it. You can read this
    /// size class like any other of the ``EnvironmentValues``, by creating a
    /// property with the ``Environment`` property wrapper:
    ///
    ///     @Environment(\.verticalSizeClass) private var verticalSizeClass
    ///
    /// DanceUI sets this size class based on several factors, including:
    ///
    /// * The current device type.
    /// * The orientation of the device.
    ///
    /// You can adjust the appearance of custom views by reading this size
    /// class and conditioning your views. If you do, be prepared to
    /// handle size class changes while your app runs, because factors like
    /// device orientation can change at runtime.
    //@inline(__always)
    public var verticalSizeClass: UserInterfaceSizeClass? {
        get {
            self[VerticalUserInterfaceSizeClassKey.self]
        }
        set {
            self[VerticalUserInterfaceSizeClassKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
internal struct BackgroundInfo {
    
    internal var layer: Int
    
    internal var groupCount: Int
    
}

@available(iOS 13.0, *)
private struct BackgroundInfoKey: EnvironmentKey {
    
    internal typealias Value = BackgroundInfo
    
    @inline(__always)
    internal static var defaultValue: Value { BackgroundInfo(layer: 0, groupCount: 0) }
    
}

@available(iOS 13.0, *)
internal enum BackgroundContext: Int, CaseIterable {
    
    case normal
    
    case grouped
}

@available(iOS 13.0, *)
private struct BackgroundContextKey: EnvironmentKey {
    
    internal typealias Value = BackgroundContext
    
    @inline(__always)
    internal static var defaultValue: Value { .normal }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var backgroundInfo: BackgroundInfo {
        get {
            self[BackgroundInfoKey.self]
        }
        set {
            self[BackgroundInfoKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var backgroundContext: BackgroundContext {
        get {
            self[BackgroundContextKey.self]
        }
        set {
            self[BackgroundContextKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var underlineStyle: Text.LineStyle? {
        get {
            self[UnderlineStyleKey.self]
        }
        set {
            self[UnderlineStyleKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var strikethroughStyle: Text.LineStyle? {
        get {
            self[StrikethroughStyleKey.self]
        }
        set {
            self[StrikethroughStyleKey.self] = newValue
        }
    }
    
    /// The default font of this environment.
    @inline(__always)
    internal var defaultUnderlineStyle: Text.LineStyle? {
        get {
            self[DefaultUnderlineStyleKey.self]
        }
        set {
            self[DefaultUnderlineStyleKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct DefaultUnderlineStyleKey: EnvironmentKey {
    
    @inline(__always)
    fileprivate static var defaultValue: Text.LineStyle? {
        nil
    }
    
}

@available(iOS 13.0, *)
private struct UnderlineStyleKey: EnvironmentKey {
    
    internal typealias Value = Text.LineStyle?
    
    @inline(__always)
    fileprivate static var defaultValue: Text.LineStyle? {
        nil
    }
}

@available(iOS 13.0, *)
private struct StrikethroughStyleKey: EnvironmentKey {
    
    internal typealias Value = Text.LineStyle?
    
    @inline(__always)
    fileprivate static var defaultValue: Text.LineStyle? {
        nil
    }
}

@available(iOS 13.0, *)
private struct SliderStyleKey : EnvironmentKey {
    
    internal typealias Value = AnySliderStyle
    
    internal static let defaultValue: AnySliderStyle = AnySliderStyle.default
}

@available(iOS 13.0, *)
private struct ListRowInsetsKey: EnvironmentKey {
    
    @inline(__always)
    internal static var defaultValue: EdgeInsets {
        .zero
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var sliderStyle: AnySliderStyle {
        get {
            self[SliderStyleKey.self]
        }
        set {
            self[SliderStyleKey.self] = newValue
        }
    }
    
    @available(iOS 13.0, *)   @inline(__always)
    internal var sceneSession: UISceneSession? {
        get {
            self[SceneSessionKey.self]
        }
        set {
            self[SceneSessionKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var isSplitViewExpended: Bool {
        get {
            self[ExpandedSplitViewKey.self]
        }
        set {
            self[ExpandedSplitViewKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var listRowInsets: EdgeInsets {
        get {
            self[ListRowInsetsKey.self]
        }
        set {
            self[ListRowInsetsKey.self] = newValue
        }
    }
    
    @inline(__always)
    internal var separatorThickness: CGFloat {
        
        switch preferredContentSizeCategory {
        case .extraSmall,
                .small,
                .medium,
                .large,
                .extraLarge,
                .extraExtraLarge,
                .extraExtraExtraLarge:
            let displayScale = self.displayScale
            if displayScale > 0 {
                return 1 / displayScale
            }
            return 1
        default:
            return 1
        }
    }
    
    @inline(__always)
    internal var openSensitiveURL: OpenURLAction {
        get {
            self[OpenSensitiveURLActionKey.self]
        }
        set {
            self[OpenSensitiveURLActionKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct SceneSessionKey: EnvironmentKey {
    
    internal typealias Value = UISceneSession?
    
    @inline(__always)
    internal static var defaultValue: UISceneSession? { nil }
    
}

@available(iOS 13.0, *)
private struct OpenSensitiveURLActionKey: EnvironmentKey {
    
    internal typealias Value = OpenURLAction
    
    @inline(__always)
    internal static var defaultValue: OpenURLAction {
        OpenURLAction(handler: {_ , _ in }, isDefault: true)
    }
    
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The size to apply to controls within a view.
    ///
    /// The default is ``ControlSize/regular``.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public var controlSize: ControlSize {
        get {
            self[ControlSizeKey.self]
        }
        set {
            self[ControlSizeKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct ControlSizeKey: EnvironmentKey {
    
    fileprivate typealias Value = ControlSize
    
    @inline(__always)
    fileprivate static var defaultValue: Value {
        .regular
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The keyboard shortcut that buttons in this environment will be triggered
    /// with.
    ///
    /// This is particularly useful in button styles when a button's appearance
    /// depends on the shortcut associated with it. On macOS, for example, when
    /// a button is bound to the Return key, it is typically drawn with a
    /// special emphasis. This happens automatically when using the built-in
    /// button styles, and can be implemented manually in custom styles using
    /// this environment key:
    ///
    ///     private struct MyButtonStyle: ButtonStyle {
    ///         @Environment(\.keyboardShortcut)
    ///         private var shortcut: KeyboardShortcut?
    ///
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             let labelFont = Font.body
    ///                 .weight(shortcut == .defaultAction ? .bold : .regular)
    ///             configuration.label
    ///                 .font(labelFont)
    ///         }
    ///     }
    ///
    /// If no keyboard shortcut has been applied to the view or its ancestor,
    /// then the environment value will be `nil`.
    public var keyboardShortcut: KeyboardShortcut? {
        get {
            self[ButtonKeyboardShortcutKey.self]
        }
        set {
            self[ButtonKeyboardShortcutKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct ButtonKeyboardShortcutKey: EnvironmentKey {
    
    fileprivate typealias Value = KeyboardShortcut?
    
    @inline(__always)
    fileprivate static var defaultValue: Value {
        nil
    }
}

@available(iOS 13.0, *)
private struct ExpandedSplitViewKey: EnvironmentKey {
    
    @inline(__always)
    static var defaultValue: Bool {
        true
    }
}

@available(iOS 13.0, *)
private struct EnvironmentFetch<Member>: Rule, Equatable, Hashable {
    
    internal typealias Value = Member
    
    @Attribute
    internal var environment: EnvironmentValues
    
    internal var keyPath: KeyPath<EnvironmentValues, Member>
    
    internal var value: Value {
        environment[keyPath: keyPath]
    }
    
    internal func hash(into hasher: inout Hasher) {
        hasher.combine($environment.identifier)
        hasher.combine(keyPath)
    }
    
}

@available(iOS 13.0, *)
extension Attribute where Value == EnvironmentValues {
    
    @inline(__always)
    internal func value<Member>(_ keyPath: KeyPath<EnvironmentValues, Member>,
                                _ owner: DGAttribute) -> Member {
        let fetch = EnvironmentFetch(environment: self, keyPath: keyPath)
        return fetch.cachedValue(.withoutPrefetching, owner: owner)
    }
    
}

@available(iOS 13.0, *)
// MARK: - FocusState

extension EnvironmentValues {
    
    @inline(__always)
    internal var focusScopes: [Namespace.ID] {
        get {
            self[FocusScopesKey.self]
        }
        set {
            self[FocusScopesKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct FocusScopesKey: EnvironmentKey {
    
    fileprivate typealias Value = [Namespace.ID]
    
    @inline(__always)
    fileprivate static var defaultValue: Value {
        []
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var focusGroupID: FocusGroupID? {
        get { self[FocusGroupIDKey.self] }
        set { self[FocusGroupIDKey.self] = newValue }
    }
    
}

@available(iOS 13.0, *)
private struct FocusGroupIDKey: EnvironmentKey {
    
    fileprivate typealias Value = FocusGroupID?
    
    @inline(__always)
    fileprivate static var defaultValue: Value {
        nil
    }
    
}

@available(iOS 13.0, *)
private struct IsPlatformFocusSystemEnabledKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Bool {
        false
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var isPlatformFocusSystemEnabled: Bool {
        get {
            self[IsPlatformFocusSystemEnabledKey.self]
        }
        set {
            self[IsPlatformFocusSystemEnabledKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var focusBridge: FocusBridge? {
        get {
            self[FocusBridgeKey.self].base
        }
        set {
            self[FocusBridgeKey.self].base = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct FocusBridgeKey: EnvironmentKey {
    
    fileprivate typealias Value = WeakBox<FocusBridge>
    
    @inline(__always)
    fileprivate static var defaultValue: Value {
        WeakBox<FocusBridge>(base: nil)
    }
    
}

@available(iOS 13.0, *)
private struct IsFocusedKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Bool {
        false
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// Returns whether the nearest focusable ancestor has focus.
    ///
    /// If there is no focusable ancestor, the value is `false`.
    public var isFocused: Bool {
        get {
            self[IsFocusedKey.self]
        }
        set {
            self[IsFocusedKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct CanTakeFocusKey: EnvironmentKey {
    
    fileprivate typealias Value = Bool
    
    @inline(__always)
    fileprivate static var defaultValue: Bool {
        false
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    @inline(__always)
    internal var canTakeFocus: Bool {
        get {
            self[CanTakeFocusKey.self]
        }
        set {
            self[CanTakeFocusKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct DynamicTypeSizeKey: EnvironmentKey {

    fileprivate typealias Value = ContentSizeCategory

    @inline(__always)
    fileprivate static var defaultValue: Value {
        .large
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    /// rename to dynamicTypeSize
    public var sizeCategory: ContentSizeCategory {
        get {
            self[DynamicTypeSizeKey.self]
        }
        set {
            self[DynamicTypeSizeKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct EffectiveLabelStyleKey: EnvironmentKey {
    
    fileprivate typealias Value = EffectiveLabelStyle?
    
    @inline(__always)
    fileprivate static var defaultValue: EffectiveLabelStyle? { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    internal var effectiveLabelStyle: EffectiveLabelStyle? {
        get {
            self[EffectiveLabelStyleKey.self]
        }
        set {
            self[EffectiveLabelStyleKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
private struct TintColorKey: EnvironmentKey {
    
    fileprivate typealias Value = Color?
    
    @inline(__always)
    fileprivate static var defaultValue: Color? { nil }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    internal var tintColor: Color? {
        get {
            self[TintColorKey.self]
        }
        set {
            self[TintColorKey.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    fileprivate struct PlacehodlerColor: EnvironmentKey {
        
        fileprivate typealias Value = Color?
        
        @inline(__always)
        fileprivate static var defaultValue: Value { nil }
        
    }
    
    public var placeholderColor: Color? {
        get {
            self[PlacehodlerColor.self]
        }
        set {
            self[PlacehodlerColor.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension EnvironmentValues {

    fileprivate struct ScenePhaseKey: EnvironmentKey {
        
        fileprivate typealias Value = ScenePhase
        
        @inline(__always)
        fileprivate static var defaultValue: Value {
            .background
        }
        
    }
    
    public var scenePhase: ScenePhase {
        get {
            self[ScenePhaseKey.self]
        }
        set {
            self[ScenePhaseKey.self] = newValue
        }
    }
}


@frozen
public enum ScenePhase: Comparable, Hashable {

  case background

  case inactive

  case active


}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    private struct SubmitLabelKey: EnvironmentKey {
        
        fileprivate typealias Value = SubmitLabel
        
        @inline(__always)
        fileprivate static var defaultValue: Value {
            .`return`
        }
        
    }
    
    @inline(__always)
    internal var submitLabel: SubmitLabel {
        get {
            self[SubmitLabelKey.self]
        }
        set {
            self[SubmitLabelKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
extension EnvironmentValues {
    
    /// The font weight to apply to text.
    ///
    /// This value reflects the value of the Bold Text display setting found in
    /// the Accessibility settings.
    public var legibilityWeight: LegibilityWeight? {
        get {
            self[LegibilityWeightKey.self]
        }
        set {
            self[LegibilityWeightKey.self] = newValue
        }
    }
    
}

@available(iOS 13.0, *)
private struct LegibilityWeightKey: EnvironmentKey {
    
    internal typealias Value = LegibilityWeight?
    
    @inline(__always)
    internal static var defaultValue: Value { nil }
}

