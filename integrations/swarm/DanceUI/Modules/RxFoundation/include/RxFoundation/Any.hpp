//
//  Any.hpp
//  RxFoundation
//
//  Created by closure on 10/30/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Any_hpp
#define Any_hpp

#include <RxFoundation/RxObject.hpp>

#include <RxFoundation/TypeInfo.hpp>

#include <type_traits>
#include <utility>
#include <typeinfo>
#include <string>
#include <cassert>


namespace Rx {
    class Any {
        template<typename T>
        using decay = typename std::decay<T>::type;
        
        template<typename T>
        using none = typename std::enable_if<!std::is_same<Any, T>::value>::type;
        
        mutable SpinLock _lock;
        
        struct base {
        public:
            virtual ~base() { }
            virtual bool is(TypeInfo::id) const = 0;
            virtual base *copy() const = 0;
            virtual TypeInfo::id typeID() const = 0;
            virtual bool compare(const base *rhs) const = 0;
        } *p = nullptr;
        
        template<typename T>
        struct data : base, std::tuple<T> {
            using std::tuple<T>::tuple;
            
            T       &get()      & { return std::get<0>(*this); }
            T const &get() const& { return std::get<0>(*this); }
            
            bool is(TypeInfo::id i) const override { return i == typeID(); }
            base *copy()  const override { return new data{get()}; }
            bool compare(const base *rhs) const override {
                return (get() == reinterpret_cast<const data<T> *>(rhs)->get());
            }
            
            TypeInfo::id typeID() const override { return TypeInfo::ID<T>(); }
        };
        
        template<typename T>
        T &stat() { return static_cast<data<T>&>(*p).get(); }
        
        template<typename T>
        T const &stat() const { return static_cast<data<T> const&>(*p).get(); }
        
        template<typename T>
        T &dyn() { return dynamic_cast<data<T>&>(*p).get(); }
        
        template<typename T>
        T const &dyn() const { return dynamic_cast<data<T> const&>(*p).get(); }
        
    public:
        Any() : p(nullptr) { }
        ~Any() {
            LockGuard<decltype(_lock)> lock(_lock);
            if (p) {
                delete p;
                p = nullptr;
            }
        }
        
        Any(Any &&s) { LockGuard<decltype(s._lock)> lock(s._lock); p = s.p; s.p = nullptr; }
        Any(const Any &s) {
            LockGuard<decltype(s._lock)> lock(s._lock);
            if (s.p) {
                p = s.p->copy();
            } else {
                p = nullptr;
            }
        }
        
        template<typename T, typename U = decay<T>, typename = none<U>>
        Any(T &&x) : p(new data<U>{std::forward<T>(x)}) { }
        
        Any(decltype(nullptr) &&x) : p(nullptr) { }
        
        Any &operator=(Any s) {
            LockGuard<decltype(_lock)> lock(_lock);
            LockGuard<decltype(s._lock)> slock(s._lock);
            swap(*this, s);
            return *this;
        }
        
        bool operator==(const Any &value) const RX_NOEXCEPT {
            LockGuard<decltype(_lock)> lock(_lock);
            LockGuard<decltype(value._lock)> slock(value._lock);
            if (p == nullptr && value.p == nullptr) {
                return true;
            }
            if (p != nullptr && value.p != nullptr) {
                bool result = (p->typeID() == value.p->typeID() && (p->compare(value.p)));
                return result;
            }
            return false;
        }
        
        bool operator!=(const Any &value) const RX_NOEXCEPT {
            return !(*this == value);
        }
        
        bool operator<(const Any &value) const RX_NOEXCEPT {
            LockGuard<decltype(_lock)> lock(_lock);
            LockGuard<decltype(value._lock)> slock(value._lock);
            return p < value.p;
        }
            
        friend void swap(Any &s, Any &r) { std::swap(s.p, r.p); }
        
        void clear() { LockGuard<decltype(_lock)> lock(_lock); delete p; p = nullptr; }
        
        bool empty() const { LockGuard<decltype(_lock)> lock(_lock); return p == nullptr; }
        
        template<typename T>
        bool is() const {
            LockGuard<decltype(_lock)> lock(_lock);
            return p ? p->is(TypeInfo::ID<T>()) : false;
        }
        
        template<typename T>
        const T* isKindOf() const {
            if (p && p->is(TypeInfo::ID<T>())) {
                return &_<T>();
            }
            return nullptr;
        }
        
        template<typename T> operator T     &&()     && { LockGuard<decltype(_lock)> lock(_lock); return std::move(_<T>()); }
        template<typename T> operator T      &()      & { LockGuard<decltype(_lock)> lock(_lock); return _<T>(); }
        template<typename T> operator T const&() const& { LockGuard<decltype(_lock)> lock(_lock); return _<T>(); }
    private:
        template<typename T> T      &&_()     && { return std::move(stat<T>()); }
        template<typename T> T       &_()      & { return stat<T>(); }
        template<typename T> T const &_() const& { return stat<T>(); }
        
        template<typename T> T      &&cast()     && { return std::move(dyn<T>()); }
        template<typename T> T       &cast()      & { return dyn<T>(); }
        template<typename T> T const &cast() const& { return dyn<T>(); }
    };
}
            
#endif /* Any_hpp */
