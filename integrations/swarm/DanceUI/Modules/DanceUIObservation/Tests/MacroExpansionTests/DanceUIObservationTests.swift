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

import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import DanceUIObservationMacroImpl
import XCTest

fileprivate let testMacros: [String: Macro.Type] = [
    "Observable": ObservableMacro.self,
    "ObservationTracked": ObservationTrackedMacro.self,
    "ObservationIgnored": ObservationIgnoredMacro.self,
]

final class DanceUIObservationTests: XCTestCase {
    func testObservable() throws {
        assertMacroExpansion(
            """
            @Observable
            public class Foo {
            }
            """,
            expandedSource: """
            public class Foo {
            
                private let _$observationRegistrar = DanceUIObservation.ObservationRegistrar()
            
                internal nonisolated func access<Member>(
                    keyPath: KeyPath<Foo, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }
            
                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<Foo, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testObservableWithSimpleMember() throws {
        assertMacroExpansion(
            """
            @Observable
            public class Foo {
            
                var foo: Int
            
                init(foo: Int) {
                    self.foo = foo
                }
            
            }
            """,
            expandedSource: """
            public class Foo {
            
                var foo: Int {
                    @storageRestrictions(initializes: _foo)
                    init(initialValue) {
                        _foo = initialValue
                    }
                    get {
                        access(keyPath: \\.foo)
                        return _foo
                    }
                    set {
                        withMutation(keyPath: \\.foo) {
                            _foo = newValue
                        }
                    }
                    _modify {
                        access(keyPath: \\.foo)
                        _$observationRegistrar.willSet(self, keyPath: \\.foo)
                        defer {
                            _$observationRegistrar.didSet(self, keyPath: \\.foo)
                        }
                        yield &_foo
                    }
                }
            
                init(foo: Int) {
                    self.foo = foo
                }
            
                private let _$observationRegistrar = DanceUIObservation.ObservationRegistrar()
            
                internal nonisolated func access<Member>(
                    keyPath: KeyPath<Foo, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }
            
                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<Foo, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }
            
            }
            """,
            macros: testMacros
        )
    }
    
    func testObservableWithObservationIgnored() throws {
        assertMacroExpansion(
            """
            @Observable
            public class Foo {
            
                @ObservationIgnored
                var foo: Int
            
                init(foo: Int) {
                    self.foo = foo
                }
            
            }
            """,
            expandedSource: """
            public class Foo {
                var foo: Int
            
                init(foo: Int) {
                    self.foo = foo
                }
            
                private let _$observationRegistrar = DanceUIObservation.ObservationRegistrar()
            
                internal nonisolated func access<Member>(
                    keyPath: KeyPath<Foo, Member>
                ) {
                    _$observationRegistrar.access(self, keyPath: keyPath)
                }
            
                internal nonisolated func withMutation<Member, MutationResult>(
                    keyPath: KeyPath<Foo, Member>,
                    _ mutation: () throws -> MutationResult
                ) rethrows -> MutationResult {
                    try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
                }
            
            }
            """,
            macros: testMacros
        )
    }
}
