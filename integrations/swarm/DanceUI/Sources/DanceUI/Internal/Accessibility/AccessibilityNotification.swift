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
internal protocol AccessibilityNotification {
    
    static var name: UIAccessibility.Notification { get }
    
    var info: Accessibility.Notification.Info { get }

}

@available(iOS 13.0, *)
extension AccessibilityNotification {
    
    @inlinable
    internal func post() {
        info.post(name: Self.name)
    }
}

@available(iOS 13.0, *)
protocol AccessibilityElementNotification: AccessibilityNotification {
    
    init(element: Any)

}

@available(iOS 13.0, *)
internal enum Accessibility {
    
    internal static var enabledGlobally: Bool = false

    internal enum Notification {
        
        internal struct Info {

            internal var argument: Any?

            internal func post(name: UIAccessibility.Notification) {
                UIAccessibility.post(notification: name, argument: argument)
            }
            
        }
        
        internal struct LayoutChanged: AccessibilityNotification {

            internal var nextElement: Any?
            
            internal static var name: UIAccessibility.Notification {
                .layoutChanged
            }
            
            internal var info: Info {
                Info(argument: nextElement)
            }

        }

        internal struct ValueChanged: AccessibilityElementNotification {

            internal var element: Any
            
            internal static var name: UIAccessibility.Notification {
                UIAccessibility.Notification(rawValue: 0x3ed)
            }
            
            internal var info: Info {
                Info(argument: element)
            }

        }

        internal struct LabelChanged: AccessibilityElementNotification {

            internal var element: Any
            
            internal static var name: UIAccessibility.Notification {
                UIAccessibility.Notification(rawValue: 0x3ed)
            }
            
            internal var info: Info {
                Info(argument: element)
            }

        }
        
    }
    
}
