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

/// The structure that defines the kinds of available accessibility actions.
///

@available(iOS 13.0, *)
public struct AccessibilityActionKind : Equatable {

    internal let kind: ActionKind

    /// The value that represents the default accessibility action.
    public static let `default` = AccessibilityActionKind(kind: .default)

    /// The value that represents an action that cancels a pending accessibility action.
    public static let escape = AccessibilityActionKind(kind: .escape)

    @available(macOS, unavailable)
    public static let magicTap = AccessibilityActionKind(kind: .magicTap)
    
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let delete = AccessibilityActionKind(kind: .delete)
    
    @available(macOS 10.15, *)
    @available(iOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public static let showMenu = AccessibilityActionKind(kind: .showMenu)

    public init(named name: Text) {
        self.kind = .named(name)
    }
    
    internal init(kind: ActionKind) {
        self.kind = kind
    }
    
    internal enum ActionKind: Equatable {

        case named(Text)

        case `default`

        case escape

        case magicTap

        case delete

        case showMenu

    }
     
}
