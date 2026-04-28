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
internal protocol Feature: ViewInputBoolFlag {
    
    static var isEnable: Bool { get }
}

@available(iOS 13.0, *)
extension Feature {
    static var defaultValue: Value {
        isEnable
    }
}

@available(iOS 13.0, *)// DanceUIAddition
internal struct IOS14Above: Feature {
    
    internal static var isEnable: Bool {
        guard #available(iOS 14.0, *) else {
            return false
        }
        return true
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    @inline(__always)
    internal func modifier<F: Feature, M: ViewModifier>(_ viewModifier: M, require feature: F.Type) -> some View {
        modifier(StaticIf(feature, then: viewModifier, else: EmptyModifier()))
    }
    
    @inline(__always)
    internal func featureModifier<F, Then, Else>(_ flag: F.Type, enabledModifier: Then, disabledModifier: Else) -> ModifiedContent<Self, StaticIf<F, Then, Else>> where F: Feature, Then: ViewModifier, Else: ViewModifier {
        modifier(StaticIf(F.self, then: enabledModifier, else: disabledModifier))
    }
}

@available(iOS 13.0, *)
protocol FeatureView: View where Body == StaticIf<F, Then, Else> {
    associatedtype F: Feature
    associatedtype Then: View
    associatedtype Else: View
    
    @ViewBuilder
    var enabledBody: Self.Then { get }
    
    @ViewBuilder
    var disabledBody: Self.Else { get }
}

@available(iOS 13.0, *)
extension FeatureView {
    public var body: Body {
        StaticIf(F.self) {
            enabledBody
        } else: {
            disabledBody
        }
    }
}

@available(iOS 13.0, *)
extension Feature {
    @inline(__always)
    internal static func makeAttribute<Enabled, Disabled>(inputs: _GraphInputs, enabled: Enabled, disabled: Disabled) -> Attribute<Enabled.Value> where Enabled: Rule, Disabled: Rule, Enabled.Value == Disabled.Value {
        if evaluate(inputs: inputs) {
            Attribute(enabled)
        } else {
            Attribute(disabled)
        }
    }
    
    @inline(__always)
    internal static func makeInterface<I>(enabled: I, disabled: I) -> I {
        if isEnable {
            enabled
        } else {
            disabled
        }
    }
    
    @inline(__always)
    internal static func call<Value>(enabled: () -> Value, disabled: () -> Value) -> Value {
        if isEnable {
            enabled()
        } else {
            disabled()
        }
    }
}
