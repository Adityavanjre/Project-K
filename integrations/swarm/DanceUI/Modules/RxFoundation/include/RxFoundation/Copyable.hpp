//
//  Copyable.hpp
//  RxFoundation
//
//  Created by closure on 10/4/16.
//  Copyright © 2016 closure. All rights reserved.
//

#ifndef Copyable_h
#define Copyable_h

#include <RxFoundation/RxObject.hpp>

namespace Rx {
    template<typename MutableType>
    class CopyableProtocol {
    public:
        CopyableProtocol() {};
        virtual ~CopyableProtocol() {};
    public:
        virtual CopyableProtocol *copy() const = 0;
        virtual MutableType *mutableCopy() const = 0;
    };
}

#endif /* Copyable_h */
