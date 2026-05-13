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

    /// Links multiple accessibility elements so that the user can quickly
    /// navigate from one element to another, even when the elements are not near
    /// each other in the accessibility hierarchy.
    ///
    /// This can be useful to allow quickly jumping between content in a list and
    /// the same content shown in a detail view, for example. All elements marked
    /// with `accessibilityLinkedGroup` with the same namespace and identifier will be
    /// linked together.
    ///
    /// - Parameters:
    ///   - id: A hashable identifier used to separate sets of linked elements
    ///     within the same namespace. Elements with matching `namespace` and `id`
    ///     will be linked together.
    ///   - namespace: The namespace to use to organize linked accessibility
    ///     elements. All elements marked with `accessibilityLink` in this
    ///     namespace and with the specified `id` will be linked together.
    public func accessibilityLinkedGroup<ID: Hashable>(id: ID, in namespace: Namespace.ID) -> some View {
        accessibilityRelationShip(.linkedGroup, id: id, in: namespace)
    }

    /// Pairs an accessibility element representing a label with the element
    /// for the matching content.
    ///
    /// Use `accessibilityLabeledPair` with a role of `AccessibilityLabeledPairRole.label`
    /// to identify the label, and a role of `AccessibilityLabeledPairRole.content`
    /// to identify the content.
    /// This improves the behavior of accessibility features such as VoiceOver
    /// when navigating such elements, allowing users to better understand the
    /// relationship between them.
    ///
    /// - Parameters:
    ///   - role: Determines whether this element should be used as the label
    ///     in the pair, or the content in the pair.
    ///   - id: The identifier for the label / content pair. Elements with
    ///     matching identifiers within the same namespace will be paired
    ///     together.
    ///   - namespace: The namespace used to organize label and content. Label
    ///     and content under the same namespace with matching identifiers will
    ///     be paired together.
    public func accessibilityLabeledPair<ID: Hashable>(role: AccessibilityLabeledPairRole, id: ID, in namespace: Namespace.ID) -> some View {
        accessibilityRelationShip(.labeledPair(role), id: id, in: namespace)
    }

}
