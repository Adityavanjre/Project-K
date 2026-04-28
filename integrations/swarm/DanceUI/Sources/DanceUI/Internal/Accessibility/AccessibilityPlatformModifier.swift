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

import UIKit
internal import DanceUIGraph

@available(iOS 13.0, *)
extension View {
    
    internal func accessibility(platformView: UIView) -> ModifiedContent<Self, AccessibilityPlatformModifier> {
         modifier(AccessibilityPlatformModifier(platformView: platformView))
    }
    
}

@available(iOS 13.0, *)
internal struct AccessibilityPlatformModifier: PrimitiveViewModifier, MultiViewModifier {

    internal let platformView: UIView
    
    internal static func _makeView(modifier: _GraphValue<AccessibilityPlatformModifier>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let attachment = PlatformAccessibilityAttachment(
            platformView: modifier.value[keyPath: \.platformView],
            externalProperties: Attribute<AccessibilityProperties?>(value: nil)
        )
        
        return AccessibilityAttachmentModifier._makeView(
            modifier: _GraphValue(attachment),
            inputs: inputs,
            body: body
        )
    }

}

@available(iOS 13.0, *)
fileprivate struct PlatformAccessibilityAttachment: Rule {
    
    fileprivate typealias Value = AccessibilityAttachmentModifier

    @Attribute
    private var platformView: UIView

    @Attribute
    private var externalProperties: AccessibilityProperties?
    
    fileprivate init(platformView: Attribute<UIView>, externalProperties: Attribute<AccessibilityProperties?>) {
        self._platformView = platformView
        self._externalProperties = externalProperties
    }
    
    fileprivate var value: Value {
        AccessibilityAttachmentModifier(
            attachment: .platform(nil, platformView, AccessibilityAttachment.ExternalPlatformProperties(attribute: $externalProperties)),
            onlyApplyToFirstNode: true
        )
    }

}
