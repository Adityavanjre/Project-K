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
internal struct AccessibilityTraitStorage: Equatable, Codable, CustomStringConvertible {

    fileprivate var mask: TraitSet

    fileprivate var values: TraitSet
    
    internal static let empty = AccessibilityTraitStorage()
    
    @inlinable
    internal init() {
        self.mask = .empty
        self.values = .empty
    }
    
    @inlinable
    internal init(adding traits: AccessibilityTraits) {
        let t = traits.traitSet.map { TraitSet($0) }
        self.mask = TraitSet(t)
        self.values = TraitSet(t)
    }
    
    @inlinable
    internal init(removing traits: AccessibilityTraits) {
        self.mask = TraitSet(traits.traitSet.map { TraitSet($0) })
        self.values = .empty
    }
    
    @inline(__always)
    private init(mask: TraitSet, values: TraitSet) {
        self.mask = mask
        self.values = values
    }
    
    @inlinable
    internal subscript(raw: AccessibilityRawTrait) -> Bool? {
        get {
            let trait = TraitSet(raw)
            guard mask.contains(trait) else {
                return nil
            }
            return values.contains(trait)
        }
        set {
            let trait = TraitSet(raw)
            guard let newValue = newValue else {
                mask.remove(trait)
                return
            }
            mask.insert(trait)
            if newValue {
                values.insert(trait)
            } else {
                values.remove(trait)
            }
        }
    }

    @inline(__always)
    internal func combined(with trait: AccessibilityTraitStorage) -> AccessibilityTraitStorage {
        AccessibilityTraitStorage(
            mask: mask.union(trait.mask),
            values: values.subtracting(trait.mask).union(trait.values)
        )
    }
    
    @inline(__always)
    internal func contains(_ raw: AccessibilityRawTrait) -> Bool {
        self[raw] == true
    }
    
    internal var description: String {
        let maskString = AccessibilityRawTrait.allCases
            .filter { mask.contains(TraitSet($0)) }
            .map { $0.description }
            .joined(separator: ", ")
        let valueString = AccessibilityRawTrait.allCases
            .filter { values.contains(TraitSet($0)) }
            .map {$0.description }
            .joined(separator: ", ")
        
        return "Mask: \(mask.rawValue)[\(maskString)], value: \(values.rawValue)[\(valueString)]"
    }
    
    fileprivate struct TraitSet: OptionSet, Codable {

        fileprivate let rawValue: UInt32
        
        @inline(__always)
        fileprivate static var empty: TraitSet {
            TraitSet(rawValue: 0x0)
        }
        
        @inline(__always)
        fileprivate init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        
        @inline(__always)
        fileprivate init(_ raw: AccessibilityRawTrait) {
            self.rawValue = 0x1 << raw.rawValue
        }

    }
    
}
