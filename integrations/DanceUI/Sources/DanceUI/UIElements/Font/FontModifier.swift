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

import CoreText
import Foundation


@available(iOS 13.0, *)
internal protocol FontModifier : Hashable {
    
    func modify(descriptor: inout CTFontDescriptor)
}


@available(iOS 13.0, *)
internal class AnyFontModifier: FontModifier, Equatable, Hashable {
    
    private static var staticModifiers: [ObjectIdentifier: AnyFontModifier] = [:]
    
    internal static func `static`<A: StaticFontModifier>(type: A.Type) -> AnyFontModifier {
        if let cache = staticModifiers[ObjectIdentifier(type)] {
            return cache
        } else {
            let result = AnyStaticFontModifier<A>()
            staticModifiers[ObjectIdentifier(type)] = result
            return result
        }
    }
    
    internal static func dynamic<A: FontModifier>(modifier: A) -> AnyFontModifier {
        AnyDynamicFontModifier(modifier: modifier)
    }
    
    internal static func == (lhs: AnyFontModifier, rhs: AnyFontModifier) -> Bool {
        rhs.isEqual(to: lhs)
    }
    
    internal func hash(into hasher: inout Hasher) {
        return
    }
    
    internal func isEqual(to: AnyFontModifier) -> Bool {
        return false
    }
    
    internal func modify(descriptor: inout CTFontDescriptor) {
        return
    }
}

@available(iOS 13.0, *)
internal protocol StaticFontModifier {
    
    static func modify(descriptor: inout CTFontDescriptor)
}


@available(iOS 13.0, *)
internal final class AnyStaticFontModifier<A>: AnyFontModifier where A: StaticFontModifier {
    
    internal override func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(A.self))
    }
    
    internal override func isEqual(to: AnyFontModifier) -> Bool {
        to is Self
    }
    
    internal override func modify(descriptor: inout CTFontDescriptor) {
        A.modify(descriptor: &descriptor)
    }
}


@available(iOS 13.0, *)
internal final class AnyDynamicFontModifier<A: FontModifier>: AnyFontModifier {
    
    internal let modifier: A
    
    internal init(modifier: A) {
        self.modifier = modifier
    }
    
    internal static func == (lhs: AnyDynamicFontModifier, rhs: AnyDynamicFontModifier) -> Bool {
        lhs.modifier == rhs.modifier
    }
    
    internal override func hash(into hasher: inout Hasher) {
        modifier.hash(into: &hasher)
    }
    
    internal override func isEqual(to: AnyFontModifier) -> Bool {
        if let value = to as? AnyDynamicFontModifier {
            return value.modifier == self.modifier
        } else {
            return false
        }
    }
    
    internal override func modify(descriptor: inout CTFontDescriptor) {
        modifier.modify(descriptor: &descriptor)
    }
}

