//
//  TypeInfo.hpp
//  RxFoundation
//
//  Created by closure on 6/3/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef TypeInfo_hpp
#define TypeInfo_hpp

#include <RxFoundation/RxBase.hpp>

namespace Rx {
    class TypeInfo final {
        template <typename T>
        struct type { static void id() {} };
        
        TypeInfo() = delete;
        ~TypeInfo() = delete;
        TypeInfo(const TypeInfo &) = delete;
        TypeInfo(TypeInfo &&) = delete;
        
    public:
        using id = size_t;
        
        template <typename T>
        static id ID() {
            const id v = reinterpret_cast<size_t>(&type<T>::id);
            return v;
        }
    };
}

#endif /* TypeInfo_hpp */
