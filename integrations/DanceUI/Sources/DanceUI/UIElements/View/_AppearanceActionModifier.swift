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

@usableFromInline
@available(iOS 13.0, *)
internal struct _AppearanceActionModifier: MultiViewModifier {
    
    @usableFromInline
    internal typealias Body = Never
    
    @usableFromInline
    internal var appear: (() -> ())?
    
    @usableFromInline
    internal var disappear: (() -> ())?
    
    @usableFromInline
    internal init(appear: (() -> ())?,
                  disappear: (() -> ())?) {
        self.appear = appear
        self.disappear = disappear
    }
    
    public static func _makeView(modifier: _GraphValue<Self>,
                                 inputs: _ViewInputs,
                                 body: @escaping (_Graph, _ViewInputs) -> _ViewOutputs) -> _ViewOutputs {
        let appearanceEffect = AppearanceEffect(modifier: modifier.value,
                                                phase: inputs.phase,
                                                lastValue: nil,
                                                resetSeed: nil,
                                                isVisible: false,
                                                node: .init())
        let attribute = Attribute(appearanceEffect)
        
        attribute.setFlags([.active, .removable], mask: .reserved)
        
        return body(_Graph(), inputs)
    }
    
    public static func _makeViewList(modifier: _GraphValue<_AppearanceActionModifier>, inputs: _ViewListInputs, body: @escaping (_Graph, _ViewListInputs) -> _ViewListOutputs) -> _ViewListOutputs {
        let graphValue = _GraphValue(Attribute(MergedCallbacks(modifier: modifier.value, box: MergedBox())))
        var outputs = body(_Graph(), inputs)
        outputs.multiModifier(graphValue, inputs: inputs)
        return outputs
    }
    
    fileprivate final class MergedBox {
        
        fileprivate var count: UInt32
        
        fileprivate var lastCount: UInt32
        
        fileprivate var base: _AppearanceActionModifier
        
        fileprivate var pendingUpdate: Bool
        
        fileprivate init() {
            self.count = 0
            self.lastCount = 0
            self.base = _AppearanceActionModifier(appear: nil, disappear: nil)
            self.pendingUpdate = false
        }
        
        fileprivate func appear() {
            if count == 0 {
                update()
            }
            count &+= 1
        }
        
        fileprivate func disappear() {
            count &-= 1
            if count == 0 {
                update()
            }
        }
        
        fileprivate func update() {
            guard !pendingUpdate else {
                return //BDCOV_EXCL_LINE 抖动
            }
            
            pendingUpdate = true
            Update.enqueueAction {
                self.pendingUpdate = false
                let lastCnt = self.lastCount
                self.lastCount = self.count
                if lastCnt == 0 {
                    if self.count != 0, let appear = self.base.appear {
                        appear()
                    }
                } else {
                    if self.count == 0, let disappear = self.base.disappear {
                        disappear()
                    }
                }
            }
        }
    }
    
    fileprivate struct MergedCallbacks : Rule {
        
        fileprivate typealias Value = _AppearanceActionModifier
        
        @Attribute
        fileprivate var modifier: _AppearanceActionModifier
        
        fileprivate let box: MergedBox
        
        fileprivate var value: _AppearanceActionModifier {
            box.base = modifier
            return _AppearanceActionModifier {
                box.appear()
            } disappear: {
                box.disappear()
            }
            
        }
    }
}

@available(iOS 13.0, *)
private struct AppearanceEffect: StatefulRule {
    
    internal typealias Value = ()
    
    @Attribute
    internal var modifier: _AppearanceActionModifier
    
    @Attribute
    internal var phase: _GraphInputs.Phase
    
    internal var lastValue: _AppearanceActionModifier?
    
    internal var resetSeed: UInt32?
    
    internal var isVisible: Bool
    
    internal var node: AnyOptionalAttribute
    
    private mutating func disappeared() {
        guard isVisible else {
            return
        }
        guard let modifier = self.lastValue else {
            return
        }
        defer {
            isVisible = false
        }
        guard let disappear = modifier.disappear else {
            return
        }
        Update.enqueueAction {
            disappear()
        }
    }
    
    private mutating func appeared() {
        guard !isVisible else {
            return
        }
        guard let modifier = self.lastValue else {
            return
        }
        defer {
            isVisible = true
        }
        guard let appear = modifier.appear else {
            return
        }
        Update.enqueueAction {
            appear()
        }
    }
    
    internal mutating func updateValue() {
        if node.attribute == nil {
            node.attribute = .current
        }
        let phase = self.phase
        
        if self.resetSeed == nil || phase.seed != self.resetSeed {
            self.resetSeed = phase.seed
            self.disappeared()
        }
        self.lastValue = self.modifier
        self.appeared()
    }
    
}

@available(iOS 13.0, *)
extension AppearanceEffect: RemovableAttribute {
    
    internal static func willRemove(attribute: DGAttribute) {
        let value = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        guard let _ = value.pointee.lastValue else {
            return
        }
        value.pointee.disappeared()
    }
    
    internal static func didReinsert(attribute: DGAttribute) {
        let value = UnsafeMutableRawPointer(mutating: attribute.info.body).assumingMemoryBound(to: Self.self)
        guard let nodeAttribute = value.pointee.node.attribute else {
            return
        }
        nodeAttribute.invalidateValue()
        nodeAttribute.graph.graphHost().graphInvalidation(from: attribute)
    }
    
}

@available(iOS 13.0, *)
extension AppearanceEffect: CustomStringConvertible {
    
    internal var description: String {
        "\(Self.self)"
    }
}
