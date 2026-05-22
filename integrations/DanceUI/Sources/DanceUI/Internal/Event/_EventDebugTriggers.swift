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

import Foundation

@available(iOS 13.0, *)var _eventDebugTriggers: _EventDebugTriggers = []
@available(iOS 13.0, *)
internal struct _EventDebugTriggers: OptionSet {

    internal let rawValue: Int

    internal static let responders: _EventDebugTriggers = .init(rawValue: 0x1 << 0x1)

    internal static let sendEvents: _EventDebugTriggers = .init(rawValue: 0x1 << 0x2)

    internal static let eventBindings: _EventDebugTriggers = .init(rawValue: 0x1 << 0x3)

    internal static let eventPhases: _EventDebugTriggers = .init(rawValue: 0x1 << 0x4)
    
}
