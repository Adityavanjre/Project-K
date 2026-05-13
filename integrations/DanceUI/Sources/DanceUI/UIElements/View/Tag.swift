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

    /// Sets the unique tag value of this view.
    ///
    /// Use `tag(_:)` to differentiate between a number of views for the purpose
    /// of selecting controls like pickers and lists. Tag values can be of any
    /// type that conforms to the [Hashable](https://developer.apple.com/documentation/Swift/Hashable)
    /// protocol.
    ///
    /// In the example below, the ``ForEach`` loop in the ``Picker`` view
    /// builder iterates over the `Flavor` enumeration. It extracts the text raw
    /// value of each enumeration element for use as the row item label and uses
    /// the enumeration item itself as input to the `tag(_:)` modifier.
    /// The tag identifier can be any value that conforms to the
    /// [Hashable](https://developer.apple.com/documentation/Swift/Hashable) protocol:
    ///
    ///     struct FlavorPicker: View {
    ///         enum Flavor: String, CaseIterable, Identifiable {
    ///             var id: String { self.rawValue }
    ///             case vanilla, chocolate, strawberry
    ///         }
    ///
    ///         @State private var selectedFlavor: Flavor? = nil
    ///         var body: some View {
    ///             Picker("Flavor", selection: $selectedFlavor) {
    ///                 ForEach(Flavor.allCases) {
    ///                     Text($0.rawValue).tag($0)
    ///                 }
    ///             }
    ///         }
    ///     }
    ///
    /// - SeeAlso: `List`, `Picker`, `Hashable`
    /// - Parameter tag: A [Hashable](https://developer.apple.com/documentation/Swift/Hashable) value
    ///   to use as the view's tag.
    ///
    /// - Returns: A view with the specified tag set.
    @inlinable
    public func tag<V>(_ tag: V) -> some View where V : Hashable {
        return _trait(TagValueTraitKey<V>.self, .tagged(tag))
    }
    
    @inlinable
    public func _untagged() -> some View {
        return _trait(IsAuxiliaryContentTraitKey.self, true)
    }

}
