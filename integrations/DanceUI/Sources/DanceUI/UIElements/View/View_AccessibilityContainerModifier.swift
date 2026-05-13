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

    /// Creates a new accessibility element, or modifies the
    /// ``AccessibilityChildBehavior`` of the existing accessibility element.
    ///
    /// See also:
    /// - ``AccessibilityChildBehavior/ignore``
    /// - ``AccessibilityChildBehavior/combine``
    /// - ``AccessibilityChildBehavior/contain``
    ///
    /// - Parameters:
    ///     -   children: The behavior to use when creating or
    ///     transforming an accessibility element.
    ///     The default is ``AccessibilityChildBehavior/ignore``
    public func accessibilityElement(children: AccessibilityChildBehavior = .ignore) -> some View {
        debuggableAccessibilityModifier(AccessibilityContainerModifier(behavior: children))
    }

}

@available(iOS 13.0, *)
internal struct AccessibilityContainerModifier: AccessibilityViewModifier {
    
    internal let behavior: AccessibilityChildBehavior
    
    internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        behavior.provider.attachment(for: nodes)
    }
    
    internal func initialPropertiesForNode(nodes: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
        behavior.provider.parentProperties(children: nodes, environment: environment)
    }
    
    internal func willCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        behavior.provider.shouldCreateNode(for: nodes)
    }

}

@available(iOS 13.0, *)
public struct AccessibilityChildBehavior: Hashable {

    fileprivate var provider: AnyBehaviorBox
    
    private static let textCombineKeyPaths: [WritableKeyPath<AccessibilityProperties, Text?>] = [
        \.label,
         \.hint,
         \.value,
    ]
    
    /// Any child accessibility elements become hidden.
    ///
    /// Use this behavior when you want a view represented by
    /// a single accessibility element. The new accessibility element
    /// has no initial properties. So you will need to use other
    /// accessibility modifiers, such as ``View/accessibilityLabel(_:)-7wxyo``,
    /// to begin making it accessible.
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button("Previous Page", action: goBack)
    ///             Text("\(pageNumber)")
    ///             Button("Next Page", action: goForward)
    ///         }
    ///         .accessibilityElement(children: .ignore)
    ///         .accessibilityValue("Page \(pageNumber) of \(pages.count)")
    ///         .accessibilityAdjustableAction { action in
    ///             if action == .increment {
    ///                 goForward()
    ///             } else {
    ///                 goBack()
    ///             }
    ///         }
    ///     }
    ///
    /// Before using the  ``AccessibilityChildBehavior/ignore``behavior, consider
    /// using the ``AccessibilityChildBehavior/combine`` behavior.
    ///
    /// - Note: A new accessibility element is always created.
    public static let ignore = AccessibilityChildBehavior(provider: BehaviorBox(Ignore()))

    /// Any child accessibility elements become children of the new
    /// accessibility element.
    ///
    /// Use this behavior when you want a view to be an accessibility
    /// container. An accessibility container groups child accessibility
    /// elements which improves navigation. For example, all children
    /// of an accessibility container are navigated in order before
    /// navigating through the next accessibility container.
    ///
    ///     var body: some View {
    ///         ScrollView {
    ///             VStack {
    ///                 HStack {
    ///                     ForEach(users) { user in
    ///                         UserCell(user)
    ///                     }
    ///                 }
    ///                 .accessibilityElement(children: .contain)
    ///                 .accessibilityLabel("Users")
    ///
    ///                 VStack {
    ///                     ForEach(messages) { message in
    ///                         MessageCell(message)
    ///                     }
    ///                 }
    ///                 .accessibilityElement(children: .contain)
    ///                 .accessibilityLabel("Messages")
    ///             }
    ///         }
    ///     }
    ///
    /// A new accessibility element is created when:
    /// * The view contains multiple or zero accessibility elements
    /// * The view contains a single accessibility element with no children
    ///
    /// - Note: If an accessibility element is not created, the
    ///         ``AccessibilityChildBehavior`` of the existing
    ///         accessibility element is modified.
    public static let contain = AccessibilityChildBehavior(provider: BehaviorBox(Contain()))

    /// Any child accessibility element's properties are merged
    /// into the new accessibility element.
    ///
    /// Use this behavior when you want a view represented by
    /// a single accessibility element. The new accessibility element
    /// merges properties from all non-hidden children. Some
    /// properties may be transformed or ignored to achieve the
    /// ideal combined result. For example, not all of ``AccessibilityTraits``
    /// are merged and a ``AccessibilityActionKind/default`` action
    /// may become a named action (``AccessibilityActionKind/init(named:)``).
    ///
    ///     struct UserCell: View {
    ///         var user: User
    ///
    ///         var body: some View {
    ///             VStack {
    ///                 Image(user.image)
    ///                 Text(user.name)
    ///                 Button("Options", action: showOptions)
    ///             }
    ///             .accessibilityElement(children: .combine)
    ///         }
    ///     }
    ///
    /// A new accessibility element is created when:
    /// * The view contains multiple or zero accessibility elements
    /// * The view wraps a ``UIViewRepresentable``/``NSViewRepresentable``.
    ///
    /// - Note: If an accessibility element is not created, the
    ///         ``AccessibilityChildBehavior`` of the existing
    ///         accessibility element is modified.
    public static let combine = AccessibilityChildBehavior(provider: BehaviorBox(Combine(allowPlatformElements: false)))
    
    internal static func defaultChildProperties(from nodes: [AccessibilityNode]) -> [AccessibilityProperties] {
        nodes
            .filter { $0.properties.visibility != .hidden }
            .sorted(with: nil)
            .map { $0.properties }
    }
    
    internal static func defaultCombine(childProperties: [AccessibilityProperties], environment: EnvironmentValues) -> AccessibilityProperties {
        var properties = childProperties.reduce(AccessibilityProperties()) { partialResult, nextValue in
            nextValue.combined(with: partialResult)
        }
        
        let textSeparator = Text(", ", tableName: nil, bundle: nil, comment: nil)
        for keyPath in textCombineKeyPaths {
            properties.combineText(
                separator: textSeparator,
                keyPath: keyPath,
                childProperties: childProperties,
                environment: environment
            )
        }
        
        properties.visibility = .element
        
        properties.identifier = childProperties
            .compactMap { $0.identifier }
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        
        properties.inputLabels.append(contentsOf: childProperties.reduce([]) { partialResult, nextValue in
            partialResult + nextValue.inputLabels
        })
        
        properties.actions.append(contentsOf: childProperties.compactMap {
            $0.namedActionFromDefault(in: environment)
        })
        return properties
    }
    
    public static func == (lhs: AccessibilityChildBehavior, rhs: AccessibilityChildBehavior) -> Bool {
        lhs.provider.isEqual(to: rhs.provider)
    }
    
    public func hash(into hasher: inout Hasher) {
        provider.hash(into: &hasher)
    }
    
    
    internal struct Ignore: AccessibilityChildBehaviorProvider {
        
        internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
            .properties(AccessibilityProperties())
        }
        
        internal func parentProperties(children: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
            AccessibilityProperties(\.visibility, .element)
        }
        
    }
    
    
    internal struct Contain: AccessibilityChildBehaviorProvider {
        
        internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
            .properties(AccessibilityProperties())
        }
        
        internal func parentProperties(children: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
            AccessibilityProperties(\.visibility, .container)
        }
    
    }
    
     
    internal struct Combine: AccessibilityChildBehaviorProvider {

        internal var allowPlatformElements: Bool
        
        internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
            guard allowPlatformElements else {
                return .properties(AccessibilityProperties())
            }
            
            return nodes
                .first { $0.platformElement != nil }?.attachment ??
                .properties(AccessibilityProperties())
        }
        
        internal func parentProperties(children: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
            let childProperties = AccessibilityChildBehavior.defaultChildProperties(from: children)
            return AccessibilityChildBehavior.defaultCombine(childProperties: childProperties, environment: environment)
        }
        
        internal func shouldCreateNode(for nodes: [AccessibilityNode]) -> Bool {
            guard nodes.count == 1, let first = nodes.first else {
                return true
            }
            
            guard !allowPlatformElements else {
                return false
            }
            
            switch first.attachment {
            case .properties:
                return false
            case .platform:
                return true
            }
        }
        
    }
    
}

@available(iOS 13.0, *)
fileprivate class AnyBehaviorBox {
    
    fileprivate func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        _abstract(self)
    }
    
    fileprivate func parentProperties(children: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
        _abstract(self)
    }
    
    fileprivate func shouldCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        _abstract(self)
    }
    
    fileprivate func isEqual(to rhs: AnyBehaviorBox) -> Bool {
        _abstract(self)
    }
    
    fileprivate func hash(into hasher: inout Hasher) {
        _abstract(self)
    }

}

@available(iOS 13.0, *)
private final class BehaviorBox<Provider: AccessibilityChildBehaviorProvider>: AnyBehaviorBox {

    fileprivate let base: Provider
    
    deinit {
        _intentionallyLeftBlank()
    }
    
    fileprivate init(_ base: Provider) {
        self.base = base
    }
    
    fileprivate override func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        base.attachment(for: nodes)
    }
    
    fileprivate override func parentProperties(children: [AccessibilityNode], environment: EnvironmentValues) -> AccessibilityProperties {
        base.parentProperties(children: children, environment: environment)
    }
    
    fileprivate override func shouldCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        base.shouldCreateNode(for: nodes)
    }
    
    fileprivate override func isEqual(to rhs: AnyBehaviorBox) -> Bool {
        guard let rhs = rhs as? BehaviorBox<Provider> else {
            return false
        }
        return self.base == rhs.base
    }
    
    fileprivate override func hash(into hasher: inout Hasher) {
        hasher.combine(base)
    }
    
}
