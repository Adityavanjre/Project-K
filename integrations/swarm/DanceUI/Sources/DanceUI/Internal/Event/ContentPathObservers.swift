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
internal protocol ContentPathObserver: AnyObject {

    func contentPathDidChange()
    
}

@available(iOS 13.0, *)
internal struct ContentPathObservers {

    fileprivate struct Observer {
        
        weak var value: ContentPathObserver?
    }
    
    fileprivate var observers: [Observer]

    internal init() {
        self.observers = []
    }
    
    internal mutating func add(observer: ContentPathObserver) {
        if let emptyObserversIndex = observers.firstIndex (where: { $0.value == nil }) {
            observers[emptyObserversIndex].value = observer
        } else {
            observers.append(Observer(value: observer))
        }
    }
    
    internal mutating func notify() {
        let previouslyObservers = observers
        observers = []
        
        for item in previouslyObservers {
            item.value?.contentPathDidChange()
        }
    }
}
