//
//  CollectionContainer3.hpp
//  RxFoundation
//
//  Created by closure on 3/13/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CollectionContainer3_hpp
#define CollectionContainer3_hpp

#include <memory>
#include <algorithm>
#include <RxFoundation/RxBaseMacro.hpp>

namespace Rx {
    template <
    template <typename, typename, typename> class __CollectionContainer,
    typename __ElementType,
    template <typename> class __Compare,
    typename __AllocatorType = std::allocator<__ElementType>,
    typename __iterator = typename __CollectionContainer<__ElementType, __Compare<__ElementType>, __AllocatorType>::iterator,
    typename __const_iterator = typename __CollectionContainer<__ElementType, __Compare<__ElementType>, __AllocatorType>::const_iterator>
    class CollectionContainer3 {
    protected:
        typedef __CollectionContainer<__ElementType, __Compare<__ElementType>, __AllocatorType> StorageType;
        StorageType _storage;
    public:
        typedef typename StorageType::value_type value_type;
        typedef typename StorageType::size_type size_type;
        typedef typename StorageType::const_reference const_reference;
        typedef __iterator iterator;
        typedef __const_iterator const_iterator;
        
        CollectionContainer3() RX_NOEXCEPT {
        }
        
        CollectionContainer3(const CollectionContainer3 &value) RX_NOEXCEPT : _storage(value._storage) {
        }
        
        CollectionContainer3(CollectionContainer3 &&value) RX_NOEXCEPT : _storage(std::move(value._storage)) {
        }
        
        ~CollectionContainer3() RX_NOEXCEPT {
        }
        
        CollectionContainer3 &operator=(const CollectionContainer3 &copy) RX_NOEXCEPT {
            _storage = copy._storage;
            return *this;
        }
        
    public:
        virtual size_type size() const RX_NOEXCEPT {
            return _storage.size();
        }
        
        virtual bool isEmpty() const RX_NOEXCEPT {
            return size() == 0;
        }
        
        virtual const_iterator begin() const RX_NOEXCEPT {
            return _storage.begin();
        }
        
        virtual const_iterator end() const RX_NOEXCEPT {
            return _storage.end();
        }
        
        virtual iterator begin() RX_NOEXCEPT {
            return _storage.begin();
        }
        
        virtual iterator end() RX_NOEXCEPT {
            return _storage.end();
        }
        
        virtual iterator erase(const_iterator it) RX_NOEXCEPT {
            return _storage.erase(it);
        }
        
        virtual iterator erase(const_iterator __first, const_iterator __last) RX_NOEXCEPT {
            return _storage.erase(__first, __last);
        }
        
        virtual bool erase(const __ElementType &element) RX_NOEXCEPT {
            return erase(std::find(begin(), end(), element), end()) != end();
        }
        
        virtual void clear() RX_NOEXCEPT {
            _storage.clear();
        }
        
        virtual void addObject(const __ElementType &element) RX_NOEXCEPT {
            _storage.insert(element);
        }
        
        virtual void addObjects(const_iterator position, const_iterator start, const_iterator end) RX_NOEXCEPT {
            _storage.insert(position, start, end);
        }
        
        virtual bool contains(const __ElementType &element) const RX_NOEXCEPT {
            return std::find(begin(), end(), element) != end();
        }
        
        template <typename Predicate>
        const_iterator find(Predicate predicate) const RX_NOEXCEPT {
            return std::find_if(begin(), end(), predicate);
        }
        
        template <typename Predicate>
        iterator find(Predicate predicate) RX_NOEXCEPT {
            return std::find_if(begin(), end(), predicate);
        }
        
//        virtual const __ElementType &operator[](int32_t idx) const RX_NOEXCEPT {
//            return _storage[idx];
//        }
//        
//        virtual __ElementType &operator[](int32_t idx) RX_NOEXCEPT {
//            return _storage[idx];
//        }
    };
}


#endif /* CollectionContainer3_hpp */
