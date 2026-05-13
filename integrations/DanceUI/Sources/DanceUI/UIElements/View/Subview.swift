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

/// An opaque value representing a subview of another view.
///
/// Access to a `Subview` can be obtained by using `ForEach(subviews:)` or
/// `Group(subviews:)`.
///
/// Subviews are proxies to the resolved view they represent, meaning
/// that modifiers applied to the original view will be applied before
/// modifiers applied to the subview, and the view is resolved
/// using the environment of its container, *not* the environment of the
/// its subview proxy. Additionally, because subviews must represent a
/// single leaf view, or container, a subview may represent a view after the
/// application of styles. As such, attempting to apply a style to it may
/// have no affect.
@available(iOS 13.0, *)
public struct Subview: PrimitiveView, UnaryView, Identifiable {
    
    internal var base: _VariadicView_Children.Element
    
    /// A unique identifier for a subview.
    public struct ID: Hashable {
        public let base: AnyHashable
    }
    
    /// The unique identifier of the view.
    ///
    /// This identifier persists across updates, changes to the order of
    /// subviews, etc. so can be used to track the lifetime of a subview.
    public var id: ID {
        .init(base: base.id)
    }
    
    public static func _makeView(view: _GraphValue<Self>, inputs: _ViewInputs) -> _ViewOutputs {
        _VariadicView_Children.Element._makeView(view: view[{.of(&$0.base)}], inputs: inputs)
    }
    
    public static func _makeViewList(view: _GraphValue<Self>, inputs: _ViewListInputs) -> _ViewListOutputs {
        var newInputs = inputs
        let attribute = view.value.base.traits
        let inputTraitAttribute = inputs.$traits
        let mergeTrait = MergeTraits(overrideTraits: attribute, baseTraits: OptionalAttribute(inputTraitAttribute))
        let mergeTraitAttribute = Attribute(mergeTrait)
        newInputs.setTraitAttribute(mergeTraitAttribute)
        return _ViewListOutputs.unaryViewList(view: view, inputs: newInputs)
    }
    
    internal var traits: TraitValues {
        .init(base: base.traits)
    }
    
    internal func tagValue<A: Hashable>(for type: A.Type) -> A? {
        base.traits.tagValue(for: type)
    }
    
    internal subscript<A: _ViewTraitKey>(_ type: A.Type) -> A.Value {
        get {
            base[type]
        }
        set {
            base[type] = newValue
        }
    }
    
    internal func isSelected<A: Hashable>(selection: A) -> Bool {
        guard let tagValue = base.traits.tag(for: A.self) else {
            return false
        }
        
        return tagValue == selection
    }
}

@available(iOS 13.0, *)
private struct MergeTraits: Rule {
    @Attribute
    fileprivate var overrideTraits: ViewTraitCollection
    
    @OptionalAttribute
    fileprivate var baseTraits: ViewTraitCollection?
    
    fileprivate init(overrideTraits: Attribute<ViewTraitCollection>, baseTraits: OptionalAttribute<ViewTraitCollection>) {
        self._overrideTraits = overrideTraits
        self._baseTraits = baseTraits
    }
    
    fileprivate var value: ViewTraitCollection {
        var baseTraitsValue = self.baseTraits ?? .init()
        let overrideTraitsValue = self.overrideTraits
        baseTraitsValue.mergeValues(overrideTraitsValue)
        return baseTraitsValue
    }
}

@available(iOS 13.0, *)
internal struct TraitValues {
    internal var base: ViewTraitCollection
    
    internal func tag<A: Hashable>(for type: A.Type) -> A? {
        base.tag(for: type)
    }
    
    internal var isAuxiliaryContent: Bool {
        base[IsAuxiliaryContentTraitKey.self]
    }
}
