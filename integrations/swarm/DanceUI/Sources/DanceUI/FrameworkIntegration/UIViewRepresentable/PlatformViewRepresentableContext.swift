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
internal struct PlatformViewRepresentableValues {

    internal static var current: PlatformViewRepresentableValues? = nil
    
    /// This reference is weak to avoid retain cycles, since
    /// `PlatformViewRepresentableValues` can be set to `current` and
    /// there is no code to set it nil.
    internal weak var preferenceBridge: PreferenceBridge?

    internal var transaction: Transaction

    internal var environment: EnvironmentValues

    internal func asCurrent<A>(do: () -> A) -> A {
        let previous = Self.current
        Self.current = self
        defer {
            Self.current = previous
        }
        return `do`()
    }

}

@available(iOS 13.0, *)
internal struct PlatformViewRepresentableContext<PlatformViewType: PlatformViewRepresentable> {

    internal var values: PlatformViewRepresentableValues

    internal let coordinator: PlatformViewType.Coordinator
}
