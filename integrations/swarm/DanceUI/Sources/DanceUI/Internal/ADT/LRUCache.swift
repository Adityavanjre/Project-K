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
internal final class LRUCache<Key: Hashable, Value> {
    
    fileprivate var head: LRUBucket<Key, Value>
    
    fileprivate var tail: LRUBucket<Key, Value>
    
    fileprivate var bucketsForKeys: [Key : LRUBucket<Key, Value>]
    
    internal var totalWeight: Int
    
    internal private(set) var usedWeight: Int
    
    internal init(totalWeight: Int = 0) {
        self.totalWeight = totalWeight
        self.usedWeight = 0
        self.head = .init()
        self.tail = .init()
        self.head.next = tail
        self.tail.previous = head
        self.bucketsForKeys = [:]
    }
    
    @discardableResult
    internal func insertValue(
        _ value: Value,
        forKey key: Key,
        weight weightOrNil: Int? = nil
    ) -> Value? {
        let newWeight = _checkedWeight(weightOrNil)
        var oldValue: Value?
        if let _bucket = bucketsForKeys[key] {
            oldValue = _bucket.contents.value
            _removeBucket(_bucket)
            _bucket.contents = (key, value, newWeight)
            _insertBucket(_bucket)
        } else {
            let _bucket = LRUBucket(contents: (key, value, newWeight))
            bucketsForKeys[key] = _bucket
            _insertBucket(_bucket)
        }
        evictIfNeeded()
        return oldValue
    }
    
    @discardableResult
    internal func evictValue(forKey key: Key) -> Value? {
        guard let bucket = bucketsForKeys[key] else {
            return nil
        }
        bucketsForKeys[key] = nil
        _removeBucket(bucket)
        return bucket.contents.value
    }
    
    @discardableResult
    internal func value(forKey key: Key) -> Value? {
        guard let bucket = bucketsForKeys[key] else {
            return nil
        }
        _removeBucket(bucket)
        _insertBucket(bucket)
        return bucket.contents.value
    }
    
    @discardableResult
    internal func value(forKey key: Key, defaultValue: Value, weight: Int? = nil) -> Value {
        let newWeight = _checkedWeight(weight)
        let bucket: LRUBucket<Key, Value>
        if let existedBucket = bucketsForKeys[key] {
            bucket = existedBucket
            _removeBucket(bucket)
            bucket.contents = (key, defaultValue, newWeight)
            _insertBucket(bucket)
        } else {
            bucket = LRUBucket(contents: (key, defaultValue, newWeight))
            bucketsForKeys[key] = bucket
            _insertBucket(bucket)
        }
        evictIfNeeded()
        return bucket.contents.value
    }
    
    internal func evictIfNeeded() {
        guard totalWeight > 0 else {
            return
        }
        
        while usedWeight > totalWeight {
            let mostNotUsedBucket = tail.previous!
            _removeBucket(mostNotUsedBucket)
            bucketsForKeys[mostNotUsedBucket.contents.key] = nil
        }
    }
    
    internal func containsValue(forKey key: Key) -> Bool {
        bucketsForKeys[key] != nil
    }
    
    internal func setTotalWeight(_ weight: Int, evict: Bool) {
        totalWeight = weight
        guard evict else {
            return
        }
        evictIfNeeded()
    }
    
    @inline(__always)
    internal subscript(key: Key, weight: Int? = nil) -> Value? {
        get {
            value(forKey: key)
        }
        set {
            switch (newValue, containsValue(forKey: key)) {
            case let (.some(newValue), _):
                insertValue(newValue, forKey: key, weight: weight)
            case (.none, true):
                evictValue(forKey: key)
            case (.none, false):
                break
            }
        }
    }
    
    @inline(__always)
    internal subscript(key: Key, defaultValue: Value, weight: Int? = nil) -> Value {
        _read {
            let bucket = _ensuredBucket(forValue: defaultValue, forKey: key, weight: weight)
            yield bucket.contents.value
        }
        _modify {
            let bucket = _ensuredBucket(forValue: defaultValue, forKey: key, weight: weight)
            yield &bucket.contents.value
        }
    }
    
    private func _ensuredBucket(forValue value: Value, forKey key: Key, weight: Int?) -> LRUBucket<Key, Value> {
        let bucket: LRUBucket<Key, Value>
        let newWeight = _checkedWeight(weight)
        if let existedBucket = bucketsForKeys[key] {
            bucket = existedBucket
            _removeBucket(bucket)
            bucket.contents.weight = newWeight
            _insertBucket(bucket)
        } else {
            bucket = LRUBucket(contents: (key, value, newWeight))
            bucketsForKeys[key] = bucket
            _insertBucket(bucket)
        }
        evictIfNeeded()
        return bucket
    }
    
    internal func _insertBucket(_ bucket: LRUBucket<Key, Value>) {
        usedWeight += bucket.contents.weight
        
        let currentFirstBucket = head.next!
        
        head.next = bucket
        bucket.previous = head
        
        bucket.next = currentFirstBucket
        currentFirstBucket.previous = bucket
    }
    
    internal func _removeBucket(_ bucket: LRUBucket<Key, Value>) {
        usedWeight -= bucket.contents.weight
        
        let previous = bucket.previous!
        
        let next = bucket.next!
        
        previous.next = next
        next.previous = previous
        
        bucket.next = nil
        bucket.previous = nil
    }
    
    @inline(__always)
    private func _checkedWeight(_ weight: Int?) -> Int {
        if let weight = weight {
            return max(weight, 0)
        } else {
            return 1
        }
    }
}

@available(iOS 13.0, *)
extension LRUCache {
    
    internal var leastRecentlyUsedView: LRUCacheLeastRecentlyUsedView<Key, Value> {
        return LRUCacheLeastRecentlyUsedView(cache: self)
    }
    
}

@available(iOS 13.0, *)
internal struct LRUCacheLeastRecentlyUsedView<Key: Hashable, Value>: Sequence {
    
    internal let cache: LRUCache<Key, Value>
    
    internal init(cache: LRUCache<Key, Value>) {
        self.cache = cache
    }
    
    internal typealias Iterator = LRUCacheLeastRecentlyUsedViewIterator<Key, Value>
    
    internal __consuming func makeIterator() -> Iterator {
        return Iterator(cache: cache)
    }
}

@available(iOS 13.0, *)
internal struct LRUCacheLeastRecentlyUsedViewIterator<Key: Hashable, Value>:
    IteratorProtocol
{
    
    internal let cache: LRUCache<Key, Value>
    
    internal unowned var current: LRUBucket<Key, Value>
    
    internal init(cache: LRUCache<Key, Value>) {
        self.cache = cache
        self.current = cache.head.next!
    }
    
    internal typealias Element = (key: Key, value: Value)
    
    internal mutating func next() -> Element? {
        guard let (key, value, _) = current.contents else {
            return nil
        }
        current = current.next!
        return (key, value)
    }
}

@available(iOS 13.0, *)
internal final class LRUBucket<Key: Hashable, Value> {
    
    internal unowned var previous: LRUBucket?
    
    internal unowned var next: LRUBucket?
    
    internal var contents: (key: Key, value: Value, weight: Int)!
    
    internal init(contents: (key: Key, value: Value, weight: Int)? = nil) {
        self.contents = contents
    }
    
}
