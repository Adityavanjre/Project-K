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
internal struct TupleTypeDescription<PD: ProtocolDescriptor>: CustomStringConvertible {
    
    internal let contentTypes: [(Int, TypeConformance<PD>)]
    
    internal init(_ tupleType: DGTupleType) {
        var contentTypes = [(Int, TypeConformance<PD>)]()
        
        for elementIndex in tupleType.indices {
            let type = tupleType.getElementType(at: elementIndex)
            
            guard let viewConformance = TypeConformance<PD>(type) else {
                print("Ignoring invalid View type at index \(elementIndex), type \(type)")
                continue
            }
            
            contentTypes.append((elementIndex, viewConformance))
        }
        
        self.contentTypes = contentTypes
    }
    
    internal var description: String {
        let componentDescriptions = contentTypes.map { (offset, viewConformance) -> String in
            return "(Offset = \(offset), \(viewConformance.metadata))"
        }
        return "<\(type(of: self)); \(componentDescriptions.joined(separator: ", "))>"
    }
}
