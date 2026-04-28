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
import Foundation

#if FEAT_MONITOR

@_spi(ForDanceUIExtensionOnly)
@available(iOS 13.0, *)
public class Auditor<Data: PerformanceIndicatorCollection> {
    internal private(set) var data: Data
    
    private var hasChanged = false
    
    internal let underlyingQueue = DispatchQueue(label: "com.ByteDance.DanceUI.Auditor.UnderlyingQueue")
    
    internal init() {
        self.data = Data()
    }
    
    internal func enqueueDataChanges(_ body: @escaping (_ data: inout Data)  -> Void) {
        underlyingQueue.async {
            self.hasChanged = true
            body(&self.data)
        }
    }
    
    internal func commit(on timing: PerformanceIndicatorCommitTiming, category: [AnyHashable : Any]) {
        
    }
    
    public func enqueueCommit(on timing: PerformanceIndicatorCommitTiming, category: [AnyHashable : Any]) {
        underlyingQueue.async {
            guard self.hasChanged else {
                return
            }
            
            self.commit(on: timing, category: category)
            
            self.hasChanged = false
        }
    }
}

@available(iOS 13.0, *)
extension Auditor {
    internal func currentResidentMemoryAbsolute() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                          task_flavor_t(MACH_TASK_BASIC_INFO),
                          $0,
                          &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return UInt64(info.resident_size)
        } else {
            LogService.error(module: .performance, keyword: .measuring, "An error occured while measuring current resident memory", info: [
                "error" : String(cString: mach_error_string(kerr))
            ])
            return .min
        }
    }
    
    // We only have to calculate the memory usage delta. Map to Int64
    // is enough for this task.
    internal func currentResidentMemory() -> Int64 {
        func mapUInt64ToInt64(_ u: UInt64) -> Int64 {
            return Int64(bitPattern: u) &- Int64.min
        }
        
        return mapUInt64ToInt64(currentResidentMemoryAbsolute())
    }
    
}

#if DEBUG

@available(iOS 13.0, *)
extension Auditor {
    
    internal func testableGetUnderlyingQueue() -> DispatchQueue {
        return underlyingQueue
    }

    internal func testableGetHasChanged() -> Bool {
        return hasChanged
    }

    internal func testableSetHasChanged(_ newValue: Bool) {
        self.hasChanged = newValue
    }
    
    internal func testableGetData() -> Data {
        // This method is called by tests on the 'underlyingQueue',
        // so direct access to self.data is safe here.
        return self.data
    }
    
}

#endif // DEBUG


internal enum DisplayListItemValueCategory: UInt, AggregatorCategory {
    
    case contentOfBackdrop
    
    case contentOfColor
    
    case contentOfChameleonColor
    
    case contentOfImage
    
    case contentOfAnimatedImage
    
    case contentOfShape
    
    case contentOfShadow
    
    case contentOfPlatformView
    
    case contentOfPlatformLayer
    
    case contentOfText
    
    case contentOfFlattened
    
    case contentOfDrawing
    
    case contentOfView
    
    case contentOfPlaceholder
    
    case effectOfBackdropGroup
    
    case effectOfProperties
    
    case effectOfPlatformGroup
    
    case effectOfOpacity
    
    case effectOfBlendMode
    
    case effectOfClip
    
    case effectOfMask
    
    case effectOfAffine
    
    case effectOfProjection
    
    case effectOfFilter
    
    case effectOfAnimation
    
    case effectOfView
    
    case effectOfAX
    
    case effectOfIdentity
    
    case effectOfGeometryGroup
    
    case effectOfCompositingGroup
    
    case effectOfArchive
    
    // Compose Addition
    case renderNodeLayer
    
    case effectOfGestureRecognizers
    
    case empty
    
    internal var narrative: String {
        switch self {
        case .contentOfBackdrop:
            return "content-of-backdrop"
        case .contentOfColor:
            return "content-of-color"
        case .contentOfChameleonColor:
            return "content-of-chameleon-color"
        case .contentOfImage:
            return "content-of-image"
        case .contentOfAnimatedImage:
            return "content-of-animated-image"
        case .contentOfShape:
            return "content-of-shape"
        case .contentOfShadow:
            return "content-of-shadow"
        case .contentOfPlatformView:
            return "content-of-platform-view"
        case .contentOfPlatformLayer:
            return "content-of-platform-layer"
        case .contentOfText:
            return "content-of-text"
        case .contentOfFlattened:
            return "content-of-flattened"
        case .contentOfDrawing:
            return "content-of-drawing"
        case .contentOfView:
            return "content-of-view"
        case .contentOfPlaceholder:
            return "content-of-placeholder"
        case .effectOfBackdropGroup:
            return "effect-of-backdrop-group"
        case .effectOfProperties:
            return "effect-of-properties"
        case .effectOfPlatformGroup:
            return "effect-of-platform-group"
        case .effectOfOpacity:
            return "effect-of-opacity"
        case .effectOfBlendMode:
            return "effect-of-blend-mode"
        case .effectOfClip:
            return "effect-of-clip"
        case .effectOfMask:
            return "effect-of-mask"
        case .effectOfAffine:
            return "effect-of-affine"
        case .effectOfProjection:
            return "effect-of-projection"
        case .effectOfFilter:
            return "effect-of-filter"
        case .effectOfAnimation:
            return "effect-of-animation"
        case .effectOfView:
            return "effect-of-view"
        case .effectOfAX:
            return "effect-of-ax"
        case .effectOfIdentity:
            return "effect-of-identity"
        case .effectOfGeometryGroup:
            return "effect-of-geometry-group"
        case .effectOfCompositingGroup:
            return "effect-of-compositing-group"
        case .effectOfArchive:
            return "effect-of-archive"
        case .renderNodeLayer:
            return "compose-render-node-layer"
        case .effectOfGestureRecognizers:
            return "effect-of-gesture-recognizers"
        case .empty:
            return "empty"
        }
    }
    
}

#endif
