//
//  Memory.hpp
//  RxFoundation
//
//  Created by closure on 9/24/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Memory_hpp
#define Memory_hpp

#include <RxFoundation/RxBase.hpp>
#include <memory>

#if DEPLOYMENT_TARGET_MACOSX
#include <malloc/malloc.h>
#elif DEPLOYMENT_TARGET_ANDROID

#endif
namespace Rx {
    class Memory {
    public:
        static void swap(void *ptr1, void *ptr2, UInt32 size) {
            if (ptr1 != ptr2) {
                // check that ptr1 and ptr2 do not overlap in undefined ways
//                checkf(reinterpret_cast<uint8 *>(ptr1)+size <= reinterpret_cast<uint8 *>(ptr2) || reinterpret_cast<uint8 *>(ptr2)+size <= reinterpret_cast<uint8 *>(ptr1),
//                       TEXT("Pointers given to FPlatformMemory::Memswap() point to overlapping memory areas, results are undefined."));
                
                void *temp = alloca(size);
                memcpy(temp, ptr1, size);
                memcpy(ptr1, ptr2, size);
                memcpy(ptr2, temp, size);
            }
        }
        
        static void set(void *ptr, Int32 v, size_t c) {
            __builtin_memset(ptr, v, c);
        }
    };
}

#endif /* Memory_hpp */
