//
//  NotCopyableInterface.hpp
//  RxFoundation
//
//  Created by closure on 1/7/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef NotCopyableInterface_h
#define NotCopyableInterface_h

namespace Rx {
    class NotCopyableInterface {
    public:
        NotCopyableInterface() {}
        virtual ~NotCopyableInterface() {}
    private:
        NotCopyableInterface(const NotCopyableInterface &) = delete;
        NotCopyableInterface(NotCopyableInterface &&) = delete;
        NotCopyableInterface& operator=(const NotCopyableInterface &) = delete;
    };
}

#endif /* NotCopyableInterface_h */
