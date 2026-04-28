//
//  BasicHashTypeInfo.hpp
//  RxFoundation
//
//  Created by closure on 12/20/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef BasicHashTypeInfo_h
#define BasicHashTypeInfo_h

#include <RxFoundation/RxBase.hpp>
#include <RxFoundation/String.hpp>

namespace Rx {
    template <typename T>
    struct BasicHashInfo {
//        static inline T getEmptyKey();
//        static inline T getTombstone();
//        static inline UInt64 getHashValue(const T &key) { return 0; }
//        static inline bool isEqual(const T &lhs, const T &rhs) {
//            return lhs == rhs;
//        }
    };
    
    constexpr const auto HASHFACTOR = 2654435761UL;
    
    template <typename T>
    struct BasicHashInfoHelper {
        template <typename U>
        static inline auto _getHashValue(const U &key) ->
        std::enable_if_t<std::is_integral<U>::value, std::enable_if_t<!std::is_floating_point<U>::value, HashCode>> {
            return ((key > 0) ? (HashCode)(key) : (HashCode)(-key)) * HASHFACTOR;
        }
        
        template <typename U>
        static inline auto _getHashValue(const U &key) ->
        std::enable_if_t<!std::is_integral<U>::value, std::enable_if_t<std::is_floating_point<U>::value, HashCode>> {
            double dInt;
            if (key < 0) key = -key;
            dInt = floor(key + 0.5);
            HashCode integralHash = HASHFACTOR * (HashCode)fmod(dInt, (double)std::numeric_limits<unsigned long>::max());
            return (HashCode)(integralHash + (HashCode)((key - dInt) * std::numeric_limits<unsigned long>::max()));
        }
        
        template <typename U>
        static inline auto _getHashValue(const U &key) ->
        std::enable_if_t<!std::is_arithmetic<U>::value, HashCode> {
            return (HashCode)key;
        }
        
        static inline auto getHashValue(const T &key) -> HashCode {
            return _getHashValue<T>(key);
        }
        
        static inline bool isEqual(const T &lhs, const T &rhs) {
            return lhs == rhs;
        }
    };
    
    template <typename T>
    struct BasicHashInfoHelper<T *> {
        static inline HashCode getHashValue(const T *key) {
            return (unsigned((uintptr_t)key) >> 4) ^
            (unsigned((uintptr_t)key) >> 9);
        }
        
        static inline bool isEqual(const T *lhs, const T *rhs) {
            if (lhs == rhs) {
                return true;
            }
            return (*lhs) == (*rhs);
        }
    };
    
    template <typename T>
    struct BasicHashInfo<T *> {
        static inline T *getEmptyKey() {
            return nullptr;
        }
        
        static inline T *getTombstone() {
            uintptr_t val = static_cast<uintptr_t>(-1);
            return reinterpret_cast<T *>(val);
        }
        
        static inline UInt64 getHashValue(const T *val) {
            return BasicHashInfoHelper<decltype(val)>::getHashValue(val);
        }
        
        static inline bool isEqual(const T *lhs, const T *rhs) {
            return lhs == rhs;
        }
    };
    
    template <>
    struct BasicHashInfo<char> {
        static inline char getEmptyKey() { return ~0; }
        static inline char getTombstonKey() { return ~0 - 1; }
        static UInt64 getHashValue(const char &val) { return BasicHashInfoHelper<decltype(val)>::getHashValue(val); }
        static bool isEqual(const char &lhs, const char &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<unsigned> {
        static inline unsigned getEmptyKey() { return ~0U; }
        static inline unsigned getTombstoneKey() { return ~0U - 1; }
        static UInt64 getHashValue(const unsigned &val) { return BasicHashInfoHelper<decltype(val)>::getHashValue(val); }
        static bool isEqual(const unsigned &lhs, const unsigned &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<unsigned long> {
        static inline unsigned long getEmptyKey() { return ~0UL; }
        static inline unsigned long getTombstoneKey() { return ~0UL - 1L; }
        static UInt64 getHashValue(const unsigned long &val) {
            return BasicHashInfoHelper<decltype(val)>::getHashValue(val);
        }
        static bool isEqual(const unsigned long &lhs, const unsigned long &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<unsigned long long> {
        static inline unsigned long long getEmptyKey() { return ~0ULL; }
        static inline unsigned long long getTombstoneKey() { return ~0ULL - 1ULL; }
        static UInt64 getHashValue(const unsigned long long &val) {
            return BasicHashInfoHelper<decltype(val)>::getHashValue(val);
        }
        static bool isEqual(const unsigned long long &lhs,
                            const unsigned long long &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<int> {
        static inline int getEmptyKey() { return 0x7fffffff; }
        static inline int getTombstoneKey() { return -0x7fffffff - 1; }
        static UInt64 getHashValue(const int &val) { return BasicHashInfoHelper<decltype(val)>::getHashValue(val); }
        static bool isEqual(const int &lhs, const int &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<long> {
        static inline long getEmptyKey() {
            return (1UL << (sizeof(long) * 8 - 1)) - 1UL;
        }
        static inline long getTombstoneKey() { return getEmptyKey() - 1L; }
        static UInt64 getHashValue(const long &val) {
            return BasicHashInfoHelper<decltype(val)>::getHashValue(val);
        }
        static bool isEqual(const long &lhs, const long &rhs) {
            return lhs == rhs;
        }
    };
    
    template<>
    struct BasicHashInfo<long long> {
        static inline long long getEmptyKey() { return 0x7fffffffffffffffLL; }
        static inline long long getTombstoneKey() { return -0x7fffffffffffffffLL - 1; }
        static UInt64 getHashValue(const long long &val) {
            return BasicHashInfoHelper<decltype(val)>::getHashValue(val);
        }
        static bool isEqual(const long long &lhs,
                            const long long &rhs) {
            return lhs == rhs;
        }
    };
    
    /// Simplistic combination of 32-bit hash values into 32-bit hash values.
    static inline UInt64 combineHashValue(UInt64 a, UInt64 b) {
        uint64_t key = (uint64_t)a << 32 | (uint64_t)b;
        key += ~(key << 32);
        key ^= (key >> 22);
        key += ~(key << 13);
        key ^= (key >> 8);
        key += (key << 3);
        key ^= (key >> 15);
        key += ~(key << 27);
        key ^= (key >> 31);
        return (unsigned)key;
    }
    
    // Provide DenseMapInfo for all pairs whose members have info.
    template<typename T, typename U>
    struct BasicHashInfo<std::pair<T, U> > {
        typedef std::pair<T, U> Pair;
        typedef BasicHashInfo<T> FirstInfo;
        typedef BasicHashInfo<U> SecondInfo;
        
        static inline Pair getEmptyKey() {
            return std::make_pair(FirstInfo::getEmptyKey(),
                                  SecondInfo::getEmptyKey());
        }
        static inline Pair getTombstoneKey() {
            return std::make_pair(FirstInfo::getTombstoneKey(),
                                  SecondInfo::getTombstoneKey());
        }
        static UInt64 getHashValue(const Pair& PairVal) {
            return combineHashValue(FirstInfo::getHashValue(PairVal.first),
                                    SecondInfo::getHashValue(PairVal.second));
        }
        static bool isEqual(const Pair &LHS, const Pair &RHS) {
            return FirstInfo::isEqual(LHS.first, RHS.first) &&
            SecondInfo::isEqual(LHS.second, RHS.second);
        }
    };
    
    template<typename ...Ts>
    struct BasicHashInfo<std::tuple<Ts...> > {
        typedef std::tuple<Ts...> Tuple;
        
        /// Helper class
        template<unsigned N> struct UnsignedC { };
        
        static inline Tuple getEmptyKey() {
            return Tuple(BasicHashInfo<Ts>::getEmptyKey()...);
        }
        
        static inline Tuple getTombstoneKey() {
            return Tuple(BasicHashInfo<Ts>::getTombstoneKey()...);
        }
        
        template<unsigned I>
        static UInt64 getHashValueImpl(const Tuple& values, std::false_type) {
            typedef typename std::tuple_element<I, Tuple>::type EltType;
            std::integral_constant<bool, I+1 == sizeof...(Ts)> atEnd;
            return combineHashValue(
                                    BasicHashInfo<EltType>::getHashValue(std::get<I>(values)),
                                    getHashValueImpl<I+1>(values, atEnd));
        }
        
        template<unsigned I>
        static UInt64 getHashValueImpl(const Tuple& values, std::true_type) {
            return 0;
        }
        
        static unsigned getHashValue(const std::tuple<Ts...>& values) {
            std::integral_constant<bool, 0 == sizeof...(Ts)> atEnd;
            return getHashValueImpl<0>(values, atEnd);
        }
        
        template<unsigned I>
        static bool isEqualImpl(const Tuple &lhs, const Tuple &rhs, std::false_type) {
            typedef typename std::tuple_element<I, Tuple>::type EltType;
            std::integral_constant<bool, I+1 == sizeof...(Ts)> atEnd;
            return BasicHashInfo<EltType>::isEqual(std::get<I>(lhs), std::get<I>(rhs))
            && isEqualImpl<I+1>(lhs, rhs, atEnd);
        }
        
        template<unsigned I>
        static bool isEqualImpl(const Tuple &lhs, const Tuple &rhs, std::true_type) {
            return true;
        }
        
        static bool isEqual(const Tuple &lhs, const Tuple &rhs) {
            std::integral_constant<bool, 0 == sizeof...(Ts)> atEnd;
            return isEqualImpl<0>(lhs, rhs, atEnd);
        }
    };
    
    template <>
    struct BasicHashInfo<String> {
        static inline String getEmptyKey() {
            return String(reinterpret_cast<const char *>(~static_cast<uintptr_t>(0)), 0);
        }
        
        static inline String getTombstoneKey() {
            return String(reinterpret_cast<const char *>(~static_cast<uintptr_t>(1)), 0);
        }
        
        static UInt64 getHashValue(const String &val) {
            assert(val.data() != getEmptyKey().data() && "Cannot hash the empty key!");
            assert(val.data() != getTombstoneKey().data() &&
                   "Cannot hash the tombstone key!");
            return (UInt64)(val.hash());
        }
        
        static bool isEqual(const String &lhs, const String &rhs) {
            if (rhs.data() == getEmptyKey().data())
                return lhs.data() == getEmptyKey().data();
            if (rhs.data() == getTombstoneKey().data())
                return lhs.data() == getTombstoneKey().data();
            return lhs == rhs;
        }
    };
    
    template <>
    struct BasicHashInfo<const String> {
        static inline const String getEmptyKey() {
            return String(reinterpret_cast<const char *>(~static_cast<uintptr_t>(0)), 0);
        }
        
        static inline const String getTombstoneKey() {
            return String(reinterpret_cast<const char *>(~static_cast<uintptr_t>(1)), 0);
        }
        
        static UInt64 getHashValue(const String &val) {
            assert(val.data() != getEmptyKey().data() && "Cannot hash the empty key!");
            assert(val.data() != getTombstoneKey().data() &&
                   "Cannot hash the tombstone key!");
            return (UInt64)(val.hash());
        }
        
        static bool isEqual(const String &lhs, const String &rhs) {
            if (rhs.data() == getEmptyKey().data())
                return lhs.data() == getEmptyKey().data();
            if (rhs.data() == getTombstoneKey().data())
                return lhs.data() == getTombstoneKey().data();
            return lhs == rhs;
        }
    };
}

#endif /* BasicHashTypeInfo_h */
