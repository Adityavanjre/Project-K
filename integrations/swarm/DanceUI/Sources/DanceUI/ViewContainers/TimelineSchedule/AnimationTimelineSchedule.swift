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

/// A pausable schedule of dates updating at a frequency no more quickly than
/// the provided interval.
///
/// You can also use ``TimelineSchedule/animation(minimumInterval:paused:)`` to
/// construct this schedule.
@available(iOS 13.0, *)
public struct AnimationTimelineSchedule : TimelineSchedule {
    

    internal var minimumInterval: Double


    internal var paused: Bool

    /// Create a pausable schedule of dates updating at a frequency no more
    /// quickly than the provided interval.
    ///
    /// - Parameters:
    ///     - minimumInterval: The minimum interval to update the schedule at.
    ///     Pass nil to let the system pick an appropriate update interval.
    ///     - paused: If the schedule should stop generating updates.
    public init(minimumInterval: Double? = nil, paused: Bool = false) {
        self.minimumInterval = minimumInterval ?? 1/120
        self.paused = paused
    }

    /// Returns entries at the frequency of the animation schedule.
    ///
    /// When in `.lowFrequency` mode, return no entries, effectively pausing the animation.
    public func entries(from start: Date, mode: TimelineScheduleMode) -> AnimationTimelineSchedule.Entries {
        let interval = (mode == .lowFrequency || paused) ? nil : minimumInterval
        return .init(date: start, interval: interval)
    }

    /// The sequence of dates within a schedule.
    ///
    /// The ``TimelineSchedule/entries(from:mode:)`` method returns a value
    /// of this type, which is a
    /// [Sequence](https://developer.apple.com/documentation/Swift/Sequence)
    /// of dates in ascending order. A ``TimelineView`` that you create with a
    /// schedule updates its content at the moments in time corresponding to
    /// the dates included in the sequence.
    public struct Entries : Sequence, IteratorProtocol {
        

        internal var date: Date

        internal var interval: Double?

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
            guard let interval = interval else { return nil }
            let current = date
            date += interval
            return current
        }

        /// A type representing the sequence's elements.
        public typealias Element = Date

        /// A type that provides the sequence's iteration interface and
        /// encapsulates its iteration state.
        public typealias Iterator = AnimationTimelineSchedule.Entries
    }
}
