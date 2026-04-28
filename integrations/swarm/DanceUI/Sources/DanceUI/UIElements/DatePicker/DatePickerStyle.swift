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

/// A type that specifies the appearance and interaction of all date pickers
/// within a view hierarchy.
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public protocol DatePickerStyle {
    associatedtype _Body : View
    
    typealias _Label = _DatePickerStyleLabel
    
    @ViewBuilder func _body(configuration: DatePicker<Self._Label>) -> Self._Body
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension DatePickerStyle where Self == DefaultDatePickerStyle {

    /// The default style for date pickers.
    @_alwaysEmitIntoClient
    public static var automatic: DefaultDatePickerStyle {
        DefaultDatePickerStyle()
    }
}

@available(iOS 14.0, macOS 10.15, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension DatePickerStyle where Self == GraphicalDatePickerStyle {

    /// A date picker style that displays an interactive calendar or clock.
    ///
    /// This style is useful when you want to allow browsing through days in a
    /// calendar, or when the look of a clock face is appropriate.
    @_alwaysEmitIntoClient
    public static var graphical: GraphicalDatePickerStyle {
        GraphicalDatePickerStyle()
    }
}

@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension DatePickerStyle where Self == WheelDatePickerStyle {

    /// A date picker style that displays each component as columns in a
    /// scrollable wheel.
    @_alwaysEmitIntoClient
    public static var wheel: WheelDatePickerStyle {
        WheelDatePickerStyle()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension DatePickerStyle where Self == CompactDatePickerStyle {

    /// A date picker style that displays the components in a compact, textual
    /// format.
    ///
    /// Use this style when space is constrained and users expect to make
    /// specific date and time selections. Some variants may include rich
    /// editing controls in a pop up.
    @_alwaysEmitIntoClient
    public static var compact: CompactDatePickerStyle {
        CompactDatePickerStyle()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension View {

    /// Sets the style for date pickers within this view.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public func datePickerStyle<S>(_ style: S) -> some View where S : DatePickerStyle {
        modifier(DatePickerStyleModifier(style: style))
    }

}
