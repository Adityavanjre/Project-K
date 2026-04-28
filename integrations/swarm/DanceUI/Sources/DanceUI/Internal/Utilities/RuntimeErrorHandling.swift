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

//@_transparent
@_spi(DanceUIExtension)
@available(iOS 13.0, *)
public func _abstract(_ object: AnyObject, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Abstract instance function \(function) at line \(line) in file \(file).")
}

//@_transparent
@_spi(DanceUIExtension)
@available(iOS 13.0, *)
public func _abstract(_ class: AnyClass.Type, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Abstract class function \(function) at line \(line) in file \(file).")
}

@_spi(DanceUIExtension)
@available(iOS 13.0, *)
public func _abstractFunction(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Abstract protocol function \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _notImplemented(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Not implemented function \(function) at line \(line) in file \(file).")
    
}

//@_transparent
@available(iOS 13.0, *)
internal func _notImplemented<T>(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> T {
    _danceuiException("Not implemented function \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _notAvailable(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Not available function \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _notAvailable<T>(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> T {
    _danceuiException("Not available function \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _deletedMethod<T>(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> T {
    _danceuiException("Deleted method \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _missingImplementationCheckpoint<T>(_ value: T, file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> T {
    return value
}

@usableFromInline
@available(iOS 13.0, *)
internal func _terminatedViewNode(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Intentionally terminated `View` node function \(function) at line \(line) in file \(file).")
}

//@_transparent
@available(iOS 13.0, *)
internal func _intentionallyLeftBlank() {
}

//@_transparent
@available(iOS 13.0, *)
public func _abstractExtensionFunction(file: StaticString = #file, line: Int = #line, function: StaticString = #function) -> Never {
    _danceuiException("Abstract Extension protocol function \(function) at line \(line) in file \(file).")
}
