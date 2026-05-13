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
    
    /// Marks the view as containing sensitive, private user data.
    ///
    /// DanceUI redacts views marked with this modifier when you apply the
    /// ``RedactionReasons/privacy`` redaction reason.
    ///
    ///     struct BankAccountView: View {
    ///         var body: some View {
    ///             VStack {
    ///                 Text("Account #")
    ///
    ///                 Text(accountNumber)
    ///                     .font(.headline)
    ///                     .privacySensitive() // Hide only the account number.
    ///             }
    ///         }
    ///     }
    public func privacySensitive(_ sensitive: Bool = true) -> some View {
        modifier(PrivacyRedactionViewModifier(sensitive: sensitive))
    }
    
}

@available(iOS 13.0, *)
private struct PrivacyRedactionViewModifier: ViewModifier {
    
    @Environment(\.redactionReasons)
    internal var redactionReasons: RedactionReasons
    
    internal var sensitive: Bool
    
    internal var shouldRedact: Bool {
        sensitive && redactionReasons.contains(.privacy)
    }
    
    internal func body(content: Content) -> some View {
        content
            .environment(\.redactionReasons, [])
            .environment(\.sensitiveContent, sensitive)
            .opacity(shouldRedact ? 0.0 : 1.0)
            .transition(.opacity)
            .overlay(shouldRedact ? content
                .environment(\.redactionReasons, .placeholder)
                .opacity(shouldRedact ? 1.0 : 0.0)
                .transition(.opacity) : nil)
    }
}
