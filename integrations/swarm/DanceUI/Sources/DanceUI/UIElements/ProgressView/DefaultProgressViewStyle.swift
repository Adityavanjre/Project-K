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

/// The default progress view style in the current context of the view being
/// styled.
///
/// Use ``ProgressViewStyle/automatic`` to construct this style.
@available(iOS 13.0, *)
public struct DefaultProgressViewStyle : ProgressViewStyle {

    /// Creates a default progress view style.
    public init() {
        _intentionallyLeftBlank()
    }

    /// Creates a view representing the body of a progress view.
    ///
    /// - Parameter configuration: The properties of the progress view being
    ///   created.
    ///
    /// The view hierarchy calls this method for each progress view where this
    /// style is the current progress view style.
    ///
    /// - Parameter configuration: The properties of the progress view, such as
    ///  its preferred progress type.
    public func makeBody(configuration: DefaultProgressViewStyle.Configuration) -> some View {
        if configuration.fractionCompleted != nil {
            ProgressView(configuration)
                .modifier(ProgressViewStyleModifier(style: LinearProgressViewStyle()))
        } else {
            ProgressView(configuration)
                .modifier(ProgressViewStyleModifier(style: CircularProgressViewStyle()))
        }
        
    }
}
