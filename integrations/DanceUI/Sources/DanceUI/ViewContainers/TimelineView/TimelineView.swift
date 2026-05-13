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
internal import DanceUIGraph
@_spi(DanceUI) import DanceUIObservation

/// A view that updates according to a schedule that you provide.
///
/// A timeline view acts as a container with no appearance of its own. Instead,
/// it redraws the content it contains at scheduled points in time.
/// For example, you can update the face of an analog timer once per second:
///
///     TimelineView(.periodic(from: startDate, by: 1)) { context in
///         AnalogTimerView(date: context.date)
///     }
///
/// The closure that creates the content receives an input of type ``Context``
/// that you can use to customize the content's appearance. The context includes
/// the ``Context/date`` that triggered the update. In the example above,
/// the timeline view sends that date to an analog timer that you create so the
/// timer view knows how to draw the hands on its face.
///
/// The context also includes a ``Context/cadence-swift.property``
/// property that you can use to hide unnecessary detail. For example, you
/// can use the cadence to decide when it's appropriate to display the
/// timer's second hand:
///
///     TimelineView(.periodic(from: startDate, by: 1.0)) { context in
///         AnalogTimerView(
///             date: context.date,
///             showSeconds: context.cadence <= .seconds)
///     }
///
/// The system might use a cadence that's slower than the schedule's
/// update rate. For example, a view on watchOS might remain visible when the
/// user lowers their wrist, but update less frequently, and thus require
/// less detail.
///
/// You can define a custom schedule by creating a type that conforms to the
/// ``TimelineSchedule`` protocol, or use one of the built-in schedule types:
/// * Use an ``TimelineSchedule/everyMinute`` schedule to update at the
///   beginning of each minute.
/// * Use a ``TimelineSchedule/periodic(from:by:)`` schedule to update
///   periodically with a custom start time and interval between updates.
/// * Use an ``TimelineSchedule/explicit(_:)`` schedule when you need a finite number, or
///   irregular set of updates.
///
/// For a schedule containing only dates in the past,
/// the timeline view shows the last date in the schedule.
/// For a schedule containing only dates in the future,
/// the timeline draws its content using the current date
/// until the first scheduled date arrives.
@available(iOS 13.0, *)
public struct TimelineView<Schedule, Content> where Schedule : TimelineSchedule {
    
    internal var schedule: Schedule

    internal var content: (Context) -> Content

    /// Information passed to a timeline view's content callback.
    ///
    /// The context includes both the ``date`` from the schedule that triggered
    /// the callback, and a ``cadence-swift.property`` that you can use
    /// to customize the appearance of your view. For example, you might choose
    /// to display the second hand of an analog clock only when the cadence is
    /// ``Cadence-swift.enum/seconds`` or faster.
    public struct Context {

        /// A rate at which timeline views can receive updates.
        ///
        /// Use the cadence presented to content in a ``TimelineView`` to hide
        /// information that updates faster than the view's current update rate.
        /// For example, you could hide the millisecond component of a digital
        /// timer when the cadence is ``seconds`` or ``minutes``.
        ///
        /// Because this enumeration conforms to the
        /// [Comparable](https://developer.apple.com/documentation/Swift/Comparable)
        /// protocol, you can compare cadences with relational operators.
        /// Slower cadences have higher values, so you could perform the check
        /// described above with the following comparison:
        ///
        ///     let hideMilliseconds = cadence > .live
        ///
        public enum Cadence : Comparable {

            /// Updates the view continuously.
            case live

            /// Updates the view approximately once per second.
            case seconds

            /// Updates the view approximately once per minute.
            case minutes
        }

        /// The date from the schedule that triggered the current view update.
        ///
        /// The first time a ``TimelineView`` closure receives this date, it
        /// might be in the past. For example, if you create an
        /// ``TimelineSchedule/everyMinute`` schedule at `10:09:55`, the
        /// schedule creates entries `10:09:00`, `10:10:00`, `10:11:00`, and so
        /// on. In response, the timeline view performs an initial update
        /// immediately, at `10:09:55`, but the context contains the `10:09:00`
        /// date entry. Subsequent entries arrive at their corresponding times.
        public let date: Date

        /// The rate at which the timeline updates the view.
        ///
        /// Use this value to hide information that updates faster than the
        /// view's current update rate. For example, you could hide the
        /// millisecond component of a digital timer when the cadence is
        /// anything slower than ``Cadence-swift.enum/live``.
        ///
        /// Because the ``Cadence-swift.enum`` enumeration conforms to the
        /// [Comparable](https://developer.apple.com/documentation/Swift/Comparable)
        /// protocol, you can compare cadences with relational operators.
        /// Slower cadences have higher values, so you could perform the check
        /// described above with the following comparison:
        ///
        ///     let hideMilliseconds = cadence > .live
        ///
        public let cadence: Cadence
        
        public init(date: Date, cadence: Cadence) {
            self.date = date
            self.cadence = cadence
        }
    }
}

@available(iOS 13.0, *)
extension TimelineView.Context.Cadence : Hashable {
}

@available(iOS 13.0, *)
extension TimelineView: UnaryView, PrimitiveView where Content : View {

}

@available(iOS 13.0, *)
extension TimelineView : View where Content : View {
    
    /// The type of view representing the body of this view.
    ///
    /// When you create a custom view, Swift infers this type from your
    /// implementation of the required ``View/body-swift.property`` property.
    public typealias Body = Never

    /// Creates a new timeline view that uses the given schedule.
    ///
    /// - Parameters:
    ///   - schedule: A schedule that produces a sequence of dates that
    ///     indicate the instances when the view should update.
    ///     Use a type that conforms to ``TimelineSchedule``, like
    ///     ``TimelineSchedule/everyMinute``, or a custom timeline schedule
    ///     that you define.
    ///   - content: A closure that generates view content at the moments
    ///     indicated by the schedule. The closure takes an input of type
    ///     ``Context`` that includes the date from the schedule that
    ///     prompted the update, as well as a ``Context/Cadence-swift.enum``
    ///     value that the view can use to customize its appearance.
#if swift(>=5.8)
    @available(*, deprecated, message: "Use TimelineViewDefaultContext for the type of the context parameter passed into TimelineView's content closure to resolve this warning. The new version of this initializer, using TimelineViewDefaultContext, improves compilation performance by using an independent generic type signature, which helps avoid unintended cyclical type dependencies.")
    @_disfavoredOverload public init(_ schedule: Schedule, @ViewBuilder content: @escaping (TimelineView<Schedule, Content>.Context) -> Content) {
        self.schedule = schedule
        self.content = content
    }
#else
    public init(_ schedule: Schedule, @ViewBuilder content: @escaping (TimelineView<Schedule, Content>.Context) -> Content) {
        self.schedule = schedule
        self.content = content
    }
#endif
    
#if swift(>=5.8)
    /// Creates a new timeline view that uses the given schedule.
    ///
    /// - Parameters:
    ///   - schedule: A schedule that produces a sequence of dates that
    ///     indicate the instances when the view should update.
    ///     Use a type that conforms to ``TimelineSchedule``, like
    ///     ``TimelineSchedule/everyMinute``, or a custom timeline schedule
    ///     that you define.
    ///   - content: A closure that generates view content at the moments
    ///     indicated by the schedule. The closure takes an input of type
    ///     ``TimelineViewDefaultContext`` that includes the date from the schedule that
    ///     prompted the update, as well as a ``Context/Cadence-swift.enum``
    ///     value that the view can use to customize its appearance.
    public typealias TimelineViewDefaultContext = TimelineView<EveryMinuteTimelineSchedule, Never>.Context
    @inline(__always)
    public init(_ schedule: Schedule, @ViewBuilder content: @escaping (TimelineViewDefaultContext) -> Content) {
        self.init(schedule) { (context: Context) -> Content in
            // We can't back deploy a conversion between the different context
            // types, but they have the same layout since they don't ever use
            // the types they're generic over, so we unsafe cast between them.
            content(unsafeBitCast(
                context,
                to: TimelineViewDefaultContext.self))
        }
    }
#endif
    
    public static func _makeView(view: _GraphValue<TimelineView<Schedule, Content>>, inputs: _ViewInputs) -> _ViewOutputs {
        let filter = UpdateFilter(view: view.value,
                                  schedule: view[ {.of(&$0.schedule)} ].value,
                                  phase: inputs.phase,
                                  time: inputs.time,
                                  resetSeed: 0,
                                  iterator: nil,
                                  currentTime: .infinity,
                                  nextTime: .infinity,
                                  cadence: .live)
        
        let attribute = Attribute(filter)

        attribute.flags = .removable

        
        let graphValue = _GraphValue(attribute)
        
        return Content.makeDebuggableView(value: graphValue, inputs: inputs)
    }
}

@available(iOS 13.0, *)
extension TimelineView {
    fileprivate struct UpdateFilter : StatefulRule, ObservationAttribute {
        
        fileprivate typealias Value = Content
        

        @Attribute
        fileprivate var view: TimelineView<Schedule, Content>


        @Attribute
        fileprivate var schedule: Schedule


        @Attribute
        fileprivate var phase: _GraphInputs.Phase


        @Attribute
        fileprivate var time: Time


        fileprivate var resetSeed: UInt32

        fileprivate var iterator: Schedule.Entries.Iterator?

        fileprivate var currentTime: Double

        fileprivate var nextTime: Double

        fileprivate var cadence: Context.Cadence
        

        fileprivate var previousObservationTrackings: [ObservationTracking]?
        

        fileprivate var deferredObservationGraphMutation: DeferredObservationGraphMutation?
        
        fileprivate mutating func updateValue() {
            let oldTime = currentTime
            if phase.seed != resetSeed {
                self.resetSeed = phase.seed
                self.iterator = nil
                self.currentTime = .infinity
                self.nextTime = .infinity
            }
            
            let (_, changed) = $schedule.changedValue()
            
            let date = Date()
            let interval = date.timeIntervalSinceReferenceDate
            if changed || iterator == nil {
                let newIterator = view.schedule.entries(from: date, mode: .normal).makeIterator()
                iterator = newIterator
                nextTime = .infinity
                if let currentDate = iterator?.next() {
                    currentTime = currentDate.timeIntervalSinceReferenceDate
                }
                if let nextDate = iterator?.next() {
                    nextTime = nextDate.timeIntervalSinceReferenceDate
                }
            }
            if interval >= nextTime {
                while let iteratorDate = iterator?.next() {
                    currentTime = nextTime
                    nextTime = iteratorDate.timeIntervalSinceReferenceDate
                    if nextTime > interval {
                        break
                    }
                }
            }
            if currentTime == .infinity {
                currentTime = interval
            }
            if cadence != .seconds || currentTime != oldTime || optionalValue == nil || AnyRuleContext.wasModified {
                let context = Context(date: Date(timeIntervalSinceReferenceDate: currentTime), cadence: .live)

                let (view, isViewChanged) = $view.changedValue()

                value = withObservation(shouldCancelPrevious: isViewChanged) {
                    view.content(context)
                }
            }
            if nextTime < .infinity {
                let graph = GraphHost.currentHost as? ViewGraph
                let advancedTime = time.advanced(by: nextTime - interval)
                graph?.scheduleNextViewUpdate(byTime: advancedTime)
            }
        }
    }
}
