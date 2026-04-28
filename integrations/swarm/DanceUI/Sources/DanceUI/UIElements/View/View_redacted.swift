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

@available(iOS 13.0, *)
extension View {
    
    /// Adds a reason to apply a redaction to this view hierarchy.
    ///
    /// Adding a redaction is an additive process: any redaction
    /// provided will be added to the reasons provided by the parent.
    public func redacted(reason: RedactionReasons) -> some View {
        self.transformEnvironment(\.redactionReasons) { value in
            guard !value.contains(reason) else {
                return
            }
            value.insert(reason)
        }
    }
    
    
    /// Removes any reason to apply a redaction to this view hierarchy.
    public func unredacted() -> some View {
        self.transformEnvironment(\.redactionReasons) { value in
            value = []
        }
    }
    
}
