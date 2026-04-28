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

@available(iOS 13.0, *)
extension View {
    
    internal func accessibility(_ attachment: AccessibilityAttachment) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        debuggableAccessibilityModifier(AccessibilityAttachmentModifier(attachment: attachment, onlyApplyToFirstNode: false))
    }
    
}

@available(iOS 13.0, *)
internal enum AccessibilityAttachment: Equatable {

    case properties(_ properties: AccessibilityProperties)

    case platform(_ properties: AccessibilityProperties?, _ target: AnyObject, _ externalPlatformProperties: ExternalPlatformProperties)
    
    internal static func == (lhs: AccessibilityAttachment, rhs: AccessibilityAttachment) -> Bool {
        switch (lhs, rhs) {
        case (.properties(let lhsProperties), .properties(let rhsProperties)) :
            return lhsProperties == rhsProperties
        case (.platform(let lhsProperties, let lhsTarget, let lhsExternalPlatformProperties), .platform(let rhsProperties, let rhsTarget, let rhsExternalPlatformProperties)):
            return lhsProperties == rhsProperties && lhsTarget === rhsTarget && lhsExternalPlatformProperties == rhsExternalPlatformProperties
        default:
            return false
        }
    }
    
    internal static func combine(_ attachments: [AccessibilityAttachment]) -> AccessibilityAttachment {
        attachments.reduce(.properties(AccessibilityProperties())) { partialResult, next in
            switch (next, partialResult) {
            case (.properties(let nextProperties), .properties(let resultProperties)):
                return .properties(nextProperties.combined(with: resultProperties))
            case (.properties(let nextProperties), .platform(let resultProperties, let target, let externalPlatformProperties)):
                let properties = (resultProperties ?? AccessibilityProperties()).combined(with: nextProperties)
                return .platform(properties, target, externalPlatformProperties)
            case (.platform, _):
                return next
            }
        }
    }
    
    @inlinable
    internal var properties: AccessibilityProperties? {
        switch self {
        case .properties(let properties):
            return properties
        case .platform(let properties, _, _):
            return properties
        }
    }
    
    @inlinable
    internal func updatedProperties(_ properties: AccessibilityProperties) -> AccessibilityAttachment {
        switch self {
        case .properties:
            return .properties(properties)
        case .platform(_, let object, let externalPlatformProperties):
            return .platform(properties, object, externalPlatformProperties)
        }
    }
    
    internal struct ExternalPlatformProperties: Equatable {

        @WeakAttribute
        internal var properties: AccessibilityProperties??

        internal var value: AccessibilityProperties?
        
        @inlinable
        internal init() {
            self._properties = WeakAttribute()
            self.value = nil
        }
        
        @inlinable
        internal init(attribute: Attribute<AccessibilityProperties?>) {
            self._properties = WeakAttribute(attribute)
            self.value = attribute.value
        }

    }

}
