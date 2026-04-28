//
//  CollectionContainer.hpp
//  RxFoundation
//
//  Created by closure on 3/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CollectionContainer_hpp
#define CollectionContainer_hpp

#include <RxFoundation/RxBase.hpp>
#include <memory>
#include <algorithm>

namespace Rx {

    template <class _Tp>
    struct __is_input_iterator : public std::__has_iterator_category_convertible_to<_Tp, std::input_iterator_tag> {};

    template <class _Tp>
    struct __is_forward_iterator : public std::__has_iterator_category_convertible_to<_Tp, std::forward_iterator_tag> {};

    template <class _Tp>
    struct __is_bidirectional_iterator : public std::__has_iterator_category_convertible_to<_Tp, std::bidirectional_iterator_tag> {};

    template <class _Tp>
    struct __is_random_access_iterator : public std::__has_iterator_category_convertible_to<_Tp, std::random_access_iterator_tag> {};

    template <
    template <typename, typename> class __CollectionContainer,
    typename __ElementType,
    typename __AllocatorType = std::allocator<__ElementType>,
    typename __iterator = typename __CollectionContainer<__ElementType, __AllocatorType>::iterator,
    typename __const_iterator = typename __CollectionContainer<__ElementType, __AllocatorType>::const_iterator>
    class CollectionContainer {
    protected:
        typedef __CollectionContainer<__ElementType, __AllocatorType> StorageType;
        StorageType _storage;
    public:
        typedef typename StorageType::value_type value_type;
        typedef typename StorageType::size_type size_type;
        typedef typename StorageType::const_reference const_reference;
        typedef __iterator iterator;
        typedef __const_iterator const_iterator;
        
        CollectionContainer() RX_NOEXCEPT {
        }
        
        CollectionContainer(std::initializer_list<value_type> __il) RX_NOEXCEPT : _storage(__il) {
        }
        
        CollectionContainer(const CollectionContainer &value) RX_NOEXCEPT : _storage(value._storage) {
        }
        
        CollectionContainer(CollectionContainer &&value) RX_NOEXCEPT : _storage(std::move(value._storage)) {
        }
        
        CollectionContainer(const StorageType &value) RX_NOEXCEPT : _storage(value) {
        }
        
        CollectionContainer(StorageType &&value) RX_NOEXCEPT : _storage(value) {
        }
        
        ~CollectionContainer() RX_NOEXCEPT {
        }
        
        CollectionContainer &operator=(const CollectionContainer &copy) RX_NOEXCEPT {
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
        
        virtual void push_back(const __ElementType &element) RX_NOEXCEPT {
            // back_inserter interface
            addObject(element);
        }
        
        virtual void addObject(const __ElementType &element) RX_NOEXCEPT {
            _storage.push_back(element);
        }
        
        virtual void addObjects(const_iterator position, const_iterator start, const_iterator end) RX_NOEXCEPT {
            _storage.insert(position, start, end);
        }
        
        virtual __ElementType &front() RX_NOEXCEPT {
            return _storage.front();
        }
        
        virtual __ElementType &back() RX_NOEXCEPT {
            return _storage.back();
        }
        
        virtual const __ElementType &front() const RX_NOEXCEPT {
            return _storage.front();
        }
        
        virtual const __ElementType &back() const RX_NOEXCEPT {
            return _storage.back();
        }
        
        virtual void pop_back() RX_NOEXCEPT {
            _storage.pop_back();
        }
        
        virtual void reserve(size_type size) RX_NOEXCEPT {
            _storage.reserve(size);
        }
        
        virtual void resize(size_type size, const_reference v) RX_NOEXCEPT {
            _storage.resize(size, v);
        }
        
        virtual const value_type *data() const RX_NOEXCEPT {
            return _storage.data();
        }
        
        virtual value_type *data() RX_NOEXCEPT {
            return _storage.data();
        }
        
        
        iterator insert(const_iterator __position, const_reference __x) {
            return _storage.insert(__position, __x);
        }

        iterator insert(const_iterator __position, value_type&& __x) {
            return _storage.insert(__position, __x);
        }

        iterator insert(const_iterator __position, size_type __n, const_reference __x) {
            return _storage.insert(__position, __n, __x);
        }
        
        template <class _InputIterator>
        typename std::enable_if
        <
        __is_input_iterator  <_InputIterator>::value &&
        !__is_forward_iterator<_InputIterator>::value &&
        std::is_constructible<
        value_type,
        typename std::iterator_traits<_InputIterator>::reference>::value,
        iterator
        >::type
        insert(const_iterator __position, _InputIterator __first, _InputIterator __last) RX_NOEXCEPT {
            return _storage.insert(__position, __first, __last);
        }
        
        template <class _ForwardIterator>
        typename std::enable_if
        <
        __is_forward_iterator<_ForwardIterator>::value &&
        std::is_constructible<
        value_type,
        typename std::iterator_traits<_ForwardIterator>::reference>::value,
        iterator
        >::type
        insert(const_iterator __position, _ForwardIterator __first, _ForwardIterator __last) {
            return _storage.insert(__position, __first, __last);
        }

        iterator insert(const_iterator __position, std::initializer_list<value_type> __il) RX_NOEXCEPT {
            return insert(__position, __il.begin(), __il.end());
        }
        
        template <class _InputIterator>
        typename std::enable_if
        <
        __is_input_iterator<_InputIterator>::value &&
        !__is_forward_iterator<_InputIterator>::value &&
        std::is_constructible<
        value_type,
        typename std::iterator_traits<_InputIterator>::reference>::value,
        void
        >::type
        assign(_InputIterator __first, _InputIterator __last) RX_NOEXCEPT {
            _storage.assign(__first, __last);
        }
        
        template <class _ForwardIterator>
        typename std::enable_if
        <
        __is_forward_iterator<_ForwardIterator>::value &&
        std::is_constructible<
        value_type,
        typename std::iterator_traits<_ForwardIterator>::reference>::value,
        void
        >::type
        assign(_ForwardIterator __first, _ForwardIterator __last) RX_NOEXCEPT {
            _storage.assign(__first, __last);
        }
        
        void assign(size_type __n, const_reference __u) RX_NOEXCEPT {
            _storage.assign(__n, __u);
        }
        
        void assign(std::initializer_list<value_type> __il) RX_NOEXCEPT {
            _storage.assign(__il);
        }
        
        virtual bool contains(const __ElementType &element) const RX_NOEXCEPT {
            return std::find(begin(), end(), element) != end();
        }
        
        virtual const_iterator find(const __ElementType &element) const RX_NOEXCEPT {
            return std::find(begin(), end(), element);
        }
        
        virtual iterator find(const __ElementType &element) RX_NOEXCEPT {
            return std::find(begin(), end(), element);
        }
        
        template <typename Predicate>
        const_iterator find(Predicate predicate) const RX_NOEXCEPT {
            return std::find_if(begin(), end(), predicate);
        }
        
        template <typename Predicate>
        iterator find(Predicate predicate) RX_NOEXCEPT {
            return std::find_if(begin(), end(), predicate);
        }
        
        virtual const __ElementType &operator[](size_t idx) const RX_NOEXCEPT {
            return _storage[idx];
        }
        
        virtual __ElementType &operator[](size_t idx) RX_NOEXCEPT {
            return _storage[idx];
        }
        
        bool operator==(const CollectionContainer &value) const RX_NOEXCEPT {
            return _storage == value._storage;
        }
    };
}

#endif /* CollectionContainer_hpp */
