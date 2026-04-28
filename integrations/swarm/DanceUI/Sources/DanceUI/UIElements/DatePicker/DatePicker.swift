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

/// A control for selecting an absolute date.
///
/// Use a `DatePicker` when you want to provide a view that allows the user to
/// select a calendar date, and optionally a time. The view binds to a
/// [Date](https://developer.apple.com/documentation/Foundation/Date) instance.
///
/// The following example creates a basic `DatePicker`, which appears on iOS as
/// text representing the date. This example limits the display to only the
/// calendar date, not the time. When the user taps or clicks the text, a
/// calendar view animates in, from which the user can select a date. When the
/// user dismisses the calendar view, the view updates the bound
/// [Date](https://developer.apple.com/documentation/Foundation/Date).
///
///     @State private var date = Date()
///
///     var body: some View {
///         DatePicker(
///             "Start Date",
///             selection: $date,
///             displayedComponents: [.date]
///         )
///     }
///
/// ![An iOS date picker, consisting of a label that says Start Date, and a
/// label showing the date Apr 1, 1976.](DanceUI-DatePicker-basic.png)
///
/// You can limit the `DatePicker` to specific ranges of dates, allowing
/// selections only before or after a certain date, or between two dates. The
/// following example shows a date-and-time picker that only permits selections
/// within the year 2021 (in the `UTC` time zone).
///
///     @State private var date = Date()
///     let dateRange: ClosedRange<Date> = {
///         let calendar = Calendar.current
///         let startComponents = DateComponents(year: 2021, month: 1, day: 1)
///         let endComponents = DateComponents(year: 2021, month: 12, day: 31, hour: 23, minute: 59, second: 59)
///         return calendar.date(from:startComponents)!
///             ...
///             calendar.date(from:endComponents)!
///     }()
///
///     var body: some View {
///         DatePicker(
///             "Start Date",
///              selection: $date,
///              in: dateRange,
///              displayedComponents: [.date, .hourAndMinute]
///         )
///     }
///
/// ![A DanceUI standard date picker on iOS, with the label Start Date, and
/// buttons for the time 5:15 PM and the date Jul 31,
/// 2021.](DanceUI-DatePicker-selectFromRange.png)
///
/// ### Styling Date Pickers
///
/// To use a different style of date picker, use the
/// ``View/datePickerStyle(_:)`` view modifier. The following example shows the
/// graphical date picker style.
///
///     @State private var date = Date()
///
///     var body: some View {
///         DatePicker(
///             "Start Date",
///             selection: $date,
///             displayedComponents: [.date]
///         )
///         .datePickerStyle(.graphical)
///     }
///
/// ![A DanceUI date picker using the graphical style, with the label Start Date
/// and wheels for the month, day, and year, showing the selection
/// October 22, 2021.](DanceUI-DatePicker-graphicalStyle.png)
///
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct DatePicker<Label> : View where Label : View {

    public typealias Components = DatePickerComponents
    
    internal let selection: Binding<Date>

    internal let minimumDate: Date?

    internal let maximumDate: Date?

    internal let displayedComponents: DatePickerComponents

    internal let label: Label

    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of primitive views that DanceUI provides, plus other
    /// composite views that you've already defined:
    ///
    ///     struct MyView: View {
    ///         var body: some View {
    ///             Text("Hello, World!")
    ///         }
    ///     }
    ///
    /// For more information about composing views and a view hierarchy,
    /// see <doc:Declaring-a-Custom-View>.
    public var body: some View {
        ResolvedDatePickerStyle(configuration: DatePicker<_DatePickerStyleLabel>(self))
            .viewAlias(_DatePickerStyleLabel.self) {
                label
            }
    }

//    public typealias Body = ModifiedContent<ResolvedDatePickerStyle, StaticSourceWriter<_DatePickerStyleLabel, Label>>

}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension DatePicker {

    /// Creates an instance that selects a `Date` with an unbounded range.
    ///
    /// - Parameters:
    ///   - selection: The date value being displayed and selected.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    ///   - label: A view that describes the use of the date.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(selection: Binding<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date], @ViewBuilder label: () -> Label) {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = label()
        
    }

    /// Creates an instance that selects a `Date` in a closed range.
    ///
    /// - Parameters:
    ///   - selection: The date value being displayed and selected.
    ///   - range: The inclusive range of selectable dates.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    ///   - label: A view that describes the use of the date.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(selection: Binding<Date>, in range: ClosedRange<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date], @ViewBuilder label: () -> Label) {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = label()
    }

    /// Creates an instance that selects a `Date` on or after some start date.
    ///
    /// - Parameters:
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range from some selectable start date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    ///   - label: A view that describes the use of the date.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(selection: Binding<Date>, in range: PartialRangeFrom<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date], @ViewBuilder label: () -> Label) {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = label()
    }

    /// Creates an instance that selects a `Date` on or before some end date.
    ///
    /// - Parameters:
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range before some selectable end date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    ///   - label: A view that describes the use of the date.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(selection: Binding<Date>, in range: PartialRangeThrough<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date], @ViewBuilder label: () -> Label) {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = label()
    }
}

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
extension DatePicker where Label == Text {

    /// Creates an instance that selects a `Date` with an unbounded range.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(_ titleKey: LocalizedStringKey, selection: Binding<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = Text(titleKey)
    }

    /// Creates an instance that selects a `Date` in a closed range.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The inclusive range of selectable dates.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(_ titleKey: LocalizedStringKey, selection: Binding<Date>, in range: ClosedRange<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = Text(titleKey)
    }

    /// Creates an instance that selects a `Date` on or after some start date.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range from some selectable start date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(_ titleKey: LocalizedStringKey, selection: Binding<Date>, in range: PartialRangeFrom<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = Text(titleKey)
    }

    /// Creates an instance that selects a `Date` on or before some end date.
    ///
    /// - Parameters:
    ///   - titleKey: The key for the localized title of `self`, describing
    ///     its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range before some selectable end date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    public init(_ titleKey: LocalizedStringKey, selection: Binding<Date>, in range: PartialRangeThrough<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = Text(titleKey)
    }

    /// Creates an instance that selects a `Date` within the given range.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @_disfavoredOverload
    public init<S>(_ title: S, selection: Binding<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) where S : StringProtocol {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = Text(title)
    }

    /// Creates an instance that selects a `Date` in a closed range.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The inclusive range of selectable dates.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @_disfavoredOverload
    public init<S>(_ title: S, selection: Binding<Date>, in range: ClosedRange<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) where S : StringProtocol {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = Text(title)
    }

    /// Creates an instance that selects a `Date` on or after some start date.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range from some selectable start date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @_disfavoredOverload
    public init<S>(_ title: S, selection: Binding<Date>, in range: PartialRangeFrom<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) where S : StringProtocol {
        self.selection = selection
        self.minimumDate = range.lowerBound
        self.maximumDate = nil
        self.displayedComponents = displayedComponents
        self.label = Text(title)
    }

    /// Creates an instance that selects a `Date` on or before some end date.
    ///
    /// - Parameters:
    ///   - title: The title of `self`, describing its purpose.
    ///   - selection: The date value being displayed and selected.
    ///   - range: The open range before some selectable end date.
    ///   - displayedComponents: The date components that user is able to
    ///     view and edit. Defaults to `[.hourAndMinute, .date]`.
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @_disfavoredOverload
    public init<S>(_ title: S, selection: Binding<Date>, in range: PartialRangeThrough<Date>, displayedComponents: DatePicker<Label>.Components = [.hourAndMinute, .date]) where S : StringProtocol {
        self.selection = selection
        self.minimumDate = nil
        self.maximumDate = range.upperBound
        self.displayedComponents = displayedComponents
        self.label = Text(title)
    }
}

@available(iOS 13.0, *)
extension DatePicker where Label == _DatePickerStyleLabel {
    init<A: View>(_ picker: DatePicker<A>) {
        self.selection = picker.selection
        self.minimumDate = picker.minimumDate
        self.maximumDate = picker.maximumDate
        self.displayedComponents = picker.displayedComponents
        self.label = _DatePickerStyleLabel()
    }
}

@available(iOS 13.0, *)
public struct _DatePickerStyleLabel : ViewAlias { }

@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(iOS 13.0, *)
public struct DatePickerComponents : OptionSet {

    /// The corresponding value of the raw type.
    ///
    /// A new instance initialized with `rawValue` will be equivalent to this
    /// instance. For example:
    ///
    ///     enum PaperSize: String {
    ///         case A4, A5, Letter, Legal
    ///     }
    ///
    ///     let selectedSize = PaperSize.Letter
    ///     print(selectedSize.rawValue)
    ///     // Prints "Letter"
    ///
    ///     print(selectedSize == PaperSize(rawValue: selectedSize.rawValue)!)
    ///     // Prints "true"
    public let rawValue: UInt

    /// Creates a new option set from the given raw value.
    ///
    /// This initializer always succeeds, even if the value passed as `rawValue`
    /// exceeds the static properties declared as part of the option set. This
    /// example creates an instance of `ShippingOptions` with a raw value beyond
    /// the highest element, with a bit mask that effectively contains all the
    /// declared static members.
    ///
    ///     let extraOptions = ShippingOptions(rawValue: 255)
    ///     print(extraOptions.isStrictSuperset(of: .all))
    ///     // Prints "true"
    ///
    /// - Parameter rawValue: The raw value of the option set to create. Each bit
    ///   of `rawValue` potentially represents an element of the option set,
    ///   though raw values may include bits that are not defined as distinct
    ///   values of the `OptionSet` type.
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
    
    /// Displays hour and minute components based on the locale
    public static let hourAndMinute: DatePickerComponents = .init(rawValue: 96)

    /// Displays day, month, and year based on the locale
    public static let date: DatePickerComponents = .init(rawValue: 28)

    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = DatePickerComponents

    /// The element type of the option set.
    ///
    /// To inherit all the default implementations from the `OptionSet` protocol,
    /// the `Element` type must be `Self`, the default.
    public typealias Element = DatePickerComponents

    /// The raw type that can be used to represent all values of the conforming
    /// type.
    ///
    /// Every distinct value of the conforming type has a corresponding unique
    /// value of the `RawValue` type, but there may be values of the `RawValue`
    /// type that don't have a corresponding value of the conforming type.
    public typealias RawValue = UInt
}
