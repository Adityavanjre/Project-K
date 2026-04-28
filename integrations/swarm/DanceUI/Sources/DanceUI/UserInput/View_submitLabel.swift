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

/// A semantic label describing the label of submission within a view hierarchy.
///
/// A submit label is a description of a submission action provided to a
/// view hierarchy using the ``View/onSubmit(of:_:)`` modifier.
@available(iOS 13.0, *)
public struct SubmitLabel {
    
    internal enum Role {

      case done

      case go

      case send

      case join

      case route

      case search

      case `return`

      case next

      case `continue`

    }

    internal var role : Role

    /// Defines a submit label with text of "Done".
    public static var done: SubmitLabel {
        SubmitLabel(role: .done)
    }

    /// Defines a submit label with text of "Go".
    public static var go: SubmitLabel {
        SubmitLabel(role: .go)
    }

    /// Defines a submit label with text of "Send".
    public static var send: SubmitLabel {
        SubmitLabel(role: .send)
    }

    /// Defines a submit label with text of "Join".
    public static var join: SubmitLabel {
        SubmitLabel(role: .join)
    }

    /// Defines a submit label with text of "Route".
    public static var route: SubmitLabel {
        SubmitLabel(role: .route)
    }

    /// Defines a submit label with text of "Search".
    public static var search: SubmitLabel {
        SubmitLabel(role: .search)
    }

    /// Defines a submit label with text of "Return".
    public static var `return`: SubmitLabel {
        SubmitLabel(role: .return)
    }

    /// Defines a submit label with text of "Next".
    public static var next: SubmitLabel {
        SubmitLabel(role: .next)
    }

    /// Defines a submit label with text of "Continue".
    public static var `continue`: SubmitLabel {
        SubmitLabel(role: .continue)
    }
}

@available(iOS 13.0, *)
extension View {

    /// Sets the submit label for this view.
    ///
    ///     Form {
    ///         TextField("Username", $viewModel.username)
    ///             .submitLabel(.continue)
    ///         SecureField("Password", $viewModel.password)
    ///             .submitLabel(.done)
    ///     }
    ///
    /// - Parameter submitLabel: One of the cases specified in ``SubmitLabel``.
    public func submitLabel(_ submitLabel: SubmitLabel) -> some View {
        self.environment(\.submitLabel, submitLabel)
    }

}

@available(iOS 13.0, *)
extension UIReturnKeyType {
    
    @inline(__always)
    internal init(_ submitLabel: SubmitLabel) {
        switch submitLabel.role {
        case .done:     self = .done
        case .go:       self = .go
        case .send:     self = .send
        case .join:     self = .join
        case .route:    self = .route
        case .search:   self = .search
        case .return:   self = .`default`
        case .next:     self = .next
        case .continue: self = .continue
        }
    }
    
}
