//
//  Set.hpp
//  RxFoundation
//
//  Created by closure on 3/13/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef Set_hpp
#define Set_hpp

#include <RxFoundation/CollectionContainer3.hpp>
#include <RxFoundation/RxObject.hpp>
#include <RxFoundation/String.hpp>
#include <RxFoundation/CopyDescriptionChecker.hpp>
#include <set>

namespace Rx {
    template <typename __ElementType>
    class CollectionContainer3<std::set, __ElementType, std::less> {
    protected:
        typedef std::allocator<__ElementType> __AllocatorType;
        typedef std::set <__ElementType, std::less<__ElementType>, __AllocatorType> StorageType;
        typedef typename StorageType::iterator __iterator;
        typedef typename StorageType::const_iterator __const_iterator;
        StorageType _storage;
    public:
        typedef typename StorageType::key_type      key_type;
        typedef typename StorageType::value_type    value_type;
        typedef typename StorageType::size_type     size_type;
        typedef typename StorageType::const_reference const_reference;
        typedef __iterator iterator;
        typedef __const_iterator const_iterator;
        
        
        CollectionContainer3() {
        }
        
        CollectionContainer3(const CollectionContainer3 &value) : _storage(value._storage) {
        }
        
        CollectionContainer3(CollectionContainer3 &&value) : _storage(std::move(value._storage)) {
        }
        
        CollectionContainer3(std::initializer_list<value_type> &__il) : _storage(__il) {
        }
        
        ~CollectionContainer3() {
        }
        
        CollectionContainer3 &operator=(const CollectionContainer3 &copy) {
            _storage = copy._storage;
            return *this;
        }
        
    public:
        virtual size_type size() const {
            return _storage.size();
        }
        
        virtual bool isEmpty() const {
            return size() == 0;
        }
        
        virtual const_iterator begin() const {
            return _storage.begin();
        }
        
        virtual const_iterator end() const {
            return _storage.end();
        }
        
        virtual iterator begin() {
            return _storage.begin();
        }
        
        virtual iterator end() {
            return _storage.end();
        }
        
        virtual iterator erase(const_iterator it) {
            return _storage.erase(it);
        }
        
        virtual iterator erase(const_iterator __first, const_iterator __last) {
            return _storage.erase(__first, __last);
        }
        
        virtual bool erase(const __ElementType &element) {
            auto it = std::find(begin(), end(), element);
            return erase(it) != end();
        }
        
        virtual void clear() {
            _storage.clear();
        }
        
        virtual void addObject(const __ElementType &element) {
            _storage.insert(element);
        }
        
        virtual void addObjects(const_iterator start, const_iterator end) RX_NOEXCEPT {
            _storage.insert(start, end);
        }
        
        template <typename T>
        bool contains(const T &element) const {
            return std::find(begin(), end(), element) != end();
        }
        
        virtual bool contains(const __ElementType &element) const {
            return std::find(begin(), end(), element) != end();
        }
        
        template <typename Predicate>
        const_iterator find(Predicate predicate) const {
            return std::find_if(begin(), end(), predicate);
        }
        
        template <typename Predicate>
        iterator find(Predicate predicate) {
            return std::find_if(begin(), end(), predicate);
        }
        
        virtual iterator operator[](const key_type &__k) {
            return _storage.find(__k);
        }
        
        virtual const_iterator operator[](const key_type &__k) const {
            return _storage.find(__k);
        }
    };
    
    template <typename T>
    class Set : public virtual Object, public CollectionContainer3<std::set, T, std::less> {
    public:
        using base = CollectionContainer3<std::set, T, std::less>;
        using StorageType = typename base::StorageType;
        
        typedef typename base::value_type value_type;
        typedef typename base::size_type size_type;
        typedef typename base::const_reference const_reference;
        typedef typename base::iterator iterator;
        typedef typename base::const_iterator const_iterator;
        
        Set() RX_NOEXCEPT : base() {
        }
        
        Set(std::initializer_list<value_type> __il) RX_NOEXCEPT : base(__il) {
        }
        
        Set(const Set &value) RX_NOEXCEPT : base(value) {
        }
        
        Set(Set &&value) RX_NOEXCEPT : base(std::move(value)) {
        }
        
        Set(const StorageType &value) RX_NOEXCEPT : base(value) {
        }
        
        Set(StorageType &&value) RX_NOEXCEPT : base(value) {
        }
        
        ~Set() RX_NOEXCEPT {
        }
        
        Set &operator=(const Set &copy) RX_NOEXCEPT {
            base::operator=(copy);
            return *this;
        }
        
        virtual String copyDescription() const RX_NOEXCEPT {
            const Integer cnt = base::size();
            Integer idx = 0;
            String description = "(";
            for (auto it = base::begin(), end = base::end(); it != end; ++it, idx++) {
                auto desc = Rx::copyDescription(*it);
                if (idx + 1 == cnt) {
                    description += desc;
                } else {
                    description += desc + ", ";
                }
            }
            description += ")";
            return description;
        }
        
        virtual HashCode hash() const RX_NOEXCEPT {
            return base::size();
        }
    };
    
    
    template <typename __ElementType>
    class CollectionContainer3<std::multiset, __ElementType, std::less> {
    private:
        typedef std::allocator<__ElementType> __AllocatorType;
        typedef std::set <__ElementType, std::less<__ElementType>, __AllocatorType> StorageType;
        typedef typename StorageType::iterator __iterator;
        typedef typename StorageType::const_iterator __const_iterator;
        StorageType _storage;
    public:
        typedef typename StorageType::key_type      key_type;
        typedef typename StorageType::value_type    value_type;
        typedef typename StorageType::size_type     size_type;
        typedef __iterator iterator;
        typedef __const_iterator const_iterator;
        
        
        CollectionContainer3() {
        }
        
        CollectionContainer3(const CollectionContainer3 &value) : _storage(value._storage) {
        }
        
        CollectionContainer3(CollectionContainer3 &&value) : _storage(std::move(value._storage)) {
        }
        
        ~CollectionContainer3() {
        }
        
        CollectionContainer3 &operator=(const CollectionContainer3 &copy) {
            _storage = copy._storage;
            return *this;
        }
        
    public:
        virtual size_type size() const {
            return _storage.size();
        }
        
        virtual bool isEmpty() const {
            return size() == 0;
        }
        
        virtual const_iterator begin() const {
            return _storage.begin();
        }
        
        virtual const_iterator end() const {
            return _storage.end();
        }
        
        virtual iterator begin() {
            return _storage.begin();
        }
        
        virtual iterator end() {
            return _storage.end();
        }
        
        virtual iterator erase(const_iterator it) {
            return _storage.erase(it);
        }
        
        virtual iterator erase(const_iterator __first, const_iterator __last) {
            return _storage.erase(__first, __last);
        }
        
        virtual bool erase(const __ElementType &element) {
            return erase(std::find(begin(), end(), element), end()) != end();
        }
        
        virtual void clear() {
            _storage.clear();
        }
        
        virtual void addObject(const __ElementType &element) {
            _storage.insert(element);
        }
        
        template <typename T>
        bool contains(const T &element) const {
            return std::find(begin(), end(), element) != end();
        }
        
        virtual bool contains(const __ElementType &element) const {
            return std::find(begin(), end(), element) != end();
        }
        
        template <typename Predicate>
        const_iterator find(Predicate predicate) const {
            return std::find_if(begin(), end(), predicate);
        }
        
        template <typename Predicate>
        iterator find(Predicate predicate) {
            return std::find_if(begin(), end(), predicate);
        }
        
        virtual iterator operator[](const key_type &__k) {
            return _storage.find(__k);
        }
        
        virtual const_iterator operator[](const key_type &__k) const {
            return _storage.find(__k);
        }
    };
    
    template <typename T>
    using Bag = CollectionContainer3<std::multiset, T, std::less>;
    
}

#endif /* Set_hpp */
