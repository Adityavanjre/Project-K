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

/// A view that shows the progress toward completion of a task.
///
/// Use a progress view to show that a task is incomplete but advancing toward
/// completion. A progress view can show both determinate (percentage complete)
/// and indeterminate (progressing or not) types of progress.
///
/// Create a determinate progress view by initializing a `ProgressView` with
/// a binding to a numeric value that indicates the progress, and a `total`
/// value that represents completion of the task. By default, the progress is
/// `0.0` and the total is `1.0`.
///
/// The example below uses the state property `progress` to show progress in
/// a determinate `ProgressView`. The progress view uses its default total of
/// `1.0`, and because `progress` starts with an initial value of `0.5`,
/// the progress view begins half-complete. A "More" button below the progress
/// view allows people to increment the progress in increments of five percent:
///
///     struct LinearProgressDemoView: View {
///         @State private var progress = 0.5
///
///         var body: some View {
///             VStack {
///                 ProgressView(value: progress)
///                 Button("More") { progress += 0.05 }
///             }
///         }
///     }
///
///
/// To create an indeterminate progress view, use an initializer that doesn't
/// take a progress value:
///
///     var body: some View {
///         ProgressView()
///     }
///
///
/// You can also create a progress view that covers a closed range of
/// [Date](https://developer.apple.com/documentation/Foundation/Date) values. As long
/// as the current date is within the range, the progress view automatically
/// updates, filling or depleting the progress view as it nears the end of the
/// range. The following example shows a five-minute timer whose start time is
/// that of the progress view's initialization:
///
///     struct DateRelativeProgressDemoView: View {
///         let workoutDateRange = Date()...Date().addingTimeInterval(5*60)
///
///         var body: some View {
///              ProgressView(timerInterval: workoutDateRange) {
///                  Text("Workout")
///              }
///         }
///     }
///
///
/// ### Styling progress views
///
/// You can customize the appearance and interaction of progress views by
/// creating styles that conform to the ``ProgressViewStyle`` protocol. To set a
/// specific style for all progress view instances within a view, use the
/// ``View/progressViewStyle(_:)`` modifier. In the following example, a custom
/// style adds a rounded pink border to all progress views within the enclosing
/// ``VStack``:
///
///     struct BorderedProgressViews: View {
///         var body: some View {
///             VStack {
///                 ProgressView(value: 0.25) { Text("25% progress") }
///                 ProgressView(value: 0.75) { Text("75% progress") }
///             }
///             .progressViewStyle(PinkBorderedProgressViewStyle())
///         }
///     }
///
///     struct PinkBorderedProgressViewStyle: ProgressViewStyle {
///         func makeBody(configuration: Configuration) -> some View {
///             ProgressView(configuration)
///                 .padding(4)
///                 .border(.pink, width: 3)
///                 .cornerRadius(4)
///         }
///     }
///
///
/// DanceUI provides two built-in progress view styles,
/// ``ProgressViewStyle/linear`` and ``ProgressViewStyle/circular``, as well as
/// an automatic style that defaults to the most appropriate style in the
/// current context. The following example shows a circular progress view that
/// starts at 60 percent completed.
///
///     struct CircularProgressDemoView: View {
///         @State private var progress = 0.6
///
///         var body: some View {
///             VStack {
///                 ProgressView(value: progress)
///                     .progressViewStyle(.circular)
///             }
///         }
///     }
///
///
/// On platforms other than macOS, the circular style may appear as an
/// indeterminate indicator instead.
@available(iOS 13.0, *)
public struct ProgressView<Label: View, CurrentValueLabel: View>: View {

    private var base: Base

    /// The content and behavior of the view.
    ///
    /// When you implement a custom view, you must implement a computed
    /// `body` property to provide the content for your view. Return a view
    /// that's composed of built-in views that DanceUI provides, plus other
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
        Group {
            switch self.base {
            case .custom(let customProgressView):
                customProgressView
            }
        }
    }
    
    
    private enum Base {
        case custom(CustomProgressView<Label, CurrentValueLabel>)
    }
    
    private init<V: BinaryFloatingPoint>(value: V?, total: V, label: Label?, currentValueLabel: CurrentValueLabel?) {
        var f: Double? = nil
        if let val = value {
            f = Double(val/total)
            if val < 0 {
                f = nil
            }
        }
        self.base = Base.custom(
            CustomProgressView(fractionCompleted: f,
                               alwaysIndeterminate: true,
                               label: label,
                               currentValueLabel: currentValueLabel
            )
        )
    }
}

@available(iOS 13.0, *)
private struct CustomProgressView<A: View, B: View>: View {

    private var fractionCompleted: Double?

    private var alwaysIndeterminate: Bool

    private var label: A?

    private var currentValueLabel: B?
    
    internal init(fractionCompleted: Double?, alwaysIndeterminate: Bool, label: A?, currentValueLabel: B?) {
        self.fractionCompleted = fractionCompleted
        self.alwaysIndeterminate = alwaysIndeterminate
        self.label = label
        self.currentValueLabel = currentValueLabel
    }
    
    public var body: some View {
        let currentVL = OptionalViewAlias<ProgressViewStyleConfiguration.CurrentValueLabel>.init(sourceExists: true)
        let labe = OptionalViewAlias<ProgressViewStyleConfiguration.Label>.init(sourceExists: true)
        ResolvedProgressView(configuration:
                                ProgressViewStyleConfiguration(fractionCompleted: self.fractionCompleted,
                                                               label: ProgressViewStyleConfiguration.Label(),
                                                               currentValueLabel: ProgressViewStyleConfiguration.CurrentValueLabel()),
                             label: labe,
                             currentValueLabel: currentVL)
            .viewAlias(ProgressViewStyleConfiguration.CurrentValueLabel.self) {
                currentValueLabel
            }
            .viewAlias(ProgressViewStyleConfiguration.Label.self) {
                label
            }
    }
}

@available(iOS 13.0, *)
fileprivate struct ResolvedProgressView: View {

    fileprivate var configuration: ProgressViewStyleConfiguration

    @OptionalViewAlias<ProgressViewStyleConfiguration.Label>
    fileprivate var label: ProgressViewStyleConfiguration.Label?

    @OptionalViewAlias<ProgressViewStyleConfiguration.CurrentValueLabel>
    fileprivate var currentValueLabel: ProgressViewStyleConfiguration.CurrentValueLabel?

    public var body: some View {
        ResolvedProgressViewStyle(configuration: self.configuration)
            .modifier(AccessibilityContainerModifier(behavior: .combine))
            .accessibilityAddTraits((configuration.fractionCompleted == nil && configuration.label == nil) ? .isProgressIndicator : .isActivityIndicator)
            .accessibilityAddTraits(.updatesFrequently)
        
    }
}

@available(iOS 13.0, *)
extension ProgressView where CurrentValueLabel == EmptyView {

    /// Creates a progress view for showing indeterminate progress, without a
    /// label.
    public init() where Label == EmptyView {
        self.base = Base.custom(
            CustomProgressView(fractionCompleted: nil,
                               alwaysIndeterminate: true,
                               label: EmptyView(),
                               currentValueLabel: EmptyView()
            )
        )
    }

    /// Creates a progress view for showing indeterminate progress that displays
    /// a custom label.
    ///
    /// - Parameters:
    ///     - label: A view builder that creates a view that describes the task
    ///       in progress.
    public init(@ViewBuilder label: () -> Label) {
        self.init(label: label())
    }

    /// Creates a progress view for showing indeterminate progress that
    /// generates its label from a localized string.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// ``Text`` for more information about localizing strings. To initialize a
    /// indeterminate progress view with a string variable, use
    /// the corresponding initializer that takes a `StringProtocol` instance.
    ///
    /// - Parameters:
    ///     - titleKey: The key for the progress view's localized title that
    ///       describes the task in progress.
    public init(_ titleKey: LocalizedStringKey) where Label == Text {
        let cpv: CustomProgressView<Text, EmptyView> = CustomProgressView(fractionCompleted: nil, alwaysIndeterminate: true, label: Text(titleKey), currentValueLabel: EmptyView())
        self.base = Base.custom(cpv)
    }

    /// Creates a progress view for showing indeterminate progress that
    /// generates its label from a string.
    ///
    /// - Parameters:
    ///     - title: A string that describes the task in progress.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(verbatim:)``. See ``Text`` for more
    /// information about localizing strings. To initialize a progress view with
    /// a localized string key, use the corresponding initializer that takes a
    /// `LocalizedStringKey` instance.
    @_disfavoredOverload
    public init<S>(_ title: S) where Label == Text, S: StringProtocol {
        let cpv: CustomProgressView<Text, EmptyView> = CustomProgressView(fractionCompleted: nil, alwaysIndeterminate: true, label: Text(title), currentValueLabel: EmptyView())
        self.base = Base.custom(cpv)
    }
    
    private init(label: Label?) {
        self.base = Base.custom(
            CustomProgressView(fractionCompleted: nil,
                               alwaysIndeterminate: true,
                               label: label,
                               currentValueLabel: EmptyView()
            )
        )
    }
}

@available(iOS 13.0, *)
extension ProgressView {

    /// Creates a progress view for showing determinate progress.
    ///
    /// If the value is non-`nil`, but outside the range of `0.0` through
    /// `total`, the progress view pins the value to those limits, rounding to
    /// the nearest possible bound. A value of `nil` represents indeterminate
    /// progress, in which case the progress view ignores `total`.
    ///
    /// - Parameters:
    ///     - value: The completed amount of the task to this point, in a range
    ///       of `0.0` to `total`, or `nil` if the progress is indeterminate.
    ///     - total: The full amount representing the complete scope of the
    ///       task, meaning the task is complete if `value` equals `total`. The
    ///       default value is `1.0`.
    public init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0) where Label == EmptyView, CurrentValueLabel == EmptyView {
        self.init(value: value, total: total, label: EmptyView(), currentValueLabel: EmptyView())
    }

    /// Creates a progress view for showing determinate progress, with a
    /// custom label.
    ///
    /// If the value is non-`nil`, but outside the range of `0.0` through
    /// `total`, the progress view pins the value to those limits, rounding to
    /// the nearest possible bound. A value of `nil` represents indeterminate
    /// progress, in which case the progress view ignores `total`.
    ///
    /// - Parameters:
    ///     - value: The completed amount of the task to this point, in a range
    ///       of `0.0` to `total`, or `nil` if the progress is indeterminate.
    ///     - total: The full amount representing the complete scope of the
    ///       task, meaning the task is complete if `value` equals `total`. The
    ///       default value is `1.0`.
    ///     - label: A view builder that creates a view that describes the task
    ///       in progress.
    public init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0, @ViewBuilder label: () -> Label) where CurrentValueLabel == EmptyView {
        self.init(value: value, total: total, label: label(), currentValueLabel: EmptyView())
    }

    /// Creates a progress view for showing determinate progress, with a
    /// custom label.
    ///
    /// If the value is non-`nil`, but outside the range of `0.0` through
    /// `total`, the progress view pins the value to those limits, rounding to
    /// the nearest possible bound. A value of `nil` represents indeterminate
    /// progress, in which case the progress view ignores `total`.
    ///
    /// - Parameters:
    ///     - value: The completed amount of the task to this point, in a range
    ///       of `0.0` to `total`, or `nil` if the progress is indeterminate.
    ///     - total: The full amount representing the complete scope of the
    ///       task, meaning the task is complete if `value` equals `total`. The
    ///       default value is `1.0`.
    ///     - label: A view builder that creates a view that describes the task
    ///       in progress.
    ///     - currentValueLabel: A view builder that creates a view that
    ///       describes the level of completed progress of the task.
    public init<V: BinaryFloatingPoint>(value: V?, total: V = 1.0, @ViewBuilder label: () -> Label, @ViewBuilder currentValueLabel: () -> CurrentValueLabel) {
#if DEBUG || DANCE_UI_INHOUSE
        if let val = value {
            if val > total {
                runtimeIssue(type: .warning, "ProgressView initialized with an out-of-bounds progress value. The value will be clamped to the range of `0...total`.")
            }
        }
#endif
        self.init(value: value, total: total, label: label(), currentValueLabel: currentValueLabel())
    }

    /// Creates a progress view for showing determinate progress that generates
    /// its label from a localized string.
    ///
    /// If the value is non-`nil`, but outside the range of `0.0` through
    /// `total`, the progress view pins the value to those limits, rounding to
    /// the nearest possible bound. A value of `nil` represents indeterminate
    /// progress, in which case the progress view ignores `total`.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// localized key similar to ``Text/init(_:tableName:bundle:comment:)``. See
    /// ``Text`` for more information about localizing strings. To initialize a
    ///  determinate progress view with a string variable, use
    ///  the corresponding initializer that takes a `StringProtocol` instance.
    ///
    /// - Parameters:
    ///     - titleKey: The key for the progress view's localized title that
    ///       describes the task in progress.
    ///     - value: The completed amount of the task to this point, in a range
    ///       of `0.0` to `total`, or `nil` if the progress is
    ///       indeterminate.
    ///     - total: The full amount representing the complete scope of the
    ///       task, meaning the task is complete if `value` equals `total`. The
    ///       default value is `1.0`.
    public init<V: BinaryFloatingPoint>(_ titleKey: LocalizedStringKey, value: V?, total: V = 1.0) where Label == Text, CurrentValueLabel == EmptyView {
        self.init(value: value, total: total, label: Text(titleKey), currentValueLabel: EmptyView())
    }

    /// Creates a progress view for showing determinate progress that generates
    /// its label from a string.
    ///
    /// If the value is non-`nil`, but outside the range of `0.0` through
    /// `total`, the progress view pins the value to those limits, rounding to
    /// the nearest possible bound. A value of `nil` represents indeterminate
    /// progress, in which case the progress view ignores `total`.
    ///
    /// This initializer creates a ``Text`` view on your behalf, and treats the
    /// title similar to ``Text/init(verbatim:)``. See ``Text`` for more
    /// information about localizing strings. To initialize a determinate
    /// progress view with a localized string key, use the corresponding
    /// initializer that takes a `LocalizedStringKey` instance.
    ///
    /// - Parameters:
    ///     - title: The string that describes the task in progress.
    ///     - value: The completed amount of the task to this point, in a range
    ///       of `0.0` to `total`, or `nil` if the progress is
    ///       indeterminate.
    ///     - total: The full amount representing the complete scope of the
    ///       task, meaning the task is complete if `value` equals `total`. The
    ///       default value is `1.0`.
    @_disfavoredOverload
    public init<S: StringProtocol, V: BinaryFloatingPoint>(_ title: S, value: V?, total: V = 1.0) where Label == Text, CurrentValueLabel == EmptyView {
        self.init(value: value, total: total, label: Text(title), currentValueLabel: EmptyView())
    }
}

@available(iOS 13.0, *)

extension ProgressView {

    /// Creates a progress view based on a style configuration.
    ///
    /// You can use this initializer within the
    /// ``ProgressViewStyle/makeBody(configuration:)`` method of a
    /// ``ProgressViewStyle`` to create an instance of the styled progress view.
    /// This is useful for custom progress view styles that only modify the
    /// current progress view style, as opposed to implementing a brand new
    /// style. Because this modifier style can't know how the current style
    /// represents progress, avoid making assumptions about the view's contents,
    /// such as whether it uses bars or other shapes.
    ///
    /// The following example shows a style that adds a rounded pink border to a
    /// progress view, but otherwise preserves the progress view's current
    /// style:
    ///
    ///     struct PinkBorderedProgressViewStyle: ProgressViewStyle {
    ///         func makeBody(configuration: Configuration) -> some View {
    ///             ProgressView(configuration)
    ///                 .padding(4)
    ///                 .border(.pink, width: 3)
    ///                 .cornerRadius(4)
    ///         }
    ///     }
    ///
    ///
    /// - Note: Progress views in widgets don't apply custom styles.
    public init(_ configuration: ProgressViewStyleConfiguration) where Label == ProgressViewStyleConfiguration.Label, CurrentValueLabel == ProgressViewStyleConfiguration.CurrentValueLabel {
        let cpv: CustomProgressView = CustomProgressView(fractionCompleted: configuration.fractionCompleted,
                                                         alwaysIndeterminate: true,
                                                         label: ProgressViewStyleConfiguration.Label(),
                                                         currentValueLabel: ProgressViewStyleConfiguration.CurrentValueLabel())
        self.base = Base.custom(cpv)
    }
}
