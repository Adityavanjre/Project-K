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
public struct ButtonRole: Equatable {
    
    internal var rawValue: UInt8

    /// A role that indicates a destructive button.
    ///
    /// Use this role for a button that deletes user data, or performs an
    /// irreversible operation. A destructive button signals by its appearance
    /// that the user should carefully consider whether to tap or click the
    /// button. For example, DanceUI presents a destructive button that you add
    /// with the ``View/swipeActions(edge:allowsFullSwipe:content:)``
    /// modifier using a red background:
    ///
    ///     List {
    ///         ForEach(items) { item in
    ///             Text(item.title)
    ///                 .swipeActions {
    ///                     Button(role: .destructive) { delete() } label: {
    ///                         Label("Delete", systemImage: "trash")
    ///                     }
    ///                 }
    ///         }
    ///     }
    ///     .navigationTitle("Shopping List")
    ///
    public static let destructive: ButtonRole = .init(rawValue: 0x1)

    internal static let role0x2: ButtonRole = .init(rawValue: 0x2)
    internal static let role0x3: ButtonRole = .init(rawValue: 0x3)
    
    /// A role that indicates a button that cancels an operation.
    ///
    /// Use this role for a button that cancels the current operation.
    public static let cancel: ButtonRole = .init(rawValue: 0x4)

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    public static func == (a: ButtonRole, b: ButtonRole) -> Bool {
        return a.rawValue == b.rawValue
    }
}
