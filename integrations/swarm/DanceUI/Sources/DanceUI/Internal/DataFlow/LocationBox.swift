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
internal final class LocationBox<LocationType: Location>: AnyLocation<LocationType.Value>, Location {
    
    internal typealias Value = LocationType.Value
    
    internal var location: LocationType
    
    @UnsafeLockedPointer
    internal var cache: LocationProjectionCache
    
    internal init(_ location: LocationType) {
        self.location = location
        cache = LocationProjectionCache()
    }
    
    deinit {
        $cache.destroy()
    }
    
    internal override var wasRead: Bool {
        get { return location.wasRead }
        set { location.wasRead = newValue }
    }
    
    internal override var _host: GraphHost? {
        nil
    }
    
    internal override func get() -> Value {
        return location.get()
    }
    
    internal override func set(_ value: Value, transaction: Transaction) {
        location.set(value, transaction: transaction)
    }
    
    internal override func update() -> (LocationType.Value, Bool) {
        location.update()
    }
    
    internal override func projecting<P: Projection>(_ projection: P) -> AnyLocation<P.Projected> where Value == P.Base {
        $cache.withMutableData { cache in
            cache.reference(for: projection, on: location)
        }
    }
    
}
