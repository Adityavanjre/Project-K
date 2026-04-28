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
internal struct PlatformItemListView<Content: View, Transformed: View>: View {
    
    internal let content: Content
    
    internal let resolver: (PlatformItemList) -> Transformed
    
    internal init(content: Content, @ViewBuilder resolver: @escaping (PlatformItemList) -> Transformed) {
        self.content = content
        self.resolver = resolver
    }
    
    internal var body: some View {
        PlatformItemList.Key._delay { (key) in
            key._force(resolver)
                .secondaryPlatformItemListContent {
                    content
                        .frame(width: 0, height: 0)
                        .hiddenAllowingPlatformItemList()
                }
        }
        .input(PlatformItemListIncludeAX.self)
    }
    
}

@available(iOS 13.0, *)
fileprivate struct PlatformItemListGeneratingViewModifier<SecondaryView: View>: MultiViewModifier {
    
    fileprivate typealias Body = Never
    
    fileprivate var secondaryView: SecondaryView
    
    fileprivate static func _makeView(modifier: _GraphValue<Self>, inputs: _ViewInputs, body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        
        let bodyOutputs = body(_Graph(), inputs)
        
        let secondaryInputs = inputs.withoutGeometryDependencies
        
        let secondaryOutputs = SecondaryView.makeDebuggableView(value: modifier[{.of(&$0.secondaryView)}], inputs: secondaryInputs)
        
        #warning("AccessibilityNodesKey")
        
        var visitor = PairwisePreferenceCombinerVisitor(outputs: (bodyOutputs, secondaryOutputs),
                                                        result: _ViewOutputs())
        for key in inputs.preferences.keys {
            key.visitKey(&visitor)
        }
        visitor.result.overrideLayout(bodyOutputs.layout)
        
        return visitor.result
    }
    
}

@available(iOS 13.0, *)
extension View {
    
    internal func platformItemListTransformModifier<Content: View>(_ content: Content, _ callback: @escaping (inout PlatformItemList) -> Void) -> some View {
        let view = content.frame(width: 0, height: 0).hiddenAllowingPlatformItemList().transformPreference(PlatformItemList.Key.self, callback)
        return modifier(PlatformItemListGeneratingViewModifier(secondaryView: view))
    }
    
    fileprivate func secondaryPlatformItemListContent<SecondaryView: View>(@ViewBuilder content: () -> SecondaryView) -> some View {
        modifier(content().platformItemListContent())
    }
    
    fileprivate func platformItemListContent() -> some ViewModifier {
        PlatformItemListGeneratingViewModifier(secondaryView: self.frame(width: 0, height: 0).hiddenAllowingPlatformItemList())
    }
    
}

@available(iOS 13.0, *)
internal struct PlatformItemListIncludeAX: ViewInputBoolFlag, ViewInput {
    
    internal typealias Input = PlatformItemListIncludeAX
    
    internal typealias Value = Bool
    
    internal static var defaultValue: Value { false }
    
}
