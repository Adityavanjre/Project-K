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

import SwiftSyntax
import Foundation

extension DeclModifierListSyntax {
    
    var mimimalAccessControlForProtocolConformance: DeclModifierListSyntax {
        reduce([]) { partialResult, modifier in
            var next = partialResult
            switch modifier.name.tokenKind {
            case .keyword(.private):
                next.append(modifier.with(\.name, .keyword(.fileprivate)))
            case .keyword(.public), .keyword(.internal), .keyword(.package), .keyword(.fileprivate):
                next.append(modifier)
            default:
                break
            }
            return next
        }
    }
}

extension TypeSyntax {
    
    var nonQualifiedIdentifier: String? {
        for token in tokens(viewMode: .all).reversed() {
            switch token.tokenKind {
            case .identifier(let identifier):
                return identifier
            default:
                break
            }
        }
        return nil
    }
    
    var fullyQualifiedIdentifier: String? {
        return tokens(viewMode: .all).reduce(Optional<String>.none) { partialResult, token in
            if let partialResult {
                return partialResult.appending(token.text)
            } else {
                return token.text
            }
        }
    }
    
}

extension VariableDeclSyntax {
    
    internal func hasPropertyWrapper(_ name: String) -> Bool {
        let targetAttribute = AttributeSyntax(stringLiteral: name)
        for attribute in attributes {
            switch attribute {
            case .attribute(let attr):
                if attr.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) == targetAttribute.attributeName.tokens(viewMode: .all).map({ $0.tokenKind }) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    internal var isObservationIgnored: Bool {
        return hasMacroApplication(ObservableMacro.ignoredMacroName)
    }
    
}

extension InheritanceClauseSyntax {
    
    internal func inherits<S: Sequence>(anyOf typeSyntaxes: S) -> Bool where S.Element == TypeSyntax {
        let identifiersToHit = Set(typeSyntaxes.compactMap(\.fullyQualifiedIdentifier))
        return inherits(anyOf: identifiersToHit)
    }
    
    internal func inherits<S: Sequence>(anyOf identifiers: S) -> Bool where S.Element == String {
        let identifiersToSearch = Set(inheritedTypes.compactMap(\.type.fullyQualifiedIdentifier))
        let identifiersToHit = Set(identifiers)
        return !identifiersToSearch.intersection(identifiersToHit).isEmpty
    }
    
}

extension DeclGroupSyntax {
    
    func addIfNeeded<DeclSyntaxType: DeclSyntaxProtocol>(_ decl: DeclSyntaxType?, to declarations: inout [DeclSyntax]) {
        guard let decl else { return }
        if let fn = decl.as(FunctionDeclSyntax.self) {
            if !hasMemberFunction(equvalentTo: fn) {
                declarations.append(DeclSyntax(decl))
            }
        } else if let property = decl.as(VariableDeclSyntax.self) {
            if !hasMemberProperty(equivalentTo: property) {
                declarations.append(DeclSyntax(decl))
            }
        }
    }
    
}
