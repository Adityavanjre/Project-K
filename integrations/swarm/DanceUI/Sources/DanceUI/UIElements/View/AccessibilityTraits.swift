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

/// A set of accessibility traits that describe how an element behaves.

@available(iOS 13.0, *)
public struct AccessibilityTraits : SetAlgebra {
    
    /// The type of the elements of an array literal.
    public typealias ArrayLiteralElement = AccessibilityTraits
    
    /// A type for which the conforming type provides a containment test.
    public typealias Element = AccessibilityTraits
    
    internal var traitSet: Set<AccessibilityRawTrait>
    
    /// The accessibility element is a button.
    public static let isButton = AccessibilityTraits(traitSet: [.button])
    
    /// The accessibility element is a header that divides content into
    /// sections, like the title of a navigation bar.
    public static let isHeader = AccessibilityTraits(traitSet: [.header])
    
    /// The accessibility element is currently selected.
    public static let isSelected = AccessibilityTraits(traitSet: [.selected])
    
    /// The accessibility element is a link.
    public static let isLink = AccessibilityTraits(traitSet: [.link])
    
    /// The accessibility element is a search field.
    public static let isSearchField = AccessibilityTraits(traitSet: [.searchField])
    
    /// The accessibility element is an image.
    public static let isImage = AccessibilityTraits(traitSet: [.image])
    
    /// The accessibility element plays its own sound when activated.
    public static let playsSound = AccessibilityTraits(traitSet: [.playsSound])
    
    /// The accessibility element behaves as a keyboard key.
    public static let isKeyboardKey = AccessibilityTraits(traitSet: [.keyboardKey])
    
    /// The accessibility element is a static text that cannot be
    /// modified by the user.
    public static let isStaticText = AccessibilityTraits(traitSet: [.staticText])
    
    /// The accessibility element provides summary information when the
    /// application starts.
    ///
    /// Use this trait to characterize an accessibility element that provides
    /// a summary of current conditions, settings, or state, like the
    /// temperature in the Weather app.
    public static let isSummaryElement = AccessibilityTraits(traitSet: [.summaryElement])
    
    /// The accessibility element frequently updates its label or value.
    ///
    /// Use this trait when you want an assistive technology to poll for
    /// changes when it needs updated information. For example, you might use
    /// this trait to characterize the readout of a stopwatch.
    public static let updatesFrequently = AccessibilityTraits(traitSet: [.updatesFrequently])
    
    /// The accessibility element starts a media session when it is activated.
    ///
    /// Use this trait to silence the audio output of an assistive technology,
    /// such as VoiceOver, during a media session that should not be interrupted.
    /// For example, you might use this trait to silence VoiceOver speech while
    /// the user is recording audio.
    public static let startsMediaSession = AccessibilityTraits(traitSet: [.startsMediaSession])
    
    /// The accessibility element allows direct touch interaction for
    /// VoiceOver users.
    public static let allowsDirectInteraction = AccessibilityTraits(traitSet: [.allowsDirectInteraction])
    
    /// The accessibility element causes an automatic page turn when VoiceOver
    /// finishes reading the text within it.
    public static let causesPageTurn = AccessibilityTraits(traitSet: [.causesPageTurn])
    
    /// The accessibility element is modal.
    ///
    /// Use this trait to restrict which accessibility elements an assistive
    /// technology can navigate. When a modal accessibility element is visible,
    /// sibling accessibility elements that are not modal are ignored.
    public static let isModal = AccessibilityTraits(traitSet: [.modal])
    
    internal static let labelTitle = AccessibilityTraits(traitSet: [.labelTitle])

    internal static let labelIcon = AccessibilityTraits(traitSet: [.labelIcon])
    
    internal static let isProgressIndicator = AccessibilityTraits(traitSet: [.progressIndicator])
    
    internal static let isActivityIndicator = AccessibilityTraits(traitSet: [.activityIndicator])
    
    /// Creates an empty set.
    ///
    /// This initializer is equivalent to initializing with an empty array
    /// literal. For example, you create an empty `Set` instance with either
    /// this initializer or with an empty array literal.
    ///
    ///     var emptySet = Set<Int>()
    ///     print(emptySet.isEmpty)
    ///     // Prints "true"
    ///
    ///     emptySet = []
    ///     print(emptySet.isEmpty)
    ///     // Prints "true"
    public init() {
        self.traitSet = Set()
    }
    
    internal init(traitSet: Set<AccessibilityRawTrait>) {
        self.traitSet = traitSet
    }
    
    /// Returns a new set with the elements of both this and the given set.
    ///
    /// In the following example, the `attendeesAndVisitors` set is made up
    /// of the elements of the `attendees` and `visitors` sets:
    ///
    ///     let attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors = ["Marcia", "Nathaniel"]
    ///     let attendeesAndVisitors = attendees.union(visitors)
    ///     print(attendeesAndVisitors)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     let initialIndices = Set(0..<5)
    ///     let expandedIndices = initialIndices.union([2, 3, 6, 7])
    ///     print(expandedIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set with the unique elements of this set and `other`.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    public func union(_ other: AccessibilityTraits) -> AccessibilityTraits {
        AccessibilityTraits(traitSet: traitSet.union(other.traitSet))
    }
    
    /// Adds the elements of the given set to the set.
    ///
    /// In the following example, the elements of the `visitors` set are added to
    /// the `attendees` set:
    ///
    ///     var attendees: Set = ["Alicia", "Bethany", "Diana"]
    ///     let visitors: Set = ["Diana", "Marcia", "Nathaniel"]
    ///     attendees.formUnion(visitors)
    ///     print(attendees)
    ///     // Prints "["Diana", "Nathaniel", "Bethany", "Alicia", "Marcia"]"
    ///
    /// If the set already contains one or more elements that are also in
    /// `other`, the existing members are kept.
    ///
    ///     var initialIndices = Set(0..<5)
    ///     initialIndices.formUnion([2, 3, 6, 7])
    ///     print(initialIndices)
    ///     // Prints "[2, 4, 6, 7, 0, 1, 3]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    public mutating func formUnion(_ other: AccessibilityTraits) {
        traitSet.formUnion(other.traitSet)
    }
    
    /// Returns a new set with the elements that are common to both this set and
    /// the given set.
    ///
    /// In the following example, the `bothNeighborsAndEmployees` set is made up
    /// of the elements that are in *both* the `employees` and `neighbors` sets.
    /// Elements that are in only one or the other are left out of the result of
    /// the intersection.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     let bothNeighborsAndEmployees = employees.intersection(neighbors)
    ///     print(bothNeighborsAndEmployees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    ///
    /// - Note: if this set and `other` contain elements that are equal but
    ///   distinguishable (e.g. via `===`), which of these elements is present
    ///   in the result is unspecified.
    public func intersection(_ other: AccessibilityTraits) -> AccessibilityTraits {
        AccessibilityTraits(traitSet: traitSet.intersection(other.traitSet))
    }
    
    /// Removes the elements of this set that aren't also in the given set.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// not also members of the `neighbors` set are removed. In particular, the
    /// names `"Alicia"`, `"Chris"`, and `"Diana"` are removed.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Chris", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani", "Greta"]
    ///     employees.formIntersection(neighbors)
    ///     print(employees)
    ///     // Prints "["Bethany", "Eric"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    public mutating func formIntersection(_ other: AccessibilityTraits) {
        traitSet.formIntersection(other.traitSet)
    }
    
    /// Returns a new set with the elements that are either in this set or in the
    /// given set, but not in both.
    ///
    /// In the following example, the `eitherNeighborsOrEmployees` set is made up
    /// of the elements of the `employees` and `neighbors` sets that are not in
    /// both `employees` *and* `neighbors`. In particular, the names `"Bethany"`
    /// and `"Eric"` do not appear in `eitherNeighborsOrEmployees`.
    ///
    ///     let employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     let eitherNeighborsOrEmployees = employees.symmetricDifference(neighbors)
    ///     print(eitherNeighborsOrEmployees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type as the current set.
    /// - Returns: A new set.
    public func symmetricDifference(_ other: AccessibilityTraits) -> AccessibilityTraits {
        AccessibilityTraits(traitSet: traitSet.symmetricDifference(other.traitSet))
    }
    
    /// Removes the elements of the set that are also in the given set and adds
    /// the members of the given set that are not already in the set.
    ///
    /// In the following example, the elements of the `employees` set that are
    /// also members of `neighbors` are removed from `employees`, while the
    /// elements of `neighbors` that are not members of `employees` are added to
    /// `employees`. In particular, the names `"Bethany"` and `"Eric"` are
    /// removed from `employees` while the name `"Forlani"` is added.
    ///
    ///     var employees: Set = ["Alicia", "Bethany", "Diana", "Eric"]
    ///     let neighbors: Set = ["Bethany", "Eric", "Forlani"]
    ///     employees.formSymmetricDifference(neighbors)
    ///     print(employees)
    ///     // Prints "["Diana", "Forlani", "Alicia"]"
    ///
    /// - Parameter other: A set of the same type.
    public mutating func formSymmetricDifference(_ other: AccessibilityTraits) {
        traitSet.formSymmetricDifference(other.traitSet)
    }
    
    /// Returns a Boolean value that indicates whether the given element exists
    /// in the set.
    ///
    /// This example uses the `contains(_:)` method to test whether an integer is
    /// a member of a set of prime numbers.
    ///
    ///     let primes: Set = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37]
    ///     let x = 5
    ///     if primes.contains(x) {
    ///         print("\(x) is prime!")
    ///     } else {
    ///         print("\(x). Not prime.")
    ///     }
    ///     // Prints "5 is prime!"
    ///
    /// - Parameter member: An element to look for in the set.
    /// - Returns: `true` if `member` exists in the set; otherwise, `false`.
    public func contains(_ member: AccessibilityTraits) -> Bool {
        member.traitSet.isSubset(of: traitSet)
    }
    
    /// Inserts the given element in the set if it is not already present.
    ///
    /// If an element equal to `newMember` is already contained in the set, this
    /// method has no effect. In this example, a new element is inserted into
    /// `classDays`, a set of days of the week. When an existing element is
    /// inserted, the `classDays` set does not change.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.wednesday, .friday]
    ///     print(classDays.insert(.monday))
    ///     // Prints "(true, .monday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    ///     print(classDays.insert(.friday))
    ///     // Prints "(false, .friday)"
    ///     print(classDays)
    ///     // Prints "[.friday, .wednesday, .monday]"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Returns: `(true, newMember)` if `newMember` was not contained in the
    ///   set. If an element equal to `newMember` was already contained in the
    ///   set, the method returns `(false, oldMember)`, where `oldMember` is the
    ///   element that was equal to `newMember`. In some cases, `oldMember` may
    ///   be distinguishable from `newMember` by identity comparison or some
    ///   other means.
    @discardableResult
    public mutating func insert(_ newMember: AccessibilityTraits) -> (inserted: Bool, memberAfterInsert: AccessibilityTraits) {
        guard !contains(newMember) else {
            return (false, newMember)
        }
        traitSet.formUnion(newMember.traitSet)
        return (true, newMember)
    }
    
    /// Removes the given element and any elements subsumed by the given element.
    ///
    /// - Parameter member: The element of the set to remove.
    /// - Returns: For ordinary sets, an element equal to `member` if `member` is
    ///   contained in the set; otherwise, `nil`. In some cases, a returned
    ///   element may be distinguishable from `member` by identity comparison
    ///   or some other means.
    ///
    ///   For sets where the set type and element type are the same, like
    ///   `OptionSet` types, this method returns any intersection between the set
    ///   and `[member]`, or `nil` if the intersection is empty.
    @discardableResult
    public mutating func remove(_ member: AccessibilityTraits) -> AccessibilityTraits? {
        let intersection = traitSet.intersection(member.traitSet)
        intersection.forEach {
            traitSet.remove($0)
        }
        return intersection.isEmpty ? nil : AccessibilityTraits(traitSet: intersection)
    }
    
    /// Inserts the given element into the set unconditionally.
    ///
    /// If an element equal to `newMember` is already contained in the set,
    /// `newMember` replaces the existing element. In this example, an existing
    /// element is inserted into `classDays`, a set of days of the week.
    ///
    ///     enum DayOfTheWeek: Int {
    ///         case sunday, monday, tuesday, wednesday, thursday,
    ///             friday, saturday
    ///     }
    ///
    ///     var classDays: Set<DayOfTheWeek> = [.monday, .wednesday, .friday]
    ///     print(classDays.update(with: .monday))
    ///     // Prints "Optional(.monday)"
    ///
    /// - Parameter newMember: An element to insert into the set.
    /// - Returns: For ordinary sets, an element equal to `newMember` if the set
    ///   already contained such a member; otherwise, `nil`. In some cases, the
    ///   returned element may be distinguishable from `newMember` by identity
    ///   comparison or some other means.
    ///
    ///   For sets where the set type and element type are the same, like
    ///   `OptionSet` types, this method returns any intersection between the
    ///   set and `[newMember]`, or `nil` if the intersection is empty.
    @discardableResult
    public mutating func update(with newMember: AccessibilityTraits) -> AccessibilityTraits? {
        let intersection = traitSet.intersection(newMember.traitSet)
        traitSet.formUnion(newMember.traitSet)
        return intersection.isEmpty ? nil : AccessibilityTraits(traitSet: intersection)
    }
    
}
