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
@_spi(DanceUI) import DanceUIObservation

@available(iOS 13.0, *)
internal struct ForEachChild<Data: RandomAccessCollection, ID: Hashable, Content: View>: StatefulRule, ObservationAttribute where Data.Index: Hashable {
    
    internal typealias Value = Content
    
    @Attribute
    internal var info: ForEachState<Data, ID, Content>.Info
    
    internal let id: ID
    

    internal var previousObservationTrackings: [ObservationTracking]?
    

    internal var deferredObservationGraphMutation: DeferredObservationGraphMutation?
    
    internal mutating func updateValue() {
        let info = info
        let items = info.state.items
        
        guard let item = items[self.id] else {
            return
        }
        
        guard item.seed == info.state.seed else {
            return
        }
        
        let forEach = info.state.view!
        let element = forEach.data[item.index]
        
        func content(_ element: Data.Element) -> Content {
            
                // The system propogates the seed of ForEach to ForEachChild when
                // ForEach is changed. We always need to cancel the previous
                // observation trackings if the program went to this place.
            withObservation(shouldCancelPrevious: true) {
                Update.syncMainWithoutUpdate {
                    forEach.content(element)
                }
            }
            
        }
        value = content(element)
    }
    
}
