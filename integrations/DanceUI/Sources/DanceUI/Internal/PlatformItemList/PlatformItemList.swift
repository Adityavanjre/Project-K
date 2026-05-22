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
internal struct PlatformItemList {
    
    internal var items: [Item] = []
    
    internal struct Item {
        
        internal var text: NSAttributedString? = nil
        
        internal var platformIdentifier: String? = nil
        
        internal var platformTag: Int? = nil
        
        internal var isEnabled: Bool = true
        
        internal var resolvedImage: Image.Resolved? = nil
        
        internal var systemItem: SystemItem? = nil
        
        internal var selectionBehavior: SelectionBehavior? = nil

        internal var accessibility: Accessibility? = nil
        
        internal var children: PlatformItemList? = nil
        
        internal var toggleState: ToggleState? = nil

        internal init(text: NSAttributedString? = nil,
                      image: Image.Resolved? = nil,
                      selectionBehavior: SelectionBehavior? = nil,
                      accessibility: Accessibility? = nil) {
            #warning("_notImplemented")
            self.text = text
            self.platformIdentifier = nil
            self.platformTag = nil
            self.isEnabled = true
            self.resolvedImage = image
            self.systemItem = nil
            self.selectionBehavior = selectionBehavior
            self.accessibility = accessibility
            self.children = nil
        }
        
        internal init(text: ResolvedStyledText) {
            self.init(text: text.resolvedContent(),
                      image: nil,
                      selectionBehavior: nil,
                      accessibility: nil)
        }
        
        internal var image: UIImage? {
            if let image = resolvedImage, let label = image.label {
                if let uiImage = image.platformItemImage {
                    return uiImage
                }
                return image.image.makePlatformImage(fixedSymbolConfiguration: false, flattenMaskColor: false)
            }
            return nil
        }
        
        internal struct SelectionBehavior {
            
            internal var isMomentary: Bool
            
            internal var isContainerSelection: Bool
            
            internal var visualStyle: VisualStyle
            
            internal var keyboardShortcut: KeyboardShortcut?
            
            internal var onSelect: (() -> Void)?

            internal var onDeselect: (() -> Void)?

            internal var platformSelector: Selector?
            
            @inlinable
            internal init() {
                self.isMomentary = false
                self.isContainerSelection = false
                self.visualStyle = .plain
                self.keyboardShortcut = nil
                self.onSelect = nil
                self.onDeselect = nil
                self.platformSelector = nil
            }
            
            @inlinable
            internal init(isMomentary: Bool,
                          isContainerSelection: Bool,
                          visualStyle: PlatformItemList.Item.SelectionBehavior.VisualStyle,
                          keyboardShortcut: KeyboardShortcut? = nil,
                          onSelect: (() -> Void)? = nil,
                          onDeselect: (() -> Void)? = nil,
                          platformSelector: Selector? = nil) {
                self.isMomentary = isMomentary
                self.isContainerSelection = isContainerSelection
                self.visualStyle = visualStyle
                self.keyboardShortcut = keyboardShortcut
                self.onSelect = onSelect
                self.onDeselect = onDeselect
                self.platformSelector = platformSelector
            }
            
            internal enum VisualStyle: Hashable {
                
                case plain

                case checkmark

                case navigation

                case selected
            }
        }
        
        internal enum SystemItem : Hashable {

            case divider

            case spacer

            case section

        }
        
        internal struct Accessibility {
            
            internal let identifiers: [UniqueID]
            
            internal let label: String?
            
        }
        
    }
    
    internal struct Key: PreferenceKey {
        
        internal typealias Value = PlatformItemList
        
        @inline(__always)
        internal static var defaultValue: PlatformItemList { PlatformItemList() }
        
        internal static func reduce(value: inout PlatformItemList,
                                    nextValue: () -> PlatformItemList) {
            value.items.append(contentsOf: nextValue().items)
        }
        
    }
    
}

@available(iOS 13.0, *)
extension PreferencesInputs {
    
    @inlinable
    internal var requiresPlatformItemList: Bool {
        get {
            contains(PlatformItemList.Key.self)
        }
        set {
            if newValue {
                add(PlatformItemList.Key.self)
            } else {
                remove(PlatformItemList.Key.self)
            }
        }
    }

}

@available(iOS 13.0, *)
extension _ViewOutputs {
    
    internal var platformItemList: Attribute<PlatformItemList>? {
        get {
            self[PlatformItemList.Key.self]
        }
        set {
            self[PlatformItemList.Key.self] = newValue
        }
    }
    
}

