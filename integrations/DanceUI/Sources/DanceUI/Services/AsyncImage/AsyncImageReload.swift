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

internal import DanceUIGraph

@available(iOS 13.0, *)
fileprivate struct AsyncImageReloadWriter: _GraphInputsModifier, ViewModifier {

    fileprivate typealias Body = Never
    
    fileprivate let times: Int

    fileprivate static func _makeInputs(modifier: _GraphValue<AsyncImageReloadWriter>, inputs: inout _GraphInputs) {
        inputs.asyncImageReload = _GraphValue(modifier[\.times].value)
    }
}

@available(iOS 13.0, *)
fileprivate struct AsyncImageReloadInput : ViewInput {
    
    fileprivate typealias Value = _GraphValue<Int>?
    
    @inline(__always)
    fileprivate static var defaultValue: Value { nil }
}

@available(iOS 13.0, *)
extension View {
    
    public func imageReload(_ times: Int) -> some View {
        modifier(AsyncImageReloadWriter(times: times))
    }
}

@available(iOS 13.0, *)
extension _GraphInputs {

    @inline(__always)
    internal var asyncImageReload: _GraphValue<Int>? {
        get {
            self[AsyncImageReloadInput.self]
        }
        set {
            self[AsyncImageReloadInput.self] = newValue
        }
    }
}

@available(iOS 13.0, *)
extension _ViewInputs {

    @inline(__always)
    internal var asyncImageReload: _GraphValue<Int>? {
        self[AsyncImageReloadInput.self]
    }
}

@available(iOS 13.0, *)
extension _ViewListInputs {
    
    @inline(__always)
    internal var asyncImageReload: _GraphValue<Int>? {
        self[AsyncImageReloadInput.self]
    }
}
