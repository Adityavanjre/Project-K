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
internal struct ResolvedSafeAreaInsets: Rule {
    
    internal typealias Value = EdgeInsets
    
    internal let regions: SafeAreaRegions

    @Attribute
    internal var environment: EnvironmentValues

    @Attribute
    internal var size: ViewSize

    @Attribute
    internal var position: ViewOrigin

    @Attribute
    internal var transform: ViewTransform

    @OptionalAttribute
    internal var safeAreaInsets: SafeAreaInsets?
    
    internal var value: Value {
        guard let safeAreaInsets = safeAreaInsets else {
            return .zero
        }
        let context = _PositionAwarePlacementContext(
            context: AnyRuleContext.current,
            size: $size,
            environment: $environment,
            transform: $transform,
            position: $position)
        return safeAreaInsets.resolve(regions: regions, in: context)
    }
    
}
