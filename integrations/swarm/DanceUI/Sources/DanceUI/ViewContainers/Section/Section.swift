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

/// A container view that you can use to add hierarchy to certain collection views.
///
/// Use `Section` instances in views like ``List``, ``Picker``, and
/// ``Form`` to organize content into separate sections. Each section has
/// custom content that you provide on a per-instance basis. You can also
/// provide headers and footers for each section.
@available(iOS 13.0, *)
public struct Section<Parent, Content, Footer> {
    
    internal var header: Parent
    
    internal var content: Content
    
    internal var footer: Footer
}

@available(iOS 13.0, *)
extension Section: PrimitiveView where Parent : View, Content : View, Footer : View {
    
}

@available(iOS 13.0, *)
extension Section: PubliclyPrimitiveView where Parent : View, Content : View, Footer : View {
    
    
    internal var internalBody: some View {
        ResolvedSectionStyle(configuration: SectionStyleConfiguration(header: SectionStyleConfiguration.Header(), footer: SectionStyleConfiguration.Footer(), content: SectionStyleConfiguration.Content()))
            .viewAlias(SectionStyleConfiguration.Header.self) {
                header
            }
            .viewAlias(SectionStyleConfiguration.Footer.self) {
                footer
            }
            .viewAlias(SectionStyleConfiguration.Content.self) {
                content
            }
        
    }
    
    public static func _viewListCount(inputs: _ViewListCountInputs) -> Int? {
        nil
    }
}

@available(iOS 13.0, *)
extension Section : View where Parent : View, Content : View, Footer : View {
    

    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never
}

@available(iOS 13.0, *)
extension Section where Parent : View, Content : View, Footer : View  {

    /// Creates a section with a header, footer, and the provided section
    /// content.
    ///
    /// - Parameters:
    ///   - content: The section's content.
    ///   - header: A view to use as the section's header.
    ///   - footer: A view to use as the section's footer.
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent, @ViewBuilder footer: () -> Footer) {
        self.header = header()
        self.content = content()
        self.footer = footer()
    }
}

@available(iOS 13.0, *)
extension Section where Parent == EmptyView, Content : View, Footer : View {

    /// Creates a section with a footer and the provided section content.
    /// - Parameters:
    ///   - content: The section's content.
    ///   - footer: A view to use as the section's footer.
    public init(@ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.header = EmptyView()
        self.content = content()
        self.footer = footer()
    }
}

@available(iOS 13.0, *)
extension Section where Parent : View, Content : View, Footer == EmptyView {

    /// Creates a section with a header and the provided section content.
    /// - Parameters:
    ///   - content: The section's content.
    ///   - header: A view to use as the section's header.
    public init(@ViewBuilder content: () -> Content, @ViewBuilder header: () -> Parent) {
        self.header = header()
        self.content = content()
        self.footer = EmptyView()
    }
}

@available(iOS 13.0, *)
extension Section where Parent == EmptyView, Content : View, Footer == EmptyView {

    /// Creates a section with the provided section content.
    /// - Parameters:
    ///   - content: The section's content.
    public init(@ViewBuilder content: () -> Content) {
        self.header = EmptyView()
        self.content = content()
        self.footer = EmptyView()
    }
}

@available(iOS 13.0, *)
extension Section where Parent == Text, Content : View, Footer == EmptyView {

    /// Creates a section with the provided section content.
    /// - Parameters:
    ///   - titleKey: The key for the section's localized title, which describes
    ///     the contents of the section.
    ///   - content: The section's content.
    public init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.header = Text(titleKey)
        self.content = content()
        self.footer = EmptyView()
    }

    /// Creates a section with the provided section content.
    /// - Parameters:
    ///   - title: A string that describes the contents of the section.
    ///   - content: The section's content.
    @_disfavoredOverload
    public init<S>(_ title: S, @ViewBuilder content: () -> Content) where S : StringProtocol {
        self.header = Text(title)
        self.content = content()
        self.footer = EmptyView()
    }
}

@available(iOS 13.0, *)
extension Section where Parent : View, Content : View, Footer : View {

    /// Creates a section with a header, footer, and the provided section content.
    /// - Parameters:
    ///   - header: A view to use as the section's header.
    ///   - footer: A view to use as the section's footer.
    ///   - content: The section's content.
    @available(iOS, deprecated: 100000.0, renamed: "Section(content:header:footer:)")
    @available(macOS, deprecated: 100000.0, renamed: "Section(content:header:footer:)")
    @available(tvOS, deprecated: 100000.0, renamed: "Section(content:header:footer:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Section(content:header:footer:)")
    public init(header: Parent, footer: Footer, @ViewBuilder content: () -> Content) {
        self.header = header
        self.footer = footer
        self.content = content()
    }
}

@available(iOS 13.0, *)
extension Section where Parent == EmptyView, Content : View, Footer : View {

    /// Creates a section with a footer and the provided section content.
    /// - Parameters:
    ///   - footer: A view to use as the section's footer.
    ///   - content: The section's content.
    @available(iOS, deprecated: 100000.0, renamed: "Section(content:footer:)")
    @available(macOS, deprecated: 100000.0, renamed: "Section(content:footer:)")
    @available(tvOS, deprecated: 100000.0, renamed: "Section(content:footer:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Section(content:footer:)")
    public init(footer: Footer, @ViewBuilder content: () -> Content) {
        self.header = EmptyView()
        self.content = content()
        self.footer = footer
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Section where Parent : View, Content : View, Footer == EmptyView {

    /// Creates a section with a header and the provided section content.
    /// - Parameters:
    ///   - header: A view to use as the section's header.
    ///   - content: The section's content.
    @available(iOS, deprecated: 100000.0, renamed: "Section(content:header:)")
    @available(macOS, deprecated: 100000.0, renamed: "Section(content:header:)")
    @available(tvOS, deprecated: 100000.0, renamed: "Section(content:header:)")
    @available(watchOS, deprecated: 100000.0, renamed: "Section(content:header:)")
    public init(header: Parent, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
        self.footer = EmptyView()
    }
}

@available(iOS 13.0, *)
private struct ResolvedSectionStyle: StyleableView {
    
    internal var configuration: SectionStyleConfiguration
    
internal func defaultBody() -> some View {
        Section(header: configuration.header, content: configuration.content, footer: configuration.footer)
            .sectionStyle(PlainSectionStyle())
    }

}

@available(iOS 13.0, *)
internal struct SectionStyleConfiguration {
    
    internal let header: Header

    internal let footer: Footer

    internal let content: Content
    
    internal struct Header: ViewAlias {
        
    }
    
    internal struct Footer: ViewAlias {
        
    }
    
    internal struct Content: ViewAlias {
        
    }
}

@available(iOS 13.0, *)
internal protocol SectionStyle {
    
    associatedtype Body: View
    
    func makeBody(configuration: SectionStyleConfiguration) -> Body
    
}

@available(iOS 13.0, *)
private struct SectionStyleModifier<Style: SectionStyle>: StyleModifier {
    
    internal typealias Style = Style
    
    internal typealias Subject = ResolvedSectionStyle
    
    internal typealias SubjectBody = Style.Body
    
    internal var style: Style
    
    internal static func body(view: ResolvedSectionStyle, style: Style) -> Style.Body {
        style.makeBody(configuration: view.configuration)
    }
}

@available(iOS 13.0, *)
extension View {
    
    fileprivate func sectionStyle<Style: SectionStyle>(_ style: Style) -> some View {
        modifier(SectionStyleModifier<Style>(style: style))
    }
}

@available(iOS 13.0, *)
private struct PlainSectionStyle: SectionStyle {
    
    internal typealias Body = StyledView
    
    func makeBody(configuration: SectionStyleConfiguration) -> StyledView {
        StyledView(configuration: configuration)
    }
}

@available(iOS 13.0, *)
private struct StyledView: MultiView, PrimitiveView {
    
    internal typealias Body = Never
    
    internal var configuration: SectionStyleConfiguration
    
    internal static func _makeViewList(view: _GraphValue<StyledView>, inputs: _ViewListInputs) -> _ViewListOutputs {
        typealias Tree = _VariadicView.Tree<SectionContainer, SectionStyleConfiguration.Content>
        return Tree._makeViewList(view: _GraphValue(SectionBody(view: view.value)), inputs: inputs)
    }
}

@available(iOS 13.0, *)
private struct SectionContainer: _VariadicView_MultiViewRoot {
    
    internal typealias Body = Never
    
    internal var parent: SectionStyleConfiguration.Header

    internal var footer: SectionStyleConfiguration.Footer
    
    internal static func _makeViewList(root: _GraphValue<SectionContainer>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        .groupViewList(parent: root[{.of(&$0.parent)}], footer: root[{.of(&$0.footer)}], inputs: inputs, body: body)
    }
}

@available(iOS 13.0, *)
private struct SectionBody: Rule {
    
    internal typealias Value = _VariadicView.Tree<SectionContainer, SectionStyleConfiguration.Content>
    
    @Attribute
    internal var view: StyledView
    
    internal var value: Value {
        let view = self.view
        return .init(root: SectionContainer(parent: view.configuration.header, footer: view.configuration.footer), content: view.configuration.content)
    }
    
}

@available(iOS 13.0, *)
internal struct SectionedTrait: Rule {
    
    internal typealias Value = ViewTraitCollection
    
    @OptionalAttribute
    internal var traits: ViewTraitCollection?
    
    internal var value: ViewTraitCollection {
        let traitCollection = traits ?? .init()
        return traitCollection[IsSectionedTraitKey.self] ? traitCollection : .init()
    }
}

@available(iOS 13.0, *)
@usableFromInline
internal struct IsSectionedTraitKey: _ViewTraitKey {
    
    @usableFromInline
    internal typealias Value = Bool
    
    @inlinable
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
internal struct DepthTrait: Rule {
    
    internal typealias Value = ViewTraitCollection
    
    @OptionalAttribute
    internal var traits: ViewTraitCollection?
    
    internal var value: ViewTraitCollection {
        let traitCollection = traits ?? .init()
        return traitCollection[DepthTraitKey.self] != 0 ? traitCollection : .init()
    }
}

@available(iOS 13.0, *)
@usableFromInline
internal struct DepthTraitKey: _ViewTraitKey {
    
    @usableFromInline
    internal typealias Value = Int
    
    @inlinable
    internal static var defaultValue: Int {
        0
    }
}

@available(iOS 13.0, *)
internal struct SectionFooterTrait: Rule {
    
    internal typealias Value = ViewTraitCollection
    
    @OptionalAttribute
    internal var traits: ViewTraitCollection?
    
    internal var value: ViewTraitCollection {
        let traitCollection = traits ?? .init()
        return traitCollection[SectionFooterTraitKey.self] ? traitCollection : .init()
    }
}

@available(iOS 13.0, *)
internal struct SectionFooterTraitKey: _ViewTraitKey {
    
    internal typealias Value = Bool
    
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
internal struct IsSectionHeaderTraitKey: _ViewTraitKey {
    internal static var defaultValue: Bool {
        false
    }
}

@available(iOS 13.0, *)
internal struct SectionHeaderTrait: Rule {
    @OptionalAttribute
    internal var traits: ViewTraitCollection?
    
    internal var value: ViewTraitCollection {
        let traitCollection = traits ?? .init()
        return traitCollection[IsSectionHeaderTraitKey.self] ? traitCollection : .init()
    }
}
