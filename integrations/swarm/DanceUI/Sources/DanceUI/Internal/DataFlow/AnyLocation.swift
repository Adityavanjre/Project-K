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

@usableFromInline
@available(iOS 13.0, *)
internal class AnyLocationBase {
    
    internal init() {
        
    }
    
}

@usableFromInline
@available(iOS 13.0, *)
internal class AnyLocation<Value> : AnyLocationBase {
    
    internal override init() {
        super.init()
    }
    

    deinit {
        
    }
    
    internal var wasRead: Bool {
        get {
            _abstract(self)
        }
        set {
            _abstract(self)
        }
    }

    internal weak var _host: GraphHost? {
        _abstract(self)
    }

    internal func get() -> Value {
        _abstract(self)
    }

    internal func set(_ value: Value, transaction: Transaction) {
        _abstract(self)
    }

    internal func projecting<P: Projection>(_ projection: P) -> AnyLocation<P.Projected> where Value == P.Base {
        _abstract(self)
    }

    internal func update() -> (Value, Bool) {
        _abstract(self)
    }
    
}
