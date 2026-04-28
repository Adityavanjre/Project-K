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
internal final class MatchedGeometryScope: ViewInput {
    
    internal typealias Value = MatchedGeometryScope?

    internal let subgraph: DGSubgraphRef

    internal let inputs: _ViewInputs

    internal var frames: [Frame]

    internal var keyedFrames: Dictionary<AnyHashable, Int>
    
    internal static var defaultValue: MatchedGeometryScope? {
        nil
    }
    
    internal init(inputs: _ViewInputs) {
        self.subgraph = .current!
        self.inputs = inputs
        self.frames = []
        self.keyedFrames = [:]
    }
    
    internal func frame<ID: Hashable>(index: inout Int?, for key: ID, view: Frame.View) -> (ViewFrame?, DanceUIGraph.AnyOptionalAttribute) {
        let hashKey = AnyHashable(key)
        if let frameIndex = index {
            if frames[frameIndex].key == hashKey {
                return frames[frameIndex].frame
            } else {
                releaseFrame(index: frameIndex, owner: view.attribute)
                index = nil
            }
        }
        
        var needsRefreshFrame = false
        
        var keyedFrameIndex: Int = 0
        if let index = keyedFrames[hashKey] {
            keyedFrameIndex = index
            needsRefreshFrame = true
        } else {
            if let idx = frames.firstIndex(where: {$0.views.isEmpty}) {
                keyedFrameIndex = idx
                let frame = frames[idx]
                frame.$frame.mutateBody(as: SharedFrame.self, invalidating: true) { body in
                    body.reset()
                }
                needsRefreshFrame = true
                frames[keyedFrameIndex].key = hashKey
            } else {
                keyedFrameIndex = frames.count
                subgraph.apply {
                    let sharedFrame = Attribute(SharedFrame(time: inputs.time,
                                                            environment: inputs.environment,
                                                            scope: self,
                                                            frameIndex: keyedFrameIndex,
                                                            listeners: [],
                                                            animatorState: nil,
                                                            resetSeed: 0,
                                                            lastSourceAttribute: .init()))
                    sharedFrame.flags = .active
                    frames.append(Frame(frame: sharedFrame, key: hashKey, views: [], logged: false))
                }
                needsRefreshFrame = false
            }
            keyedFrames[hashKey] = keyedFrameIndex
        }
        
        frames[keyedFrameIndex].views.insert(view, at: 0)
        if needsRefreshFrame {
            let weakFrame = DGWeakAttribute(frames[keyedFrameIndex].$frame.identifier)
            ViewGraph.current.continueTransaction {
                guard let attribute = weakFrame.attribute else {
                    return
                }
                attribute.invalidateValue()
            }
        }
        index = keyedFrameIndex
        return frames[keyedFrameIndex].frame
    }
    
    internal func releaseFrame(index: Int, owner: DGAttribute) {
        guard let viewIndex = frames[index].views.firstIndex(where: {$0.attribute == owner}) else {
            return
        }
        frames[index].views.remove(at: viewIndex)
        guard frames[index].views.isEmpty else {
            return
        }
        keyedFrames.removeValue(forKey: frames[index].key)
        frames[index].key = AnyHashable(EmptyKey())
    }
    
}

@available(iOS 13.0, *)
extension MatchedGeometryScope {
    
    internal struct Frame {
        
        @Attribute
        internal var frame: (ViewFrame?, DanceUIGraph.AnyOptionalAttribute)

        internal var key: AnyHashable

        internal var views: [View]

        internal var logged: Bool

        internal struct View {
            internal var attribute: DGAttribute

            @Attribute
            internal var args: (properties: MatchedGeometryProperties, anchor: UnitPoint, isSource: Bool)

            @Attribute
            internal var transaction: Transaction

            @Attribute
            internal var phase: _GraphInputs.Phase

            @Attribute
            internal var size: ViewSize

            @Attribute
            internal var position: ViewOrigin

            @Attribute
            internal var transform: ViewTransform

        }
    }
    
    fileprivate struct EmptyKey: Hashable, Equatable {
        
    }
}

@available(iOS 13.0, *)
@frozen
public struct MatchedGeometryProperties: OptionSet {

    public let rawValue: UInt32
    
    @inlinable
    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    public static let position = MatchedGeometryProperties(rawValue: 0x1 << 0)
    
    public static let size = MatchedGeometryProperties(rawValue: 0x1 << 1)
    
    public static let frame = MatchedGeometryProperties([.position, .size])

}
