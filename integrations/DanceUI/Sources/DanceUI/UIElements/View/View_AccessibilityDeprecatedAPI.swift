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
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {

    /// Specifies whether to hide this view from system accessibility features.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    public func accessibility(hidden: Bool) -> ModifiedContent<Content, Modifier> {
        accessibilityHidden(hidden)
    }

    /// Adds a label to the view that describes its contents.
    ///
    /// Use this method to provide an accessibility label for a view that doesn't display text, like an icon.
    /// For example, you could use this method to label a button that plays music with the text "Play".
    /// Don't include text in the label that repeats information that users already have. For example,
    /// don't use the label "Play button" because a button already has a trait that identifies it as a button.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    public func accessibility(label: Text) -> ModifiedContent<Content, Modifier> {
        accessibilityLabel(label)
    }

    /// Communicates to the user what happens after performing the view's
    /// action.
    ///
    /// Provide a hint in the form of a brief phrase, like "Purchases the item" or
    /// "Downloads the attachment".
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    public func accessibility(hint: Text) -> ModifiedContent<Content, Modifier> {
        accessibilityHint(hint)
    }

    /// Sets alternate input labels with which users identify a view.
    ///
    /// If you don't specify any input labels, the user can still refer to the view using the accessibility
    /// label that you add with the accessibilityLabel() modifier. Provide labels in descending order
    /// of importance. Voice Control and Full Keyboard Access use the input labels.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    public func accessibility(inputLabels: [Text]) -> ModifiedContent<Content, Modifier> {
        accessibilityInputLabels(inputLabels)
    }

    /// Uses the specified string to identify the view.
    ///
    /// Use this value for testing. It isn't visible to the user.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    public func accessibility(identifier: String) -> ModifiedContent<Content, Modifier> {
        accessibilityIdentifier(identifier)
    }

    @available(iOS, deprecated, introduced: 13.0)
    @available(macOS, deprecated, introduced: 10.15)
    @available(tvOS, deprecated, introduced: 13.0)
    @available(watchOS, deprecated, introduced: 6)
    public func accessibility(selectionIdentifier: AnyHashable) -> ModifiedContent<Content, Modifier> {
        _accessibilitySelectionIdentifier(selectionIdentifier)
    }
    
    private func _accessibilitySelectionIdentifier(_ identifier: AnyHashable) -> ModifiedContent<Content, Modifier> {
        modifiedAccessibilityProperties {
            $0.selectionIdentifier = identifier
        }
    }

    /// Sets the sort priority order for this view's accessibility
    /// element, relative to other elements at the same level.
    ///
    /// Higher numbers are sorted first. The default sort priority is zero.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    public func accessibility(sortPriority: Double) -> ModifiedContent<Content, Modifier> {
        accessibilitySortPriority(sortPriority)
    }

    /// Specifies the point where activations occur in the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    public func accessibility(activationPoint: CGPoint) -> ModifiedContent<Content, Modifier> {
        accessibilityActivationPoint(activationPoint)
    }

    /// Specifies the unit point where activations occur in the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    public func accessibility(activationPoint: UnitPoint) -> ModifiedContent<Content, Modifier> {
        accessibilityActivationPoint(activationPoint)
    }
}

@available(iOS 13.0, *)
extension View {

    /// Specifies whether to hide this view from system accessibility features.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityHidden(_:)")
    public func accessibility(hidden: Bool) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityHidden(hidden)
    }

    /// Adds a label to the view that describes its contents.
    ///
    /// Use this method to provide an accessibility label for a view that doesn't display text, like an icon.
    /// For example, you could use this method to label a button that plays music with the text "Play".
    /// Don't include text in the label that repeats information that users already have. For example,
    /// don't use the label "Play button" because a button already has a trait that identifies it as a button.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityLabel(_:)")
    public func accessibility(label: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityLabel(label)
    }

    /// Communicates to the user what happens after performing the view's
    /// action.
    ///
    /// Provide a hint in the form of a brief phrase, like "Purchases the item" or
    /// "Downloads the attachment".
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityHint(_:)")
    public func accessibility(hint: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityHint(hint)
    }

    /// Sets alternate input labels with which users identify a view.
    ///
    /// Provide labels in descending order of importance. Voice Control
    /// and Full Keyboard Access use the input labels.
    ///
    /// > Note: If you don't specify any input labels, the user can still
    ///   refer to the view using the accessibility label that you add with the
    ///   ``accessibility(label:)`` modifier.
    ///
    /// - Parameter inputLabels: An array of Text elements to use as input labels.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityInputLabels(_:)")
    public func accessibility(inputLabels: [Text]) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityInputLabels(inputLabels)
    }

    /// Uses the specified string to identify the view.
    ///
    /// Use this value for testing. It isn't visible to the user.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityIdentifier(_:)")
    public func accessibility(identifier: String) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityIdentifier(identifier)
    }

    /// Sets a selection identifier for this view's accessibility element.
    ///
    /// Picker uses the value to determine what node to use for the
    /// accessibility value.
    @available(iOS, deprecated, introduced: 13.0)
    @available(macOS, deprecated, introduced: 10.15)
    @available(tvOS, deprecated, introduced: 13.0)
    @available(watchOS, deprecated, introduced: 6)
    public func accessibility(selectionIdentifier: AnyHashable) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        _accessibilitySelectionIdentifier(selectionIdentifier)
    }
    
    private func _accessibilitySelectionIdentifier(_ identifier: AnyHashable) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(\.selectionIdentifier, identifier)
    }

    /// Sets the sort priority order for this view's accessibility element,
    /// relative to other elements at the same level.
    ///
    /// Higher numbers are sorted first. The default sort priority is zero.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilitySortPriority(_:)")
    public func accessibility(sortPriority: Double) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilitySortPriority(sortPriority)
    }

    /// Specifies the point where activations occur in the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    public func accessibility(activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityActivationPoint(activationPoint)
    }

    /// Specifies the unit point where activations occur in the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityActivationPoint(_:)")
    public func accessibility(activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityActivationPoint(activationPoint)
    }
    
}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {

    /// Adds the given traits to the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    public func accessibility(addTraits traits: AccessibilityTraits) -> ModifiedContent<Content, Modifier> {
        accessibilityAddTraits(traits)
    }

    /// Removes the given traits from this view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    public func accessibility(removeTraits traits: AccessibilityTraits) -> ModifiedContent<Content, Modifier> {
        accessibilityRemoveTraits(traits)
    }
    
}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {

    /// Adds a textual description of the value that the view contains.
    ///
    /// Use this method to describe the value represented by a view, but only if that's different than the
    /// view's label. For example, for a slider that you label as "Volume" using accessibility(label:),
    /// you can provide the current volume setting, like "60%", using accessibility(value:).
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    public func accessibility(value: Text) -> ModifiedContent<Content, Modifier> {
        accessibilityValue(value)
    }
}

@available(iOS 13.0, *)
extension View {

    /// Adds the given traits to the view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityAddTraits(_:)")
    public func accessibility(addTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityAddTraits(traits)
    }

    /// Removes the given traits from this view.
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityRemoveTraits(_:)")
    public func accessibility(removeTraits traits: AccessibilityTraits) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityRemoveTraits(traits)
    }
}

@available(iOS 13.0, *)
extension View {

    /// Adds a textual description of the value that the view contains.
    ///
    /// Use this method to describe the value represented by a view, but only if that's different than the
    /// view's label. For example, for a slider that you label as "Volume" using accessibility(label:),
    /// you can provide the current volume setting, like "60%", using accessibility(value:).
    @available(iOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(macOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(tvOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    @available(watchOS, deprecated: 100000.0, renamed: "accessibilityValue(_:)")
    public func accessibility(value: Text) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityValue(value)
    }
}
