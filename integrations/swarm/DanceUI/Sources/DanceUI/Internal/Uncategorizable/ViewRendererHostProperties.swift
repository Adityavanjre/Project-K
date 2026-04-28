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
internal struct ViewRendererHostProperties: OptionSet, RawRepresentable {

    internal var rawValue: UInt16

    @inlinable
    internal init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    internal static let rootView: ViewRendererHostProperties = .init(rawValue: 0x1 << 0)

    internal static let environment: ViewRendererHostProperties = .init(rawValue: 0x1 << 1)

    internal static let focusedValues: ViewRendererHostProperties = .init(rawValue: 0x1 << 2)

    internal static let transform: ViewRendererHostProperties = .init(rawValue: 0x1 << 3)

    internal static let size: ViewRendererHostProperties = .init(rawValue: 0x1 << 4)

    internal static let safeArea: ViewRendererHostProperties = .init(rawValue: 0x1 << 5)

    internal static let focusStore: ViewRendererHostProperties = .init(rawValue: 0x1 << 6)

    internal static let accessibilityFocusStore: ViewRendererHostProperties = .init(rawValue: 0x1 << 7)

    internal static let focusedItem: ViewRendererHostProperties = .init(rawValue: 0x1 << 8)

    internal static let accessibilityFocus: ViewRendererHostProperties = .init(rawValue: 0x1 << 9)

    internal static let gestureObservers: ViewRendererHostProperties = .init(rawValue: 0x1 << 10)

    internal static let all: ViewRendererHostProperties = [
        .rootView,
        .environment,
        .focusedValues,
        .transform,
        .size,
        .safeArea,
        .focusStore,
        .accessibilityFocusStore,
        .focusedItem,
        .accessibilityFocus,
        .gestureObservers,
    ]
}
