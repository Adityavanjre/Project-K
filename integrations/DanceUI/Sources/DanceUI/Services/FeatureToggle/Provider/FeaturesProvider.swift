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

// MARK: - FeaturesProvider

/// This protocol defines a provider for feature flag values; you can implement your own sources both local or remote ones.
/// Take a look to BentoFlag's built-in provider sources to get an insight of what you can accomplish.
@available(iOS 13.0, *)
internal protocol FeaturesProvider {
    
    /// Return `false` if provider support overwriting values.
    /// Some local providers may support overrides, some remotes may not.
    var isFrozen: Bool { get }
    
    /// Fetch value for a specific flag.
    ///
    /// - Parameter key: key of the flag to retrive.
    func value<K: SettingsKey>(for key: K.Type) -> K.Value?
}
