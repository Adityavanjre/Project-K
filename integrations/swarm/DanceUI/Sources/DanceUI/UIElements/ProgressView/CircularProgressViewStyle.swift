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

/// A progress view that uses a circular gauge to indicate the partial
/// completion of an activity.
///
/// On watchOS, and in widgets and complications, a circular progress view
/// appears as a gauge with the ``GaugeStyle/accessoryCircularCapacity``
/// style. If the progress view is indeterminate, the gauge is empty.
///
/// In cases where no determinate circular progress view style is available,
/// circular progress views use an indeterminate style.
///
/// Use ``ProgressViewStyle/circular`` to construct the circular progress view
/// style.
@available(iOS 13.0, *)
public struct CircularProgressViewStyle: ProgressViewStyle {

    @Environment(\.tintColor)
    internal var controlTint: Color?
    
    public let tint: Color?
    
    
    internal var effectiveTint: Color? {
        if let styleTint = self.tint {
            return styleTint
        }
        if let environmentTint = self.controlTint {
            return environmentTint
        }
        return nil
    }

    /// Creates a circular progress view style.
    public init() {
        self.tint = nil
    }

    /// Creates a circular progress view style with a tint color.
    public init(tint: Color) {
        // 0x4f35e0 iOS14.3
        self.tint = tint
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
    public func makeBody(configuration: CircularProgressViewStyle.Configuration) -> some View {

        VStack(alignment: .center) {
            CircularUIKitProgressView(tint: effectiveTint)
            VStack(alignment: .center) {
                HStack {
                    configuration.label
                }
                .defaultForegroundColor(.secondary)
                HStack {
                    configuration.currentValueLabel
                }
                .defaultForegroundColor(.secondary)
                .font(.caption)
            }
            .animation(nil)
        }
    }
}
