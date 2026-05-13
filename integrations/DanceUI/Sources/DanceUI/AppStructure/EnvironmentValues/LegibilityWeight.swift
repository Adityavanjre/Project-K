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

/// The Accessibility Bold Text user setting options.
///
/// The app can't override the user's choice before iOS 16, tvOS 16 or
/// watchOS 9.0.

@available(iOS 13.0, *)
public enum LegibilityWeight : Hashable {
    
    /// Use regular font weight (no Accessibility Bold).
    case regular
    
    /// Use heavier font weight (force Accessibility Bold).
    case bold
    
}

@available(iOS 13.0, *)
extension LegibilityWeight {
    
    /// Creates a legibility weight from its UILegibilityWeight equivalent.
    @available(iOS 13.0, tvOS 13.0, *)
    @available(macOS, unavailable)
    @available(watchOS, unavailable)
    public init?(_ uiLegibilityWeight: UILegibilityWeight) {
        switch uiLegibilityWeight {
        case .regular:
            self = .regular
        case .bold:
            self = .bold
        default:
            return nil
        }
    }
}
