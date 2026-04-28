//
//  CancellableInterface.hpp
//  RxFoundation
//
//  Created by closure on 3/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef CancellableInterface_h
#define CancellableInterface_h

#include <RxFoundation/RxObject.hpp>

namespace Rx {
    class CancellableInterface {
    public:
        CancellableInterface() {}
        virtual ~CancellableInterface() {}
    public:
        virtual void cancel() = 0;
    };
}

#endif /* CancellableInterface_h */
