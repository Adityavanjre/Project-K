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

@available(iOS 13.0, *)
public struct _ViewListInputs {
    
    internal fileprivate(set) var base: _GraphInputs
    
    internal var implicitID: Int
    
    private var options: Options
    
    @OptionalAttribute
    internal var traits: ViewTraitCollection?
    
    internal var traitKeys: ViewTraitKeys?
    
    @inline(__always)
    internal init(base: _GraphInputs) {
        self.base = base
        self.implicitID = 0
        self.options = .init()
        self._traits = OptionalAttribute<ViewTraitCollection>()
        self.traitKeys = .init()
    }
    
    @inline(__always)
    internal init(base: _GraphInputs,
                  implicitID: Int,
                  options: Options,
                  traits: OptionalAttribute<ViewTraitCollection> = .init(),
                  traitKeys: ViewTraitKeys?) {
        self.base = base
        self.implicitID = implicitID
        self.options = options
        self._traits = traits
        self.traitKeys = traitKeys
    }
    
    @inline(__always)
    internal var canTransition: Bool {
        options.contains(.needTransition) ? !options.contains(.disableTransition) : false
    }
    
    @inline(__always)
    internal mutating func setTraitAttribute(_ traitAttribute: Attribute<ViewTraitCollection>) {
        self._traits = OptionalAttribute(traitAttribute)
    }
    
    @inline(__always)
    internal var disableTransition: Bool {
        get {
            options.contains(.disableTransition)
        }
        set {
            if newValue {
                options.insert(.disableTransition)
            } else {
                options.remove(.disableTransition)
            }
        }
    }
    
    @inline(__always)
    internal var requiresDepthAndSections: Bool {
        get {
            options.contains(.requiresDepthAndSections)
        }
        
        set {
            if newValue {
                options.insert(.requiresDepthAndSections)
            } else {
                options.remove(.requiresDepthAndSections)
            }
        }
    }
    
    @inline(__always)
    internal var footerSectionedTrait: Bool {
        get {
            options.contains(.footerSectionedTrait)
        }
        
        set {
            if newValue {
                options.insert(.footerSectionedTrait)
            } else {
                options.remove(.footerSectionedTrait)
            }
        }
    }
    
    @inline(__always)
    internal var needTransition: Bool {
        get {
            options.contains(.needTransition)
        }
        
        set {
            if newValue {
                options.insert(.needTransition)
            } else {
                options.remove(.needTransition)
            }
        }
    }
    
    @inline(__always)
    internal var hasParent: Bool {
        get {
            options.contains(.hasParent)
        }
        
        set {
            if newValue {
                options.insert(.hasParent)
            } else {
                options.remove(.hasParent)
            }
        }
    }
    
    @inline(__always)
    internal var headerStyleInput: Bool {
        get {
            options.contains(.headerStyleInput)
        }
        
        set {
            if newValue {
                options.insert(.headerStyleInput)
            } else {
                options.remove(.headerStyleInput)
            }
        }
    }
    
    @inline(__always)
    internal var footerStyleInput: Bool {
        get {
            options.contains(.footerStyleInput)
        }
        
        set {
            if newValue {
                options.insert(.footerStyleInput)
            } else {
                options.remove(.footerStyleInput)
            }
        }
    }
    
    @inline(__always)
    internal var allowsNestedSections: Bool {
        get {
            options.contains(.allowsNestedSections)
        }
        
        set {
            if newValue {
                options.insert(.allowsNestedSections)
            } else {
                options.remove(.allowsNestedSections)
            }
        }
    }
    
    @inline(__always)
    internal var requiresSections: Bool {
        get {
            options.contains(.requiresSections)
        }
        
        set {
            if newValue {
                options.insert(.requiresSections)
            } else {
                options.remove(.requiresSections)
            }
        }
    }
    
    @inline(__always)
    internal var tupleViewCreatesUnaryElements: Bool {
        get {
            options.contains(.tupleViewCreatesUnaryElements)
        }
        
        set {
            if newValue {
                options.insert(.tupleViewCreatesUnaryElements)
            } else {
                options.remove(.tupleViewCreatesUnaryElements)
            }
        }
    }
    
    internal subscript <A: ViewInput>(_ type: A.Type) -> A.Value {
        get {
            base[type]
        }
        set {
            base[type] = newValue
        }
    }
    
    internal mutating func append<A: ViewInput, B>(_ value: B, for viewInput: A.Type) where A.Value == [B] {
        base.append(value: value, for: viewInput)
    }
    
    internal mutating func popLast<A: ViewInput, B>(for input: A.Type) -> B? where A.Value == [B] {
        base.popLast(for: input)
    }
    
    internal mutating func addTraitKey<A: _ViewTraitKey>(_ type: A.Type) {
        traitKeys?.insert(type)
    }
    
    @inline(__always)
    internal func unionViewListOptions(_ newOptions: Options) -> Options {
        self.options.union(newOptions)
    }
    
    @inline(__always)
    internal var viewListCountInputs: _ViewListCountInputs {
        _ViewListCountInputs(customInputs: self.base.customInputs, options: self.options, baseOptions: self.base.options, customModifierTypes: [])
    }
    
    @inline(__always)
    internal mutating func withMutableGraphInputs<R>(_ body: (inout _GraphInputs) -> R) -> R {
        return body(&self.base)
    }
    
    public struct Options: OptionSet {
        
        public typealias RawValue = Int
        
        public var rawValue: RawValue
        
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        internal static let needTransition: Options = Options(rawValue: 1 << 0x0)
        
        internal static let disableTransition: Options = Options(rawValue: 1 << 0x1)
        
        internal static let requiresDepthAndSections: Options = Options(rawValue: 1 << 0x2)
        
        internal static let footerSectionedTrait: Options = Options(rawValue: 1 << 0x3)
        
        internal static let hasParent: Options = Options(rawValue: 1 << 0x4)
        
        internal static let headerStyleInput: Options = Options(rawValue: 1 << 0x5)
        
        internal static let footerStyleInput: Options = Options(rawValue: 1 << 0x6)
        
        internal static let requiresSections: Options = Options(rawValue: 1 << 0x8)
        
        internal static let tupleViewCreatesUnaryElements: Options = .init(rawValue: 1 << 0x9)
        
        internal static let allowsNestedSections: Options = Options(rawValue: 1 << 0xc) 
    }
    
}
