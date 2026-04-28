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
import XCTest

struct TestingError: Error, Hashable, Codable, CustomStringConvertible {
    let description: String

    static func == (lhs: TestingError, rhs: String) -> Bool {
        return lhs.description == rhs
    }

    static func == (lhs: String, rhs: TestingError) -> Bool {
        return lhs == rhs.description
    }

    static func != (lhs: TestingError, rhs: String) -> Bool {
        return !(lhs == rhs)
    }

    static func != (lhs: String, rhs: TestingError) -> Bool {
        return !(lhs == rhs)
    }

    static let oops: TestingError = "oops"
}

extension TestingError: LocalizedError {
    var errorDescription: String? { return description }
}

extension TestingError: ExpressibleByStringLiteral {
    init(stringLiteral value: String) {
        self.init(description: value)
    }
}

protocol EquatableError: Error {
    func isEqual(_ other: EquatableError) -> Bool
}

extension EquatableError where Self: Equatable {
    func isEqual(_ other: EquatableError) -> Bool {
        return self == (other as? Self)
    }
}

extension TestingError: EquatableError {}

extension NSError: EquatableError {}

func assertThrowsError<Result>(_ expression: @autoclosure () throws -> Result,
                               _ expected: TestingError,
                               _ message: @autoclosure () -> String = "") {
    XCTAssertThrowsError(try expression(), message()) { error in
        if let error = error as? TestingError {
            XCTAssertEqual(error, expected)
        } else {
            XCTFail(message())
        }
    }
}

// swiftlint:disable:next generic_type_name
func throwing<A, B, C>(_: A, _: B) throws -> C {
    throw TestingError.oops
}

// swiftlint:disable:next generic_type_name
func throwing<A, B>(_: A) throws -> B {
    throw TestingError.oops
}
