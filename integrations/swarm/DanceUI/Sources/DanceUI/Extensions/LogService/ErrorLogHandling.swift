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


// swift-format-ignore: AlwaysUseLowerCamelCase
@available(iOS 13.0, *)
internal func _danceuiPrecondition(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    let result = condition()
    let errMessage = message()
    if !_fastPath(result) {
        setupErrorLog(errMessage, .precondition, file, line)
    }
    precondition(result, errMessage, file: file, line: line)
}

@available(iOS 13.0, *)
internal func _danceuiPreconditionFailure(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    let errMessage = message()
    setupErrorLog(errMessage, .fatalError, file, line)
    preconditionFailure(errMessage, file: file, line: line)
}

@available(iOS 13.0, *)
internal func _danceuiFatalError(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    let errMessage = message()
    setupErrorLog(errMessage, .fatalError, file, line)
    fatalError(errMessage, file: file, line: line)
}

@available(iOS 13.0, *)
internal func _danceuiException(_ message: String) -> Never {
    NSException(name: .internalInconsistencyException, reason: message).raise()
    exit(1)
}

@available(iOS 13.0, *)
private func setupErrorLog(_ errMessage: String, _ error: DanceUICrashError, _ file: StaticString, _ line: UInt = #line) {
    let errFile = file.description.components(separatedBy: "/").last ?? file.description
    let errLog = "\(errFile):\(line): \(error.rawValue): \(errMessage)"
}

@available(iOS 13.0, *)
private enum DanceUICrashError: String {
    case fatalError = "Fatal error"
    case precondition = "Precondition failed"
}
