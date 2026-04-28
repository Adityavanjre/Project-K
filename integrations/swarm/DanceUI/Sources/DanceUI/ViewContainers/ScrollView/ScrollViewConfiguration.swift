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

// MARK: - ScrollViewExtendedConfigs Stub
// Original type was deleted from Extensions/ScrollView/ScrollViewExtendedConfigs.swift
@available(iOS 13.0, *)
internal struct ScrollViewExtendedConfigs {
    internal init() {}
}

@available(iOS 13.0, *)
internal struct ScrollViewConfiguration {

    internal var axes: Axis.Set
    
    internal var indicators: IndicatorStorage
    
    internal var bounceBehavior: ScrollBounces

    internal var isEnabled : Bool
    
//    var scrollDismissesKeyboard : ScrollDismissesKeyboardMode
//
//    var onScrollToTopGesture : ScrollToTopGestureAction?
//
//    weak var safeAreaTransitionState : SafeAreaTransitionState?
//
//    var refreshAction : RefreshAction?
//
    internal var isPagingEnabled : Bool
//
//    var interactionStyle : InteractionStyle
//
//    var decelerationOffset : ((DecelerationParameters) -> CGPoint?)?
//
//    var interactionActivityTag : String?
    

    internal var extendedConfigs: ScrollViewExtendedConfigs
    
    internal enum IndicatorStorage {
        // show
        case initial(Bool)
        
        case resolved(Indicators)
        
    }
    
    internal struct Indicators {
        
        internal var horizontal: ScrollIndicatorConfiguration
        
        internal var vertical: ScrollIndicatorConfiguration
        
        internal func axis(_ axis: Axis) -> ScrollIndicatorConfiguration {
            switch axis {
            case .horizontal:
                return horizontal
            case .vertical:
                return vertical
            }
        }
    }
    
    internal struct ScrollBounces {
        
        internal var horizontal: ScrollBounceBehavior
        
        internal var vertical: ScrollBounceBehavior
        
        internal func axis(_ axis: Axis) -> ScrollBounceBehavior.Role {
            switch axis {
            case .horizontal:
                return horizontal.role
            case .vertical:
                return vertical.role
            }
        }

    }
    
    internal var scrollableEdges: Edge.Set {
        var edges: Edge.Set = Edge.Set()
        
        if axes.contains(.vertical) {
            edges.insert(.vertical)
        }
        if axes.contains(.horizontal) {
            edges.insert(.horizontal)
        }
        
        return edges
    }

}
