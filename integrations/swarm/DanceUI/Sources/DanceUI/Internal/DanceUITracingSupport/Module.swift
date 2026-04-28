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
internal struct Module: Hashable {
    
#if DEBUG || DANCE_UI_INHOUSE
    internal let rawValue: String
#endif
    
    @inline(__always)
    private init(_rawValue rawValue: String) {
#if DEBUG || DANCE_UI_INHOUSE
        self.rawValue = rawValue
        assert(rawValue.isCamelCased(firstLetterCase: .uppercase), "Module name starts with a capital letter.")
#endif
    }
    
    @inline(__always)
    internal init(_ value: String) {
        self.init(_rawValue: value)
    }
    
    /// The `unspecified` module name is used for checking whether
    /// infrastructures that offering tracing conveniences have
    /// correctly set their module name.
    ///
    /// - WARNING: Developers shall never use this module name.
    ///
    internal static let unspecified = Module("Unspecified")
    
    internal static let dataFlow = Module("DataFlow")
    
}
