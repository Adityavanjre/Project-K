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

@available(iOS 13.0, *)
internal struct Switch: UIViewRepresentable {
    
    internal typealias UIViewType = UISwitch
    
    internal typealias Coordinator = PlatformSwitchCoordinator
    
    @Binding
    internal var isOn: Bool
    
    internal var tint: Color?
    
    internal func makeUIView(context: Context) -> UISwitch {
        let view = UISwitch()
        view.addTarget(context.coordinator, action: #selector(PlatformSwitchCoordinator.isOnChanged(view:)), for: .valueChanged)
        return view
    }
    
    internal func updateUIView(_ uiView: UISwitch, context: Context) {
        
        let isOn = self.isOn
        
        let isAnimated = context.transaction.animation
        
        if isAnimated != nil {
            uiView.setOn(isOn, animated: true)
        } else {
            uiView.setOn(isOn, animated: false)
        }
        
        if let tintColorValue = self.tint {
            let switchTintColor = tintColorValue.resolvedUIColor(in: context.environment)
            
            let onTintColor = uiView.onTintColor
            
            if onTintColor == nil || switchTintColor != onTintColor {
                uiView.onTintColor = switchTintColor
            }
            
        } else {
            let onTintColor = uiView.onTintColor
            
            if onTintColor != nil {
                uiView.onTintColor = nil
            }
        }
        
        context.coordinator.update(isOn: $isOn)
    }
    
    internal func makeCoordinator() -> Coordinator {
        PlatformSwitchCoordinator(isOn: self._isOn)
    }
    
    internal final class PlatformSwitchCoordinator: PlatformViewCoordinator {
        
        @Binding
        internal var isOn: Bool

        internal init(isOn: Binding<Bool>) {
            self._isOn = isOn
            super.init()
        }
        
        @inline(__always)
        internal func update(isOn: Binding<Bool>) {
            self._isOn = isOn
        }
        
        @objc
        internal func isOnChanged(view: UISwitch) -> Void {
            let binding = self.$isOn.animation()
            Update.perform {
                binding.wrappedValue = view.isOn
            }
            view.setOn(self.isOn, animated: true)
        }
    }
}
