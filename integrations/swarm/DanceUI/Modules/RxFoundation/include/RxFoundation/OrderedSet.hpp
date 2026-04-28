//
//  OrderedSet.hpp
//  RxFoundation
//
//  Created by Closure on 6/15/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef OrderedSet_hpp
#define OrderedSet_hpp

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/Array.hpp>
#include <RxFoundation/Set.hpp>
#include <RxFoundation/RxObject.hpp>
#include <RxFoundation/CopyDescriptionChecker.hpp>
#include <RxFoundation/HashChecker.hpp>
#include <algorithm>

namespace Rx {
    template <typename T>
    class OrderedSet : public virtual Object {
    public:
        typedef T value_type;
        typedef ptrdiff_t difference_type;
        typedef value_type &reference_type;
        typedef const value_type &const_reference;
        typedef size_t size_type;
        typedef value_type *pointer_type;
        
        static constexpr const size_type NotFound = ~0;
        
        template <typename ValueTy>
        class __iterator : public std::iterator<std::bidirectional_iterator_tag, ValueTy> {
            friend class OrderedSet<value_type>;
            static constexpr const Index BeginIndex = 0;
            static constexpr const Index EndIndex = -1;
            __iterator(const OrderedSet<value_type> &orderedSet, const Index index) RX_NOEXCEPT :
            _orderedSet(orderedSet),
            _index(index) {
            }
        public:
            __iterator(const __iterator &value) RX_NOEXCEPT :
            _orderedSet(value._orderedSet),
            _index(value._index) {
            }
            
        public:
            __iterator operator++() const RX_NOEXCEPT {
                if (_index == EndIndex) {
                    return *this;
                } else if (_index + 1 == _orderedSet.size()) {
                    return __iterator(_orderedSet, EndIndex);
                }
                return __iterator(_orderedSet, _index + 1);
            }

            __iterator operator--() const {
                if (_index == BeginIndex) {
                    return *this;
                } else if (_index == EndIndex && _orderedSet.size()) {
                    return __iterator(_orderedSet, _orderedSet.size() - 1);
                }
                return __iterator(_orderedSet, _index - 1);
            }
            
            __iterator &operator++() RX_NOEXCEPT {
                if (_index == EndIndex) {
                    return *this;
                } else if (_index + 1 == _orderedSet.size()) {
                    _index = EndIndex;
                    return *this;
                }
                _index++;
                return *this;
            }
            
            __iterator &operator--() RX_NOEXCEPT {
                if (_index == BeginIndex) {
                    return *this;
                } else if (_index == EndIndex && _orderedSet.size()) {
                    _index == _orderedSet.size() - 1;
                    return *this;
                }
                _index--;
                return *this;
            }
            
            bool operator==(const __iterator &value) const RX_NOEXCEPT {
                if (&(*this) == &value) {
                    return true;
                }
                return (&_orderedSet == &value._orderedSet) && _index == value._index;
            }
            
            bool operator!=(const __iterator &value) const RX_NOEXCEPT {
                return !(operator==(value));
            }
            
            const ValueTy &operator*() const RX_NOEXCEPT {
                RxCheck((bool)(*this));
                return _orderedSet._array[_index];
            }
            
            const ValueTy *operator->() const {
                if (!(*this)) {
                    return nullptr;
                }
                return &operator*();
            }
            
            operator bool() const RX_NOEXCEPT {
                if (_index == EndIndex) {
                    return false;
                }
                auto size = _orderedSet.size();
                return size && size > _index;
            }
        private:
            
            size_type _getPosition() const RX_NOEXCEPT {
                if (!(*this)) {
                    return NotFound;
                }
                return _index;
            }
            
            const OrderedSet<value_type> &_orderedSet;
            size_type _index;
        };
        
        using iterator = __iterator<value_type>;
        using const_iterator = __iterator<const value_type>;
        
        OrderedSet() RX_NOEXCEPT {}
        OrderedSet(const OrderedSet &value) RX_NOEXCEPT : _array(value._array), _set(value._set) {}
        OrderedSet(OrderedSet &&value) RX_NOEXCEPT : _array(std::move(value._array)), _set(std::move(value._set)) {}
        OrderedSet(std::initializer_list<value_type> __il) RX_NOEXCEPT {
            for (const auto &element : __il) {
                if (_set.contains(element)) {
                    continue;
                }
                _set.addObject(element);
                _array.addObject(element);
            }
            size();
        }
        ~OrderedSet() RX_NOEXCEPT {}
        
        const_iterator begin() const RX_NOEXCEPT {
            if (size()) {
                return const_iterator(*this, const_iterator::BeginIndex);
            }
            return end();
        }
        const_iterator end() const RX_NOEXCEPT {
            return const_iterator(*this, const_iterator::EndIndex);
        }
        
        void addObject(const value_type &value) RX_NOEXCEPT {
            size();
            _array.addObject(value);
            _set.addObject(value);
            size();
        }
        
        virtual void addObjects(const_iterator start, const_iterator end) RX_NOEXCEPT {
            if (!(start._orderedSet == end._orderedSet) ||
                start._orderedSet == *this) {
                return;
            }
            auto startPosition = start._getPosition();
            auto endPosition = end._getPosition();
            if (startPosition == endPosition) {
                return;
            }
            auto cnt = size();
            if (startPosition >= cnt) {
                return;
            }
            if (endPosition != const_iterator::EndIndex &&
                endPosition < startPosition) {
                return;
            }
            auto &targetOrderedSet = start._orderedSet;
            auto array_begin_it = targetOrderedSet._array.begin() + startPosition;
            auto array_end_it = endPosition == const_iterator::EndIndex ? targetOrderedSet._array.end() : array_begin_it + endPosition;
            _array.addObjects(_array.end(), array_begin_it, array_end_it);
            for (auto it = array_begin_it; it != array_end_it; it++) {
                _set.addObject(*it);
            }
            size();
        }
        
        void erase(const value_type &value) RX_NOEXCEPT {
            size();
            _array.erase(value);
            _set.erase(value);
            size();
        }
        
        void erase(const_iterator &it) RX_NOEXCEPT {
            if (!it) {
                return;
            }
            auto &value = *it;
            typename decltype(_array)::iterator _it = _array.begin() + it._getPosition();
            _array.erase(_it);
            _set.erase(value);
        }
        
        size_type size() const RX_NOEXCEPT {
            auto size = _array.size();
            RxCheck(size == _set.size());
            return size;
        }
        
        bool isEmpty() const RX_NOEXCEPT {
            return size() == 0;
        }
        
        virtual const_reference front() const RX_NOEXCEPT {
            return _array.front();
        }
        
        virtual const_reference back() const RX_NOEXCEPT {
            return _array.back();
        }
        
        virtual void pop_back() RX_NOEXCEPT {
            auto ref = back();
            _array.pop_back();
            _set.erase(ref);
            size();
        }
        
        virtual const value_type *data() const RX_NOEXCEPT {
            return _array.data();
        }
        
        OrderedSet &operator=(const OrderedSet &value) RX_NOEXCEPT {
            _array = value._array;
            _set = value._set;
            return *this;
        }
        
        virtual bool contains(const_reference element) const RX_NOEXCEPT {
            return std::find(_set.begin(), _set.end(), element) != _set.end();
        }
        
        virtual const_iterator find(const_reference element) const RX_NOEXCEPT {
            auto it = std::find(_set.begin(), _set.end(), element);
            if (it == _set.end()) {
                // not found
                return end();
            }
            auto arrayIt = std::find(_array.begin(), _array.end(), *it);
            RxCheck(arrayIt != _array.end());
            auto index = arrayIt - _array.begin();
            return const_iterator(*this, index);
        }
        
        template <typename Predicate>
        const_iterator find(Predicate predicate) const RX_NOEXCEPT {
            auto it = _set.find(predicate);
            if (it == _set.end()) {
                // not found
                return end();
            }
            auto arrayIt = _array.find(*it);
            RxCheck(arrayIt != _array.end());
            auto index = arrayIt - _array.begin();
            return const_iterator(*this, index);
        }
        
        virtual const_reference operator[](size_t idx) const RX_NOEXCEPT {
            return _array[idx];
        }
        
        bool operator==(const OrderedSet &value) const RX_NOEXCEPT {
            if (&(*this) == &value) {
                return true;
            }
            if (size() != value.size()) {
                return false;
            }
            return _array == value._array && _set == value._set;
        }
        
        virtual String copyDescription() const RX_NOEXCEPT {
            return _array.copyDescription();
        }
        
        virtual HashCode hash() const RX_NOEXCEPT {
            return Rx::hash(_array);
        }
    private:
        Array<T> _array;
        Set<T> _set;
    };
    
}

#endif /* OrderedSet_hpp */
