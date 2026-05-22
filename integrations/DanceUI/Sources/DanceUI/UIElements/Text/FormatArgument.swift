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
internal import DanceUIGraph
internal import DanceUIRuntime

@available(iOS 13.0, *)
extension LocalizedStringKey {
    
    @usableFromInline
    internal struct FormatArgument: Equatable {
        internal let storage: Storage

        internal enum Storage: Equatable {
            
            internal static func == (lhs: LocalizedStringKey.FormatArgument.Storage, rhs: LocalizedStringKey.FormatArgument.Storage) -> Bool {
                switch (lhs, rhs) {
                case (.value(let lhs), .value(let rhs)):
                    return lhs.1 == rhs.1 && DGCompareValues(lhs: lhs.0, rhs: rhs.0)
                case (.text(let lhs), .text(let rhs)):
                    return lhs.1 == rhs.1 && lhs.0 == rhs.0
                case (.formatStyleValue(let lhs), .formatStyleValue(let rhs)):
                    return lhs.isEqual(to: rhs)
                case (.attributedString(let lhs), .attributedString(let rhs)):
                    return lhs == rhs
                default:
                    return false
                }
            }
            
            case value((CVarArg, Formatter?))
            case text((Text, Token))
            case formatStyleValue(FormatStyleBoxBase)
            case attributedString(NSAttributedString) // should be AttributedString

        }
        
        internal func resolve(in environment: EnvironmentValues) -> CVarArg {
            switch storage {
            case .value((let arg, let formatter)):
                guard let formatter = formatter else {
                    return arg
                }
                
                if let configurableFormatter = formatter as? EnvironmentConfigurableFormatter {
                    configurableFormatter.configure(in: environment)
                }
                
                if let result = formatter.string(for: arg) {
                    return result
                }
                
                return ""
            case .text((_, let token)):
                return "\(Token.delimiter)\(token.id)\(Token.delimiter)"
            case .formatStyleValue(let formatStyleBoxBase):
                return formatStyleBoxBase.format(in: environment)
            case .attributedString(let nsAttributedString):
                return nsAttributedString
            }
        }
        
        internal struct Token: Equatable {
            
            internal let id: Int
            
            @usableFromInline
            internal static let delimiter : Character = {
                let string: String = {
                    let data = Data([0xef, 0xbf, 0xbc])
                    return data.withUnsafeBytes { (dataBytes: UnsafeRawBufferPointer) -> String in
                        let datas = UnsafeBufferPointer<UInt8>(start: dataBytes.bindMemory(to: UInt8.self).baseAddress!, count: 3)
                        return String._tryFromUTF8(datas)!
                    }
                }()
                return Character(string)
            }()
        }
    }
}
