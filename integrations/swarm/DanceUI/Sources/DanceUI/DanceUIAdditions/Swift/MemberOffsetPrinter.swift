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

#if DEBUG || DANCE_UI_INHOUSE


@available(iOS 13.0, *)
internal func printMemberOffsets<RootType>(for rootType: RootType.Type) {
    var outputs = String()
    printMemberOffsets(for: rootType, to: &outputs)
    logger.debug(Logger.Message(stringLiteral: outputs))
}


@available(iOS 13.0, *)
internal func printMemberOffsets<RootType, Stream: TextOutputStream>(for rootType: RootType.Type, to stream: inout Stream) {
    let behaviors: DynamicPropertyBehaviors = [.continueWhenUnknown]
    forEachField(of: rootType, options: behaviors) { (namePtr, offset, metadata) in
        let name = String(bytesNoCopy: UnsafeMutablePointer(mutating: namePtr), length: strlen(namePtr), encoding: .utf8, freeWhenDone: false)!
        print("[\(_typeName(rootType))] offset of .\(name) : 0x\(String(offset, radix: 16))", to: &stream)
        return true
    }
}

#endif // DEBUG || DANCE_UI_INHOUSE
