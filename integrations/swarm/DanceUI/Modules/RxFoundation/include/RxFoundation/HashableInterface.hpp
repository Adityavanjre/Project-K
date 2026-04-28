//
//  HashableInterface.hpp
//  RxFoundation
//
//  Created by closure on 2/1/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef Hashable_hpp
#define Hashable_hpp

#include <RxFoundation/RxBase.hpp>

namespace Rx {
    class HashableInterface {
    public:
        HashableInterface() {}
        virtual ~HashableInterface() {};
        
    public:
        virtual HashCode hash() const RX_NOEXCEPT = 0;
    };
    
    HashCode hash(const UInt8 *ptr, Index length) RX_NOEXCEPT;
}

#endif /* HashableInterface_hpp */
