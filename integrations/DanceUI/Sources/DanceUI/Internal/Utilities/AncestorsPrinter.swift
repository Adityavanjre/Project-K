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

@available(iOS 13.0, *)
internal enum AncestorsPrinter: CustomStringConvertible {
    
    case leaf(this: String)
    
    indirect case root(child: AncestorsPrinter)
    
    indirect case child(this: String, child: AncestorsPrinter)
    
    internal var description: String {
        recursiveDescription(level: 0, newLineSpaceCount: 0, indent: 2)
    }
    
    private func recursiveDescription(level: Int, newLineSpaceCount: Int, indent: Int) -> String {
        let newLineSpaces = String(repeating: " ", count: newLineSpaceCount)
        switch self {
        case let .root(child):
            assert(level == 0)
            return """
            \(newLineSpaces)Root: \(child.recursiveDescription(level: level, newLineSpaceCount: newLineSpaceCount + 6, indent: indent))
            """
        case let .child(this, child):
            let indents = String(repeating: " ", count: level * indent)
            return """
            \(this)
            \(newLineSpaces)\(indents)+- \(child.recursiveDescription(level: level + 1, newLineSpaceCount: newLineSpaceCount + 1, indent: indent))
            """
        case let .leaf(this):
            return """
            \(this)
            """
        }
    }
    
}
