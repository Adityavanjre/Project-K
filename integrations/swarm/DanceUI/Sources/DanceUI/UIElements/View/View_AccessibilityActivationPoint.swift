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
    
    /// Specifies the point where activations occur in the view.
    public func accessibilityActivationPoint(_ activationPoint: CGPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityActivationPoint(.point(activationPoint))
    }

    /// Specifies the unit point where activations occur in the view.
    public func accessibilityActivationPoint(_ activationPoint: UnitPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibilityActivationPoint(.unitPoint(activationPoint))
    }
    
    @inline(__always)
    internal func accessibilityActivationPoint(_ activationPoint: AccessibilityActivationPoint) -> ModifiedContent<Self, AccessibilityAttachmentModifier> {
        accessibility(\.activationPoint, activationPoint)
    }

}

@available(iOS 13.0, *)
extension ModifiedContent where Modifier == AccessibilityAttachmentModifier {
    
    /// Specifies the point where activations occur in the view.
    public func accessibilityActivationPoint(_ activationPoint: CGPoint) -> ModifiedContent<Content, Modifier> {
        accessibilityActivationPoint(.point(activationPoint))
    }

    /// Specifies the unit point where activations occur in the view.
    public func accessibilityActivationPoint(_ activationPoint: UnitPoint) -> ModifiedContent<Content, Modifier> {
        accessibilityActivationPoint(.unitPoint(activationPoint))
    }
    
    @inline(__always)
    internal func accessibilityActivationPoint(_ activationPoint: AccessibilityActivationPoint) -> ModifiedContent<Content, Modifier> {
        modifiedAccessibilityProperties {
            $0.activationPoint = activationPoint
        }
    }
    
}

@available(iOS 13.0, *)
internal enum AccessibilityActivationPoint: Equatable {
    
    case point(CGPoint)
    
    case unitPoint(UnitPoint)
    
}
