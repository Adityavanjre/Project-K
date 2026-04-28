//
//  Allocator.hpp
//  RxFoundation
//
//  Created by closure on 2/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef Allocator_hpp
#define Allocator_hpp

#include <RxFoundation/Memory.hpp>

namespace Rx {
    class Allocator {
    public:
        static Allocator &Default;
        
    public:
        template <typename T>
        T *allocate(size_t count) {
            T *ptr = reinterpret_cast<T *>(
#if DEPLOYMENT_TARGET_MACOSX
                    malloc_zone_calloc((malloc_zone_t *)this, 1, count * sizeof(T))
#elif DEPLOYMENT_TARGET_ANDROID
            calloc(count, sizeof(T))
#endif
            );
            return ptr;
        }
        
        template <typename T>
        void deallocate(T *ptr) {
            if (ptr == nullptr) {
                return;
            }
#if DEPLOYMENT_TARGET_MACOSX
            malloc_make_purgeable((void *)ptr);
            malloc_zone_free((malloc_zone_t *)this, (void *)ptr);
#elif DEPLOYMENT_TARGET_ANDROID
            free(ptr);
#endif
        }
        
    private:
        Allocator();
        ~Allocator();
        Allocator(const Allocator &);
        Allocator(Allocator &&);
    private:
        static Allocator _Default;
    };
}

#endif /* Allocator_hpp */
