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

/// A type that applies standard interaction behavior to all progress views
/// within a view hierarchy.
///
/// To configure the current progress view style for a view hierarchy, use the
/// ``View/progressViewStyle(_:)`` modifier.
@available(iOS 13.0, *)
public protocol ProgressViewStyle {

    /// A view representing the body of a progress view.
    associatedtype Body : View

    @ViewBuilder
    func makeBody(configuration: Self.Configuration) -> Self.Body

    typealias Configuration = ProgressViewStyleConfiguration
}

@available(iOS 13.0, *)
extension ProgressViewStyle where Self == DefaultProgressViewStyle {

    /// The default progress view style in the current context of the view being
    /// styled.
    ///
    /// The default style represents the recommended style based on the original
    /// initialization parameters of the progress view, and the progress view's
    /// context within the view hierarchy.
    @_alwaysEmitIntoClient
    public static var automatic: DefaultProgressViewStyle {
        DefaultProgressViewStyle()
    }
}

@available(iOS 13.0, *)
extension ProgressViewStyle where Self == CircularProgressViewStyle {

    /// The style of a progress view that uses a circular gauge to indicate the
    /// partial completion of an activity.
    ///
    /// On watchOS, and in widgets and complications, a circular progress view
    /// appears as a gauge with the ``GaugeStyle/accessoryCircularCapacity``
    /// style. If the progress view is indeterminate, the gauge is empty.
    ///
    /// In cases where no determinate circular progress view style is available,
    /// circular progress views use an indeterminate style.
    @_alwaysEmitIntoClient
    public static var circular: CircularProgressViewStyle {
        CircularProgressViewStyle()
    }
}

@available(iOS 13.0, *)
extension ProgressViewStyle where Self == LinearProgressViewStyle {

    /// A progress view that visually indicates its progress using a horizontal
    /// bar.
    @_alwaysEmitIntoClient
    public static var linear: LinearProgressViewStyle {
        LinearProgressViewStyle()
    }
}



