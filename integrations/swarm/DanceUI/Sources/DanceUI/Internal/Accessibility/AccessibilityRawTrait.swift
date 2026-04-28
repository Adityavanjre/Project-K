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
internal enum AccessibilityRawTrait: UInt32, Hashable, CaseIterable, CustomStringConvertible {
    
    case button
    
    case header
    
    case selected
    
    case link
    
    case searchField
    
    case image
    
    case playsSound
    
    case keyboardKey
    
    case staticText
    
    case summaryElement
    
    case updatesFrequently
    
    case startsMediaSession
    
    case allowsDirectInteraction
    
    case causesPageTurn
    
    case modal
    
    case toggle
    
    case radioButton
    
    case radioGroup
    
    case labelTitle
    
    case labelIcon
    
    case progressIndicator
    
    case activityIndicator
    
    internal var description: String {
        switch self {
        case .button:
            return "button"
        case .header:
            return "header"
        case .selected:
            return "selected"
        case .link:
            return "link"
        case .searchField:
            return "searchField"
        case .image:
            return "image"
        case .playsSound:
            return "playsSound"
        case .keyboardKey:
            return "keyboardKey"
        case .staticText:
            return "staticText"
        case .summaryElement:
            return "summaryElement"
        case .updatesFrequently:
            return "updatesFrequently"
        case .startsMediaSession:
            return "startsMediaSession"
        case .allowsDirectInteraction:
            return "allowsDirectInteraction"
        case .causesPageTurn:
            return "causesPageTurn"
        case .modal:
            return "modal"
        case .toggle:
            return "toggle"
        case .radioButton:
            return "radioButton"
        case .radioGroup:
            return "radioGroup"
        case .labelTitle:
            return "labelTitle"
        case .labelIcon:
            return "labelIcon"
        case .progressIndicator:
            return "progressIndicator"
        case .activityIndicator:
            return "activityIndicator"
        }
    }

}
