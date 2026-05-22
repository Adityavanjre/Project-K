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

/// A view modifier that adds accessibility properties to the view

@available(iOS 13.0, *)
public struct AccessibilityAttachmentModifier: AccessibilityViewModifier {
    
    internal var attachment: AccessibilityAttachment?

    internal var onlyApplyToFirstNode: Bool
    
    internal func attachment(for nodes: [AccessibilityNode]) -> AccessibilityAttachment? {
        guard case var .properties(properties) = attachment,
              properties.platformFocusable == true,
              let firstNode = nodes.first,
              properties.focusableDescendantNode == nil else {
            return attachment
        }
        
        properties.focusableDescendantNode = firstNode

        return .properties(properties)
    }
    
    internal func attachment(for nodes: [AccessibilityNode], atIndex index: Int) -> AccessibilityAttachment {
        
        guard let newAttachment = attachment(for: nodes) else {
            return .properties(AccessibilityProperties())
        }
        guard case let .properties(properties) = newAttachment else {
            return newAttachment
        }
        
        var newProperties: AccessibilityProperties
        
        if case .platform = attachment {
            newProperties = index > 0 ? AccessibilityProperties() : properties
        } else {
            newProperties = properties
        }
    
        if nodes.count >= 2 {
            newProperties.outline = .defaultFrame
        }
        
        return .properties(newProperties)
    }
    
    internal mutating func properties(body: (inout AccessibilityProperties) -> ()) {
        guard let attachment = attachment else {
            return
        }
        
        var properties = attachment.properties ?? AccessibilityProperties()
        body(&properties)
        
        self.attachment = attachment.updatedProperties(properties)
    }
    
    internal func willCreateNode(for nodes: [AccessibilityNode]) -> Bool {
        nodes.count == 0
    }

}

@available(iOS 13.0, *)
extension View {
    
    internal func debuggableAccessibilityModifier(_ modifier: AccessibilityAttachmentModifier) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        self.modifier(modifier).accessibilityCaptureTypeInfo()
    }
    
    internal func debuggableAccessibilityModifier<Modifier: AccessibilityViewModifier>(_ modifier: Modifier) -> ModifiedContent<ModifiedContent<Self, Modifier>, AccessibilityAttachmentModifier> {
        self.modifier(modifier).accessibilityCaptureTypeInfo()
    }
    
    internal func accessibilityCaptureTypeInfo() -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(\.viewTypeBox, AXViewTypeDescribingBox(of: Self.self))
    }
    
    internal func accessibility() -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        modifier(AccessibilityAttachmentModifier(attachment: nil, onlyApplyToFirstNode: false))
    }
    
}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    
    internal func accessibilityCaptureTypeInfo() -> ModifiedContent<Content, Modifier> {
        guard let attachment = modifier.attachment else {
            return self
        }
        
        var properties = attachment.properties ?? AccessibilityProperties()
        properties.viewTypeBox = AXViewTypeDescribingBox(of: Self.self)
        
        var newSelf = self
        let newAttachment: AccessibilityAttachment
        switch attachment {
        case .properties:
            newAttachment = .properties(properties)
        case .platform(_, let object, let externalPlatformProperties):
            newAttachment = .platform(properties, object, externalPlatformProperties)
        }
        
        newSelf.modifier.attachment = newAttachment
        return newSelf
    }
    
    @inline(__always)
    internal func modifiedAccessibilityProperties(_ body: (inout AccessibilityProperties) -> ()) -> ModifiedContent<Content, Modifier> {
        modifiedModifier { $0.properties(body: body) }
    }

}
