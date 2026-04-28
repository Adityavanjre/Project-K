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
internal final class PlatformAlertController: UIAlertController {
    
    internal var onDismissAction: (() -> Void)?
    
    internal override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let onDismissCallback = onDismissAction else {
            return
        }
        onDismissCallback()
    }
    
    internal func update<PresentationType: AlertControllerConvertible>(presentation: PresentationType, with environment: EnvironmentValues, environmentChanged: Bool) {
        
        if let popoverPresentationControllerValue = self.popoverPresentationController {
            popoverPresentationControllerValue.sourceRect = presentation.sourceRect
        }
        
        let title = presentation.title
        
        let message = presentation.message
        
        self.title = title.resolveText(with: environment)
        
        if let messageValue = message {
            self.message = messageValue.resolveText(with: environment)
        }
        
        let buttonTitlesInPresentation: [String] = presentation.buttons.map { (button) -> String in
            button.label.resolveText(with: environment)
        }
        
        let buttonTitlesInAlertController: [String?] = self.actions.map {
            $0.title
        }
        
        let isAlertButtonsEqual = (buttonTitlesInAlertController == buttonTitlesInPresentation)
        
        if !environmentChanged || !isAlertButtonsEqual {
            
            let actions: [UIAlertAction] = presentation.buttons.map { alertButton in
                let label = alertButton.label
                let title: String = label.resolveText(with: environment)
                return .makeAction(alertButton, title: title)
            }
            
            self.onDismissAction = presentation.onDismiss
            
            self.my_setActions(actions)
        }
    }
}

@available(iOS 13.0, *)
extension Text {
    @inline(__always)
    fileprivate func resolveText(with environments: EnvironmentValues) -> String {
        switch self.storage {
        case .verbatim(let string):
            return string
        case .anyTextStorage(_):
            let attributeString = self.resolveString(in: environments, includeDefaultAttributes: false, options: .zero)
            return attributeString?.string ?? ""
        }
    }
}

@available(iOS 13.0, *)
extension UIAlertAction {
    
    fileprivate static func makeAction<AlertAction: AlertActionConvertible>(_ alertAction: AlertAction, title: String?) -> UIAlertAction {
        
        let alert: UIAlertAction = .init(title: title, style: alertActionStyleTransformer(with: alertAction.style)) { _ in
            if let actionCallback = alertAction.action {
                actionCallback()
            }
        }
        
        alert.isEnabled = (alertAction.action == nil) ? false : true
        
        return alert
    }
    
    fileprivate static func alertActionStyleTransformer(with alertButtonStyle: Alert.Button.Style) -> UIAlertAction.Style {
        switch alertButtonStyle {
        case .`default`:
            return .`default`
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}
