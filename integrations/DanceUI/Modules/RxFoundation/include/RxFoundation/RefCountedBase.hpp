//
//  RefCountedBase.hpp
//  RxFoundation
//
//  Created by closure on 10/1/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef RefCountedBase_hpp
#define RefCountedBase_hpp

#include <RxFoundation/RxBase.hpp>

namespace Rx {
    template <class Derived>
    class RefCountedBase {
    public:
        typedef uint64_t RefCountType;
        
        RefCountedBase() : ref_cnt(0) {}
        RefCountedBase(const RefCountedBase &) : ref_cnt(0) {}
        virtual ~RefCountedBase() {}
        
        void retain() const { ++ref_cnt; }
        void release() const {
            if (ref_cnt <= 0) {
                assert (ref_cnt > 0 && "Reference count is already zero.");
            }
            if (--ref_cnt == 0) {
                delete dynamic_cast<const Derived*>(this);
            }
        }
        
        unsigned getRetainCount() const { return ref_cnt; }
    private:
        mutable RefCountType ref_cnt;
    };
}

#endif /* RefCountedBase_hpp */
