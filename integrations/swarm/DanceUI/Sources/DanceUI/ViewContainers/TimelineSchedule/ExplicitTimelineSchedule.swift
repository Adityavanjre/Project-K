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


/// A schedule for updating a timeline view at explicit points in time.
///
/// You can also use ``TimelineSchedule/explicit(_:)`` to construct this
/// schedule.
@available(iOS 13.0, *)
public struct ExplicitTimelineSchedule<Entries> : TimelineSchedule where Entries : Sequence, Entries.Element == Date {

    internal var entries: Entries
    
    /// Creates a schedule composed of an explicit sequence of dates.
    ///
    /// Use the ``ExplicitTimelineSchedule/entries(from:mode:)`` method
    /// to get the sequence of dates.
    ///
    /// - Parameter dates: The sequence of dates at which a timeline view
    ///   updates. Use a monotonically increasing sequence of dates,
    ///   and ensure that at least one is in the future.
    public init(_ dates: Entries) {
        self.entries = dates
    }

    /// Provides the sequence of dates with which you initialized the schedule.
    ///
    /// A ``TimelineView`` that you create with a schedule calls this
    /// ``TimelineSchedule`` method to ask the schedule when to update its
    /// content. The explicit timeline schedule implementation
    /// of this method returns the unmodified sequence of dates that you
    /// provided when you created the schedule with
    /// ``TimelineSchedule/explicit(_:)``. As a result, this particular
    /// implementation ignores the `startDate` and `mode` parameters.
    ///
    /// - Parameters:
    ///   - startDate: The date from which the sequence begins. This
    ///     particular implementation of the protocol method ignores the start
    ///     date.
    ///   - mode: The mode for the update schedule. This particular
    ///     implementation of the protocol method ignores the mode.
    /// - Returns: The sequence of dates that you provided at initialization.
    public func entries(from startDate: Date, mode: TimelineScheduleMode) -> Entries {
        entries
    }
}
