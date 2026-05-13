//
//  Math.hpp
//  RxFoundation
//
//  Created by closure on 12/19/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Math_hpp
#define Math_hpp

#include <RxFoundation/RxBase.hpp>

namespace Rx {
    class Math final {
    private:
        Math() = delete;
        ~Math();
        Math(const Math &) = delete;
        Math(Math &&) = delete;
    public:
        static UInt64 nextPowerOf2(UInt64 v) {
            v |= (v >> 1);
            v |= (v >> 2);
            v |= (v >> 4);
            v |= (v >> 8);
            v |= (v >> 16);
            v |= (v >> 32);
            return v + 1;
        }
        
        static UInt32 nextPowerOf2(UInt32 v) {
            v |= (v >> 1);
            v |= (v >> 2);
            v |= (v >> 4);
            v |= (v >> 8);
            v |= (v >> 16);
            return v + 1;
        }
        
        static UInt16 nextPowerOf2(UInt16 v) {
            v |= (v >> 1);
            v |= (v >> 2);
            v |= (v >> 4);
            v |= (v >> 8);
            return v + 1;
        }
        
        template <typename T>
        static T abs(T v0) {
            return v0 >= 0 ? v0 : -v0;
        }
        
        template <typename T>
        static T max(T v0, T v1) {
            return v0 < v1 ? v1 : v0;
        }
        
        template <typename T>
        static T min(T v0, T v1) {
            return v0 < v1 ? v0 : v1;
        }
        
        /// CountLeadingZeros_32 - this function performs the platform optimal form of
        /// counting the number of zeros from the most significant bit to the first one
        /// bit.  Ex. CountLeadingZeros_32(0x00F000FF) == 8.
        /// Returns 32 if the word is zero.
        static inline unsigned countLeadingZeros_32(uint32_t Value) {
            unsigned Count; // result
#if __GNUC__ >= 4
            // PowerPC is defined for __builtin_clz(0)
#if !defined(__ppc__) && !defined(__ppc64__)
            if (!Value) return 32;
#endif
            Count = __builtin_clz(Value);
#else
            if (!Value) return 32;
            Count = 0;
            // bisection method for count leading zeros
            for (unsigned Shift = 32 >> 1; Shift; Shift >>= 1) {
                uint32_t Tmp = Value >> Shift;
                if (Tmp) {
                    Value = Tmp;
                } else {
                    Count |= Shift;
                }
            }
#endif
            return Count;
        }
        
        static inline unsigned log2_32_Ceil(UInt32 v) {
            return 32 - countLeadingZeros_32(v - 1);
        }
    };
}

#endif /* Math_hpp */
