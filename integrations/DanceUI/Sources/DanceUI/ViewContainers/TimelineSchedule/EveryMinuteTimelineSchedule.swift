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

/// A schedule for updating a timeline view at the start of every minute.
///
/// You can also use ``TimelineSchedule/everyMinute`` to construct this
/// schedule.
@available(iOS 13.0, *)
public struct EveryMinuteTimelineSchedule : TimelineSchedule {

    /// The sequence of dates in an every minute schedule.
    ///
    /// The ``EveryMinuteTimelineSchedule/entries(from:mode:)`` method returns
    /// a value of this type, which is a
    /// [Sequence](https://developer.apple.com/documentation/Swift/Sequence)
    /// of dates, one per minute, in ascending order. A ``TimelineView`` that
    /// you create updates its content at the moments in time corresponding to
    /// the dates included in the sequence.
    public struct Entries : Sequence, IteratorProtocol {
        
        internal var nextDate: Date?
        
        internal init(startDate: Foundation.Date) {
            if Calendar.current.date(startDate, matchesComponents: Self.zeroSecondComponents) {
                self.nextDate = startDate
            } else {
                self.nextDate = Calendar.current.nextDate(after: startDate, matching: Self.zeroSecondComponents, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .backward) ?? startDate
            }
        }

        /// Advances to the next element and returns it, or `nil` if no next element
        /// exists.
        ///
        /// Repeatedly calling this method returns, in order, all the elements of the
        /// underlying sequence. As soon as the sequence has run out of elements, all
        /// subsequent calls return `nil`.
        ///
        /// You must not call this method if any other copy of this iterator has been
        /// advanced with a call to its `next()` method.
        ///
        /// The following example shows how an iterator can be used explicitly to
        /// emulate a `for`-`in` loop. First, retrieve a sequence's iterator, and
        /// then call the iterator's `next()` method until it returns `nil`.
        ///
        ///     let numbers = [2, 3, 5, 7]
        ///     var numbersIterator = numbers.makeIterator()
        ///
        ///     while let num = numbersIterator.next() {
        ///         print(num)
        ///     }
        ///     // Prints "2"
        ///     // Prints "3"
        ///     // Prints "5"
        ///     // Prints "7"
        ///
        /// - Returns: The next element in the underlying sequence, if a next element
        ///   exists; otherwise, `nil`.
        public mutating func next() -> Date? {
            guard let nextDate = nextDate else {
                return nil
            }
            self.nextDate = Calendar.current.nextDate(after: nextDate, matching: Self.zeroSecondComponents, matchingPolicy: .nextTime, repeatedTimePolicy: .first, direction: .forward)
            return nextDate
        }

        /// A type representing the sequence's elements.
        public typealias Element = Date

        /// A type that provides the sequence's iteration interface and
        /// encapsulates its iteration state.
        public typealias Iterator = EveryMinuteTimelineSchedule.Entries
        
        internal static var zeroSecondComponents : DateComponents {
            .init(calendar: nil, timeZone: nil, era: nil, year: nil, month: nil, day: nil, hour: nil, minute: nil, second: 0, nanosecond: 0, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
        }
        
        
    }

    /// Creates a per-minute update schedule.
    ///
    /// Use the ``EveryMinuteTimelineSchedule/entries(from:mode:)`` method
    /// to get the sequence of dates.
    public init() { }

    /// Provides a sequence of per-minute dates starting from a given date.
    ///
    /// A ``TimelineView`` that you create with an every minute schedule
    /// calls this method to ask the schedule when to update its content.
    /// The method returns a sequence of per-minute dates in increasing
    /// order, from earliest to latest, that represents
    /// when the timeline view updates.
    ///
    /// For a `startDate` that's exactly minute-aligned, the
    /// schedule's sequence of dates starts at that time. Otherwise, it
    /// starts at the beginning of the specified minute. For
    /// example, for start dates of both `10:09:32` and `10:09:00`, the first
    /// entry in the sequence is `10:09:00`.
    ///
    /// - Parameters:
    ///   - startDate: The date from which the sequence begins.
    ///   - mode: The mode for the update schedule.
    /// - Returns: A sequence of per-minute dates in ascending order.
    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> EveryMinuteTimelineSchedule.Entries {
        .init(startDate: startDate)
    }
}
