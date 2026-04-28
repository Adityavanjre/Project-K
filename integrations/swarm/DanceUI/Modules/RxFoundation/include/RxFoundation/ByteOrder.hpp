//
//  ByteOrder.hpp
//  RxFoundation
//
//  Created by closure on 3/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef ByteOrder_hpp
#define ByteOrder_hpp


#include <RxFoundation/type_traits.hpp>
#include <stdexcept>

namespace Rx {
    enum Endianness {
        little_endian,
        big_endian,
        network_endian = big_endian,
        
#if defined(__LITTLE_ENDIAN__)
        host_endian = little_endian
#elif defined(__BIG_ENDIAN__)
        host_endian = big_endian
#else
#error "unable to determine system endianness"
#endif
    };
    
    namespace detail {
        template <typename T, size_t sz>
        struct swap_bytes {
            RX_INLINE_VISIBILITY T operator()(T val) {
                throw std::out_of_range("data size");
            }
        };
        
        template <typename T>
        struct swap_bytes<T, 1> {
            RX_INLINE_VISIBILITY T operator()(T val) {
                return val;
            }
        };
        
        template <typename T>
        struct swap_bytes <T, 2> {
            RX_INLINE_VISIBILITY T operator()(T val) {
                return ((((val) >> 8) & 0xff) | (((val) & 0xff) << 8));
            }
        };
        
        template <typename T>
        struct swap_bytes<T, 4> {
            RX_INLINE_VISIBILITY T operator()(T val) {
                return ((((val) & 0xff000000) >> 24) |
                        (((val) & 0x00ff0000) >>  8) |
                        (((val) & 0x0000ff00) <<  8) |
                        (((val) & 0x000000ff) << 24));
            }
        };
        
        template<>
        struct swap_bytes <float, 4> {
            RX_INLINE_VISIBILITY float operator()(float val) {
                uint32_t mem = swap_bytes<uint32_t, sizeof(uint32_t)>()(*(uint32_t*)&val);
                return *(float*)&mem;
            }
        };
        
        template <typename T>
        struct swap_bytes<T, 8> {
            RX_INLINE_VISIBILITY T operator()(T val) {
                return ((((val) & 0xff00000000000000ull) >> 56) |
                        (((val) & 0x00ff000000000000ull) >> 40) |
                        (((val) & 0x0000ff0000000000ull) >> 24) |
                        (((val) & 0x000000ff00000000ull) >> 8 ) |
                        (((val) & 0x00000000ff000000ull) << 8 ) |
                        (((val) & 0x0000000000ff0000ull) << 24) |
                        (((val) & 0x000000000000ff00ull) << 40) |
                        (((val) & 0x00000000000000ffull) << 56));
            }
        };
        
        template <>
        struct swap_bytes <double, 8> {
            RX_INLINE_VISIBILITY double operator()(double val) {
                uint64_t mem = swap_bytes<uint64_t, sizeof(uint64_t)>()(*(uint64_t*)&val);
                return *(double*)&mem;
            }
        };
        
        template <Endianness from, Endianness to, class T>
        struct do_byte_swap {
            RX_INLINE_VISIBILITY T operator()(T value) {
                return swap_bytes<T, sizeof(T)>()(value);
            }
        };
        
        // specialisations when attempting to swap to the same endianess
        template <class T>
        struct do_byte_swap<little_endian, little_endian, T> {
            RX_INLINE_VISIBILITY T operator()(T value) {
                return value;
            }
        };
        template <class T> struct do_byte_swap<big_endian, big_endian, T> {
            RX_INLINE_VISIBILITY T operator()(T value) {
                return value;
            }
        };
        
    } // namespace detail
    
    template <Endianness from, Endianness to, class T>
    RX_INLINE_VISIBILITY T byte_swap(T value) {
        // ensure the data is only 1, 2, 4 or 8 bytes
        static_assert(sizeof(T) == 1 || sizeof(T) == 2 || sizeof(T) == 4 || sizeof(T) == 8, "sizeof(T) is invalid");
        // ensure we're only swapping arithmetic types
        static_assert(std::is_arithmetic<T>::value, "T is can not do swapping");
        return detail::do_byte_swap<from, to, T>()(value);
    }
    
    Int32 SwapInt32BigToHost(Int32 v);
    
}

#endif /* ByteOrder_hpp */
